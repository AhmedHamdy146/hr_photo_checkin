#!/bin/bash
set -e

# If we're root (the default at container start), fix ownership on the
# mounted volumes, then re-exec this exact script as 'frappe'.
if [ "$(id -u)" = "0" ]; then
  echo "Fixing ownership on /home/frappe..."
  chown -R frappe:frappe /home/frappe
  exec su -p frappe -s /bin/bash -c "$0 $*"
fi

# --- everything below this line runs as 'frappe' ---
SITE_NAME=${SITE_NAME:-localhost}
cd /home/frappe

echo "Waiting for MariaDB..."
until mysqladmin ping -h mariadb -u root -p"${DB_ROOT_PASSWORD}" --silent >/dev/null 2>&1; do
  sleep 2
done
echo "MariaDB is ready"

if [ ! -d "frappe-bench" ]; then
    echo "Creating bench (this clones frappe itself, ~3-5 min)..."
    bench init frappe-bench --frappe-branch version-16 --skip-redis-config-generation --no-backups
fi

cd frappe-bench

# Point bench at the docker-compose services instead of localhost.
# redis-socketio is intentionally mapped onto the same instance as
# redis-cache: modern Frappe no longer needs a dedicated socketio
# Redis process, but bench still reads this config key.
bench set-mariadb-host mariadb
bench set-redis-cache-host redis://redis-cache:6379
bench set-redis-queue-host redis://redis-queue:6379
bench set-redis-socketio-host redis://redis-cache:6379

# bench start normally also tries to launch its OWN local redis_cache,
# redis_queue, redis_socketio, and watch processes via the Procfile —
# which fights with the external containers above. Strip those lines
# so bench only runs web/socketio/worker/schedule, talking to the
# containers we already configured.
sed -i '/^redis/d; /^watch/d' ./Procfile

if [ ! -d "sites/${SITE_NAME}" ]; then
    echo "Creating site '${SITE_NAME}'..."
    bench new-site ${SITE_NAME} \
        --db-host mariadb \
        --mariadb-root-password "${DB_ROOT_PASSWORD}" \
        --admin-password "${ADMIN_PASSWORD}" \
        --no-mariadb-socket

    echo "Fetching apps..."
    bench get-app erpnext --branch version-16
    bench get-app hrms --branch version-16
    bench get-app hr_photo_checkin https://github.com/AhmedHamdy146/hr_photo_checkin

    echo "Installing apps on site..."
    bench --site ${SITE_NAME} install-app erpnext
    bench --site ${SITE_NAME} install-app hrms
    bench --site ${SITE_NAME} install-app hr_photo_checkin
    bench --site ${SITE_NAME} set-config developer_mode 1
fi

bench use ${SITE_NAME}
echo "Starting Frappe (web + websocket + scheduler + worker)..."
exec bench start