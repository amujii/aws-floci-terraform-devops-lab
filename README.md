# AWS Floci & DevOps Engineering Lab

A hands-on DevOps learning project focused on infrastructure automation, containerization, CI/CD and Kubernetes.

This repository documents practical implementations, configurations, troubleshooting experiences and lessons learned while building a local AWS and DevOps environment using Docker, Floci, Terraform, Jenkins and Kubernetes.

The primary objective is to understand how real-world DevOps tools work together while minimizing infrastructure costs through local development and AWS service emulation.

---

## 1. Project Objectives

The objectives of this project are:

- Build a local AWS development environment using Floci.
- Understand Infrastructure as Code (IaC) using Terraform.
- Automate AWS resource provisioning.
- Automate local file creation using Terraform.
- Configure Jenkins for CI/CD automation.
- Understand Docker and container management.
- Learn Kubernetes architecture and application deployment.
- Integrate Git and GitHub into the development workflow.
- Document real implementation challenges and troubleshooting solutions.

## 2. Technology Stack

| Technology | Purpose |
|---|---|
| Docker Desktop | Container runtime |
| Docker Compose | Multi-container orchestration |
| Floci | Local AWS service emulation |
| Terraform | Infrastructure as Code |
| Jenkins | CI/CD automation |
| AWS CLI | Interacting with AWS-compatible services |
| Git | Version control |
| GitHub | Source code hosting |
| Kind | Local Kubernetes cluster |
| kubectl | Kubernetes cluster management |
| PowerShell | Windows command-line environment |

### Environment and versions

Versions verified during implementation:

| Component | Version |
|---|---|
| Terraform | 1.17.2 |
| AWS Terraform provider | 6.73.0 |
| Docker Engine | 29.4.3 |
| Git | 2.53.0.windows.2 |
| kubectl | 1.34.1 |
| Kind | 0.33.0 |
| Kubernetes node | 1.37.0 |
| Operating system | Windows |

Note: These are the versions recorded during the initial implementation. Image tags such as `latest` and `lts` may resolve to newer versions over time.

---

## 3. Project Architecture

The project uses Docker Desktop as the local container environment.

```text
                 Windows Machine
                        |
                 Docker Desktop
                        |
             Docker Compose Environment
                        |
       +----------------+----------------+
       |                |                |
       v                v                v
     Floci            Jenkins         Terraform
       |                |                |
       |                |                |
       v                v                v
 Local AWS          CI/CD Pipeline    Infrastructure
 Emulator                              Automation
       |
       v
   S3 Bucket


       Separate Local Kubernetes Environment

                 Docker Desktop
                        |
                        v
                 Kind Cluster
                        |
                        v
                 Control Plane
                        |
                        v
                  Kubernetes
```

### Local service endpoints

| Service | Local endpoint |
|---|---|
| Floci | http://localhost:4566 |
| Floci AWS UI | http://localhost:4500 |
| Jenkins | http://localhost:8080 |
| Kubernetes | Managed using kubectl |

---

## 4. Repository Structure

```text
aws-floci-terraform-devops-lab/
|
+-- .gitignore
+-- README.md
+-- docker-compose.yml
+-- terraform.tfrc
|
+-- terraform/
|   |
|   +-- main.tf
|   +-- provider.tf
|   +-- .terraform.lock.hcl
|   |
|   +-- fileCreation/
|       |
|       +-- main.tf
|       +-- .terraform.lock.hcl
|
+-- docs/
    |
    +-- learning-progress.md
```

Local Terraform state files, provider binaries, generated files and Floci data are excluded from Git.

---

# 5. Implementation Details

## Phase 1: Docker and Floci Setup

### Objective

Build a local AWS-compatible environment without provisioning real AWS infrastructure.

### Docker Compose

Docker Compose is used to manage the following services:

- Floci
- Jenkins
- Terraform

The Floci service exposes port 4566 and uses local storage.

Jenkins is configured with persistent storage through a Docker named volume.

Terraform runs inside the official HashiCorp Terraform container.

### Important configuration

Floci endpoint:

```text
http://floci:4566
```

