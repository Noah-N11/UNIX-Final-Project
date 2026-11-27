# GCP AI Infrastructure Architecture

## Overview
The project deploys a multi-tier containerized AI application on Google Cloud Platform.
Infrastructure is provisioned using Terraform and VM startup scripts.

## Network
- Custom VPC: ai-project-vpc
- Subnet: ai-project-subnet
- Region: us-central1
- CIDR: 10.10.0.0/20
- SSH access: Google Cloud IAP
- External application access: Load balancer only

## Web Tier
- Managed Instance Group
- Minimum instances: 3
- Maximum instances: 6
- One web container per instance
- Automatic scaling
- External load balancing

## AI Tier
- CPU-only Google Compute Engine VM
- Two inference container replicas
- Internal load balancing
- Persistent model storage mounted at /models
- Container CPU and memory limits

## Database Tier
- Google Compute Engine VM
- Containerized RAG database
- Persistent database storage mounted at /data/db
- Internal network access only

## Storage
Logical volumes will be created using LVM.

Required mount points:
- /data/db - database persistence
- /models - model weights

Volumes will be configured in /etc/fstab for persistent mounting.

## Automation
Terraform provisions:
- VPC and subnet
- Firewall rules
- IAM service account
- Compute infrastructure
- Persistent disks
- Load balancers
- Instance groups

Startup scripts configure:
- Docker
- LVM
- Persistent mounts
- Containers
- Application configuration

Startup scripts must be idempotent.

## Security

- No direct public access to AI or database ports
- SSH through IAP
- Service account authentication
- Secrets stored in Secret Manager
- No secrets committed to GitHub