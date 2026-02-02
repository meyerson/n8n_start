terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = ">= 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

provider "google-beta" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

# VPC and Subnet
resource "google_compute_network" "n8n" {
  name                    = var.network_name
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "n8n" {
  name          = var.subnet_name
  ip_cidr_range = "10.10.0.0/24"
  region        = var.region
  network       = google_compute_network.n8n.id
}

# Firewall: allow SSH and Postgres (restricted by allowed_cidr)
resource "google_compute_firewall" "allow_ssh" {
  name    = "n8n-allow-ssh"
  network = google_compute_network.n8n.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = [var.allowed_cidr]
}

resource "google_compute_firewall" "allow_postgres" {
  name    = "n8n-allow-postgres"
  network = google_compute_network.n8n.name

  allow {
    protocol = "tcp"
    ports    = ["5432"]
  }

  source_ranges = [var.allowed_cidr]
}

# Persistent Disk for Postgres
resource "google_compute_disk" "postgres" {
  name  = "n8n-pd"
  type  = "pd-standard"
  zone  = var.zone
  size  = var.disk_size_gb
}

# Service account for the VM
resource "google_service_account" "vm_sa" {
  account_id   = "n8n-vm-sa"
  display_name = "n8n VM Service Account"
}

# Compute Instance for Postgres
resource "google_compute_instance" "postgres_vm" {
  name         = "n8n-postgres-vm"
  machine_type = var.machine_type
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
    }
  }

  attached_disk {
    source      = google_compute_disk.postgres.id
    device_name = google_compute_disk.postgres.name
  }

  network_interface {
    subnetwork = google_compute_subnetwork.n8n.id
    access_config {}
  }

  service_account {
    email  = google_service_account.vm_sa.email
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }

  metadata = {
    DB_NAME     = var.db_name
    DB_USER     = var.db_user
    DB_PASSWORD = var.db_password
  }

  metadata_startup_script = templatefile("${path.module}/startup.sh", {
    DB_NAME     = var.db_name,
    DB_USER     = var.db_user,
    DB_PASSWORD = var.db_password
  })
}

# Secret Manager: N8N_ENCRYPTION_KEY and DB_PASSWORD
resource "google_secret_manager_secret" "n8n_key" {
  secret_id  = "n8n-encryption-key"
  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "n8n_key_v" {
  secret      = google_secret_manager_secret.n8n_key.id
  secret_data = var.encryption_key
}

resource "google_secret_manager_secret" "db_password" {
  secret_id  = "n8n-db-password"
  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "db_password_v" {
  secret      = google_secret_manager_secret.db_password.id
  secret_data = var.db_password
}

# Serverless VPC Access Connector for Cloud Run
resource "google_vpc_access_connector" "run_connector" {
  name   = "n8n-run-connector"
  region = var.region
  network = google_compute_network.n8n.name
  ip_cidr_range = "10.10.10.0/28"
}

# Cloud Run (n8n) — skeleton service
resource "google_cloud_run_v2_service" "n8n" {
  name     = "n8n-service"
  location = var.region

  template {
    containers {
      image = "n8nio/n8n:latest"

      env {
        name  = "N8N_PROTOCOL"
        value = "https"
      }
      env {
        name  = "N8N_HOST"
        value = "YOUR_DOMAIN"
      }
      env {
        name  = "N8N_EDITOR_BASE_URL"
        value = "https://YOUR_DOMAIN"
      }
      env {
        name  = "WEBHOOK_URL"
        value = "https://YOUR_DOMAIN"
      }
      env {
        name  = "GENERIC_TIMEZONE"
        value = "UTC"
      }
      env {
        name = "N8N_ENCRYPTION_KEY"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.n8n_key.secret_id
            version = "latest"
          }
        }
      }
      env {
        name  = "DB_TYPE"
        value = "postgresdb"
      }
      env {
        name  = "DB_POSTGRESDB_HOST"
        value = google_compute_instance.postgres_vm.network_interface[0].network_ip
      }
      env {
        name  = "DB_POSTGRESDB_PORT"
        value = "5432"
      }
      env {
        name  = "DB_POSTGRESDB_DATABASE"
        value = var.db_name
      }
      env {
        name  = "DB_POSTGRESDB_USER"
        value = var.db_user
      }
      env {
        name = "DB_POSTGRESDB_PASSWORD"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.db_password.secret_id
            version = "latest"
          }
        }
      }
    }

    vpc_access {
      connector = google_vpc_access_connector.run_connector.name
      egress    = "ALL_TRAFFIC"
    }
  }

  ingress = "INGRESS_TRAFFIC_ALL"
}
