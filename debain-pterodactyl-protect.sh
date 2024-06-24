#!/bin/bash

# Update system packages
echo "Updating system packages..."
sudo apt-get update -y
sudo apt-get upgrade -y

# Install fail2ban
echo "Installing fail2ban..."
sudo apt-get install -y fail2ban

# Create fail2ban filter for Pterodactyl
echo "Creating fail2ban filter for Pterodactyl..."
sudo bash -c 'cat <<EOF > /etc/fail2ban/filter.d/pterodactyl.conf
[Definition]
failregex = ^<HOST> -.*"(GET|POST).*/api.*
ignoreregex =
EOF'

# Create fail2ban jail for Pterodactyl
echo "Creating fail2ban jail for Pterodactyl..."
sudo bash -c 'cat <<EOF > /etc/fail2ban/jail.d/pterodactyl.conf
[pterodactyl]
enabled = true
filter = pterodactyl
port = 80,443
logpath = /var/log/nginx/access.log
maxretry = 10
findtime = 600
bantime = 3600
EOF'

# Restart fail2ban to apply changes
echo "Restarting fail2ban..."
sudo systemctl restart fail2ban

# Check fail2ban status
echo "Checking fail2ban status..."
sudo fail2ban-client status

echo "Fail2ban setup for Pterodactyl is complete."
