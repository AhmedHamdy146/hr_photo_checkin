FROM frappe/build:version-16 AS builder

ARG FRAPPE_PATH=https://github.com/frappe/frappe
ARG FRAPPE_BRANCH=version-16

USER frappe

RUN git config --global http.lowSpeedLimit 0 && \
    git config --global http.lowSpeedTime 999999 && \
    git config --global http.postBuffer 1048576000 && \
    git config --global http.version HTTP/1.1

RUN --mount=type=secret,id=apps_json,target=/opt/frappe/apps.json,uid=1000,gid=1000 \
    export APP_INSTALL_ARGS="" && \
    if [ -f /opt/frappe/apps.json ] && [ -s /opt/frappe/apps.json ]; then \
        export APP_INSTALL_ARGS="--apps_path=/opt/frappe/apps.json"; \
    fi && \
    for i in 1 2 3 4 5; do \
        bench init ${APP_INSTALL_ARGS} \
            --frappe-branch=${FRAPPE_BRANCH} \
            --frappe-path=${FRAPPE_PATH} \
            --no-procfile \
            --no-backups \
            --skip-redis-config-generation \
            --verbose \
            /home/frappe/frappe-bench && break || \
        { echo "bench init failed, attempt $i/5, retrying in 5s..."; rm -rf /home/frappe/frappe-bench; sleep 5; }; \
    done && \
    cd /home/frappe/frappe-bench && \
    echo "{}" > sites/common_site_config.json && \
    find apps -mindepth 1 -path "*/.git" | xargs rm -fr


FROM frappe/base:version-16 AS backend

USER frappe

COPY --from=builder --chown=frappe:frappe /home/frappe/frappe-bench /home/frappe/frappe-bench

WORKDIR /home/frappe/frappe-bench

VOLUME [ \
    "/home/frappe/frappe-bench/sites", \
    "/home/frappe/frappe-bench/logs" \
]
