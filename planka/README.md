# Planka

Planka is a real-time kanban board for workgroups built with React and Redux.

## First-Time Setup

1. **Generate and add secret key to `.env` file:**
   ```bash
   openssl rand -hex 64
   ```
   
   Add the generated secret to your `.env` file:
   ```bash
   PLANKA_SECRET_KEY=<your-generated-secret>
   ```

2. **Start the services:**
   ```bash
   cd planka
   docker compose up -d
   ```

3. **Create an admin user:**
   ```bash
   docker compose run --rm planka npm run db:create-admin-user
   ```
   
   You'll be prompted for:
   - Email
   - Password
   - Name
   - Username (optional)

4. **Access Planka:**
   - URL: `https://planka.${DOMAIN_NAME}`
   - Login with the admin credentials you created

## Authentication

Planka is currently configured with Authelia forward authentication. Users need to authenticate through Authelia before accessing Planka.

In the future, this can be configured to use OIDC for better integration.

## Configuration

- **Port:** 1337 (internal, proxied through Traefik)
- **Database:** PostgreSQL 16 Alpine
- **Reverse Proxy:** Traefik with SSL via Cloudflare DNS
- **Security:** Geoblock, CrowdSec bouncer, Authelia forward auth

## Data Storage

All data is stored in `${DATADIR}/planka/`:
- `db/` - PostgreSQL database
- `favicons/` - Board favicons
- `user-avatars/` - User avatar images
- `background-images/` - Board background images
- `attachments/` - Card attachments

## Useful Commands

- **View logs:** `docker compose logs -f planka`
- **Restart:** `docker compose restart planka`
- **Stop:** `docker compose down`
- **Update:** Pull new image and restart (see main README for update procedures)

## Links

- [Official Documentation](https://docs.planka.cloud/)
- [GitHub Repository](https://github.com/plankanban/planka)