The hostname `floci` is used for communication between containers on the Docker Compose network.

### Verification

```powershell
docker compose up -d
```

Check running services:

```powershell
docker compose ps
```

Check container resource usage:

```powershell
docker stats --no-stream
```

Check Floci connectivity:

```powershell
docker compose exec floci sh
```

### Learning outcome

- Understanding Docker images and containers.
- Understanding Docker Compose services.
- Understanding container networking.
- Understanding Docker volumes.
- Understanding local AWS emulation.

---

## Phase 2: Terraform Setup and AWS Provider Configuration

### Objective

Use Terraform to provision AWS-compatible resources through Floci.

### Terraform environment

Terraform is installed and executed through Docker rather than directly through Windows.

Terraform version:

```text
Terraform v1.17.2
on linux_amd64
```

Verification:

```powershell
docker compose run --rm terraform version
```

### AWS provider configuration

The Terraform AWS provider is configured to communicate with Floci.

Example:

```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region     = "us-east-1"
  access_key = "test"
  secret_key = "test"

  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
  s3_use_path_style           = true

  endpoints {
    s3 = "http://floci:4566"
  }
}
```

The credentials shown above are dummy credentials for local emulation.

### Terraform provider mirror

A local provider mirror was configured to avoid repeatedly downloading the AWS provider.

The mirror contains:

```text
registry.terraform.io/
    hashicorp/
        aws/
            terraform-provider-aws_6.73.0_linux_amd64.zip
```

The Terraform CLI configuration uses a filesystem mirror first and allows direct provider downloads when a provider is not available in the mirror.

### Important Terraform commands

```powershell
docker compose run --rm terraform version
```

```powershell
docker compose run --rm terraform init
```

```powershell
docker compose run --rm terraform validate
```

```powershell
docker compose run --rm terraform plan
```

```powershell
docker compose run --rm terraform apply
```

---

## Phase 3: S3 Bucket Provisioning Using Terraform

### Objective

Provision an S3 bucket using Terraform and Floci.

### Terraform configuration

File: `terraform/main.tf`

```hcl
resource "aws_s3_bucket" "terraform_demo" {
  bucket = "terraform-floci-demo"
}

output "bucket_name" {
  value = aws_s3_bucket.terraform_demo.bucket
}
```

### Implementation

Initialize Terraform:

```powershell
docker compose run --rm terraform init
```

Validate the configuration:

```powershell
docker compose run --rm terraform validate
```

Preview infrastructure changes:

```powershell
docker compose run --rm terraform plan
```

Create the S3 bucket:

```powershell
docker compose run --rm terraform apply
```

### Result

Successfully created:

```text
terraform-floci-demo
```

Terraform output:

```text
Apply complete! Resources: 1 added, 0 changed, 0 destroyed.

Outputs:

bucket_name = "terraform-floci-demo"
```

### State verification

```powershell
docker compose run --rm terraform state list
```

Expected resource:

```text
aws_s3_bucket.terraform_demo
```

Additional verification:

```powershell
docker compose run --rm terraform show
```

### Learning outcome

- Terraform resources.
- Terraform providers.
- Infrastructure provisioning.
- Terraform state management.
- Terraform outputs.
- Infrastructure planning and execution.

---

## Phase 4: Terraform Local File Automation

### Objective

Automate local file creation using Terraform instead of manually creating files.

This implementation uses the `hashicorp/local` provider.

### Directory

```text
terraform/
    |
    +-- fileCreation/
        |
        +-- main.tf
```

### Terraform configuration

File: `terraform/fileCreation/main.tf`

```hcl
resource "local_file" "my_file" {
  filename = "${path.module}/automate.txt"

  content = "this is automate file created using terraform"
}
```

### Explanation

| Component | Purpose |
|---|---|
| `local_file` | Terraform resource type |
| `my_file` | Resource name |
| `filename` | Destination file path |
| `path.module` | Current Terraform module directory |
| `content` | Content written into the file |

### Implementation commands

Run the commands from the project root, where `docker-compose.yml` exists.

Initialize:

