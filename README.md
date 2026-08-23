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
- `ansible/requirements.yml` lists roles and collections.
- `ansible/group_vars/app/vars.yml` contains non-secret variables.

Create `ansible/group_vars/app/vault.yml` from the example and encrypt it with
Ansible Vault. The decrypted file is ignored by Git.

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
