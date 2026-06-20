### Hr Photo Checkin

أHr photo checkin

A custom Frappe app that adds a required/optional photo capture step to Employee Checkin, built on top of [ERPNext](https://github.com/frappe/erpnext) and [HRMS](https://github.com/frappe/hrms).

---

## Run with Docker

The whole stack — Frappe, ERPNext, HRMS, this app, MariaDB, and Redis — runs with one command. No manual bench setup, no local Python/Node install needed.

### Requirements

- [Docker](https://docs.docker.com/get-docker/) and Docker Compose (the `docker compose` plugin, not the old standalone `docker-compose`)
- ~4 GB free disk space and a few minutes for the first build (it clones and builds Frappe, ERPNext, HRMS, and this app from scratch)

### 1. Clone and run

```bash
git clone https://github.com/AhmedHamdy146/hr_photo_checkin.git
cd hr_photo_checkin
docker compose up --build
```

First run does all of this automatically:

1. Builds the Frappe bench image (Frappe + ERPNext + HRMS + hr_photo_checkin, all `version-16`)
2. Starts MariaDB and Redis containers
3. Waits for the database, then creates a new site called `frontend`
4. Installs ERPNext, HRMS, and hr_photo_checkin on that site
5. Starts the Frappe web server, scheduler, socketio, and background workers

You'll see a long stream of `Updating DocTypes...` and `Installing ...` lines — that's normal and only happens once. The setup is done and ready when you see:

```
Starting bench...
...system | web.1 started (pid=...)
```

### 2. Log in

Open **http://localhost:8000** in your browser.

| Field | Value |
|---|---|
| Username | `Administrator` |
| Password | `admin` |

### 3. Stopping / resetting

Stop the containers, keep your data:

```bash
docker compose down
```

Stop and **wipe everything** (site, database, uploaded files) for a clean slate next time:

```bash
docker compose down -v
```

### Restarting after the first run

On every start after the first, the site already exists, so the entrypoint skips site creation and just runs `bench migrate` (to pick up any app updates) before starting the bench:

```bash
docker compose up
```

(no `--build` needed unless you've changed the `Containerfile` or `apps.json`)

---

## How it's built

- **`Containerfile`** — multi-stage build. The `builder` stage runs `bench init` with `apps.json` (Frappe + ERPNext + HRMS + this app) mounted in as a build secret, so the URLs/branches aren't baked permanently into image layers. The final `backend` stage copies the finished bench onto a clean `frappe/base:version-16` image.
- **`apps.json`** — the list of apps and branches installed into the bench. Edit this if you want to point at a fork or a different branch.
- **`docker-compose.yml`** — defines three services: `backend` (the bench container, port `8000`), `db` (MariaDB 10.6), and `redis` (Redis 6.2). Site/log data persist in named volumes (`sites`, `logs`, `db-data`, `redis-data`) so they survive `docker compose down` (but not `down -v`).
- **`entrypoint.sh`** — runs on every container start. Waits for MariaDB, points bench at the `db`/`redis` containers, creates the site on first run (or migrates on later runs), generates a `Procfile` if missing, and finally execs `bench start`.

A couple of non-obvious things `entrypoint.sh` handles, in case you're modifying it:

- The image is built with `bench init --no-procfile` (standard for production-style Frappe Docker images), so the entrypoint generates one at runtime with `bench setup procfile`.
- Redis runs as its own container here, not as a bench-managed subprocess — and the `redis-server` binary isn't even installed in this image. So the entrypoint strips the `redis_cache`/`redis_queue`/`redis_socketio` lines out of the generated Procfile; otherwise `bench start` tries to launch its own Redis, fails immediately, and honcho kills every other process along with it.

### Customizing

- **Change the admin password / DB root password:** edit the `ADMIN_PASSWORD` and `MYSQL_ROOT_PASSWORD` environment variables in `docker-compose.yml` (keep both `MYSQL_ROOT_PASSWORD` entries — under `backend` and under `db` — in sync).
- **Change the exposed port:** edit the `ports` mapping under `backend` in `docker-compose.yml`, e.g. `"8080:8000"` to use port 8080 on your machine.
- **Point at a different app/fork/branch:** edit `apps.json`, then rebuild with `docker compose up --build`.

### Troubleshooting

- **`Procfile does not exist or is not a file`** — shouldn't happen with the current `entrypoint.sh`, but if you've modified it and hit this, it means `bench setup procfile` didn't run before `bench start`.
- **`redis-server: not found` / processes start then immediately stop** — same Redis vs. bench-managed-Redis conflict described above. Check that `entrypoint.sh` is stripping the redis lines from the Procfile.
- **Stuck on `Waiting for database...`** — the `db` container may still be initializing (first run can take ~15-20s). Give it a minute; if it never resolves, run `docker compose logs db` to check for MariaDB errors.
- **Want a totally clean retry** — `docker compose down -v` removes all volumes (site, DB, Redis data), then `docker compose up --build` starts completely fresh.

---

## Manual Installation (without Docker)

You can install this app using the [bench](https://github.com/frappe/bench) CLI on an existing bench:

```bash
cd $PATH_TO_YOUR_BENCH
bench get-app $URL_OF_THIS_REPO --branch main
bench install-app hr_photo_checkin
```

### Contributing

This app uses `pre-commit` for code formatting and linting. Please [install pre-commit](https://pre-commit.com/#installation) and enable it for this repository:

```bash
cd apps/hr_photo_checkin
pre-commit install
```

Pre-commit is configured to use the following tools for checking and formatting your code:

- ruff
- eslint
- prettier
- pyupgrade

### License

mit