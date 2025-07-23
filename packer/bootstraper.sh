#!/bin/bash

set -euox pipefail

echo "Setting swapfile"
sudo install -o root -g root -m 0600 /dev/null /swapfile
sudo dd if=/dev/zero of=/swapfile bs=1k count=2048k
sudo mkswap /swapfile
sudo swapon /swapfile
echo "/swapfile       swap    swap    auto      0       0" | sudo tee -a /etc/fstab
sudo sysctl -w vm.swappiness=10
echo vm.swappiness = 10 | sudo tee -a /etc/sysctl.conf

echo "Bootstrapping"
sudo git clone https://github.com/discourse/discourse_docker.git /var/discourse
sudo mv /tmp/web_only.yml /var/discourse/containers
sudo mv /tmp/env.yml /var/discourse

cd /var/discourse
sudo chmod 700 containers
sudo ./launcher bootstrap web_only
