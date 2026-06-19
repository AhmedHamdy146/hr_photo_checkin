FROM python:3.14-slim-bookworm

ENV DEBIAN_FRONTEND=noninteractive

# --- System dependencies needed to build Frappe + its Python deps ---
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
    wkhtmltopdf \
    cron \
    && rm -rf /var/lib/apt/lists/*

# --- Node 24 LTS, required by Frappe v16's package.json (>=24) ---
RUN curl -fsSL https://deb.nodesource.com/setup_24.x | bash - \
    && apt-get install -y nodejs \
    && npm install -g yarn

# --- Non-root user that bench/frappe expects ---
RUN useradd -ms /bin/bash frappe

USER frappe
WORKDIR /home/frappe

# Pin frappe-bench to a known-good release instead of "whatever is latest today"
RUN pip install --user --no-cache-dir "frappe-bench==5.31.0"
ENV PATH="/home/frappe/.local/bin:$PATH"

# Back to root only so the entrypoint can fix volume ownership at container start.
# It re-execs itself as 'frappe' immediately after — nothing app-related runs as root.
USER root

COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh && chown frappe:frappe /docker-entrypoint.sh

WORKDIR /home/frappe/frappe-bench
EXPOSE 8000 9000

ENTRYPOINT ["/docker-entrypoint.sh"]