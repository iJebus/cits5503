#!/bin/bash -v
echo -e "\n127.0.0.1 $(hostname)" | sudo tee -a /etc/hosts  # Fix sudo issue

# Format the external data volume if it is new/unformatted, then mount it
if [[ "$(sudo file -s /dev/xvdh)" == "/dev/xvdh: data" ]]; then
    mkfs -t ext4 /dev/xvdh
fi
mkdir /data
mount /dev/xvdh /data
cp /etc/fstab /etc/fstab.orig
echo "/dev/xvdh /data ext4 defaults,nofail 0 2" >> /etc/fstab
mount -a
chown -R ubuntu:ubuntu /data

# Run basic updates
apt-get update
apt-get upgrade -y

# Generate AU lang
locale-gen en_AU.UTF-8

# Install useful things
apt-get install -y git silversearcher-ag curl jq mosh htop