```powershell
docker compose run --rm terraform -chdir=/workspace/fileCreation init
```

Validate:

```powershell
docker compose run --rm terraform -chdir=/workspace/fileCreation validate
```

Preview:

```powershell
docker compose run --rm terraform -chdir=/workspace/fileCreation plan
```

Apply:

```powershell
docker compose run --rm terraform -chdir=/workspace/fileCreation apply
```

Verify the generated file:

```powershell
Get-Content .\terraform\fileCreation\automate.txt
```

### Result

```text
this is automate file created using terraform
```

The file is generated inside the Windows project directory because the Terraform folder is mounted into the Docker container.

### Learning outcome

- Terraform Local provider.
- File automation.
- Terraform resource lifecycle.
- Separate Terraform working directories.
- Docker bind mounts.
- Terraform initialization and provider installation.

---

## Phase 5: Jenkins Setup and Floci Integration

### Objective

Configure Jenkins to execute AWS CLI commands against Floci.

### Jenkins setup

Jenkins runs inside Docker using:

```text
jenkins/jenkins:lts-jdk21
```

Jenkins dashboard:

```text
http://localhost:8080
```

A persistent Docker volume stores Jenkins data:

```text
jenkins_home
```

### AWS CLI integration

AWS CLI was installed inside the Jenkins container.

The following dummy credentials were used:

```text
AWS_ACCESS_KEY_ID=test
AWS_SECRET_ACCESS_KEY=test
AWS_DEFAULT_REGION=us-east-1
```

The Floci endpoint:

```text
http://floci:4566
```

### Example command

```powershell
docker compose exec `
  -e AWS_ACCESS_KEY_ID=test `
  -e AWS_SECRET_ACCESS_KEY=test `
  -e AWS_DEFAULT_REGION=us-east-1 `
  -e AWS_EC2_METADATA_DISABLED=true `
  -e AWS_PAGER="" `
  jenkins aws s3 ls --endpoint-url http://floci:4566
```

### Pipeline implementation

A Jenkins pipeline named:

```text
Floci-S3-First-Pipeline
```

was successfully executed.

The pipeline performed:

- AWS CLI execution.
- STS identity verification.
- S3 bucket creation.
- S3 bucket listing.

Bucket created through the pipeline:

```text
jenkins-floci-demo
```

### Learning outcome

- Jenkins fundamentals.
- Jenkins jobs and pipelines.
- AWS CLI integration.
- CI/CD fundamentals.
- Docker-based Jenkins environments.
- Interaction between Jenkins and Floci.

Note: AWS CLI was installed manually inside the running Jenkins container during this exercise. A reproducible custom Jenkins image is a planned improvement.

---

## Phase 6: Kubernetes Setup Using Kind

### Objective

Build a local Kubernetes environment without using paid AWS EKS infrastructure.

### Installation

Kind was installed using Windows Package Manager:

```powershell
winget install --id Kubernetes.kind --exact --source winget
```

Verification:

```powershell
kind version
```

kubectl verification:

```powershell
kubectl version --client
```

### Create a Kubernetes cluster

Cluster creation:

```powershell
kind create cluster --name devops-lab --wait 5m
```

### Cluster verification

List clusters:

```powershell
kind get clusters
```

Check Kubernetes context:

```powershell
kubectl config get-contexts
```

Check current context:

```powershell
kubectl config current-context
```

Expected:

```text
kind-devops-lab
```

Check nodes:

```powershell
kubectl get nodes -o wide
```

Check system pods:

```powershell
kubectl get pods -A
```

### Verified cluster

```text
Cluster: devops-lab
Node: devops-lab-control-plane
Status: Ready
Kubernetes Version: v1.37.0
Container Runtime: containerd://2.3.4
```

All nine system pods were verified as Running and Ready during initial setup.

### Learning outcome

- Kubernetes cluster creation.
- Kind architecture.
- Kubernetes control plane.
- kubectl basics.
- Kubernetes contexts.
- Nodes and system pods.
- Docker-based Kubernetes environments.

The cluster is currently local and is not deployed on AWS.

---

# 6. Troubleshooting and Errors Encountered

