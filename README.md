# AWS Floci & DevOps Engineering Lab

A hands-on, continuously evolving DevOps engineering lab focused on infrastructure as code, AWS services, containerization, CI/CD, Kubernetes, and automation.

This repository documents practical implementations, configuration decisions, troubleshooting experiences, verified outcomes, and lessons learned while building a local AWS-style environment using Docker, Floci, Terraform, Jenkins, and Kubernetes.

> **Project status: Ongoing**
>
> The current completed implementation checkpoint is **Terraform-based EC2 provisioning and SSH access through Floci**. The next work will extend this foundation with instance bootstrapping, application deployment, and CI/CD automation. New implementation phases will be added to this README under the continuation section at the end.

---

## Table of Contents

1. [Project Objectives](#1-project-objectives)
2. [Technology Stack](#2-technology-stack)
3. [Project Architecture](#3-project-architecture)
4. [Repository Structure](#4-repository-structure)
5. [Implementation Details](#5-implementation-details)
   - [Phase 1: Docker and Floci Setup](#phase-1-docker-and-floci-setup)
   - [Phase 2: Terraform and AWS Provider Setup](#phase-2-terraform-and-aws-provider-setup)
   - [Phase 3: S3 Bucket Provisioning](#phase-3-s3-bucket-provisioning-using-terraform)
   - [Phase 4: Terraform Local File Automation](#phase-4-terraform-local-file-automation)
   - [Phase 5: Jenkins and Floci Integration](#phase-5-jenkins-setup-and-floci-integration)
   - [Phase 6: Kubernetes with Kind](#phase-6-kubernetes-setup-using-kind)
   - [Phase 7: EC2 Provisioning and SSH Access](#phase-7-ec2-provisioning-and-ssh-access-using-terraform-and-floci)
6. [Troubleshooting and Lessons Learned](#6-troubleshooting-and-lessons-learned)
7. [Git and GitHub Workflow](#7-git-and-github-workflow)
8. [Security and Cost Considerations](#8-security-and-cost-considerations)
9. [Current Project Progress](#9-current-project-progress)
10. [Future Learning Roadmap](#10-future-learning-roadmap)
11. [How to Run the Project](#11-how-to-run-the-project)
12. [Author and Project](#12-author-and-project)
13. [Ongoing Project Log — Continue From Here](#13-ongoing-project-log--continue-from-here)

---

## 1. Project Objectives

The primary objective is to develop practical DevOps and cloud engineering skills by implementing and troubleshooting infrastructure and deployment workflows.

Key objectives:

- Build a local AWS-compatible environment without depending on a live AWS account for every exercise.
- Understand AWS service concepts through hands-on implementation.
- Provision infrastructure using Terraform.
- Learn provider configuration, state management, resource dependencies, and outputs.
- Run and manage containerized services using Docker and Docker Compose.
- Integrate Jenkins with the local AWS-compatible endpoint.
- Learn Kubernetes fundamentals using Kind.
- Understand EC2 concepts, networking, security groups, key pairs, and SSH access.
- Practice Git branching, commits, remote synchronization, and pull-request workflows.
- Record real errors and their resolutions instead of documenting only successful commands.
- Extend the lab incrementally toward production-oriented DevOps workflows.

### Learning approach

This is a learning and experimentation repository. Each implementation should include:

1. Objective and expected outcome.
2. Configuration and commands used.
3. Verification steps.
4. Actual result.
5. Limitations and troubleshooting notes.
6. Follow-up improvements.

The local Floci environment is used for simulation. A successful local simulation does not automatically prove that the same configuration is ready for deployment in a real AWS account.

---

## 2. Technology Stack

| Area | Technology | Purpose |
|---|---|---|
| Operating system | Windows 11 | Main development environment |
| Shell | PowerShell | Local commands and workflow |
| Container runtime | Docker Desktop | Runs the lab services |
| Container orchestration | Docker Compose | Defines and starts local services |
| AWS simulation | Floci | Local AWS-compatible API environment |
| Infrastructure as Code | Terraform | Provisions and manages resources |
| Cloud provider | AWS provider for Terraform | AWS resource definitions and API calls |
| CI/CD | Jenkins | Pipeline learning and automation |
| Container orchestration | Kubernetes | Cluster practice using Kind |
| Version control | Git | Source control and branching |
| Remote repository | GitHub | Source hosting and collaboration |
| Container images | Docker images | Packaging and running services |

### Environment and versions

The following versions were observed during the lab setup. Versions may change as the project evolves.

| Component | Observed version / configuration |
|---|---|
| Docker Engine | 29.4.3 |
| Docker Desktop | Windows with Linux containers |
| Terraform CLI | 1.17.2 |
| AWS Terraform provider | 6.73.0 |
| AWS provider constraint | `~> 6.0` |
| Jenkins image | `jenkins/jenkins:lts-jdk21` |
| Floci image | `floci/floci:latest` |
| Terraform image | `hashicorp/terraform:latest` |
| Floci region used in examples | `us-east-1` |

Check the versions installed in the current environment before reproducing commands:

```powershell
docker version
docker compose version
git --version
```

Terraform is run through the Docker Compose service in this lab:

```powershell
docker compose run --rm terraform version
```

---

## 3. Project Architecture

The lab uses Docker Compose to run the local services. Terraform and Jenkins communicate with Floci over the Docker network.

### High-level architecture

```text
                       Windows 11 Host
                              |
                       PowerShell / Git
                              |
                       Docker Desktop
                              |
                       Docker Compose
                              |
          +-------------------+-------------------+
          |                   |                   |
       Floci                Jenkins            Terraform
     AWS emulator          CI/CD server       CLI container
          |                   |                   |
          |<------ Docker network -------------->|
          |
     Local AWS-compatible APIs
          |
     +----+-----------------------+
     |                            |
   S3 simulation              EC2 simulation
                                  |
                            Docker container
                                  |
                         SSH port mapping
                         Host 2200 -> 22
```

### Local service endpoints

| Service | Host endpoint | Purpose |
|---|---|---|
| Floci API | `http://localhost:4566` | Local AWS-compatible endpoint |
| Floci UI | `http://localhost:4500` | Floci interface |
| Jenkins | `http://localhost:8080` | Jenkins web interface |
| Jenkins agent port | `localhost:50000` | Jenkins inbound agent port |
| Simulated EC2 SSH | `127.0.0.1:2200` | SSH to the Floci EC2 container |

The SSH endpoint is available only when the simulated EC2 container publishes port 2200 and its SSH daemon is running.

### Important networking distinction

Containers on the Compose network use the service name and internal port. For example, Terraform uses:

```text
http://floci:4566
```

Windows applications use the host-published endpoint:

```text
http://localhost:4566
```

Do not confuse a container's internal network address with a host-accessible address.

---

## 4. Repository Structure

The repository is organized so that each Terraform exercise has its own working directory and state.

```text
aws-floci-terraform-devops-lab/
│
├── docker-compose.yml
├── terraform.tfrc
├── .gitignore
├── README.md
│
├── data/                         # Local Floci data; not committed
│
├── terraform/
│   │
│   ├── s3-bucket-automation/
│   │   ├── main.tf
│   │   ├── provider.tf
│   │   └── .terraform.lock.hcl
│   │
│   ├── fileCreation/
│   │   ├── main.tf
│   │   └── .terraform.lock.hcl
│   │
│   └── ec2-automation/
│       ├── main.tf
│       ├── provider.tf
│       ├── outputs.tf
│       ├── .terraform.lock.hcl
│       └── keys/                 # Local SSH keys; not committed
│
├── terraform-mirror/             # Local provider mirror; not committed
│
└── [additional project files]
```

The tree above describes the main project areas. Jenkins data is stored in a Docker named volume rather than in the repository.

### Terraform directory isolation

Each Terraform exercise is initialized and executed independently. This avoids accidentally using one exercise's state for another.

Examples:

- `/workspace/s3-bucket-automation`
- `/workspace/fileCreation`
- `/workspace/ec2-automation`

The Compose Terraform service mounts the repository's `terraform/` directory at `/workspace` inside the container.

---

## 5. Implementation Details

### Phase 1: Docker and Floci Setup

#### Objective

Set up Docker Compose and run Floci as the local AWS-compatible service.

#### Docker Compose services

The main Compose configuration contains the following services:

| Service | Image | Purpose |
|---|---|---|
| `floci` | `floci/floci:latest` | Local AWS API simulation |
| `jenkins` | `jenkins/jenkins:lts-jdk21` | CI/CD learning |
| `terraform` | `hashicorp/terraform:latest` | Terraform CLI |

The configuration also uses:

- Port publishing for Floci and Jenkins.
- A persistent Docker volume for Jenkins home.
- A local data directory for Floci.
- A Docker network for communication between services.
- A local Terraform provider mirror.

#### Important Floci configuration

The Floci service is configured with:

```yaml
environment:
  FLOCI_STORAGE_MODE: hybrid
  FLOCI_HOSTNAME: floci
```

The Docker socket is mounted into Floci:

```yaml
volumes:
  - /var/run/docker.sock:/var/run/docker.sock
  - ./data:/app/data
```

**Security note:** Access to the Docker socket is highly privileged. Keep this local lab trusted and do not expose it to untrusted users or public networks.

#### Start the environment

From the repository root:

```powershell
docker compose up -d
```

Check running containers:

```powershell
docker compose ps
```

View service logs:

```powershell
docker compose logs floci
docker compose logs jenkins
```

#### Verification

Open:

- Floci API: `http://localhost:4566`
- Floci UI: `http://localhost:4500`
- Jenkins: `http://localhost:8080`

A running container confirms that Docker started the service. It does not, by itself, verify every API operation.

#### Learning outcomes

- Docker images and containers.
- Docker Compose services.
- Port publishing.
- Docker volumes.
- Container networking.
- Local AWS-compatible service endpoints.

---

### Phase 2: Terraform Setup and AWS Provider Configuration

#### Objective

Configure Terraform to communicate with Floci using the AWS provider.

#### Terraform environment

Terraform is executed through the Compose service. The Terraform service mounts:

- `./terraform` at `/workspace`
- `./terraform-mirror` at `/terraform-mirror`
- `./terraform.tfrc` at `/root/.terraformrc`

The environment uses local test credentials:

```yaml
environment:
  AWS_ACCESS_KEY_ID: test
  AWS_SECRET_ACCESS_KEY: test
  AWS_DEFAULT_REGION: us-east-1
  AWS_EC2_METADATA_DISABLED: "true"
  AWS_PAGER: ""
```

These are simulation credentials for the local lab, not real AWS credentials.

#### AWS provider configuration

The provider configuration for the local S3 and EC2 exercises directs supported requests to Floci.

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

  endpoints {
    s3  = "http://floci:4566"
    ec2 = "http://floci:4566"
  }
}
```

Use only the endpoint configuration required by the individual exercise. The EC2 exercise uses the EC2 endpoint; the S3 exercise uses the S3 endpoint.

#### Terraform provider mirror

A local provider mirror was configured to make provider installation reproducible in the lab and avoid relying on a fresh provider download each time.

The mirror is local development infrastructure and is excluded from Git.

The provider lock file is committed so that the selected provider version and checksums are recorded.

#### Important Terraform commands

Run commands from the repository root:

```powershell
# Check Terraform version
docker compose run --rm terraform version

# Initialize a project
docker compose run --rm terraform -chdir=/workspace/s3-bucket-automation init

# Validate a project
docker compose run --rm terraform -chdir=/workspace/s3-bucket-automation validate

# Review planned changes
docker compose run --rm terraform -chdir=/workspace/s3-bucket-automation plan
```

The `-chdir` argument selects the Terraform project directory inside the container.

#### Learning outcomes

- Terraform provider configuration.
- Provider version constraints.
- Provider lock files.
- Local provider mirrors.
- Terraform initialization and validation.
- Separation of local simulation credentials from real credentials.

---

### Phase 3: S3 Bucket Provisioning Using Terraform

#### Objective

Provision an S3 bucket through Terraform using the local Floci endpoint.

#### Project directory

```text
terraform/s3-bucket-automation/
├── main.tf
├── provider.tf
└── .terraform.lock.hcl
```

The project uses the AWS provider and an S3 endpoint directed to Floci.

#### Resource

The bucket used in the exercise is:

```text
terraform-floci-demo
```

The Terraform configuration defines the bucket resource and its associated provider configuration.

#### Implementation commands

```powershell
docker compose run --rm terraform -chdir=/workspace/s3-bucket-automation init

docker compose run --rm terraform -chdir=/workspace/s3-bucket-automation validate

docker compose run --rm terraform -chdir=/workspace/s3-bucket-automation plan

docker compose run --rm terraform -chdir=/workspace/s3-bucket-automation apply
```

Inspect Terraform state:

```powershell
docker compose run --rm terraform -chdir=/workspace/s3-bucket-automation state list
```

#### Verification

Verify the bucket through the Floci interface or an AWS CLI configured to use the local Floci endpoint.

Do not use a real AWS endpoint for this local exercise.

#### Learning outcomes

- S3 resource configuration.
- Terraform resource lifecycle.
- Plan and apply workflow.
- Terraform state inspection.
- AWS-compatible API endpoint configuration.

---

### Phase 4: Terraform Local File Automation

#### Objective

Use Terraform to create a local file and understand the use of Terraform resources for local automation.

#### Project directory

```text
terraform/fileCreation/
```

The exercise uses a local Terraform project and generates an output file named:

```text
automate.txt
```

The generated file is excluded from Git because it is an execution artifact.

#### Implementation commands

```powershell
docker compose run --rm terraform -chdir=/workspace/fileCreation init

docker compose run --rm terraform -chdir=/workspace/fileCreation validate

docker compose run --rm terraform -chdir=/workspace/fileCreation plan

docker compose run --rm terraform -chdir=/workspace/fileCreation apply
```

Check the generated file at its configured output location.

#### Learning outcomes

- Terraform local resources.
- File generation.
- Terraform plan and apply.
- Generated artifact handling.
- Separating source configuration from generated output.

---

### Phase 5: Jenkins Setup and Floci Integration

#### Objective

Run Jenkins locally and explore how a CI/CD server can interact with the local AWS-compatible environment.

#### Jenkins setup

Jenkins is run using:

```text
jenkins/jenkins:lts-jdk21
```

The Compose configuration publishes:

- `8080` for the Jenkins web interface.
- `50000` for inbound Jenkins agents.

A named Docker volume is used for `/var/jenkins_home` so that Jenkins data persists across container restarts.

Open Jenkins:

```text
http://localhost:8080
```

#### AWS CLI integration

The AWS CLI was executed from the Jenkins container and used with the local Floci endpoint.

The AWS CLI must be configured with simulation credentials and the Floci endpoint when performing local API operations.

Example pattern:

```bash
aws --endpoint-url=http://floci:4566 sts get-caller-identity
```

The exact API operation supported depends on the Floci service implementation.

#### Pipeline learning

The Jenkins environment is intended for learning:

- Pipeline structure.
- Source control integration.
- Build stages.
- Terraform validation and planning.
- Container image build and deployment workflows.
- Environment variables and credentials handling.

Do not store real AWS credentials in source code or commit Jenkins secrets.

#### Learning outcomes

- Jenkins installation and persistence.
- Jenkins UI access.
- Jenkins container environment.
- AWS CLI usage with a local endpoint.
- CI/CD pipeline concepts.

---

### Phase 6: Kubernetes Setup Using Kind

#### Objective

Create a local Kubernetes cluster using Kind and understand the basic Kubernetes workflow.

#### Installation and verification

Kind is used to run Kubernetes locally using Docker containers as cluster nodes.

Check the installed tools:

```powershell
kind version
kubectl version --client
docker version
```

#### Create a cluster

A basic cluster can be created with:

```powershell
kind create cluster --name devops-lab
```

If a cluster with that name already exists, inspect it before creating another.

#### Cluster verification

```powershell
kind get clusters
kubectl cluster-info
kubectl get nodes
kubectl get pods -A
```

#### Learning outcomes

- Local Kubernetes cluster setup.
- Kubernetes nodes.
- `kubectl` commands.
- Cluster inspection.
- Docker-based Kubernetes learning environment.

The Kind exercise is separate from the Floci EC2 simulation. It is not evidence that an application has been deployed to a production Kubernetes cluster.

---

### Phase 7: EC2 Provisioning and SSH Access Using Terraform and Floci

#### Objective

Provision an EC2-compatible instance using Terraform through Floci, configure networking and security group resources, register an SSH public key, and establish SSH access from Windows.

This phase was completed in the local simulation environment.

#### Project directory

```text
terraform/ec2-automation/
├── main.tf
├── provider.tf
├── outputs.tf
├── .terraform.lock.hcl
└── keys/
    ├── floci-ec2-key
    └── floci-ec2-key.pub
```

The `keys/` directory is local-only and excluded from Git.

#### Terraform resources

| Resource or data source | Purpose |
|---|---|
| `aws_key_pair` | Registers the SSH public key |
| `data.aws_vpc` | Retrieves the default VPC |
| `data.aws_subnets` | Retrieves subnets associated with the VPC |
| `aws_security_group` | Configures simulated network access rules |
| `aws_instance` | Creates the simulated EC2 instance |

#### Provider configuration

The EC2 project directs EC2 API requests to Floci:

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

  endpoints {
    ec2 = "http://floci:4566"
  }
}
```

#### EC2 configuration

The implemented configuration uses:

| Attribute | Configured value |
|---|---|
| AMI | `ami-0abcdef1234567891` |
| Instance type | `t2.micro` |
| Root volume size | 8 GB |
| Root volume type | `gp3` |
| VPC | Default VPC returned by Floci |
| Subnet | First subnet returned by the subnet data source |
| SSH key pair | `floci-ec2-key` |

The security group contains ingress rules for SSH (22), HTTP (80), and the application port (8080), with `127.0.0.1/32` as the configured source in this simulation. It also contains an outbound rule.

**Important:** These are the values in the local exercise. They should not be copied blindly into a real AWS deployment.

#### Terraform implementation

Run from the repository root:

```powershell
docker compose run --rm terraform -chdir=/workspace/ec2-automation init

docker compose run --rm terraform -chdir=/workspace/ec2-automation validate

docker compose run --rm terraform -chdir=/workspace/ec2-automation plan

docker compose run --rm terraform -chdir=/workspace/ec2-automation apply
```

Validate the configuration independently:

```powershell
docker compose run --rm terraform -chdir=/workspace/ec2-automation validate
```

The observed result was:

```text
Success! The configuration is valid.
```

#### Provisioning result

Terraform successfully created three resources:

```text
Apply complete! Resources: 3 added, 0 changed, 0 destroyed.
```

Verified outputs:

| Attribute | Observed value |
|---|---|
| Instance ID | `i-fc1d21eac78dccae9` |
| Instance type | `t2.micro` |
| Instance state | `running` |
| Simulated public IP | `127.0.0.1` |
| Private IP | `172.31.32.10` |
| VPC | `vpc-default-us-east-1` |
| Subnet | `subnet-default-us-east-1-c` |
| Security group ID | `sg-0d13bdd371712103d` |
| Key pair | `floci-ec2-key` |
| Volume ID | `vol-ab0b4283767417b7e` |

These identifiers are recorded as the result of this particular local run. They may differ if the resources are recreated.

#### SSH setup and troubleshooting

The simulated EC2 instance runs as a Docker container. Floci published the container's SSH port to host port `2200`.

The observed mapping was:

```text
Host port 2200 -> Container port 22
```

The initial SSH attempt failed because the container did not have a functioning SSH daemon. Floci logs also showed that its automatic OpenSSH setup had encountered problems.

The container was inspected, and the OpenSSH server package was installed manually. The following commands were used in the local lab:

```powershell
docker exec floci-aws-ec2-i-fc1d21eac78dccae9 dnf install -y openssh-server

docker exec floci-aws-ec2-i-fc1d21eac78dccae9 ssh-keygen -A

docker exec floci-aws-ec2-i-fc1d21eac78dccae9 mkdir -p /run/sshd

docker exec floci-aws-ec2-i-fc1d21eac78dccae9 /usr/sbin/sshd
```

The SSH daemon was verified to be listening on port 22 inside the container.

#### Connect from Windows PowerShell

```powershell
ssh -4 -i .\terraform\ec2-automation\keys\floci-ec2-key -p 2200 root@127.0.0.1
```

The SSH connection was successfully established. The session displayed an Amazon Linux 2023 banner and a root shell prompt.

#### Understanding the two types of SSH keys

There are two distinct key roles:

1. **Client authentication key pair**
   - The public key is registered with Floci through the Terraform key-pair resource.
   - The public key is injected into the simulated instance's authorized keys.
   - The private key stays on the Windows host and is used by the SSH client.

2. **SSH server host keys**
   - These identify the SSH server to the connecting client.
   - They were generated inside the container using `ssh-keygen -A`.
   - They are not the same as the Terraform-managed client authentication key pair.

The public key fingerprint was verified:

```text
256 SHA256:FFM53IdSlr5CHgdGdPm8bzXPjdSX2o9SVUj1j0eOaZ0 floci-ec2-lab (ED25519)
```

#### Important Floci limitations

- The simulated EC2 instance is a Docker container, not a full virtual machine.
- The reported public IP `127.0.0.1` is a local simulation address, not a real AWS public IP.
- The SSH connection uses Docker host port mapping `2200:22`.
- The manually installed OpenSSH package and manually started daemon may not survive container recreation.
- Floci logs showed that automatic SSH setup and metadata-related operations had encountered timeouts.
- A successful Terraform apply proves that Floci accepted the simulated resource operations; it does not prove that the same configuration will provision a working real AWS EC2 instance.

#### Learning outcomes

- Terraform EC2 resource provisioning.
- AWS key-pair registration.
- VPC and subnet data sources.
- Security group configuration.
- Terraform outputs and state inspection.
- SSH public-key authentication.
- Docker port mapping.
- Troubleshooting services inside a container.
- Understanding differences between local AWS simulation and real cloud infrastructure.

---

## 6. Troubleshooting and Lessons Learned

This section records issues encountered during implementation and the lessons learned from resolving them.

### Issue 1: Terraform provider execution error

#### Problem

Terraform initially reported an execution-format error when attempting to use the AWS provider.

#### Root cause

The downloaded provider binary did not match the platform expected by the Terraform container.

#### Resolution

The provider package was checked and a compatible Linux AMD64 provider package was placed in the local provider mirror. Terraform initialization was then completed using the mirror.

#### Lesson learned

Provider binaries must match the operating system and architecture of the environment in which Terraform runs. A Windows host does not mean that a Linux container should use a Windows provider binary.

---

### Issue 2: Terraform provider initialization problems

#### Problem

Terraform provider initialization required a reliable source for the AWS provider package.

#### Root cause

The lab used a local provider mirror and a Terraform CLI configuration to control provider installation.

#### Resolution

A local filesystem mirror was configured and the provider lock file was generated.

#### Lesson learned

A provider mirror can make a lab more reproducible, but the mirror itself is local infrastructure. Do not commit provider binaries to the source repository unless there is a deliberate reason to distribute them.

---

### Issue 3: Terraform local file syntax error

#### Problem

The local file automation configuration encountered a Terraform syntax issue.

#### Root cause

The resource configuration did not initially follow the expected Terraform syntax.

#### Resolution

The Terraform configuration was corrected and validated before applying it.

#### Lesson learned

Use `terraform fmt` and `terraform validate` before applying changes. Small syntax checks can prevent unnecessary debugging later.

---

### Issue 4: Invalid multi-line string during Terraform initialization

#### Problem

Terraform reported an invalid multi-line string.

#### Root cause

The configuration contained a string declaration that did not follow Terraform's supported syntax.

#### Resolution

The string configuration was corrected and Terraform initialization and validation were repeated.

#### Lesson learned

Use valid quoted strings or Terraform heredoc syntax for multi-line values. Validate configuration after editing.

---

### Issue 5: Docker Compose working-directory confusion

#### Problem

Terraform commands did not operate on the expected project directory.

#### Root cause

The Terraform container uses `/workspace` as its working directory, while the repository contains multiple Terraform project directories.

#### Resolution

Use the `-chdir` option to select the intended project:

```powershell
docker compose run --rm terraform -chdir=/workspace/ec2-automation validate
```

#### Lesson learned

Always distinguish between the Windows host path and the mounted path inside the container.

---

### Issue 6: Git push rejected

#### Problem

A Git push was rejected because the remote branch contained changes that were not present in the local branch.

#### Root cause

The local and remote histories had diverged.

#### Resolution

Fetch the remote changes, inspect the history, reconcile the changes, and then push the intended branch.

#### Lesson learned

Use `git fetch` and inspect branch history before resolving a rejected push. Avoid force-pushing as a default fix.

---

### Issue 7: Git README merge conflict

#### Problem

README changes on different Git histories needed reconciliation.

#### Root cause

Both local and remote work had changed the README.

#### Resolution

The README content was reviewed and the desired version was retained during reconciliation.

#### Lesson learned

For documentation-heavy repositories, review the actual diff before resolving conflicts. Do not discard the remote README simply to make a merge succeed.

---

### Issue 8: SSH connection failed because the SSH server was unavailable

#### Problem

The initial SSH connection to the simulated EC2 instance failed.

#### Investigation

The container was checked for the OpenSSH server package and daemon binary. The initial Floci logs showed that automatic SSH setup had encountered timeouts.

The package and binary were subsequently verified in the container.

#### Resolution

OpenSSH was installed or verified, server host keys were generated, the runtime directory was created, and the SSH daemon was started.

Relevant commands:

```powershell
docker exec floci-aws-ec2-i-fc1d21eac78dccae9 rpm -q openssh-server

docker exec floci-aws-ec2-i-fc1d21eac78dccae9 ls -l /usr/sbin/sshd

docker exec floci-aws-ec2-i-fc1d21eac78dccae9 ssh-keygen -A

docker exec floci-aws-ec2-i-fc1d21eac78dccae9 mkdir -p /run/sshd

docker exec floci-aws-ec2-i-fc1d21eac78dccae9 /usr/sbin/sshd
```

#### Lesson learned

An instance reported as running does not guarantee that SSH is installed or listening. Verify the actual service state instead of relying only on the instance state.

---

### Issue 9: SSH port mapping and container access

#### Problem

The simulated instance's reported IP address was not a directly usable remote address from Windows.

#### Root cause

Floci runs the simulated EC2 instance as a Docker container and publishes its SSH port through Docker.

#### Resolution

The host port mapping was used:

```text
127.0.0.1:2200 -> container:22
```

The SSH client connected with:

```powershell
ssh -4 -i .\terraform\ec2-automation\keys\floci-ec2-key -p 2200 root@127.0.0.1
```

#### Lesson learned

Docker port mapping determines how a service inside a container is reached from the host. A simulated EC2 IP must not be treated as a real AWS network address.

---

## 7. Git and GitHub Workflow

The project is maintained in Git and hosted on GitHub.

Repository:

[https://github.com/amujii/aws-floci-terraform-devops-lab](https://github.com/amujii/aws-floci-terraform-devops-lab)

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

Review staged changes before committing:

```powershell
git status
git diff --cached --stat
git diff --cached
```

### Commit changes

```powershell
git commit -m "Describe the change"
```

### Add GitHub remote

```powershell
git remote add origin https://github.com/amujii/aws-floci-terraform-devops-lab.git
```

If the remote already exists, inspect it instead of adding it again:

```powershell
git remote -v
```

### Push changes

```powershell
git push -u origin main
```

For ongoing development, prefer a feature branch:

```powershell
git switch -c feature/short-description
```

Push the feature branch:

```powershell
git push -u origin feature/short-description
```

Then open a pull request into `main`.

### Fetch remote changes

```powershell
git fetch origin
```

### Inspect branch history

```powershell
git branch -vv
git log --oneline --decorate --graph --all
```

### Pull remote changes

Before pulling, inspect the current branch and working tree:

```powershell
git status
git fetch origin
```

Then choose the appropriate merge or rebase workflow for the branch. Do not overwrite local work without reviewing the changes.

### Current branch and merge checkpoint

The EC2 implementation was developed on:

```text
feature/floci-ec2-terraform-ssh
```

The feature was merged through GitHub pull request #1. The observed merge commit was:

```text
87efe98 Merge pull request #1 from amujii/feature/floci-ec2-terraform-ssh
```

This is a historical checkpoint from the current project work. Check the remote repository for newer commits before starting another change.

---

## 8. Security and Cost Considerations

### Local AWS simulation

- The Terraform examples use Floci's local endpoint.
- Test credentials such as `test` are used for simulation.
- The lab is intended to avoid creating real AWS resources for these exercises.
- Verify provider endpoints before running `terraform apply`.
- Never assume that a command is local merely because it is run from a local computer.

### Real AWS safety

If a future exercise uses a real AWS account:

- Verify the selected AWS account and region.
- Review the Terraform provider endpoint configuration.
- Inspect `terraform plan` before applying.
- Understand the pricing of every resource.
- Configure budgets and billing alerts.
- Avoid creating billable resources without explicit cost review.
- Do not assume Floci behavior is identical to real AWS.

### Git security

The repository must not contain:

- Terraform state files.
- Private SSH keys.
- AWS access keys or secret keys.
- `.env` files containing secrets.
- Local provider binaries and caches.
- Other credentials or generated sensitive files.

The `.gitignore` excludes local Terraform state, `.terraform` directories, provider mirror files, local data, and the EC2 SSH key directory.

Check whether sensitive paths are tracked:

```powershell
git ls-files "*tfstate*" "*floci-ec2-key*" "*/.terraform/*"
```

This command should return no output for the currently intended local-only files.

**Important:** `.gitignore` prevents new untracked files from being added accidentally. It does not remove files that were already committed in Git history.

### SSH security

- Keep the private key on the local machine.
- Do not commit private keys.
- Do not share private keys in screenshots or logs.
- Use a narrow trusted source CIDR or a managed access approach for real AWS environments.
- Do not use the simulation's `127.0.0.1/32` ingress rule as a real AWS access policy.

### Docker security

The Docker socket gives a container powerful control over the Docker host. Keep this lab local and trusted. Do not expose the Docker socket or Floci API publicly.

### Resource preservation

Do not run destructive cleanup commands such as:

```powershell
docker system prune -a --volumes
```

unless you have inspected what will be removed and explicitly intend to remove it. Such commands can delete unrelated containers, images, networks, and persistent data.

---

## 9. Current Project Progress

The following table represents the implementation checkpoint documented in this repository.

| Area | Implementation | Status |
|---|---|---|
| Local environment | Docker Desktop and Docker Compose | Completed |
| AWS simulation | Floci service setup | Completed |
| Terraform | AWS provider and local mirror configuration | Completed |
| S3 | Terraform bucket provisioning exercise | Implemented |
| Local automation | Terraform file creation exercise | Implemented |
| CI/CD | Jenkins local setup and Floci integration exploration | Implemented |
| Kubernetes | Kind cluster learning setup | Implemented |
| EC2 | Terraform-based simulated EC2 provisioning | Completed |
| Networking | Default VPC, subnet lookup, security group | Completed in simulation |
| SSH | Key-pair registration and successful local SSH login | Completed in simulation |
| EC2 bootstrapping | Automated user data and repeatable server setup | Pending |
| Application deployment | Nginx or sample application deployment | Pending |
| CI/CD automation | End-to-end pipeline for build and deployment | In progress / planned |

### Current verified EC2 checkpoint

- Terraform configuration validation succeeded.
- Terraform created the simulated key pair, security group, and EC2 instance.
- The instance was reported as running by Floci.
- The simulated container was configured with OpenSSH.
- SSH access from Windows through `127.0.0.1:2200` succeeded.
- The project uses a local Floci simulation, not a real AWS EC2 instance.

---

## 10. Future Learning Roadmap

The roadmap is intended to evolve as each implementation is completed.

### Stage 1: Kubernetes Fundamentals

- Pods and deployments.
- Services.
- ConfigMaps and Secrets.
- Namespaces.
- Resource requests and limits.
- Kubernetes troubleshooting.

### Stage 2: Kubernetes Package Management

- Helm fundamentals.
- Helm charts.
- Values files.
- Chart installation and upgrades.

### Stage 3: Jenkins CI/CD

- Jenkins pipeline syntax.
- Declarative pipelines.
- GitHub integration.
- Build and test stages.
- Terraform validation and planning.
- Credentials management.

### Stage 4: Container Registry

- Container image build.
- Image tagging.
- Registry concepts.
- Image push and pull.
- Vulnerability scanning concepts.

### Stage 5: Advanced Terraform

- Variables and outputs.
- Modules.
- Remote state concepts.
- State locking.
- Data sources.
- Lifecycle rules.
- Workspaces.
- Environment separation.

### Stage 6: Production-oriented DevOps

- Infrastructure automation.
- Change management.
- Monitoring and logging.
- IAM and least privilege.
- Deployment strategies.
- Rollback planning.
- Security and operational practices.

### Stage 7: EC2 Application Automation

- Terraform `user_data`.
- Repeatable instance bootstrapping.
- Automated package installation.
- Nginx installation and service configuration.
- Sample application deployment.
- Application health checks.
- SSH versus managed access approaches.
- Understanding differences between Floci simulation and real EC2.

### Stage 8: End-to-End Delivery Workflow

- Source control trigger.
- Jenkins pipeline.
- Build and test.
- Container image creation.
- Image registry integration.
- Deployment automation.
- Logging and monitoring.
- Failure handling and rollback.

Roadmap stages are learning targets, not claims that the work has already been completed.

---

## 11. How to Run the Project

### Prerequisites

- Windows 11 or a compatible host.
- Docker Desktop with Linux containers.
- Docker Compose.
- Git.
- Internet access for initial image and provider downloads.
- Sufficient local disk and memory for Docker containers.

### Clone the repository

```powershell
git clone https://github.com/amujii/aws-floci-terraform-devops-lab.git

cd aws-floci-terraform-devops-lab
```

### Start the services

```powershell
docker compose up -d
```

Inspect service status:

```powershell
docker compose ps
```

### Verify Terraform

```powershell
docker compose run --rm terraform version
```

### Run the S3 exercise

```powershell
docker compose run --rm terraform -chdir=/workspace/s3-bucket-automation init

docker compose run --rm terraform -chdir=/workspace/s3-bucket-automation validate

docker compose run --rm terraform -chdir=/workspace/s3-bucket-automation plan
```

Apply only after reviewing the plan:

```powershell
docker compose run --rm terraform -chdir=/workspace/s3-bucket-automation apply
```

### Run the local file exercise

```powershell
docker compose run --rm terraform -chdir=/workspace/fileCreation init

docker compose run --rm terraform -chdir=/workspace/fileCreation validate

docker compose run --rm terraform -chdir=/workspace/fileCreation plan
```

Apply after reviewing the plan:

```powershell
docker compose run --rm terraform -chdir=/workspace/fileCreation apply
```

### Run the EC2 simulation exercise

The EC2 exercise requires its local SSH key files. These files are intentionally not committed.

If the keys are not present, create or restore a suitable key pair locally and ensure the public key path matches the Terraform configuration:

```text
terraform/ec2-automation/keys/floci-ec2-key.pub
```

Do not commit the private key.

Initialize and validate:

```powershell
docker compose run --rm terraform -chdir=/workspace/ec2-automation init

docker compose run --rm terraform -chdir=/workspace/ec2-automation validate
```

Review the plan:

```powershell
docker compose run --rm terraform -chdir=/workspace/ec2-automation plan
```

Apply only after reviewing the plan and confirming that the provider is configured for the intended Floci endpoint:

```powershell
docker compose run --rm terraform -chdir=/workspace/ec2-automation apply
```

### SSH connection to the simulated EC2 container

If the simulated instance exists, its SSH port is published, OpenSSH is installed, and the SSH daemon is running:

```powershell
ssh -4 -i .\terraform\ec2-automation\keys\floci-ec2-key -p 2200 root@127.0.0.1
```

The manually configured SSH service may need to be prepared again if Floci recreates the simulated EC2 container.

### Verify generated file

Inspect the output location configured in the local file Terraform exercise. The generated file is named `automate.txt`.

### Stop services

To stop the Compose services without intentionally deleting named volumes:

```powershell
docker compose stop
```

To start them again:

```powershell
docker compose start
```

Do not remove volumes or prune Docker resources unless you have reviewed the impact and intend to delete the stored data.

---

## 12. Author and Project

**Project:** AWS Floci & DevOps Engineering Lab

**Repository:** [github.com/amujii/aws-floci-terraform-devops-lab](https://github.com/amujii/aws-floci-terraform-devops-lab)

**Focus areas:**

- AWS and cloud fundamentals.
- Terraform and Infrastructure as Code.
- Docker and containerization.
- Jenkins and CI/CD.
- Kubernetes.
- Linux and shell-based troubleshooting.
- Practical DevOps automation.

This repository is a practical learning record. Configurations and notes are updated as new exercises are implemented, tested, and reviewed.

---

## 13. Ongoing Project Log — Continue From Here

> **Current checkpoint — 14 November 2026**
>
> The local AWS simulation environment is established. Terraform-based S3 and local-file exercises have been implemented. Jenkins and Kind have been set up for learning. The EC2 exercise has successfully provisioned a simulated instance through Floci, registered an SSH key pair, configured a security group, and established SSH access from Windows through Docker port mapping.

### Last completed implementation

**Phase 7: EC2 Provisioning and SSH Access Using Terraform and Floci**

Verified outcomes:

- Terraform validation succeeded.
- Three resources were created: key pair, security group, and simulated EC2 instance.
- The simulated instance was reported as running.
- OpenSSH was installed and started in the simulated container.
- SSH access from the Windows host succeeded.

### Next implementation target

**Phase 8: EC2 User Data and Application Deployment**

Planned work:

1. Understand Terraform `user_data` and instance initialization.
2. Automate package installation and server configuration.
3. Deploy Nginx or a small sample application.
4. Verify application access through an appropriate local port mapping.
5. Document what works in Floci and what requires a real AWS environment.
6. Add the implementation, troubleshooting, and verification results to this README.

### Update rule for future work

Continue this README from this checkpoint:

- Add each new implementation as the next phase under **Section 5**.
- Add related errors and fixes under **Section 6**.
- Update the progress table in **Section 9**.
- Update the roadmap in **Section 10** when priorities change.
- Add the latest verified checkpoint and next task here in **Section 13**.
- Keep completed work, in-progress work, and planned work clearly separated.
- Record actual outputs and tested commands; do not document unverified results as completed.

**Project status: ONGOING — next target is automated EC2 bootstrapping and application deployment.**

---
