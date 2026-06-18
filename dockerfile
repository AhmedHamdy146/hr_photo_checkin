FROM python:3.14-slim-bookworm
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    git curl wget \
    mariadb-client \
    redis-tools \
    build-essential \
    python3-dev \
    pkg-config \
    libffi-dev libssl-dev \
    libmariadb-dev \
    libjpeg-dev liblcms2-dev \
    libldap2-dev libsasl2-dev \
    libtiff-dev libwebp-dev \
    fontconfig \
    && rm -rf /var/lib/apt/lists/*

# Node 24 LTS — Frappe v16's package.json requires >=24
RUN curl -fsSL https://deb.nodesource.com/setup_24.x | bash - \
    && apt-get install -y nodejs
RUN npm install -g yarn

RUN useradd -ms /bin/bash frappe

USER frappe
WORKDIR /home/frappe
RUN pip install --user frappe-bench
ENV PATH="/home/frappe/.local/bin:$PATH"

# Switch back to root: the entrypoint needs root once, at container start,
# to fix ownership on the mounted volumes — then it drops to 'frappe' itself.
USER root

COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

WORKDIR /home/frappe/frappe-bench
EXPOSE 8000 9000
ENTRYPOINT ["/docker-entrypoint.sh"]