This section documents real errors encountered during implementation, their root causes and the solutions used.

Documenting troubleshooting is important because DevOps engineering involves identifying failures, understanding their root causes and implementing reliable fixes.

## Issue 1: Terraform provider execution error

### Error

```text
exec format error
```

### Root cause

The AWS provider binary was not compatible with the environment in which Terraform was executing.

Terraform was running inside a Linux AMD64 Docker container, so the provider binary needed to match that platform.

### Resolution

- Downloaded the Linux AMD64 AWS provider.
- Verified the provider ZIP checksum.
- Corrected the filesystem mirror directory layout.
- Configured Terraform to use the local provider mirror.
- Successfully initialized Terraform.

### Lesson learned

Terraform providers are platform-specific binaries. The operating system and architecture must match the Terraform execution environment.

---

## Issue 2: Terraform provider initialization problems

### Problem

Terraform initially failed to locate and execute the AWS provider from the local mirror.

### Root cause

The provider mirror directory structure was incorrect.

### Resolution

Used the packed mirror layout:

```text
terraform-mirror/
    registry.terraform.io/
        hashicorp/
            aws/
                terraform-provider-aws_6.73.0_linux_amd64.zip
```

Configured the Terraform CLI provider installation settings to use the filesystem mirror.

### Lesson learned

Terraform provider installation depends on the correct mirror layout and platform-specific provider package.

---

## Issue 3: Terraform local file syntax error

### Initial configuration

```hcl
resource local_file my_file {
    filename = automate.txt
    content = "this is automate file created using terraform"
}
```

### Problems identified

1. Resource type and resource name were not quoted.
2. Filename was not specified as a string.

### Corrected configuration

```hcl
resource "local_file" "my_file" {
  filename = "${path.module}/automate.txt"
  content  = "this is automate file created using terraform"
}
```

### Lesson learned

Terraform uses HashiCorp Configuration Language (HCL).

Resource declarations follow this structure:

```hcl
resource "RESOURCE_TYPE" "RESOURCE_NAME" {
  argument = "value"
}
```

---

## Issue 4: Invalid multi-line string during Terraform initialization

### Error

```text
Error: Invalid multi-line string

Quoted strings may not be split over multiple lines.

Error: Unterminated template string
```

### Root cause

The closing quotation mark was missing from the filename argument.

Incorrect:

```hcl
filename = "${path.module}/automate.txt
```

Correct:

```hcl
filename = "${path.module}/automate.txt"
```

### Resolution

Corrected the missing quotation mark and reran:

```powershell
docker compose run --rm terraform -chdir=/workspace/fileCreation init
```

Then:

```powershell
docker compose run --rm terraform -chdir=/workspace/fileCreation validate
```

Finally:

```powershell
docker compose run --rm terraform -chdir=/workspace/fileCreation plan
```

### Lesson learned

Terraform validates the complete configuration before initialization can finish. Syntax errors must be corrected before Terraform can determine which providers and modules are required.

---

## Issue 5: Docker Compose working directory confusion

### Problem

The Terraform project was located inside:

```text
terraform/fileCreation/
```

But the Docker Compose configuration was located in the project root.

### Root cause

Docker Compose commands need to locate the Compose configuration, while Terraform independently needs to know which directory contains its `.tf` files.

These are two different working-directory concepts.

### Resolution

Run Docker Compose from the directory containing `docker-compose.yml`:

```powershell
cd D:\1_InfosysLearning\AWS_Floci_setup
```

Then use Terraform's `-chdir` option:

```powershell
docker compose run --rm terraform -chdir=/workspace/fileCreation init
```

### Lesson learned

- Host working directory: Where Docker Compose finds its configuration.
- Container working directory: Where Terraform accesses mounted files.
- Terraform `-chdir`: Selects the Terraform project directory.

---

## Issue 6: Git push rejected

### Error

```text
! [rejected] main -> main (fetch first)

error: failed to push some refs
```

### Root cause

The GitHub repository already contained an initial commit created during repository creation.

The local repository had a separate initial commit.

The two repositories had unrelated histories.

### Resolution

