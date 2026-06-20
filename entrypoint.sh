#!/bin/bash
set -e

SITE_NAME="frontend"

cd /home/frappe/frappe-bench

# Wait for MariaDB to accept connections before doing anything else
echo "Waiting for database at ${DB_HOST}:${DB_PORT}..."
until mysqladmin ping -h "${DB_HOST}" -P "${DB_PORT}" --silent; do
    sleep 2
done
echo "Database is up."

# Point bench at the right db/redis hosts (config is wiped on every fresh volume)
bench set-config -g db_host "${DB_HOST}"
bench set-config -gp db_port "${DB_PORT}"
bench set-config -g redis_cache "redis://${REDIS_CACHE}"
bench set-config -g redis_queue "redis://${REDIS_QUEUE}"
bench set-config -g redis_socketio "redis://${REDIS_QUEUE}"

# Only create the site if it doesn't already exist (so restarts don't re-run this)
if [ ! -d "sites/${SITE_NAME}" ]; then
    echo "Site not found. Creating new site: ${SITE_NAME}"
    bench new-site "${SITE_NAME}" \
        --mariadb-user-host-login-scope='%' \
        --admin-password="${ADMIN_PASSWORD}" \
        --db-root-username=root \
        --db-root-password="${MYSQL_ROOT_PASSWORD}" \
        --no-mariadb-socket

    bench --site "${SITE_NAME}" install-app erpnext
    bench --site "${SITE_NAME}" install-app hrms
    bench --site "${SITE_NAME}" install-app hr_photo_checkin
    bench --site "${SITE_NAME}" set-config developer_mode 1

    echo "Site created and apps installed."
else
    echo "Site ${SITE_NAME} already exists. Skipping creation."
fi

bench use "${SITE_NAME}"

echo "Starting bench..."
exec bench start
