# Running hr_photo_checkin with Docker

This spins up a complete, ready-to-use ERPNext + HRMS + hr_photo_checkin
instance. No bench setup, no manual app installs — just Docker.

## Prerequisites
- Docker Engine + Docker Compose v2 (`docker compose version` should work)
- ~4 GB free RAM, ~10 GB free disk
- Internet access during the first build (it git-clones erpnext, hrms, and
  this app's GitHub repo)

## Usage

```bash
git clone https://github.com/AhmedHamdy146/hr_photo_checkin.git
cd hr_photo_checkin
docker compose up --build -d
```

First run takes 10–20 minutes (cloning + building assets + creating the
site). Watch progress with:

```bash
docker compose logs -f erp
```

Once you see `Starting Frappe (web + websocket + scheduler + worker)...`
followed by the bench banner, open:

```
http://localhost:8000
```

Login: `Administrator` / the value of `ADMIN_PASSWORD` in `.env`
(defaults to `admin123`).

Every run after the first skips site creation entirely and just starts
the server in a few seconds — the site lives in a named Docker volume.

## Resetting everything
```bash
docker compose down -v   # -v also wipes the database/site volumes
```

## Updating after you push new commits to hr_photo_checkin
Because the app is pulled fresh from GitHub during the **image build**
(not copied from your local files), a normal `docker compose up` won't
pick up new commits. Rebuild without cache:

```bash
docker compose build --no-cache erp
docker compose up -d
```

## Notes
- `PYTHON_VERSION` / `NODE_VERSION` build args in the `Dockerfile` should
  match whatever your own working bench uses — check with
  `python3 --version` / `node --version` inside your WSL2 bench and update
  the `ARG` defaults if they differ.
- The browser's camera API (`getUserMedia`, used by the photo check-in
  feature) treats `localhost` as a secure context, so the camera will work
  fine over plain HTTP for local testing — no certificates needed.
- This is a single-container setup (one process running everything via
  `bench start`) — great for demos and letting teammates try the feature.
  For a real production rollout, split into separate worker/websocket/nginx
  services per Frappe's own docs.