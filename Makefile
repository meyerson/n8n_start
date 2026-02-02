ENV_FILE ?=.env.postgres.local
COMPOSE := ENV_FILE=$(ENV_FILE) docker compose --env-file $(ENV_FILE)

.PHONY: up up-remote down down-remote logs open status psql db-shell psql-remote n8n-shell

up:
	$(COMPOSE) --profile local-db up -d

down:
	$(COMPOSE) --profile local-db down

# Open an interactive shell inside the running n8n container
n8n-shell:
	docker exec -it n8n sh

up-remote:
	ENV_FILE=.env.postgres.remote docker compose --env-file .env.postgres.remote up -d

down-remote:
	ENV_FILE=.env.postgres.remote docker compose --env-file .env.postgres.remote down

logs:
	$(COMPOSE) logs -f n8n

open:
	# macOS convenience
	open http://localhost:5678

status:
	$(COMPOSE) ps

psql:
	$(COMPOSE) --profile local-db exec postgres sh -lc 'psql "postgres://$$POSTGRES_USER:$$POSTGRES_PASSWORD@localhost/$$POSTGRES_DB"'

# Open a shell inside the local postgres container
db-shell:
	$(COMPOSE) --profile local-db exec postgres sh

# Connect to remote Postgres using values from .env.postgres.remote (no local container needed)
psql-remote:
	ENV_FILE=.env.postgres.remote docker run --rm -it --env-file .env.postgres.remote postgres:15-alpine \
	sh -lc 'psql -h "$$DB_POSTGRESDB_HOST" -U "$$DB_POSTGRESDB_USER" -d "$$DB_POSTGRESDB_DATABASE"'
