output "postgres_vm_public_ip" {
  description = "Public IP of the Postgres VM"
  value       = google_compute_instance.postgres_vm.network_interface[0].access_config[0].nat_ip
}

output "postgres_vm_private_ip" {
  description = "Private IP of the Postgres VM"
  value       = google_compute_instance.postgres_vm.network_interface[0].network_ip
}

output "n8n_cloud_run_service_name" {
  description = "Cloud Run service name"
  value       = google_cloud_run_v2_service.n8n.name
}

output "n8n_encryption_key_secret" {
  description = "Secret Manager secret ID for N8N_ENCRYPTION_KEY"
  value       = google_secret_manager_secret.n8n_key.secret_id
}

output "db_password_secret" {
  description = "Secret Manager secret ID for Postgres password"
  value       = google_secret_manager_secret.db_password.secret_id
}
