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
LOCAL_IP=server.local.ip.address
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
PROWLARR_API_KEY=<your-prowlarr-api-key>
BAZARR_API_KEY=<your-bazarr-api-key>

# Media Server API Keys
JELLYFIN_API_KEY=<your-jellyfin-api-key>
JELLYSEER_API_KEY=<your-jellyseerr-api-key>

# qBittorrent credentials
QBIT_USER=<your-qbittorrent-username>
QBIT_PASS=<your-qbittorrent-password>

# WireGuard (WG-Easy) credentials for Homepage widget
WIREGUARD_USERNAME=<your-wireguard-username>
WIREGUARD_PASSWORD=<your-wireguard-password>

# Pi-hole API Key (found in Settings → API / Web interface)
PIHOLE_API_KEY=<your-pihole-api-key>

# CrowdSec (generate bouncer key after first deployment)
CROWDSEC_BOUNCER_KEY=<generate-after-deployment>
CROWDSEC_ENROLL_KEY=<optional-for-console>

# JOAL (Jack of All Trades torrent ratio faker)
JOAL_SECRET_TOKEN=<random-secret-string>
JOAL_SECRET_OBFUSCATION_PATH=<random-path-string>

# Restic Backup Configuration
RESTIC_PASSWORD=<generate-with-openssl-rand-base64-32>

# Paperless-ngx Configuration
PAPERLESS_SECRET_KEY=<generate-with-openssl-rand-base64-32>

# Hindsight Configuration
HINDSIGHT_DB_PASSWORD=<generate-with-openssl-rand-hex-16>
HINDSIGHT_OPENROUTER_API_KEY=<your-openrouter-api-key>
HINDSIGHT_ACCESS_KEY=<generate-with-openssl-rand-hex-24>