Fetched the remote history:

```powershell
git fetch origin
```

Inspected both histories:

```powershell
git log --oneline --graph --decorate --all
```

Allowed Git to merge unrelated histories:

```powershell
git merge origin/main --allow-unrelated-histories
```

### Lesson learned

Git rejects non-fast-forward pushes when the remote contains commits that are not part of the local branch history.

Fetching and merging remote changes allows both histories to be preserved.

---

## Issue 7: Git README merge conflict

### Error

```text
CONFLICT (add/add): Merge conflict in README.md

Automatic merge failed; fix conflicts and then commit the result.
```

### Root cause

Both the local repository and GitHub repository contained a file named `README.md`.

The local README contained detailed project documentation, while the GitHub README contained only the automatically generated initial content.

### Resolution

Kept the local README:

```powershell
git checkout --ours README.md
```

Marked the conflict as resolved:

```powershell
git add README.md
```

Completed the merge:

```powershell
git commit -m "Merge remote history and retain local project README"
```

Pushed the changes:

```powershell
git push -u origin main
```

### Lesson learned

- `--ours` selects the current local branch version.
- `--theirs` selects the incoming branch version.
- `git add` marks a conflict as resolved.
- A merge commit records the integration of both histories.

---

# 7. Git and GitHub Workflow

The project is maintained using Git and GitHub.

### Initialize a repository

```powershell
git init
```

### Rename the branch

```powershell
git branch -M main
```

### Check repository status

```powershell
git status
```

### Stage files

```powershell
git add .
```

### Commit changes

```powershell
git commit -m "Your commit message"
```

### Add GitHub remote

```powershell
git remote add origin https://github.com/YOUR_USERNAME/aws-floci-terraform-devops-lab.git
```

### Verify remote

```powershell
git remote -v
```

### Push changes

```powershell
git push -u origin main
```

### Fetch remote changes

```powershell
git fetch origin
```

### Pull remote changes

```powershell
git pull
```

### View commit history

```powershell
git log --oneline --graph --decorate
```

---

# 8. Security and Cost Considerations

This project is designed primarily for local learning.

### AWS safety

- Floci is used for local AWS service emulation.
- Dummy AWS credentials are used for the local environment.
- The demonstrated S3 resources are created in Floci, not in a real AWS account.
- Real AWS infrastructure is not required for the completed exercises.

### Git security

The following items must not be committed:

```text
*.tfstate
*.tfstate.*
.terraform/
terraform-mirror/
data/
.env
*.pem
*.key
*.tfvars
```

Terraform state can contain sensitive infrastructure information.

### Docker security

The Floci service uses a Docker socket mount for local emulation.

Access to the Docker socket can provide extensive control over the Docker host. This configuration is intended for a trusted local development environment, not an exposed production server.

### Resource preservation

Existing Docker images, containers and volumes used for Spark, MongoDB, Jenkins and Floci are retained as part of the local learning environment.

---

# 9. Current Project Progress

| Implementation | Status |
|---|---|
| Docker Desktop setup | Completed |
| Docker Compose setup | Completed |
| Floci setup | Completed |
| Terraform installation through Docker | Completed |
| AWS provider configuration | Completed |
| Terraform provider mirror | Completed |
| S3 bucket provisioning in Floci | Completed |
| Terraform local file automation | Completed |
| Jenkins setup | Completed |
| Jenkins and Floci integration | Completed |
| Git initialization | Completed |
| GitHub repository integration | Completed |
| Git merge conflict resolution | Completed |
| Kind installation | Completed |
| Kubernetes cluster creation | Completed |
| Kubernetes Pods and Deployments practice | Pending |
| Kubernetes Services and networking | Pending |
| Helm | Pending |
| Jenkins CI/CD with Kubernetes | Pending |
| Terraform modules | Pending |
| Monitoring and logging | Pending |

---

# 10. Future Learning Roadmap

The next implementation stages will focus on production-oriented DevOps practices.

### Stage 1: Kubernetes Fundamentals

- Namespaces
- Pods
- ReplicaSets
- Deployments
- Services
- ConfigMaps
- Secrets
- Persistent Volumes
- Ingress

