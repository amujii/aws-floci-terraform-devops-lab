# AWS Floci & DevOps Learning Lab

A hands-on DevOps learning project demonstrating infrastructure automation and cloud-native tools using a local development environment.

## Technologies

- Docker and Docker Compose
- Floci (local AWS emulator)
- Terraform
- Jenkins
- Kubernetes (Kind)
- PowerShell
- Git and GitHub

## Architecture

Windows
  |
  +-- Docker Desktop
       |
       +-- Floci (localhost:4566)
       +-- Floci AWS UI (localhost:4500)
       +-- Jenkins (localhost:8080)
       +-- Terraform CLI container
       |
       +-- Kind Kubernetes Cluster
            +-- Control Plane Node

## Implemented Work

### 1. Local AWS Environment

- Configured Floci using Docker Compose.
- Configured local AWS CLI access using dummy credentials.
- Verified AWS STS identity.
- Created and listed an S3 bucket using Floci.

### 2. Terraform and AWS

- Configured Terraform AWS provider.
- Used a local provider mirror.
- Provisioned an S3 bucket named terraform-floci-demo.
- Verified Terraform state and outputs.

### 3. Terraform File Automation

Used the Terraform local provider to create a file automatically.

Resource:
- local_file.my_file

Generated file:
- terraform/fileCreation/automate.txt

Commands:

```bash
terraform init
terraform validate
terraform plan
terraform apply