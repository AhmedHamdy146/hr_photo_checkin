# ---------------------------------------------------------------------------
# hr_photo_checkin — all-in-one Frappe v16 image
# ---------------------------------------------------------------------------
# Adjust these three to MATCH the versions you already use in your working
# WSL2 bench (run `python3 --version` and `node --version` there and copy
# them here exactly — that's the combo you already know works with your app).
ARG PYTHON_VERSION=3.14.0
ARG NODE_VERSION=20.19.2

FROM python:${PYTHON_VERSION}-slim-bookworm AS base

ARG FRAPPE_BRANCH=version-16
ARG FRAPPE_PATH=https://github.com/frappe/frappe
ARG NODE_VERSION

ENV NVM_DIR=/home/frappe/.nvm
ENV PATH=${NVM_DIR}/versions/node/v${NODE_VERSION}/bin/:/home/frappe/.local/bin:${PATH}

RUN useradd -ms /bin/bash frappe \
 && apt-get update \
 && apt-get install --no-install-recommends -y \
      git curl wget vim cron gettext-base \
      mariadb-client \
      libpango-1.0-0 libharfbuzz0b libpangoft2-1.0-0 libpangocairo-1.0-0 \
      libffi-dev libssl-dev build-essential python3-dev pkg-config \
      libcairo2-dev libpango1.0-dev libjpeg-dev libgif-dev librsvg2-dev \
      libpq-dev liblcms2-dev libldap2-dev libmariadb-dev libsasl2-dev \
      libtiff-dev libwebp-dev libbz2-dev tk8.6-dev rlwrap \
      fontconfig libxrender1 xfonts-75dpi xfonts-base \
 && rm -rf /var/lib/apt/lists/*

# wkhtmltopdf — needed for print formats / PDF generation
RUN ARCH=$(dpkg --print-architecture) \
 && curl -sLo /tmp/wkhtmltox.deb \
      "https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6.1-3/wkhtmltox_0.12.6.1-3.bookworm_${ARCH}.deb" \
 && apt-get update \
 && apt-get install -y /tmp/wkhtmltox.deb \
 && rm -rf /tmp/wkhtmltox.deb /var/lib/apt/lists/*

USER frappe
WORKDIR /home/frappe

# Node via nvm (kept in user space, no root needed)
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash \
 && . ${NVM_DIR}/nvm.sh \
 && nvm install ${NODE_VERSION} \
 && nvm alias default ${NODE_VERSION} \
 && npm install -g yarn

RUN pip install --user --no-cache-dir frappe-bench

# This is the file that makes the magic happen: bench init will git-clone
# erpnext, hrms and hr_photo_checkin in one shot using this list.
COPY apps.json /opt/frappe/apps.json

RUN bench init frappe-bench \
      --frappe-branch=${FRAPPE_BRANCH} \
      --frappe-path=${FRAPPE_PATH} \
      --apps_path=/opt/frappe/apps.json \
      --no-procfile \
      --no-backups \
      --skip-redis-config-generation \
      --verbose

WORKDIR /home/frappe/frappe-bench

COPY --chown=frappe:frappe docker-entrypoint.sh /home/frappe/frappe-bench/docker-entrypoint.sh
USER root
RUN chmod +x /home/frappe/frappe-bench/docker-entrypoint.sh
USER frappe

VOLUME [ "/home/frappe/frappe-bench/sites", "/home/frappe/frappe-bench/logs" ]

EXPOSE 8000 9000

ENTRYPOINT ["/home/frappe/frappe-bench/docker-entrypoint.sh"]