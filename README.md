# Homeserver Docker Stack

A modular homeserver setup using Docker Compose with Traefik reverse proxy, Authelia authentication, Pi-hole ad blocking, WireGuard VPN, n8n automation, and more.

## Project Structure

```
homeserver/
├── .env                    # All environment variables (common + service-specific)
├── traefik/
│   └── docker-compose.yml  # Traefik reverse proxy
├── authelia/
│   ├── docker-compose.yml  # Authentication service
│   └── config/
├── <service>/
│   └── docker-compose.yml  # Each service has its own docker-compose.yml
└── ...                     # More services can be added
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

Create a `.env` file in the root directory:

```bash
cp .env.example .env
```

Edit `.env` with ALL your values (common + service-specific):

```bash
# Common variables
DATADIR=/path/to/data/directory
CONFIGDIR=/path/to/config/directory
DOMAIN_NAME=example.com
SSL_EMAIL=your-email@example.com
TIMEZONE=Asia/Jerusalem

# User/Group IDs (get with: id -u and id -g)
PUID=1000
PGID=1000

# Cloudflare API token (for Traefik SSL certificates and DDNS)
CF_DNS_API_TOKEN=<your-cloudflare-api-token>
CF_DNS_ZONE_ID=<your-cloudflare-zone-id>

# Authelia secrets (generate using command below)
JWT_SECRET=<generated-secret>
SESSION_SECRET=<generated-secret>
STORAGE_ENCRYPTION_KEY=<generated-secret>

# SMTP configuration (for email notifications)
SMTP_USERNAME=your-email@gmail.com
SMTP_PASSWORD=<gmail-app-password>

