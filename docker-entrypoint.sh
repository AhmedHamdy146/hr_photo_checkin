#!/bin/bash
set -e

# If we're root (the default now), fix ownership on the mounted volumes,
# then re-exec this exact script as 'frappe' with environment preserved.
if [ "$(id -u)" = "0" ]; then
  echo "Fixing ownership on /home/frappe..."
  chown -R frappe:frappe /home/frappe
  exec su -p frappe -s /bin/bash -c "$0 $*"
fi

# --- everything below this line now runs as 'frappe', same as before ---
SITE_NAME=${SITE_NAME:-localhost}
cd /home/frappe

echo "Waiting for MariaDB..."
until mysqladmin ping -h mariadb -u root -p"${DB_ROOT_PASSWORD}" --silent; do
  sleep 2
done
echo "MariaDB is ready"

if [ ! -d "frappe-bench" ]; then
    echo "Creating bench..."
    bench init frappe-bench --frappe-branch version-16
fi

cd frappe-bench

bench set-config -g db_host mariadb
bench set-config -g redis_cache redis://redis-cache:6379
bench set-config -g redis_queue redis://redis-queue:6379
bench set-config -g redis_socketio redis://redis-socketio:6379

if [ ! -d "sites/${SITE_NAME}" ]; then
    echo "Creating site..."
    bench new-site ${SITE_NAME} \
        --db-host mariadb \
        --mariadb-root-password ${DB_ROOT_PASSWORD} \
        --admin-password ${ADMIN_PASSWORD} \
        --no-mariadb-socket

    echo "Installing apps..."
    bench get-app erpnext https://github.com/frappe/erpnext --branch version-16
    bench get-app hrms https://github.com/frappe/hrms --branch version-16
    bench get-app hr_photo_checkin https://github.com/AhmedHamdy146/hr_photo_checkin

    bench --site ${SITE_NAME} install-app erpnext
    bench --site ${SITE_NAME} install-app hrms
    bench --site ${SITE_NAME} install-app hr_photo_checkin
    bench --site ${SITE_NAME} set-config developer_mode 1
fi

bench use ${SITE_NAME}
echo "Starting Frappe..."
exec bench start