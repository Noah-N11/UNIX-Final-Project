output "vpc_name" {
  description = "Created VPC name"
  value       = google_compute_network.project_vpc.name
}

output "vpc_id" {
  description = "Created VPC ID"
  value       = google_compute_network.project_vpc.id
}

output "subnet_name" {
  description = "Created subnet name"
  value       = google_compute_subnetwork.project_subnet.name
}

output "subnet_cidr" {
  description = "Created subnet CIDR"
  value       = google_compute_subnetwork.project_subnet.ip_cidr_range
}

output "region" {
  description = "Deployment region"
  value       = var.region
}

output "vm_service_account_email" {
  description = "Service account used by project VMs"
  value       = google_service_account.vm_service_account.email
}