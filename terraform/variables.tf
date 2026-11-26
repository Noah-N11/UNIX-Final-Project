variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP deployment region"
  type        = string
  default     = "us-central1"
}

variable "network_name" {
  description = "Name of the project VPC"
  type        = string
  default     = "ai-project-vpc"
}

variable "subnet_name" {
  description = "Name of the project subnet"
  type        = string
  default     = "ai-project-subnet"
}

variable "subnet_cidr" {
  description = "Subnet IP address range"
  type        = string
  default     = "10.10.0.0/20"
}
