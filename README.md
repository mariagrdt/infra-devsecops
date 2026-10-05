# infra-devsecops

A hands-on DevSecOps portfolio project: provisioning a cloud server with Terraform, hardening and configuring it with Ansible, running it with Docker + monitoring, and wiring it into a CI/CD pipeline with security scanning.

## Project Structure

The project is split by tool, matching the three stages of the pipeline (provision → configure → run):

```
infra-devsecops/
├── terraform/     # Infrastructure provisioning
├── ansible/       # Server configuration
├── docker/        # Application / services layer
└── docs/          # Personal notes (not part of the public portfolio narrative)
```

| File | Purpose |
|---|---|
| `terraform/main.tf` | Provider configuration, required providers, AMI lookup, the EC2 instance itself, and the `public_ip` output |
| `terraform/variables.tf` | Input variables: `region`, `instance_type`, `project_name`, `my_ip` |
| `terraform/vpc.tf` | Networking: VPC, public subnet, Internet Gateway, route table, and route table association |
| `terraform/security_group.tf` | Firewall rules: SSH restricted to the operator's IP, HTTP/HTTPS open to everyone |
| `terraform/ssh_key.tf` | Generates an RSA key pair, registers the public key with AWS, and saves the private key locally as a `.pem` file |
| `terraform/terraform.tfvars` | Local, untracked file holding the real value of `my_ip` (see `terraform.tfvars.example`) |
| `ansible/playbook.yml` | Server hardening: creates the `deploy` user, installs Docker, configures UFW, deploys the app stack |
| `ansible/inventory.ini` | Local, untracked file listing the target server and SSH connection details (see `inventory.ini.example`) |
| `docker/docker-compose.yml` | Defines the containerized services (Nginx, and later Prometheus/Grafana) |

## Getting Started

### Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install) installed
- [Ansible](https://docs.ansible.com/ansible/latest/installation_guide/index.html) installed
- An AWS account with the AWS CLI configured (`aws configure`) using an IAM user with programmatic access
- An SSH client (built into macOS/Linux; use WSL or PuTTY on Windows)

### Setup

1. Clone this repository and move into it.
2. Provision the infrastructure:
   ```bash
   cd terraform
   cp terraform.tfvars.example terraform.tfvars
   curl -4 ifconfig.me   # prints your public IPv4 address
   ```
   Edit `terraform.tfvars` so it reads `my_ip = "<your_ip>/32"`, then:
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```
   Type `yes` to confirm. This provisions the VPC, subnet, security group, SSH key pair, and the EC2 instance (10 resources). Note the `public_ip` printed at the end.
3. Configure the server with Ansible:
   ```bash
   cd ../ansible
   cp inventory.ini.example inventory.ini
   ```
   Edit `inventory.ini` with the `public_ip` from the previous step, then:
   ```bash
   ansible all -i inventory.ini -m ping     # sanity check
   ansible-playbook -i inventory.ini playbook.yml
   ```
4. Connect to the instance directly if needed:
   ```bash
   ssh -i ../terraform/devsecops-key.pem ubuntu@<public_ip>
   ```

### Tearing down

To avoid unnecessary AWS costs (this project targets the Free Tier), destroy the infrastructure when done working on it:
```bash
cd terraform
terraform destroy
```
The code stays untouched — running `terraform apply` again fully recreates the environment (with a new `public_ip`, so `ansible/inventory.ini` needs updating accordingly).

## Step 1 — Architecture Choice

### Decision

A single EC2 instance in a dedicated VPC, with a public subnet directly exposing SSH (restricted to my IP) and HTTP/HTTPS. 

```
Internet
   │
   ▼
Internet Gateway
   │
   ▼
Public Subnet (10.0.1.0/24) ── Route Table (0.0.0.0/0 → IGW)
   │
   ▼
Security Group (SSH from my IP only, HTTP/HTTPS from anywhere)
   │
   ▼
EC2 instance (t3.micro, Ubuntu)
```

### Why a simple architecture

This project is meant to demonstrate DevSecOps practices end-to-end (infrastructure as code, configuration management, containerization, CI/CD, security scanning, incident response) rather than to simulate a large-scale production system. For a single-operator portfolio project, architectural complexity adds risk and debugging overhead without adding proof of skill — what matters here is showing *why* each security decision was made, not how many components the network has.

### Security principles applied

- **Least privilege network access** — SSH is restricted to a single operator IP (`my_ip` variable) instead of `0.0.0.0/0`; only HTTP/HTTPS are open to the world.
- **Key-based SSH authentication** — no password authentication.
- **No reliance on AWS defaults** — a dedicated VPC, subnet, route table, and security group are defined explicitly and version-controlled.
- **No secrets committed** — state files, private keys, and IP-containing variable files are excluded via `.gitignore`.

## Roadmap

- [x] Step 1 — Terraform: first EC2 instance
- [x] Step 1b — VPC, Security Group, SSH key
  - [x] Variables (`region`, `instance_type`, `project_name`, `my_ip`)
  - [x] VPC + public subnet
  - [x] Internet Gateway + route table
  - [x] Security Group (SSH from operator IP, HTTP/HTTPS open)
  - [x] SSH key pair generation
  - [x] Wire the EC2 instance to the new VPC/subnet/SG/key in `main.tf`
  - [x] Verified: SSH connection to the instance works end to end
- [x] Step 2 — Ansible: server hardening and configuration (deploy user, Docker, UFW, self-signed HTTPS with HTTP→HTTPS redirect)
- [ ] Step 3 — Docker + monitoring (Nginx, Prometheus, Grafana)
- [ ] Step 4 — CI/CD + Trivy security scanning
- [ ] Step 5 — Simulated incident + post-mortem
- [ ] Step 6 — Architecture diagram and final documentation