### Stage 2: Kubernetes Package Management

- Helm fundamentals
- Helm charts
- Values files
- Application deployment using Helm

### Stage 3: Jenkins CI/CD

- Jenkins pipeline as code
- GitHub integration
- Webhooks
- Automated Docker builds
- Automated testing
- Deployment pipelines

### Stage 4: Container Registry

- Docker image creation
- Image tagging
- ECR fundamentals
- Image vulnerability scanning
- Container image management

### Stage 5: Advanced Terraform

- Input variables
- Outputs
- Data sources
- Modules
- Remote state
- State locking
- Workspaces
- Infrastructure lifecycle management

### Stage 6: Production-oriented DevOps

- AWS ECS and EKS architecture
- IAM and security
- Load balancing
- Monitoring and logging
- CloudWatch
- Deployment strategies
- Infrastructure security
- Change management

---
## Issue 8: SSH connection failed because the SSH server was unavailable

### Problem

The initial SSH connection to the simulated EC2 instance failed because the container did not have a functioning SSH daemon.

### Investigation

Checked whether the SSH server binary and package were present:

```powershell
docker exec CONTAINER_NAME rpm -q openssh-server
docker exec CONTAINER_NAME ls -l /usr/sbin/sshd
```

### Resolution

Installed OpenSSH, generated server host keys, created the runtime directory and started the SSH daemon.

Verified the listening port:

```powershell
docker exec CONTAINER_NAME ss -tlnp
```

### Lesson learned

An EC2 instance being reported as running does not guarantee that an SSH service is installed or listening.

## Issue 9: SSH port mapping and container access

### Problem

The simulated instance was not directly accessible through its reported private or public IP from Windows.

### Root cause

Floci runs the simulated EC2 instance as a Docker container and publishes its SSH port on the Docker host.

### Resolution

Used the host port mapping `2200:22` and connected through localhost:

```powershell
ssh -4 -i .\terraform\ec2-automation\keys\floci-ec2-key -p 2200 root@127.0.0.1
```

### Lesson learned

Docker port mapping determines how a service inside a container is reached from the host. A simulated EC2 public IP should not be treated as a real AWS network address.

# 11. How to Run This Project

### Prerequisites

- Windows with Docker Desktop.
- Git.
- Docker Compose.
- PowerShell.
- A GitHub account (optional, for repository hosting).

Terraform is executed through Docker in this project. A separate Windows Terraform installation is not required.

### Clone the repository

```powershell
git clone https://github.com/amujii/aws-floci-terraform-devops-lab.git
```

Navigate into the project:

```powershell
cd aws-floci-terraform-devops-lab
```

Start the local services:

```powershell
docker compose up -d
```

Check running services:

```powershell
docker compose ps
```

### Verify Terraform

```powershell
docker compose run --rm terraform version
```

### Run the file automation example

```powershell
docker compose run --rm terraform -chdir=/workspace/fileCreation init
```

```powershell
docker compose run --rm terraform -chdir=/workspace/fileCreation validate
```

```powershell
docker compose run --rm terraform -chdir=/workspace/fileCreation plan
```

```powershell
docker compose run --rm terraform -chdir=/workspace/fileCreation apply
```

### Verify generated file

```powershell
Get-Content .\terraform\fileCreation\automate.txt
```

Note: The AWS Terraform configuration requires Floci to be running and the local provider configuration to be available. The Kind cluster is created and managed separately using the Kind and kubectl commands documented above.

---

# 12. Author and Project

**Project:** AWS Floci & DevOps Engineering Lab

**Repository:** [aws-floci-terraform-devops-lab](https://github.com/amujii/aws-floci-terraform-devops-lab)

**Focus Areas:**

- AWS and Cloud Engineering
- DevOps Automation
- Infrastructure as Code
- CI/CD
- Containerization
- Kubernetes

This is an actively evolving hands-on learning project. New implementations, troubleshooting experiences, architecture improvements and automation examples will be documented as development progresses.

---

**Learning by building. Troubleshooting by doing. Improving through implementation.**