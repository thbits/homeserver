# Homeserver Docker Stack

A modular homeserver setup using Docker Compose with Traefik reverse proxy, Authelia authentication, and n8n automation.

## Project Structure

```
homeserver/
├── .env                    # Common environment variables
├── traefik/
│   ├── docker-compose.yml  # Traefik reverse proxy
│   ├── .env.example
│   └── .env                # Traefik-specific variables
├── authelia/
│   ├── docker-compose.yml  # Authentication service
│   ├── config/
│   ├── .env.example
│   └── .env                # Authelia secrets
└── n8n/
    ├── docker-compose.yml  # n8n automation
    ├── .env.example
    └── .env                # n8n-specific variables
```

## Prerequisites

### Docker installation
https://docs.docker.com/engine/install/ubuntu/#install-using-the-repository

### Github runner configuration
Repo -> Settings -> Actions -> Runners -> New self-hosted runner
Then follow the simple instructions

Install the runner service:
```bash
sudo ./svc.sh install
```

Enable and start the service:
```bash
systemctl enable actions.runner.<TAB><TAB>
systemctl start actions.runner.<TAB><TAB>
```

## Configuration

### 1. Common Environment Variables

Copy the root `.env.example` to `.env` and configure:

```bash
cp .env.example .env
```

Edit `.env` with your values:
```
DATADIR=/path/to/data/directory
DOMAIN_NAME=example.com
SSL_EMAIL=your-email@example.com
TIMEZONE=Asia/Jerusalem
```

**Note:** Set these as GitHub Actions variables/secrets:
- Variables: `DATADIR`, `DOMAIN_NAME`, `TIMEZONE`
- Secrets: `SSL_EMAIL`

### 2. Service-Specific Environment Variables

#### Traefik
```bash
cp traefik/.env.example traefik/.env
```
Currently no traefik-specific variables needed.

#### Authelia
```bash
cp authelia/.env.example authelia/.env
```

Generate secrets using:
```bash
docker run --rm authelia/authelia:latest authelia crypto rand --length 64
```

Add the three secrets to `authelia/.env`:
```
JWT_SECRET=<generated-secret>
SESSION_SECRET=<generated-secret>
STORAGE_ENCRYPTION_KEY=<generated-secret>
```

**Note:** Set these as GitHub Actions secrets: `JWT_SECRET`, `SESSION_SECRET`, `STORAGE_ENCRYPTION_KEY`

#### n8n
```bash
cp n8n/.env.example n8n/.env
```
Currently no n8n-specific variables needed.

### 3. Authelia Users

Copy the example file and edit it:
```bash
cp authelia/config/users.yaml.example authelia/config/users.yaml
```

Configure hashed password:
```bash
docker run --rm -it authelia/authelia:4.39.11 authelia crypto hash generate argon2
```

## Deployment

### Deploy All Services
```bash
# Deploy in order: traefik -> authelia -> n8n
cd traefik && docker compose --env-file ../.env up -d && cd ..
cd authelia && docker compose --env-file ../.env up -d && cd ..
cd n8n && docker compose --env-file ../.env up -d && cd ..
```

### Deploy Individual Service
```bash
cd <service-directory>
docker compose --env-file ../.env up -d
```

### Update Services
```bash
cd <service-directory>
docker compose --env-file ../.env pull
docker compose --env-file ../.env up -d
```

**Note:** The `--env-file ../.env` flag is required to load common variables (DATADIR, DOMAIN_NAME, etc.) for use in the docker-compose.yml file itself.

## Automated Updates

This project uses **Renovate** (replacing Dependabot) for automated dependency updates.

- **Schedule:** Sundays at 6:00 AM (Asia/Jerusalem timezone)
- **Auto-merge:** Minor and patch version updates are automatically merged
- **Manual review:** Major version updates require manual approval
- **Discovery:** Automatically finds all `docker-compose.yml` files in the repository

Renovate configuration is in `.github/renovate.json`

## CI/CD

The project includes GitHub Actions workflows:

- **renovate-auto-merge.yml** - Automatically merges minor/patch updates from Renovate
- **deploy-on-merge.yml** - Deploys all services when changes are merged to main
  - Automatically discovers and deploys all docker-compose files
  - Runs on self-hosted runner
