# Migration Guide: Monolithic to Modular Docker Compose

This guide will help you migrate from the old single `docker-compose.yml` to the new modular structure.

## What Changed

### Structure
- **Before:** Single `docker-compose.yml` in root with all services
- **After:** Separate directories for each service with their own `docker-compose.yml`

### Environment Variables
- **Before:** Single `.env` file or environment variables
- **After:** 
  - Root `.env` for common variables (DATADIR, DOMAIN_NAME, SSL_EMAIL, TIMEZONE)
  - Service-specific `.env` files in each service directory

### Dependency Updates
- **Before:** Dependabot
- **After:** Renovate (auto-discovers all docker-compose files)

## Migration Steps

### 1. Stop All Running Services

```bash
# Using the old docker-compose.yml (if you still have it)
docker compose down
```

### 2. Set Up Environment Files

#### Root environment file
```bash
cp .env.example .env
# Edit .env with your values:
# - DATADIR
# - DOMAIN_NAME
# - SSL_EMAIL
# - TIMEZONE
```

#### Traefik
```bash
cp traefik/.env.example traefik/.env
# Currently empty, but ready for future traefik-specific variables
```

#### Authelia
```bash
cp authelia/.env.example authelia/.env
# Add your Authelia secrets:
# - JWT_SECRET
# - SESSION_SECRET
# - STORAGE_ENCRYPTION_KEY
```

#### n8n
```bash
cp n8n/.env.example n8n/.env
# Currently empty, but ready for future n8n-specific variables
```

### 3. Deploy Services in Order

The deployment order is important because services depend on each other:

1. **Traefik** (must be first - creates the network and provides routing)
   ```bash
   cd traefik
   docker compose --env-file ../.env up -d
   cd ..
   ```

2. **Authelia** (provides authentication middleware)
   ```bash
   cd authelia
   docker compose --env-file ../.env up -d
   cd ..
   ```

3. **n8n** (depends on Traefik being healthy)
   ```bash
   cd n8n
   docker compose --env-file ../.env up -d
   cd ..
   ```

### 4. Verify Services

Check that all services are running:
```bash
docker ps
```

You should see:
- `traefik` - healthy
- `authelia` - running
- `n8n` - running

Check the Traefik network:
```bash
docker network inspect traefik_network
```

All three containers should be connected to this network.

### 5. Test Your Services

- Traefik dashboard (if enabled): `http://your-server:8080`
- Authelia: `https://auth.your-domain.com`
- n8n: `https://n8n.your-domain.com`

## Important Notes

### Docker Networks

The new setup uses a shared Docker network called `traefik_network`:
- Traefik creates and manages this network
- Authelia and n8n connect to it as external
- This allows services to communicate across compose files

### Service Dependencies

n8n has a `depends_on` with health check condition:
```yaml
depends_on:
  traefik:
    condition: service_healthy
```

This ensures n8n waits for Traefik to be healthy before starting. However, since they're in separate compose files, the services must be started in order (traefik first, then n8n).

### Environment Variable Inheritance

Each service docker-compose.yml references both:
```yaml
env_file:
  - ../.env      # Common variables
  - .env         # Service-specific variables
```

This allows you to:
- Keep common config in one place (root `.env`)
- Override or add service-specific variables in each service's `.env`

## GitHub Actions Updates

### Environment Variables/Secrets

Make sure these are set in your GitHub repository:

**Variables:**
- `DATADIR`
- `DOMAIN_NAME`
- `TIMEZONE`

**Secrets:**
- `SSL_EMAIL`
- `JWT_SECRET`
- `SESSION_SECRET`
- `STORAGE_ENCRYPTION_KEY`

### Renovate Configuration

Renovate is now configured in `.github/renovate.json`:
- Runs every Sunday at 6:00 AM (Asia/Jerusalem)
- Auto-merges minor and patch updates
- Creates PRs (without auto-merge) for major updates
- Automatically discovers all `docker-compose.yml` files

### Workflows

Two workflows have been updated:

1. **renovate-auto-merge.yml** - Handles auto-merging Renovate PRs
2. **deploy-on-merge.yml** - Dynamically finds and deploys all docker-compose files

## Troubleshooting

### n8n won't start
- Make sure Traefik is healthy: `docker ps | grep traefik`
- Check Traefik logs: `docker logs traefik`
- Ensure traefik_network exists: `docker network ls | grep traefik`

### "network not found" error
- Deploy Traefik first: `cd traefik && docker compose up -d`
- The network is created by Traefik's compose file

### Environment variables not loading
- Check that both `.env` files exist (root and service-specific)
- Verify the `.env` files are not in `.gitignore` (only `.env.example` should be tracked)
- **Always use `--env-file ../.env`** when running docker compose commands from service directories
- Run `docker compose --env-file ../.env config` in each service directory to verify variable substitution
- If variables like `${DATADIR}` show as blank, the `--env-file` flag is missing

### Renovate not creating PRs
- Ensure `.github/renovate.json` is valid JSON
- Check GitHub Actions for Renovate execution logs
- Verify your repository has Renovate installed (GitHub App)

## Rollback

If you need to rollback to the old structure:

1. Stop all services:
   ```bash
   cd traefik && docker compose down && cd ..
   cd authelia && docker compose down && cd ..
   cd n8n && docker compose down && cd ..
   ```

2. Restore the old `docker-compose.yml` from git history
3. Deploy with the old method

## Benefits of New Structure

✅ **Modularity** - Each service is independent and can be managed separately
✅ **Scalability** - Easy to add new services by creating a new directory
✅ **Flexibility** - Service-specific configurations without cluttering common config
✅ **Better CI/CD** - Dynamic discovery of services for automated deployments
✅ **Improved Dependency Management** - Renovate auto-discovers all compose files
✅ **Cleaner Repository** - Organized structure, easier to navigate

