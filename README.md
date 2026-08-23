# Bulletin Board Observability

### Hexlet tests and linter status

[![CI](https://github.com/mikitasazan/devops-engineer-from-scratch-project-318/actions/workflows/hexlet-check.yml/badge.svg)](https://github.com/mikitasazan/devops-engineer-from-scratch-project-318/actions)

Bulletin board service with Docker, PostgreSQL, S3-compatible object storage,
Ansible deployment, and Nginx reverse proxy configuration.

Application URL after cloud deployment: `https://app.example.com`.

## Requirements

The target host must be an Ubuntu server with SSH access, a public IP, ports
22/80/443 allowed, and enough disk space for Docker images and persistent
volumes. The infrastructure files are in `ansible/`.

## Commands

```bash
make test
make docker-build
make ansible-install
make deploy IMAGE=ghcr.io/mikitasazan/devops-engineer-from-scratch-project-318:<git-sha>
```

The deployment uses an immutable image tag. Use an earlier SHA tag to roll
back.

## Deployment from zero

1. Create two Ubuntu VMs in the same VPC: one in the `app` group and one in
   the `monitoring` group. Add their public IPs to `ansible/inventory` and keep
   SSH private keys outside Git.
2. Copy and encrypt `ansible/group_vars/app/vault.yml.example` and
   `ansible/group_vars/monitoring/vault.yml.example` with Ansible Vault.
3. Install roles and collections with `make ansible-install`.
4. Prepare the application VM with `ansible/playbook.yml`, then deploy the
   image with `make deploy IMAGE=...`.
5. Deploy Prometheus, Loki, and Grafana with `make monitoring-deploy`.
6. Point DNS to the application VM, run `ansible/certbot.yml`, and verify the
   HTTPS URL.

Ports: SSH `22`, HTTP/HTTPS `80/443`, application `8080`, management `9090`,
Node Exporter `9100`, Nginx Exporter `9113`, Prometheus `9090`, Grafana `3000`,
and Loki `3100`. Expose monitoring ports only to the monitoring VPC/security
group.

## Ansible

- `ansible/playbook.yml` prepares the server and installs Docker.
- `ansible/deploy.yml` pulls the selected image and starts the application.
- `ansible/certbot.yml` configures Let’s Encrypt certificate renewal.
- `ansible/monitoring.yml` deploys Prometheus on the `monitoring` host group.
- `ansible/requirements.yml` lists roles and collections.
- `ansible/group_vars/app/vars.yml` contains non-secret variables.

Create `ansible/group_vars/app/vault.yml` from the example and encrypt it with
Ansible Vault. The decrypted file is ignored by Git.

The Prometheus UI is available at `http://<monitoring-host>:9090/graph` and
Grafana at `http://<monitoring-host>:3000` after running
`make monitoring-deploy`. Grafana provisions the Prometheus datasource and the
Bulletin Board Overview dashboard automatically. Its admin password comes from
`vault_grafana_admin_password`.

Prometheus rules in `monitoring/prometheus/rules/alerts.yml` cover target
availability and application 5xx responses. Grafana provisions a webhook
contact point from `ALERT_WEBHOOK_URL`, which must be supplied through Vault or
the CI environment. To test alerting, stop the application container, wait for
the five-minute `TargetDown` period, and check the Grafana Alerting page.

Nginx Exporter is deployed by the `nginx_exporter` role and exposes `/metrics`
on port `9113`. Nginx `stub_status` is restricted to the monitoring network;
the Prometheus target is defined in `ansible/group_vars/monitoring/vars.yml`.

Loki receives JSON container logs from Promtail. In Grafana, use LogQL
queries such as `{job="containers", level="ERROR"}` for errors or
`{job="containers", app="bulletins"}` for application logs.

```bash
ansible-playbook -i ansible/inventory ansible/playbook.yml --syntax-check
ansible-playbook -i ansible/inventory ansible/deploy.yml --syntax-check
make lint
make smoke APP_URL=https://app.example.com PROMETHEUS_URL=http://monitoring.example.com:9090
```

## Local PostgreSQL and S3

Copy `.env.example` and `.env.s3.example` to local files, set strong local
passwords, and start the stack:

```bash
docker compose --env-file .env.example --env-file .env.s3 \
  -f docker-compose.prod.yml -f docker-compose.s3.yml up -d
```

MinIO creates the bucket before the application starts. Nginx can be added
with `docker-compose.nginx.yml`. The HTTPS example is in
`nginx-https.conf.example`; replace `APP_DOMAIN` after DNS is ready.

## Metrics and checks

The Node Exporter role exposes host metrics on port `9100`, restricted to the
monitoring network. Nginx forwards application health and Prometheus metrics
from management port `9090`.

| Area | Required metrics or endpoint |
| --- | --- |
| CPU | `node_load1`, `node_cpu_seconds_total` |
| Memory | `node_memory_MemAvailable_bytes`, `node_memory_MemTotal_bytes` |
| Disk | `node_filesystem_avail_bytes`, `node_filesystem_size_bytes` |
| Network | `node_network_receive_bytes_total`, `node_network_transmit_bytes_total` |
| Processes | `node_processes_running`, `node_processes_blocked` |
| Services | `node_systemd_unit_state` |
| Application | `process_uptime_seconds`, `http_server_requests_seconds_count` |

Local checks:

```bash
curl http://localhost:9090/actuator/health
curl http://localhost:9090/actuator/prometheus
curl http://localhost/actuator/health
```
