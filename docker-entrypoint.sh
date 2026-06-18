#!/bin/bash
set -e

cd /home/frappe/frappe-bench

SITE_NAME="${SITE_NAME:-localhost}"

# Point this bench at the other containers (only needs doing once, but it's
# cheap to repeat on every boot, and harmless if already set).
bench set-config -g db_host mariadb
bench set-config -g redis_cache redis://redis-cache:6379
bench set-config -g redis_queue redis://redis-queue:6379
bench set-config -g redis_socketio redis://redis-queue:6379

echo "Waiting for MariaDB to accept connections..."
until mysqladmin ping -h mariadb -u root -p"${DB_ROOT_PASSWORD}" --silent 2>/dev/null; do
  sleep 2
done
echo "MariaDB is ready."

if [ ! -d "sites/${SITE_NAME}" ]; then
  echo "No existing site found — creating '${SITE_NAME}' and installing apps (first run only)..."

  bench new-site "${SITE_NAME}" \
    --db-host mariadb \
    --mariadb-root-password "${DB_ROOT_PASSWORD}" \
    --admin-password "${ADMIN_PASSWORD}" \
    --no-mariadb-socket

  bench --site "${SITE_NAME}" install-app erpnext
  bench --site "${SITE_NAME}" install-app hrms
  bench --site "${SITE_NAME}" install-app hr_photo_checkin

  bench --site "${SITE_NAME}" set-config developer_mode 1
else
  echo "Site '${SITE_NAME}' already exists — skipping setup, going straight to start."
fi

bench use "${SITE_NAME}"

echo "Starting Frappe (web + websocket + scheduler + worker)..."
exec bench start