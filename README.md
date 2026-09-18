# infra-devsecops

A hands-on DevSecOps portfolio project: provisioning a cloud server with Terraform, hardening and configuring it with Ansible, running it with Docker + monitoring, and wiring it into a CI/CD pipeline with security scanning.

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
- [ ] Step 1b — VPC, Security Group, SSH key
  - [x] Variables (`region`, `instance_type`, `project_name`, `my_ip`)
  - [x] VPC + public subnet
  - [ ] Internet Gateway + route table
  - [ ] Security Group (SSH from operator IP, HTTP/HTTPS open)
  - [ ] SSH key pair generation
  - [ ] Wire the EC2 instance to the new VPC/subnet/SG/key in `main.tf`
- [ ] Step 2 — Ansible: server hardening and configuration
- [ ] Step 3 — Docker + monitoring (Nginx, Prometheus, Grafana)
- [ ] Step 4 — CI/CD + Trivy security scanning
- [ ] Step 5 — Simulated incident + post-mortem
- [ ] Step 6 — Architecture diagram and final documentation
