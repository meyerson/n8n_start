# Terraform — Infrastructure

This folder contains Terraform configurations for deploying n8n on Google Cloud.

Scope (to be added as .tf files):
- VPC and firewall rules
- Compute Engine VM (e2-micro) with a Persistent Disk running Dockerized Postgres (production DB)
- Secret Manager entries (`N8N_ENCRYPTION_KEY`, `DB_PASSWORD`)
- Serverless VPC Access Connector
- Cloud Run service using the official n8n image

Not used for local development. These configs will be populated to deploy on GCP.
