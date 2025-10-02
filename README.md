# Prerequisites
## Docker installation
https://docs.docker.com/engine/install/ubuntu/#install-using-the-repository

## Github runner configuration
Repo -> Settings -> Actions -> Runners -> New self-hosted runner
Then follow the simple instructions
Install the runner service
`sudo ./svc.sh install`
Start the service
`systemctl start actions.runner.<TAB><TAB>`

## Authelia config
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
