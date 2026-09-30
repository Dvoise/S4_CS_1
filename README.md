# AWS Web Environment — Terraform

A load-balanced, auto-scaling web environment on AWS, built with Terraform.
Provisioned entirely through IaC, with a self-managed
database, Prometheus/Grafana monitoring, and CodeDeploy blue/green
deployments triggered from GitHub.


## Prerequisites

- Terraform >= 1.5
- AWS CLI, configured with credentials for the target account
- An AWS account/role with permissions to create VPC, EC2, IAM, ALB, and
  CodeDeploy resources
- A GitHub repository (for the CodeDeploy source and Actions workflow)

## Setup

1. **Clone and configure secrets.** Create `terraform.tfvars` in the project
   root (this file is git-ignored):
   ```
   db_password = "YourStrongPasswordHere"
   ```

2. **Initialize Terraform:**
   ```
   terraform init
   ```

3. **Review the plan:**
   ```
   terraform plan
   ```

4. **Apply:**
   ```
   terraform apply
   ```
   A full apply takes roughly 10–15 minutes, mostly waiting on the NAT
   Gateways.

5. **Retrieve outputs:**
   ```
   terraform output alb_dns_name
   terraform output grafana_url
   terraform output prometheus_url
   terraform output db_private_ip
   ```

## Verifying the Environment

1. **Web tier** — open `http://<alb_dns_name>`; should return the current
   `index.html` content. Confirm both targets show **Healthy** in the
   `web-tg` target group.
2. **Database access** — from an SSM session on a web instance:
   ```
   mysql -h <db_private_ip> -u admin -p appdb
   ```
   should succeed. The same command from the monitoring instance (a
   different security group) should time out.
3. **Scaling** — generate CPU load on a web instance (`stress --cpu 2
   --timeout 300`) and watch the ASG's Activity tab for a scale-out event.
4. **Monitoring** — open `http://<monitoring-ip>:9090/classic/targets`; both web
   instances should show **UP**. Open `http://<monitoring-ip>:3000`, log in
   (`admin`/`admin`, then set a new password), and import dashboard ID
   `1860` (Node Exporter Full) with the Prometheus data source.
5. **Deployment** — push a change to `index.html` on `main`; the GitHub
   Actions workflow should trigger a CodeDeploy blue/green deployment, and
   the ALB URL should serve the updated content once it completes.

## CI/CD

Every push to `main` runs `.github/workflows/deploy.yml`, which calls
`aws deploy create-deployment` against the CodeDeploy application, pointing
at the pushed commit in this repository. CodeDeploy then performs a
blue/green deployment: it launches a parallel set of instances from the
current Auto Scaling configuration, applies the files and hooks defined in
`appspec.yml`, shifts ALB traffic to the new instances once healthy, and
terminates the old set.

The workflow authenticates to AWS using access keys stored as repository
secrets (`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`,
`AWS_SESSION_TOKEN`).

## Known Limitations

- **Credentials expire.** This account issues temporary, short-lived
  credentials. Both local Terraform runs and the GitHub Actions secrets
  need to be refreshed periodically — this is a property of the lab
  environment, not the Terraform configuration.
- **No persistent monitoring data.** Prometheus and Grafana store data on
  local disk on the monitoring instance; metrics history does not survive a
  `terraform destroy`. Dashboard configuration is re-provisioned
  automatically at boot via `user_data`.
- **HTTP only.** The ALB listener is HTTP on port 80; no TLS/ACM
  certificate is configured.
- **No automated CodeDeploy cleanup.** A blue/green deployment creates a
  temporary, CodeDeploy-managed Auto Scaling Group that Terraform does not
  track. Check for and remove any leftover `CodeDeploy_...` ASG in the
  console before running `terraform destroy`.

## Cost Management

This environment is not free — the NAT Gateways, ALB, and EC2 instances all
bill hourly while running. To avoid unnecessary cost, destroy the
environment when not actively in use:

```
terraform destroy
```

All Terraform-managed resources will be recreated correctly on the next
`terraform apply`, since configuration (not state) defines them. Some
resources are provisioned automatically at boot via `user_data`
(node_exporter, CodeDeploy agent, Prometheus/Grafana config), so a fresh
`apply` after a full `destroy` does not require any extra manual steps.