# SparkyFitness Configuration
SPARKY_FITNESS_DB_NAME=sparkyfitness_db
SPARKY_FITNESS_DB_USER=sparky
SPARKY_FITNESS_DB_PASSWORD=<generate-with-openssl-rand-base64-32>
SPARKY_FITNESS_APP_DB_USER=<app-db-username>
SPARKY_FITNESS_APP_DB_PASSWORD=<generate-with-openssl-rand-base64-32>
SPARKY_FITNESS_API_ENCRYPTION_KEY=<generate-with-openssl-rand-base64-32>
SPARKY_FITNESS_JWT_SECRET=<generate-with-openssl-rand-base64-32>
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
| `LOCAL_IP` | All | Your local server IP |
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
| `SONARR_API_KEY` | Recyclarr, Unpackerr, Homepage | Sonarr API key (found in Sonarr → Settings → General → Security) |
| `RADARR_API_KEY` | Recyclarr, Unpackerr, Homepage | Radarr API key (found in Radarr → Settings → General → Security) |
| `PROWLARR_API_KEY` | Homepage | Prowlarr API key (found in Prowlarr → Settings → General → Security) |
| `BAZARR_API_KEY` | Homepage | Bazarr API key (found in Bazarr → Settings → General → Security) |
| `JELLYFIN_API_KEY` | Homepage | Jellyfin API key (create in Dashboard → API Keys) |
| `JELLYSEER_API_KEY` | Homepage | Jellyseerr API key (found in Settings → General) |
| `QBIT_USER` | Homepage | qBittorrent username |
| `QBIT_PASS` | Homepage | qBittorrent password |
| `WIREGUARD_USERNAME` | Homepage | WireGuard (WG-Easy) username |
| `WIREGUARD_PASSWORD` | Homepage | WireGuard (WG-Easy) password |
| `PIHOLE_API_KEY` | Homepage | Pi-hole API key (found in Settings → API / Web interface) |
| `CROWDSEC_BOUNCER_KEY` | Traefik, CrowdSec | Generate with: `docker exec crowdsec cscli bouncers add traefik-bouncer` (after first CrowdSec deployment) |
| `CROWDSEC_ENROLL_KEY` | CrowdSec | Optional - For CrowdSec Console enrollment (get from https://app.crowdsec.net/) |
| `JOAL_SECRET_TOKEN` | JOAL | Random secret string for UI authentication |
| `JOAL_SECRET_OBFUSCATION_PATH` | JOAL | Random path string to obfuscate UI URL (e.g., `my-secret-path-123`) |
| `PAPERLESS_SECRET_KEY` | Paperless-ngx | Generate with: `openssl rand -base64 32` |
| `HINDSIGHT_DB_PASSWORD` | Hindsight | PostgreSQL password - Generate with: `openssl rand -hex 16` (hex only: it's embedded in a connection URL) |
| `HINDSIGHT_OPENROUTER_API_KEY` | Hindsight | OpenRouter API key used for LLM + embeddings (use a dedicated key, not shared) |
| `HINDSIGHT_ACCESS_KEY` | Hindsight | API bearer token + Control Plane UI login - Generate with: `openssl rand -hex 24` |
| `SPARKY_FITNESS_DB_NAME` | SparkyFitness | PostgreSQL database name (e.g., sparkyfitness_db) |
| `SPARKY_FITNESS_DB_USER` | SparkyFitness | PostgreSQL database user (e.g., sparky) |
| `SPARKY_FITNESS_DB_PASSWORD` | SparkyFitness | PostgreSQL database password - Generate with: `openssl rand -base64 32` |
| `SPARKY_FITNESS_APP_DB_USER` | SparkyFitness | Application database username |
| `SPARKY_FITNESS_APP_DB_PASSWORD` | SparkyFitness | Application database password - Generate with: `openssl rand -base64 32` |
| `SPARKY_FITNESS_API_ENCRYPTION_KEY` | SparkyFitness | API encryption key - Generate with: `openssl rand -base64 32` |
| `SPARKY_FITNESS_JWT_SECRET` | SparkyFitness | JWT authentication secret - Generate with: `openssl rand -base64 32` |

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

### 4. CrowdSec Configuration

CrowdSec protects your homeserver by analyzing Traefik access logs and blocking malicious IPs using the Traefik bouncer plugin.

#### Initial Setup

1. Deploy CrowdSec (along with Traefik):
```bash
export $(cat .env | xargs)
docker compose -f traefik/docker-compose.yml up -d
docker compose -f crowdsec/docker-compose.yml up -d
```

2. Generate a bouncer API key:
```bash
docker exec crowdsec cscli bouncers add traefik-bouncer
```

This command will output an API key. Copy it and add it to your `.env` file as `CROWDSEC_BOUNCER_KEY`.

3. Restart Traefik to apply the bouncer key:
```bash
docker compose -f traefik/docker-compose.yml restart
```

4. (Optional) Enroll in the CrowdSec Console for centralized management:
```bash
docker exec crowdsec cscli console enroll <your-enroll-key>
```

Get your enrollment key from: https://app.crowdsec.net/

#### CrowdSec Dashboard (Metabase)

A self-hosted Metabase dashboard is available at `https://crowdsec.${DOMAIN_NAME}` for visualizing CrowdSec metrics, alerts, and decisions.

**Initial Setup (First Time Only):**

1. Access the dashboard at `https://crowdsec.${DOMAIN_NAME}`
2. Complete the Metabase setup wizard:
   - Set your preferred language
   - Create an admin account
   - Skip "Add your data" (we'll add it manually)

3. Add CrowdSec database connection:
   - Click "Settings" (gear icon) → "Admin settings" → "Databases" → "Add database"
   - **Database type**: SQLite
   - **Display name**: CrowdSec
   - **Filename**: `/crowdsec-db/crowdsec.db`
   - Click "Save"


#### Applying CrowdSec Protection to Services

**For services with Authelia:**
```yaml
- traefik.http.routers.<service>.middlewares=crowdsec-bouncer@docker,authelia-forwardauth@docker
```

**For services without Authelia:**
```yaml
- traefik.http.routers.<service>.middlewares=crowdsec-bouncer@docker
```

To add CrowdSec to new services in the future, simply add the appropriate middleware label to the service's Traefik configuration.

### 5. JOAL Configuration

#### Initial Setup

1. Set the two required secrets in your `.env` file:
   - `JOAL_SECRET_TOKEN`: A random secret string for authentication (e.g., use `openssl rand -hex 32`)
   - `JOAL_SECRET_OBFUSCATION_PATH`: A random path to hide the UI URL (e.g., `my-secret-path-123`)

2. Access the web UI at: `http://${LOCAL_IP}:8584/${JOAL_SECRET_OBFUSCATION_PATH}/ui`

### 6. Restic Backup Configuration

Automated backup solution using Restic with Google Drive (via rclone) as the backend storage.

#### Features

- **Automated Backups**: Daily backups at 3:00 AM
- **Intelligent Storage**: Deduplication and compression to save space
- **Retention Policy**: Keeps 7 daily, 4 weekly, 4 monthly
- **Encryption**: All data encrypted with AES-256 before upload
- **Google Drive Backend**: Cloud storage via rclone

#### Initial Setup

1. Generate a strong password for encryption:
```bash
openssl rand -base64 32
```

Add this to your `.env` file as `RESTIC_PASSWORD`.

⚠️ **IMPORTANT**: Store this password safely! You cannot recover backups without it.

2. Configure Google Drive authentication with rclone (see `restic/README.md` for detailed instructions)

3. Configure which directories to backup in `restic/config/backup-paths.txt`

4. Configure backup path in gdrive in `RESTIC_REPOSITORY` environment variable.

5. Run initial backup:
```bash
docker exec restic /scripts/backup.sh
```

For detailed documentation, usage examples, and troubleshooting, see [restic/README.md](restic/README.md).

### 7. Unmanic Configuration

Unmanic re-encodes the media library from H.264 to HEVC to reclaim disk space. Reachable at
`https://unmanic.${DOMAIN_NAME}` (behind Authelia — Unmanic has no authentication of its own).

**Unmanic's configuration is not GitOps.** It lives in SQLite plus JSON under `/config`
(`${DATADIR}/unmanic/config`), and is edited through the web UI, not this repo. Two consequences:

- `${DATADIR}/unmanic/config` is in `restic/config/backup-paths.txt`. The cache directory is
  deliberately excluded — it holds multi-GB transcode scratch files.
- `unmanic/library-config.json` is a committed export of the whole setup: library config, enabled
  plugins, every plugin's settings, and flow order.

#### Restoring the configuration after a rebuild

```bash
# substitute the ${...} placeholders from .env, then import
python3 - <<'EOF'
import json, os, re, urllib.request
cfg = open('unmanic/library-config.json').read()
cfg = re.sub(r'\$\{(\w+)\}', lambda m: os.environ[m.group(1)], cfg)
body = json.dumps(json.loads(cfg)).encode()
req = urllib.request.Request('http://localhost:8888/unmanic/api/v2/settings/library/import',
                             data=body, headers={'Content-Type': 'application/json'})
print(urllib.request.urlopen(req).read())
EOF
```

Export it again after any UI change:

```bash
docker exec unmanic curl -s -X POST -H 'Content-Type: application/json' \
  -d '{"id":1}' http://localhost:8888/unmanic/api/v2/settings/library/export
```

Strip the API keys back to `${SONARR_API_KEY}` / `${RADARR_API_KEY}` /
`${UNMANIC_JELLYFIN_API_KEY}` before committing — the raw export embeds them verbatim.

#### Settings scope

Unmanic stores plugin settings twice: `userdata/<plugin>/settings.json` (global) and
`settings.<library_id>.json` (per-library, which wins when present). This deployment uses **globals
only** — the per-library files were removed, so `Settings → Plugins` in the UI is the single place to
configure everything. If you add a per-library override later, remember it silently takes precedence.

Which plugins are *enabled* and their *flow order* remain per-library (`enabledplugins` and
`librarypluginflow` tables) — Unmanic has no global equivalent.

#### Encoder settings

`video_transcoder` in `standard` mode: `libx265`, `preset medium`, **CRF 21**, 8-bit, container
preserved, audio and subtitles stream-copied.

`mode: standard` is load-bearing. In the default `basic` mode the preset and CRF fields are hidden and
the plugin hardcodes `-crf 28`, which is visibly worse.

8-bit rather than 10-bit is a deliberate client-compatibility choice: 10-bit would be slightly more
efficient but pushes older clients into live transcoding.

#### Sonarr custom-format caveat

TRaSH scores the `x265 (HD)` custom format at **-10000** to discourage third-party HD x265 re-encodes.
Left at that value, Sonarr re-evaluates Unmanic's own output as `x265 (HD)`, and because the Sonarr
profiles have `upgrade.allowed: true`, it searches for an x264 replacement — silently undoing every
transcode and re-downloading.

`recyclarr/recyclarr.yml` therefore assigns that custom format `score: 0` on the `WEB-1080p`,
`WEB-2160p`, and `1080p/4K` Sonarr profiles. The `Anime` profile never included it and
`reset_unmatched_scores` leaves it at 0 there. Radarr keeps the penalty — all its profiles have
`upgrade.allowed: false`, so nothing can be replaced.

**If you ever re-add that custom format to a Sonarr profile at its TRaSH default, transcoded episodes
will start being replaced.**

### 8. Maintainerr Configuration

Deletes **already-watched** movies and TV seasons once free space gets tight, at
`https://maintainerr.${DOMAIN_NAME}` (behind Authelia — it has no auth of its own).

Chosen over Janitorr and Jellysweep because both delete what nobody has *touched* recently, which
targets the unwatched backlog first. Maintainerr reads Jellyfin's watch state natively, so no
Jellystat/Tautulli is needed, and it gates on `diskspace_remaining_gb` from the *arr API.

Config is UI-managed in `${DATADIR}/maintainerr/data/maintainerr.sqlite` (in
`restic/config/backup-paths.txt`). Rule *conditions* can be exported as YAML from the rule editor, but
the endpoint reports a `skipped` count, so treat that as a restore aid rather than the source of truth.

`${DATADIR}/library` is mounted at `/data` to match **Sonarr and Radarr exactly** — leftover-folder
cleanup resolves paths as the *arrs report them, so a different mount point silently finds nothing.

#### Gotchas

- **The *arr action must stop the re-download.** `newtarr` and `prefetcharr` will re-grab anything
  merely deleted — the same fight documented in the Unmanic section above. Movies use `Delete`, which
  removes the film from disk *and* from Radarr, so there is nothing left to re-grab. Seasons use
  `Unmonitor and delete existing`, which unmonitors **only that season** and leaves the series
  monitored, so future seasons still download. Note `Unmonitor and delete all files` is **silently
  unsupported for season collections** — the Sonarr handler logs "not supported for type: season" and
  does nothing, so do not pick it here.
- **There is no dry-run; the collection is the preview.** Rules run every 8h, the handler every 12h.
  Build rules with the action on `Do nothing` first and inspect membership before arming them.
- **`/data/library` is not backed up** — only app config is, so the *arr recycle bin is the only undo.
  Radarr uses `/data/.recycle/movies`, Sonarr `/data/.recycle/tv` (host `${DATADIR}/library/.recycle/*`),
  both with a 7-day cleanup. Deliberately placed as a sibling of `media/` rather than inside it, so
  Jellyfin never indexes it, and on the same filesystem so deletes are instant renames not copies.
  **Note the trade-off:** a recycled file still occupies the disk, so space is not truly reclaimed until
  the 7-day cleanup runs. That is the reason the window is 7 days and not 30.
- **Wire up qBittorrent** (`Settings → Download Client`). Without it, a file still seeding won't free
  space when deleted. With it, Maintainerr honours the client's seeding goal, falls back to
  `download_client_fallback_ratio` (default 0.5) when no limit is set, and skips cross-seeded torrents.
- **Exclusions work via a rule condition, not the settings toggle.** Every rule group leads with
  `tags not contains dnd` (`Radarr.tags` for movies, `Sonarr.tags` for seasons), so tagging `dnd` in the
  *arr protects an item across **all** tiers at once. Tagging a *series* protects every one of its
  seasons.
  The `Radarr/Sonarr tag exclusions` setting is **write-only** and does not filter anything on its own —
  nothing in the rules engine reads it. It exists so that clicking `Excl` in the Maintainerr UI also
  stamps `dnd` into the *arr. That is worth leaving on, because it makes UI exclusions feed the rule
  condition above and become visible in Sonarr/Radarr.
- **Prefer tags over the UI `Excl` button.** An exclusion created from a collection can be scoped to
  that single rule group, which with six tiers would leave the other five still able to catch the item.
  A `dnd` tag has no such footgun.

Thresholds are tiered so cleanup stays dormant until space runs short. The **grace period shortens with
each tier too** — otherwise every tier reacts at the same speed and the emergency tier is no more urgent
than the relaxed one, just broader:

| Tier | Free space | Deletes watched older than | Grace before action |
| ---- | ---------- | -------------------------- | ------------------- |
| 1    | < 1000 GiB | 90 days                    | 30 days             |
| 2    | < 500 GiB  | 30 days                    | 14 days             |
| 3    | < 250 GiB  | 7 days                     | 3 days              |

Set `arrDiskPath` per rule (`/data/media/movies`, `/data/media/tv`) so it reads that root folder instead
of aggregating across every path the *arr reports.

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

## Restore backups

1. Install restic and rclone.

2. Authenticate rclone with `rclone.conf` file
```bash
docker run --rm -it -v $(pwd):/config/rclone rclone/rclone:latest config reconnect "gdrive:" --config /config/rclone/rclone.conf
```

Choose "No" and run the rclone command from output in other terminal window to get the token, then insert it.

3. Set those 3 environment variables
```bash
export RESTIC_REPOSITORY=rclone:gdrive:<RESTIC_REPO_PATH_INSIDE_GDRIVE>
export RCLONE_CONFIG=<PATH_TO_rclone.conf>
export RESTIC_PASSWORD=<RESTIC_PASSWORD>
```

4. List snapshots
`restic snapshots`

5. `restic restore <SNAPSHOT_ID> --target <TARGET_DIR>`