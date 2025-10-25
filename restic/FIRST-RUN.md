# First Run Guide - Step by Step

Follow these steps to run your first backup to Google Drive.

## 📋 Pre-checks

✅ RESTIC_PASSWORD is set in `.env`
✅ Google Drive Client ID and Secret ready
✅ Test directory configured: `/data/recyclarr/`
✅ Google Drive path: `backups/homeserver`

## 🚀 Step-by-Step Instructions

### Step 1: Configure rclone with Google Drive

```bash
cd /data/git/homeserver/restic
./setup-rclone.sh
```

**During setup, you'll be prompted for:**
1. **New remote**: Type `n`
2. **Name**: Type `gdrive`
3. **Storage type**: Type the number for `drive` (Google Drive)
4. **Client ID**: Paste your Google Drive Client ID
5. **Client Secret**: Paste your Google Drive Client Secret
6. **Scope**: Type `1` (Full access to all files)
7. **Root folder ID**: Press Enter (leave empty)
8. **Service Account**: Press Enter (leave empty)
9. **Advanced config**: Type `n`
10. **Auto config**: Type `n` (for remote server)
    - You'll get a URL like: `https://accounts.google.com/o/oauth2/auth?...`
    - Copy and open it in your browser
    - Authorize the application
    - Copy the verification code
    - Paste it back in the terminal
11. **Team Drive**: Type `n`
12. **Confirm**: Type `y`
13. **Quit**: Type `q`

The script will automatically test the connection!

---

### Step 2: Deploy the Restic Service

```bash
cd /data/git/homeserver

# Load environment variables
export $(cat .env | xargs)

# Start the services
docker compose -f restic/docker-compose.yml up -d
```

**Expected output:**
```
✔ Network restic      Created
✔ Volume restic-cache Created
✔ Container restic         Started
✔ Container ofelia-restic  Started
```

---

### Step 3: Run Your First Backup

```bash
docker exec restic /scripts/backup.sh
```

**What will happen:**
1. Restic will initialize the repository in `gdrive:backups/homeserver`
2. It will scan `/data/recyclarr/` directory
3. Upload and encrypt all files
4. Show progress and statistics

**Expected output:**
```
===================================
Starting Restic Backup
Date: Sat Oct 25 23:45:00 UTC 2025
===================================
Repository not found. Initializing...
created restic repository 1234567890 at rclone:gdrive:backups/homeserver
...
Backing up paths:
/data/recyclarr
...
Files:         123 new,     0 changed,     0 unmodified
Dirs:           12 new,     0 changed,     0 unmodified
Added to the repo: 45.2 MiB (compressed)
...
===================================
Backup completed successfully!
===================================

Latest snapshots:
ID        Time                 Host              Tags        Paths
----------------------------------------------------------------------
abc12345  2025-10-25 23:45:30  homeserver-restic automated  /data/recyclarr
                                                  daily
```

---

### Step 4: Verify the Backup

```bash
# View all snapshots
docker exec restic restic snapshots

# View repository statistics
docker exec restic restic stats

# Check what's in the snapshot
docker exec restic restic ls latest

# Verify files in Google Drive
docker exec restic rclone --config /config/rclone.conf ls gdrive:backups/homeserver
```

---

## ✅ Success Checklist

After running the first backup:

- [ ] No errors in backup output
- [ ] Snapshot created (check with `docker exec restic restic snapshots`)
- [ ] Files visible in Google Drive under `backups/homeserver/`
- [ ] Container logs look good (`docker logs restic`)
- [ ] Scheduler is running (`docker logs ofelia-restic`)

---

## 📁 Adding More Directories Later

To add more directories to backup:

1. **Edit the backup paths file:**
   ```bash
   nano /data/git/homeserver/restic/config/backup-paths.txt
   ```

2. **Add your paths (one per line):**
   ```
   /data/recyclarr
   /data/another-directory
   /data/photos
   /data/documents
   ```

3. **Run manual backup to test:**
   ```bash
   docker exec restic /scripts/backup.sh
   ```

**Note:** The paths must be accessible inside the container:
- `/data` maps to `${DATADIR}` from your environment
- If you need other paths, add them to `docker-compose.yml` volumes section first

**Example - Add a new mount:**

Edit `restic/docker-compose.yml`:
```yaml
volumes:
  - ${DATADIR}:/data:ro
  - /mnt/external-drive:/backup/external:ro  # Add this
```

Then in `backup-paths.txt`:
```
/data/recyclarr
/backup/external
```

---

## 🔧 Change Google Drive Location

To change where backups are stored in Google Drive:

Edit `restic/docker-compose.yml`:
```yaml
environment:
  - RESTIC_REPOSITORY=rclone:gdrive:YOUR-CUSTOM-PATH
```

Examples:
- `rclone:gdrive:backups/homeserver` (current)
- `rclone:gdrive:restic-backups`
- `rclone:gdrive:my-server/backups`

Then restart:
```bash
docker compose -f restic/docker-compose.yml restart
```

**Note:** This creates a NEW repository. Old backups remain in the old location.

---

## 🐛 Troubleshooting

### "Repository not found" after setup
This is normal on first run! Restic will automatically initialize it.

### "Authentication failed"
```bash
# Reconfigure rclone
cd /data/git/homeserver/restic
./setup-rclone.sh
```

### "No such file or directory: /data/recyclarr"
Check that the path exists and is mounted:
```bash
# Check if directory exists on host
ls -la ${DATADIR}/recyclarr

# Check if it's visible in container
docker exec restic ls -la /data/recyclarr
```

### View detailed logs
```bash
# Container logs
docker logs restic

# Follow logs in real-time
docker logs -f restic

# Scheduler logs
docker logs ofelia-restic
```

---

## 📅 What Happens Automatically

Once deployed, backups run automatically:

| Task | Schedule | Command |
|------|----------|---------|
| Daily Backup | 3:00 AM | `/scripts/backup.sh` |
| Weekly Cleanup | Sunday 4:00 AM | `/scripts/prune.sh` |
| Monthly Check | 1st of month 5:00 AM | `/scripts/check.sh` |

Monitor with:
```bash
docker logs --since 24h restic | grep "Backup completed"
```

---

## 🎉 Next Steps

After successful first backup:

1. ✅ Test a restore (see below)
2. ✅ Add more directories to backup
3. ✅ Set up monitoring/notifications (optional)
4. ✅ Document your RESTIC_PASSWORD in a safe place

### Quick Restore Test

```bash
# Restore to temporary location
docker exec -it restic restic restore latest --target /tmp/restore-test

# Check restored files
docker exec restic ls -la /tmp/restore-test

# Copy out of container if needed
docker cp restic:/tmp/restore-test /tmp/restored-files
```

---

**Need help?** Check the main README.md for detailed documentation!

