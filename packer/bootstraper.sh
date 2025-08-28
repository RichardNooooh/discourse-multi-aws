#!/bin/bash

set -euo pipefail

echo "Setting swapfile..."
sudo install -o root -g root -m 0600 /dev/null /swapfile
sudo dd if=/dev/zero of=/swapfile bs=1k count=2048k
sudo mkswap /swapfile
sudo swapon /swapfile
echo "/swapfile       swap    swap    auto      0       0" | sudo tee -a /etc/fstab
sudo sysctl -w vm.swappiness=10
echo vm.swappiness = 10 | sudo tee -a /etc/sysctl.conf

echo "Bootstrapping image..."
sudo git clone https://github.com/discourse/discourse_docker.git /var/discourse
sudo mv /tmp/web_only.yml /var/discourse/containers
sudo mv /tmp/env.yml /var/discourse

cd /var/discourse
sudo chmod 700 containers
sudo chmod 700 containers/web_only.yml
sudo chmod 700 env.yml
sudo ./launcher bootstrap web_only

# TODO check time synching

echo "Creating systemd file..."
# 1. removes first two lines (arch and warning) if they are there
# 2. removes the `+ ` and `true` parts of the start-cmd
# 3. removes `-restart=always` flag so we can let systemd handle restarts
# 4. removes `-d` flag for systemd since we're starting this as a simple service (not sure if this is needed)
# 5. replaces `%` with `%%` so that any percent signs in passwords are correctly processed
START_CMD=$(sudo ./launcher start-cmd web_only |& 
                    sed -e '/arch detected/d' \
                        -e '/^WARNING:/d' \
                        -e 's/^+ //' \
                        -e 's/^true //' \
                        -e 's/--restart=always //' \
                        -e 's/-d //' \
                        -e 's/%/%%/g')

DOCKER_CMD=`which docker.io 2> /dev/null || which docker`
SERVICE_FILE=/etc/systemd/system/discourse-web_only.service
sudo tee "$SERVICE_FILE" > /dev/null <<EOF
[Unit]
Description=Discourse Web Docker Container
Requires=docker.service
After=docker.service

[Service]
Type=simple
ExecStart=/usr/bin/env bash -c "$DOCKER_CMD $START_CMD"
ExecStop=$DOCKER_CMD stop -t 600 web_only
ExecStopPost=$DOCKER_CMD rm -f web_only
Restart=always
RestartSec=10s
StartLimitIntervalSec=60
StartLimitBurst=5

[Install]
WantedBy=multi-user.target
EOF
sudo chmod 600 "$SERVICE_FILE"
sudo systemctl daemon-reload
sudo systemctl enable discourse-web_only.service
