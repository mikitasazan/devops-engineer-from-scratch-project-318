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

```bash
ansible-playbook -i ansible/inventory ansible/playbook.yml --syntax-check
ansible-playbook -i ansible/inventory ansible/deploy.yml --syntax-check
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
