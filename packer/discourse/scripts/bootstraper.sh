#!/bin/bash

set -euo pipefail
# https://meta.discourse.org/t/create-a-swapfile-for-your-linux-server/13880
echo "Setting swapfile..."
sudo install -o root -g root -m 0600 /dev/null /swapfile
sudo dd if=/dev/zero of=/swapfile bs=1k count=2048k
sudo mkswap /swapfile
sudo swapon /swapfile
echo "/swapfile       swap    swap    auto      0       0" | sudo tee -a /etc/fstab
sudo sysctl -w vm.swappiness=10
echo vm.swappiness = 10 | sudo tee -a /etc/sysctl.conf

echo "Bootstrapping image..."
sudo mv /tmp/web_only.yml /var/discourse/containers

cd /var/discourse
sudo chmod 700 containers
sudo chmod 700 containers/web_only.yml
sudo ./launcher bootstrap web_only

# TODO check time synching
# TODO configure linux user stuff

echo "Creating systemd file for Discourse..."
# We let systemd to handle this because we want this container to spin up as soon as possible on system start, without relying on CloudInit's `user-data`
# 1. removes first two lines (arch and warning) if they are there
# 2. removes the `+ ` and `true` parts of the start-cmd
# 3. removes `-d` flag for systemd since we're starting this as a simple service (not sure if this is needed)
# 4. replaces `%` with `%%` so that any percent signs in passwords are correctly processed
START_CMD=$(sudo ./launcher start-cmd web_only |& 
                    sed -e '/arch detected/d' \
                        -e '/^WARNING:/d' \
                        -e 's/^+ //' \
                        -e 's/^true //' \
                        -e 's/-d //' \
                        -e 's/%/%%/g')

DOCKER_CMD=`which docker.io 2> /dev/null || which docker`
DISCOURSE_SERVICE_FILE=discourse-web_only.service
sudo tee "/etc/systemd/system/$DISCOURSE_SERVICE_FILE" > /dev/null <<EOF
[Unit]
Description=Discourse Web Docker Container
Requires=docker.service
After=docker.service

[Service]
Type=simple
ExecStart=/usr/bin/env bash -c "$DOCKER_CMD $START_CMD"
ExecStop=$DOCKER_CMD stop -t 600 web_only
ExecStopPost=$DOCKER_CMD rm -f web_only

[Install]
WantedBy=multi-user.target
EOF
sudo chmod 600 "/etc/systemd/system/$DISCOURSE_SERVICE_FILE"

# from https://jaanhio.me/blog/linux-node-exporter-setup
echo "Creating systemd file for node_exporter..."
NODE_EXPORTER_SERVICE_FILE=node_exporter.service
sudo tee "/etc/systemd/system/$NODE_EXPORTER_SERVICE_FILE" > /dev/null <<EOF
[Unit]
Description=Prometheus Node Exporter
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/node_exporter
Restart=always
RestartSec=10s
StartLimitIntervalSec=60
StartLimitBurst=5

[Install]
WantedBy=multi-user.target
EOF
sudo chmod 600 "/etc/systemd/system/$NODE_EXPORTER_SERVICE_FILE"

sudo systemctl daemon-reload
sudo systemctl enable discourse-web_only.service
sudo systemctl enable node_exporter.service
