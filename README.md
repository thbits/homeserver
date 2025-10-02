## Docker installation
https://docs.docker.com/engine/install/ubuntu/#install-using-the-repository

## Github runner configuration
Repo -> Settings -> Actions -> Runners -> New self-hosted runner
Then follow the simple instructions
Install the runner service
```bash
sudo ./svc.sh install
```

Enable and start the service
```bash
systemctl enable actions.runner.<TAB><TAB>
systemctl start actions.runner.<TAB><TAB>
```

## Global Variables
Set this laso as github action variables secrets
```
DATADIR=<PATH_TO_DATA_DIR>
DOMAIN_NAME=<DOMAIN> # GA Variable
SSL_EMAIL=<EMAIL_FOR_LETSENCRYPT> # GA Secret
TIMEZONE=Asia/Jerusalem # GA Variable
```

## Authelia Config
Set environment variables for the following variables
```
JWT_SECRET=
SESSION_SECRET=
STORAGE_ENCRYPTION_KEY=
```

Note: set the above also as Github Actions secrets

Populate it with the following command
```bash
docker run --rm authelia/authelia:latest authelia crypto rand --length 64
```
