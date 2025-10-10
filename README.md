# Homeserver Docker Stack

A modular homeserver setup using Docker Compose with Traefik reverse proxy, Authelia authentication, and n8n automation.

## Project Structure

```
homeserver/
├── .env                    # All environment variables (common + service-specific)
├── traefik/
│   └── docker-compose.yml  # Traefik reverse proxy
├── authelia/
│   ├── docker-compose.yml  # Authentication service
│   └── config/
└── n8n/
    └── docker-compose.yml  # n8n automation
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

### 1. Environment Variables

Copy the root `.env.example` to `.env` and configure:

```bash
cp .env.example .env
```

Edit `.env` with ALL your values (common + service-specific):

```bash
# Common variables
DATADIR=/path/to/data/directory
DOMAIN_NAME=example.com
SSL_EMAIL=your-email@example.com
TIMEZONE=Asia/Jerusalem

# Authelia secrets (generate using command below)
JWT_SECRET=<generated-secret>
SESSION_SECRET=<generated-secret>
STORAGE_ENCRYPTION_KEY=<generated-secret>

# SMTP configuration (for email notifications)
SMTP_USERNAME=your-email@gmail.com
SMTP_PASSWORD=<gmail-app-password>
```

#### Generate Authelia Secrets

```bash
docker run --rm authelia/authelia:latest authelia crypto rand --length 64
```

Run this command three times to generate the three secrets, then add them to `.env`.

#### Generate Gmail App Password

To use Gmail for email notifications, you need to generate an app password:

1. Go to [Google App Passwords](https://myaccount.google.com/apppasswords)
2. Enable 2-factor authentication if you haven't already
3. Select "Mail" and your device
4. Click "Generate" to get a 16-character password
5. Add this password to your `.env` file as `SMTP_PASSWORD`

#### GitHub Actions Configuration

Set these as GitHub Actions variables/secrets (Settings → Secrets and variables → Actions):

**Variables (public):**
| Variable | Service | Notes |
|----------|---------|-------|
| `DATADIR` | All | Path to data directory on server |
| `DOMAIN_NAME` | All | Your domain name |
| `TIMEZONE` | All | Timezone (e.g., Asia/Jerusalem) |

**Secrets (encrypted):**
| Secret | Service | Notes |
|--------|---------|-------|
| `SSL_EMAIL` | Traefik | Email for Let's Encrypt notifications |
| `JWT_SECRET` | Authelia | Generate with: `docker run --rm authelia/authelia:latest authelia crypto rand --length 64` |
| `SESSION_SECRET` | Authelia | Generate with: `docker run --rm authelia/authelia:latest authelia crypto rand --length 64` |
| `STORAGE_ENCRYPTION_KEY` | Authelia | Generate with: `docker run --rm authelia/authelia:latest authelia crypto rand --length 64` |
| `SMTP_USERNAME` | Authelia | Your Gmail address (e.g., your-email@gmail.com) |
| `SMTP_PASSWORD` | Authelia | Gmail app password (generate at https://myaccount.google.com/apppasswords) |

### 2. Authelia Users

Copy the example file and edit it:
```bash
cp authelia/config/users.yaml.example authelia/config/users.yaml
```

Configure hashed password:
```bash
docker run --rm -it authelia/authelia:4.39.11 authelia crypto hash generate argon2
```

## Deployment

### Local Deployment

**Important:** Always export environment variables first before running any docker compose commands:

```bash
export $(cat .env | xargs)
```

### Deploy Services
**From root directory**
```bash
export $(cat .env | xargs)
docker compose -f <service-directory>/docker-compose.yml up -d
```

**Note:** The `export $(cat .env | xargs)` command loads environment variables from the root `.env` file into your shell, making them available to docker-compose for variable substitution.

## Automated Updates

This project uses **Renovate** (for automated dependency updates.

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