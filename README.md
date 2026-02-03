
# n8n Start — Workspace and Quick Start

## Quick Start (Docker)
 Recommended on macOS: use Docker Desktop.
 Local run (Postgres, user-specific bind mount):

```bash
# From this folder
make up
make open
```


Stop:

```bash
make down
```

This starts a local Postgres container and points n8n at it. Data persists under `$HOME/.n8n/postgres`.

Remote DB (test parity without starting local Postgres):

```bash
make up-remote
make open
make down-remote
```

This runs n8n locally while connecting to your remote Postgres defined in [.env.postgres.remote](.env.postgres.remote).

## Container-Only
This repo documents containerized runs only. We don’t support running n8n directly on the host in these docs.

## Files in This Folder
- `docker-compose.yml`: Base compose for n8n and Postgres; bind mounts `$HOME/.n8n`.
- `.env.postgres.local`: Local environment for Postgres mode (git-ignored).
- `.env.postgres.remote`: Local n8n connecting to remote Postgres (GCP VM, git-ignored).
- `env/.env.postgres.local.example`: Template for `.env.postgres.local`.
- `env/.env.postgres.remote.example`: Template for `.env.postgres.remote`.
- `Makefile`: Convenience commands (`make up`, `make down`, `make logs`, `make open`).
- `workflows/`: Place exported workflow JSON files here (create as needed).
- `terraform/`: Stub for hybrid plan (Cloud Run + Postgres) to fill in later.
- `n8n_start.code-workspace` (optional): Saves VS Code multi-folder workspace settings; not required for single-folder use.

## Environment Setup

Environment files live at the project root and are backed by example templates in `env/`.

- Local Postgres (default `make up` / `make down` / `make psql`):
	1. Copy `env/.env.postgres.local.example` to `.env.postgres.local`.
	2. Edit `.env.postgres.local` and set real values (encryption key, DB password, runner token, etc.).

- Remote Postgres (used by `make up-remote`, `make down-remote`, `make psql-remote`):
	1. Copy `env/.env.postgres.remote.example` to `.env.postgres.remote`.
	2. Edit `.env.postgres.remote` to point at your remote Postgres host and credentials.

The real `.env.postgres.local` and `.env.postgres.remote` files are ignored via [.gitignore](.gitignore) and will not be committed.

### Why Local vs Remote Postgres?

- **Local Postgres (`.env.postgres.local`)** runs a Postgres container on your laptop and stores all n8n state under `$HOME/.n8n/postgres`. This is ideal for quick, disposable experimentation.
- **Remote Postgres (`.env.postgres.remote`)** keeps the n8n containers local but points them at a Postgres instance running elsewhere (e.g., a GCP VM). This decouples long‑lived state (users, workflows, credentials, executions) from this quick‑start repo and from your local Docker volume.
- The repo is intentionally limited to **runtime config + examples**. Actual secrets and live DB endpoints live only in your untracked `.env.postgres.*` files.

## Exporting Workflows for Version Control
- In the n8n UI: open a workflow → “Export” → save the `.json` file into `workflows/`.
- Commit those JSON files to git so you can track changes.

## Troubleshooting
- If `http://localhost:5678` doesn’t load, ensure Docker Desktop is running and retry `make up`.
- To reset local state, you can remove or rename `$HOME/.n8n` (this deletes local n8n data). Alternatively stop with `make down` and back up that folder.
- If you forget the n8n owner password, you can safely reset it without losing workflows/credentials by running `make n8n-shell` and then `n8n user-management:reset` inside the container, and following the prompts.

## Future: Remote DB / Cloud Run
- When ready to extend beyond the local/remote Postgres setups above, you can use `terraform/` to provision GCP resources (VM for Postgres, Secret Manager, VPC connector, Cloud Run service, etc.).

## Task Runners (Sidecar)
- This compose adds a `runners` sidecar so Code nodes execute out-of-process.
- Configure the shared token in `.env.postgres.local` and `.env.postgres.remote` (`N8N_RUNNERS_AUTH_TOKEN`) and keep it identical across services.
- The broker runs inside `n8n` on port 5679 (internal). The `runners` service connects via `http://n8n:5679`.
- Image versions are pinned to `2.1.4` for both `n8n` and `runners` to ensure compatibility.