# Servarr API Keys (found in Settings → General → Security in each app)
SONARR_API_KEY=<your-sonarr-api-key>
RADARR_API_KEY=<your-radarr-api-key>
```

#### Generate Authelia Secrets

```bash
docker run --rm authelia/authelia:latest authelia crypto rand --length 64
```

Run this command three times to generate the three secrets, then add them to `.env`.

#### Generate Cloudflare API Token

To use Cloudflare for SSL certificates (via DNS challenge) and dynamic DNS updates:

1. Go to [Cloudflare API Tokens](https://dash.cloudflare.com/profile/api-tokens)
2. Click "Create Token"
3. Use the "Edit zone DNS" template
4. Configure permissions:
   - Permissions: `Zone - DNS - Edit`
   - Zone Resources: `Include - Specific zone - <your-domain>`
5. Click "Continue to summary" and "Create Token"
6. Add this token to your `.env` file as `CF_DNS_API_TOKEN`

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
| `CONFIGDIR` | All | Path to config directory on server |
| `TIMEZONE` | All | Timezone (e.g., Asia/Jerusalem) |

**Secrets (encrypted):**
| Secret | Service | Notes |
|--------|---------|-------|
| `DOMAIN_NAME` | All | Your domain name |
| `PUID` | All | User ID (typically 1000) |
| `PGID` | All | Group ID (typically 1000) |
| `SSL_EMAIL` | Traefik | Email for Let's Encrypt notifications |
| `CF_DNS_API_TOKEN` | Traefik, Cloudflare-DDNS | Cloudflare API token with DNS edit permissions |
| `CF_DNS_ZONE_ID` | Cloudflare-DDNS | Cloudflare zone ID (found in domain dashboard) |
| `JWT_SECRET` | Authelia | Generate with: `docker run --rm authelia/authelia:latest authelia crypto rand --length 64` |
| `SESSION_SECRET` | Authelia | Generate with: `docker run --rm authelia/authelia:latest authelia crypto rand --length 64` |
| `STORAGE_ENCRYPTION_KEY` | Authelia | Generate with: `docker run --rm authelia/authelia:latest authelia crypto rand --length 64` |
| `SMTP_USERNAME` | Authelia | Your Gmail address (e.g., your-email@gmail.com) |
| `SMTP_PASSWORD` | Authelia | Gmail app password (generate at https://myaccount.google.com/apppasswords) |
| `SONARR_API_KEY` | Recyclarr, Unpackerr | Sonarr API key (found in Sonarr → Settings → General → Security) |
| `RADARR_API_KEY` | Recyclarr, Unpackerr | Radarr API key (found in Radarr → Settings → General → Security) |

### 2. Authelia Users

Copy the example file and edit it:
```bash
cp authelia/config/users.yaml.example authelia/config/users.yaml
```

Configure hashed password:
```bash
docker run --rm -it authelia/authelia:4.39.11 authelia crypto hash generate argon2
```

### 3. Cloudflare DDNS Configuration

To configure Cloudflare Dynamic DNS:

1. Copy the example configuration file to your config directory:
```bash
cp cloudflare-ddns/config.json.example ${CONFIGDIR}/cloudflare-ddns/config.json
```

2. Edit the configuration file and update the required fields:
```bash
nano ${CONFIGDIR}/cloudflare-ddns/config.json
```

Key fields to configure:
- `zone_id`: Your Cloudflare zone ID (found in your domain's dashboard)
- `subdomains`: Configure which subdomains to update (`@` for root domain)
- `proxied`: Set to `true` to enable Cloudflare proxy, or `false` for direct DNS

**Note:** The `${CF_DDNS_API_TOKEN}` will be automatically substituted from your environment variables.

## Available Services

The homeserver includes the following services, each with its own `docker-compose.yml`:

| Service | Description | Access URL | Protected by Authelia |
|---------|-------------|------------|----------------------|
| **Traefik** | Reverse proxy with automatic SSL | N/A | No |
| **Authelia** | Authentication and authorization | `auth.${DOMAIN_NAME}` | No |
| **Cloudflare DDNS** | Dynamic DNS updater | N/A | No |
| **Pi-hole** | Network-wide ad blocker | `pihole.${DOMAIN_NAME}` | Yes |
| **WG-Easy** | WireGuard VPN manager | `wg-easy.${DOMAIN_NAME}` | Yes |
| **n8n** | Workflow automation | `n8n.${DOMAIN_NAME}` | Yes |

All services are connected via the `internal` Docker network and automatically receive SSL certificates through Traefik's Cloudflare DNS challenge.

### Required Ports

Ensure the following ports are open in your firewall:

| Port | Protocol | Service | Purpose |
|------|----------|---------|---------|
| 80 | TCP | Traefik | HTTP (auto-redirects to HTTPS) |
| 443 | TCP | Traefik | HTTPS |
| 51820 | UDP | WG-Easy | WireGuard VPN |

## Deployment

### Local Deployment

**Important:** Always export environment variables first before running any docker compose commands:

```bash
export $(cat .env | xargs)
```

### Deploy Services

Deploy services in the following order:

**1. Deploy Traefik first** (creates required networks):
```bash
docker compose -f traefik/docker-compose.yml up -d
```

**2. Deploy all other services automatically:**
```bash
for dir in */; do [ -f "$dir/docker-compose.yml" ] && [ "$dir" != "traefik/" ] && docker compose -f "$dir/docker-compose.yml" up -d; done
```

Or deploy individual services manually:
```bash
docker compose -f authelia/docker-compose.yml up -d
```

**Note:** The `export $(cat .env | xargs)` command loads environment variables from the root `.env` file into your shell, making them available to docker-compose for variable substitution. Remember to run this command in each new shell session.

### Accessing Services

After deployment, you can access your services at:

- **Authelia**: `https://auth.${DOMAIN_NAME}`
- **Pi-hole**: `https://pihole.${DOMAIN_NAME}` (requires Authelia login)
- **WG-Easy**: `https://wg-easy.${DOMAIN_NAME}` (requires Authelia login)
- **n8n**: `https://n8n.${DOMAIN_NAME}` (requires Authelia login)

On first access to protected services, you'll be redirected to Authelia for authentication using the credentials configured in `authelia/config/users.yaml`.

## Automated Updates

This project uses **Renovate** for automated dependency updates.

- **Schedule:** Sundays between 3:00 AM - 7:00 AM (Asia/Jerusalem timezone)
- **Auto-merge:** Minor and patch version updates are automatically merged
- **Manual review:** Major version updates require manual approval
- **Discovery:** Automatically finds all `docker-compose.yml` files in the repository
- **Security:** Docker images are pinned with digests for immutable references

Renovate configuration is in `.github/renovate.json`

## CI/CD

The project includes GitHub Actions workflows:

- **renovate-auto-merge.yml** - Automatically merges minor/patch updates from Renovate
- **deploy-on-merge.yml** - Deploys all services when changes are merged to main
  - Automatically discovers and deploys all docker-compose files (Traefik first, then others)
  - Runs on self-hosted runner
  - Requires all environment variables to be set in GitHub Actions
- **runner-smoke.yml** - Manual workflow to test the self-hosted runner
  - Validates Docker and docker-compose installation
  - Can be triggered manually from GitHub Actions tab