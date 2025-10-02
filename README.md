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
