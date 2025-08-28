#!/bin/bash

set -euxo pipefail

echo "Checking SSM"
sudo systemctl status snap.amazon-ssm-agent.amazon-ssm-agent.service

echo "Starting package update..."
sudo apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get -y upgrade
sudo DEBIAN_FRONTEND=noninteractive apt-get -y install ca-certificates curl htop vim

# official Docker installation instructions
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# official postgresql installation
echo "Adding database extensions to db.discourse.internal if needed"
sudo install -d /usr/share/postgresql-common/pgdg
sudo curl -o /usr/share/postgresql-common/pgdg/apt.postgresql.org.asc --fail https://www.postgresql.org/media/keys/ACCC4CF8.asc
. /etc/os-release
sudo sh -c "echo 'deb [signed-by=/usr/share/postgresql-common/pgdg/apt.postgresql.org.asc] https://apt.postgresql.org/pub/repos/apt $VERSION_CODENAME-pgdg main' > /etc/apt/sources.list.d/pgdg.list"

sudo apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get -y install postgresql-client-15 # might want to make this a variable for future upgrades...
sudo PGPASSWORD=${DB_PASSWORD} psql --file="/tmp/db_init.sql" --host=db.discourse.internal --port=5432 --username=postgres --dbname=discourse

sudo reboot
