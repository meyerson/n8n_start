variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "GCP zone"
  type        = string
  default     = "us-central1-a"
}

variable "network_name" {
  description = "VPC network name"
  type        = string
  default     = "n8n-network"
}

variable "subnet_name" {
  description = "Subnetwork name"
  type        = string
  default     = "n8n-subnet"
}

variable "machine_type" {
  description = "Compute Engine machine type"
  type        = string
  default     = "e2-micro"
}

variable "disk_size_gb" {
  description = "Persistent Disk size in GB for Postgres data"
  type        = number
  default     = 30
}

variable "db_name" {
  description = "Postgres database name"
  type        = string
  default     = "n8n"
}

variable "db_user" {
  description = "Postgres user"
  type        = string
  default     = "n8n"
}

variable "db_password" {
  description = "Postgres password (also stored in Secret Manager)"
  type        = string
  sensitive   = true
}

variable "allowed_cidr" {
  description = "CIDR for allowed inbound access to Postgres (e.g., your home IP /32)"
  type        = string
  default     = "0.0.0.0/0"
}

variable "encryption_key" {
  description = "N8N_ENCRYPTION_KEY value to store in Secret Manager"
  type        = string
  sensitive   = true
}
