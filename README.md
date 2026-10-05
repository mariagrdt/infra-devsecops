# infra-devsecops

Small project to practice DevSecOps on AWS. Terraform creates the network and the server, Ansible configures the server, and Docker Compose runs Nginx (HTTPS), Prometheus and Grafana.

## Layout

```
terraform/   network, server, SSH key
ansible/     server configuration and deployment
docker/      containers: nginx, prometheus, grafana, node-exporter
```

| File | What it does |
|---|---|
| `terraform/vpc.tf` | VPC `10.0.0.0/16`, public subnet `10.0.1.0/24`, internet gateway, route table |
| `terraform/security_group.tf` | SSH only from my IP, HTTP and HTTPS from anywhere |
| `terraform/ssh_key.tf` | Generates an RSA key, uploads the public part to AWS, saves the private part as `devsecops-key.pem` |
| `terraform/main.tf` | The EC2 instance (Ubuntu 22.04, t3.micro) and the public IP output |
| `terraform/ansible_inventory.tf` | Writes `ansible/inventory.ini` with the instance IP after each apply |
| `terraform/variables.tf` | `region`, `instance_type`, `project_name`, `my_ip` |
| `ansible/playbook.yml` | Creates the `deploy` user, installs Docker, sets up UFW, generates the TLS certificate, starts the containers |
| `docker/docker-compose.yml` | Service definitions and volume mounts |
| `docker/nginx.conf` | Redirects port 80 to 443, serves HTTPS, proxies `/grafana/` to Grafana |
| `docker/prometheus.yml` | Scrape configuration: collects metrics from node-exporter every 15 seconds |

Local files that are not committed: `terraform/terraform.tfvars` (holds `my_ip`), `docker/.env` (holds the Grafana admin password), `ansible/inventory.ini`, and the generated `.pem` and state files.

## Usage

Requirements: Terraform, Ansible, the AWS CLI configured with an IAM user, and an SSH client.

1. Provision the infrastructure:
   ```bash
   cd terraform
   cp terraform.tfvars.example terraform.tfvars   # set my_ip to your public IP with /32
   terraform init
   terraform apply
   ```

2. Configure the server and start the containers. Terraform has already written the inventory:
   ```bash
   cd ../ansible
   ansible-playbook -i inventory.ini playbook.yml
   ```

3. Check the result:
   - `https://<public_ip>/` shows the Nginx default page. The browser warns about the self-signed certificate.
   - `https://<public_ip>/grafana/` opens Grafana. Log in as `admin` with the password from `docker/.env`.
   - Prometheus is not public. To open it, run `ssh -N -i terraform/devsecops-key.pem -L 9090:localhost:9090 ubuntu@<public_ip>` and browse to `http://localhost:9090`.

4. Destroy when you are done, to stay within the Free Tier:
   ```bash
   cd terraform
   terraform destroy
   ```
   The next `apply` creates a new IP. The inventory is regenerated automatically.

## Design choices

- **Two firewalls.** The security group filters traffic before it reaches the machine. UFW filters it again on the machine. If one is misconfigured, the other still applies.
- **Key-based SSH only.** No password login. The private key is stored with `0400` permissions and never committed.
- **Monitoring is not public.** Prometheus listens on `127.0.0.1` only. Grafana is reached through Nginx, with its own login.
- **Self-signed certificate.** Let's Encrypt does not issue certificates for a bare IP address. With a domain name and a fixed IP, I would switch to Let's Encrypt.
- **No WAF.** AWS WAF attaches to a load balancer, CloudFront or API Gateway, not to a single EC2 instance, and it is not free. Brute force on SSH is limited by the source IP restriction. Nginx rate limiting and fail2ban are the next things I would add.
- **Known limits.** Images use `latest` tags, which should be pinned. The Terraform state contains the private key in clear text, so a remote encrypted backend would be needed for anything beyond this lab. The `deploy` user is in the `docker` group, which gives root-equivalent rights; this is a trade-off I accepted here.

## Roadmap

- [x] Step 1: first EC2 instance with Terraform
- [x] Step 1b: VPC, security group, SSH key, verified over SSH
- [x] Step 2: Ansible configuration, Docker, UFW, HTTPS with HTTP redirect
- [x] Step 3: Prometheus, Grafana and node-exporter deployed behind Nginx
- [ ] Step 4: CI/CD with GitHub Actions, Trivy scan
- [ ] Step 5: simulated incident and post-mortem
- [ ] Step 6: architecture diagram and final write-up
