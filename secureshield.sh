#!/bin/bash

# secureshield.sh - Advanced security script for Pterodactyl panel and nodes

# Function to display the banner with gradient effect
display_banner() {
    echo -e "\033[38;5;82m    _____        _         ____ _                 _       "
    echo -e "\033[38;5;118m   / ____|      (_)      / ____| |               | |      "
    echo -e "\033[38;5;154m  | (___  _ __  _ _ __  | |    | | ___  _   _  __| |      "
    echo -e "\033[38;5;190m   \___ \|  _ \| |  _ \ | |    | |/ _ \| | | |/ _  |      "
    echo -e "\033[38;5;226m   ____) | |_) | | | | |  |____| | (_) | |_| | (_| |      "
    echo -e "\033[38;5;220m  |_____/| .__/|_|_| |_| \_____|_|\___/ \____|\___ |      "
    echo -e "\033[38;5;214m         | |                                              "
    echo -e "\033[38;5;208m         |_|                                              "
    echo -e "\033[38;5;202m                                                          "
    echo -e "\033[38;5;196m              S E C U R E S H I E L D                     "
    echo -e "\033[0m"  # Reset text color
}

# Function to display the menu
display_menu() {
    echo -e "\n\033[1;36m========================================"
    echo -e "           SecureShield Menu             "
    echo -e "========================================\033[0m"

    echo -e " \033[1;33m1\033[0m - Install necessary packages"
    echo -e " \033[1;33m2\033[0m - Block an IP address"
    echo -e " \033[1;33m3\033[0m - Unblock an IP address"
    echo -e " \033[1;33m4\033[0m - Set up advanced firewall rules"
    echo -e " \033[1;33m5\033[0m - Enable DDoS protection For Ports"
    echo -e " \033[1;33m6\033[0m - Set up Cloudflare proxy for panel and node ports"
    echo -e " \033[1;33m7\033[0m - Enforce HTTPS and security headers"
    echo -e " \033[1;33m8\033[0m - Install and configure Fail2Ban"
    echo -e " \033[1;33m9\033[0m - Add advanced DDoS protection For VPS + Panel"
    echo -e " \033[1;33m10\033[0m - Optimize network and increase VPS speed"
    echo -e " \033[1;33m11\033[0m - Add Premium DDoS protection (Level 1)"
    echo -e " \033[1;33m12\033[0m - Add Premium DDoS protection With Kill Switch (Level 2)"
    echo -e " \033[1;33m13\033[0m - Add Premium DDoS protection With Kill Switch (Level 3)"
    echo -e " \033[1;33m0\033[0m - Exit\n"
    echo -e "\033[1;33mPlease enter your choice: \033[0m"
}

# Function to confirm execution of actions
confirm_execution() {
    local PROMPT="$1"
    read -p "$PROMPT [y/N]: " CONFIRM
    case "$CONFIRM" in
        [yY][eE][sS]|[yY]) return 0 ;;
        *) return 1 ;;
    esac
}

# Function to install necessary packages
install_packages() {
    if confirm_execution "Are you sure you want to install the necessary packages?"; then
        echo -e "\n\e[1;34mInstalling necessary packages...\e[0m"
        apt-get update
        apt-get install -y iptables ipset fail2ban ufw nginx certbot python3-certbot-nginx snort suricata logwatch
        echo -e "\e[1;32mPackages installed successfully.\e[0m\n"
    else
        echo -e "\e[1;33mInstallation aborted.\e[0m\n"
    fi
}

# Function to block an IP address
block_ip() {
    read -p "Enter IP address to block: " IP
    if [ -n "$IP" ]; then
        iptables -A INPUT -s "$IP" -j DROP
        echo -e "\e[1;31mBlocked IP: $IP\e[0m"
    else
        echo -e "\e[1;33mNo IP address entered.\e[0m"
    fi
}

# Function to unblock an IP address
unblock_ip() {
    read -p "Enter IP address to unblock: " IP
    if [ -n "$IP" ]; then
        iptables -D INPUT -s "$IP" -j DROP
        echo -e "\e[1;32mUnblocked IP: $IP\e[0m"
    else
        echo -e "\e[1;33mNo IP address entered.\e[0m"
    fi
}

# Function to set up advanced firewall rules
setup_firewall() {
    if confirm_execution "This will apply advanced firewall rules. Do you want to continue?"; then
        echo -e "\n\e[1;34mSetting up advanced firewall rules...\e[0m"

        # Default policies
        iptables -P INPUT DROP
        iptables -P FORWARD DROP
        iptables -P OUTPUT ACCEPT

        # Allow established connections
        iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

        # Allow loopback interface
        iptables -A INPUT -i lo -j ACCEPT

        # Allow SSH, panel, and daemon ports
        read -p "Enter SSH port (default 22): " SSH_PORT
        SSH_PORT=${SSH_PORT:-22}
        iptables -A INPUT -p tcp --dport "$SSH_PORT" -j ACCEPT

        read -p "Enter Pterodactyl panel port (default 80): " PANEL_PORT
        PANEL_PORT=${PANEL_PORT:-80}
        iptables -A INPUT -p tcp --dport "$PANEL_PORT" -j ACCEPT

        read -p "Enter Pterodactyl daemon port (default 8080): " DAEMON_PORT
        DAEMON_PORT=${DAEMON_PORT:-8080}
        iptables -A INPUT -p tcp --dport "$DAEMON_PORT" -j ACCEPT

        # Drop ports 80, 443, and 8080 for DDoS protection
        iptables -A INPUT -p tcp --dport 80 -j DROP
        iptables -A INPUT -p tcp --dport 443 -j DROP
        iptables -A INPUT -p tcp --dport 8080 -j DROP

        echo -e "\e[1;32mAdvanced firewall rules set up.\e[0m\n"
    else
        echo -e "\e[1;33mFirewall setup aborted.\e[0m\n"
    fi
}

# Function to enable advanced DDoS protection
ddos_protection() {
    if confirm_execution "This will enable advanced DDoS protection. Do you want to continue?"; then
        echo -e "\n\e[1;34mEnabling advanced DDoS protection...\e[0m"

        # Create an IP blacklist with ipset
        ipset create blacklist hash:ip hashsize 4096
        iptables -I INPUT -m set --match-set blacklist src -j DROP

        # Add IPs to blacklist if they exceed certain limits
        iptables -I INPUT -p tcp --syn -m limit --limit 1/s --limit-burst 4 -j RETURN
        iptables -A INPUT -p tcp --syn -j SET --add-set blacklist src

        # Rate limiting for HTTP(S) requests
        iptables -I INPUT -p tcp -m multiport --dports 80,443 -m connlimit --connlimit-above 20 -j DROP

        # SYN-Flood Protection
        iptables -A INPUT -p tcp --syn -m limit --limit 1/s -j ACCEPT
        iptables -A INPUT -p tcp --syn -j DROP

        # Ping of death protection
        iptables -A INPUT -p icmp -m icmp --icmp-type echo-request -m limit --limit 1/s -j ACCEPT
        iptables -A INPUT -p icmp -m icmp --icmp-type echo-request -j DROP

        echo -e "\e[1;32mAdvanced DDoS protection enabled.\e[0m\n"
    else
        echo -e "\e[1;33mDDoS protection setup aborted.\e[0m\n"
    fi
}

# Function to set up Cloudflare proxy for panel and node ports
setup_cloudflare_proxy() {
    if confirm_execution "This will set up Cloudflare proxy for panel and node ports (80, 443, 8080). Do you want to continue?"; then
        echo -e "\n\e[1;34mSetting up Cloudflare proxy for panel and node ports (80, 443, 8080)...\e[0m"

        # Cloudflare IPs from https://www.cloudflare.com/ips/
        CF_IPS=("173.245.48.0/20" "103.21.244.0/22" "103.22.200.0/22" "103.31.4.0/22")

        for ip in "${CF_IPS[@]}"; do
            iptables -A INPUT -p tcp -m multiport --dports 80,443,8080 -s "$ip" -j ACCEPT
        done

        iptables -A INPUT -p tcp -m multiport --dports 80,443,8080 -j DROP

        echo -e "\e[1;32mCloudflare proxy setup completed.\e[0m\n"
    else
        echo -e "\e[1;33mCloudflare proxy setup aborted.\e[0m\n"
    fi
}

# Function to enforce HTTPS and security headers
enforce_https() {
    if confirm_execution "This will enforce HTTPS and add security headers. Do you want to continue?"; then
        echo -e "\n\e[1;34mEnforcing HTTPS and adding security headers...\e[0m"

        # Install Certbot for HTTPS
        apt-get install -y certbot python3-certbot-nginx

        # Obtain SSL certificate
        read -p "Enter your domain name (e.g., example.com): " DOMAIN
        certbot --nginx -d "$DOMAIN"

        # Modify Nginx config to enforce HTTPS and add security headers
        cat <<EOF >/etc/nginx/conf.d/secure.conf
server {
    listen 80;
    server_name $DOMAIN;
    return 301 https://\$server_name\$request_uri;
}

server {
    listen 443 ssl;
    server_name $DOMAIN;

    ssl_certificate /etc/letsencrypt/live/$DOMAIN/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$DOMAIN/privkey.pem;

    add_header X-Content-Type-Options nosniff;
    add_header X-Frame-Options DENY;
    add_header X-XSS-Protection "1; mode=block";

    # ... (other Nginx config settings)
}
EOF
        systemctl restart nginx

        echo -e "\e[1;32mHTTPS and security headers enforced.\e[0m\n"
    else
        echo -e "\e[1;33mHTTPS enforcement and security header setup aborted.\e[0m\n"
    fi
}

# Function to install and configure Fail2Ban
install_fail2ban() {
    if confirm_execution "This will install and configure Fail2Ban. Do you want to continue?"; then
        echo -e "\n\e[1;34mInstalling and configuring Fail2Ban...\e[0m"

        # Install Fail2Ban
        apt-get install -y fail2ban

        # Create basic jail.local file
        cat <<EOF >/etc/fail2ban/jail.local
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 5

[sshd]
enabled = true

[nginx-http-auth]
enabled = true
EOF
        systemctl restart fail2ban

        echo -e "\e[1;32mFail2Ban installed and configured.\e[0m\n"
    else
        echo -e "\e[1;33mFail2Ban setup aborted.\e[0m\n"
    fi
}

# Function to add advanced DDoS protection
advanced_ddos_protection() {
    if confirm_execution "This will add advanced DDoS protection (Level 2). Do you want to continue?"; then
        echo -e "\n\e[1;34mAdding advanced DDoS protection (Level 2)...\e[0m"

        # Create a more advanced blacklist
        ipset create ddos_blacklist hash:ip hashsize 4096
        iptables -I INPUT -m set --match-set ddos_blacklist src -j DROP

        # Implement a more aggressive rate limiting and filtering strategy
        iptables -A INPUT -p tcp --syn -m limit --limit 10/s --limit-burst 20 -j ACCEPT
        iptables -A INPUT -p tcp --syn -j DROP

        # Implement more aggressive SYN flood protection
        iptables -A INPUT -p tcp --syn -m limit --limit 5/s -j ACCEPT
        iptables -A INPUT -p tcp --syn -j DROP

        # More advanced rate limiting for HTTP requests
        iptables -A INPUT -p tcp -m multiport --dports 80,443 -m connlimit --connlimit-above 50 -j DROP
        iptables -A INPUT -p tcp -m multiport --dports 80,443 -m recent --name http --set
        iptables -A INPUT -p tcp -m multiport --dports 80,443 -m recent --name http --update --seconds 60 --hitcount 100 -j DROP

        # Protect against ping flood
        iptables -A INPUT -p icmp -m icmp --icmp-type echo-request -m limit --limit 1/s -j ACCEPT
        iptables -A INPUT -p icmp -m icmp --icmp-type echo-request -j DROP

        # UDP flood protection
        iptables -A INPUT -p udp -m limit --limit 10/s --limit-burst 20 -j ACCEPT
        iptables -A INPUT -p udp -j DROP

        # TCP flood protection
        iptables -A INPUT -p tcp -m limit --limit 10/s --limit-burst 20 -j ACCEPT
        iptables -A INPUT -p tcp -j DROP

        # Botnet protection
        iptables -A INPUT -p tcp --dport 80 -m recent --name botnet --set
        iptables -A INPUT -p tcp --dport 80 -m recent --name botnet --update --seconds 60 --hitcount 100 -j DROP

        echo -e "\e[1;32mAdvanced DDoS protection (Level 2) applied.\e[0m\n"
    else
        echo -e "\e[1;33mAdvanced DDoS protection setup aborted.\e[0m\n"
    fi
}

# Function to optimize network and increase VPS speed
optimize_network() {
    if confirm_execution "This will optimize network settings and increase VPS speed. Do you want to continue?"; then
        echo -e "\n\e[1;34mOptimizing network settings and increasing VPS speed...\e[0m"

        # Optimize TCP stack settings
        sysctl -w net.ipv4.tcp_fin_timeout=30
        sysctl -w net.ipv4.tcp_keepalive_time=120
        sysctl -w net.ipv4.tcp_tw_reuse=1
        sysctl -w net.ipv4.tcp_tw_recycle=1
        sysctl -w net.ipv4.ip_local_port_range="1024 65535"
        sysctl -w net.core.somaxconn=1024
        sysctl -w net.core.netdev_max_backlog=5000

        echo -e "\e[1;32mNetwork optimization and VPS speed increase applied.\e[0m\n"
    else
        echo -e "\e[1;33mNetwork optimization aborted.\e[0m\n"
    fi
}

# Function to add Premium1 DDoS protection
premium1_ddos_protection() {
if confirm_execution "This will add Premium DDoS protection (Level 1). Do you want to continue?"; then
        echo -e "\n\e[1;34mAdding Premium DDoS protection (Level 1)...\e[0m"

sudo apt-get update
sudo apt-get install -y iptables-persistent fail2ban haveged apparmor ufw crowdsec crowdsec-firewall-bouncer-iptables iftop cpufrequtils

read -p "Enter IP addresses to whitelist, separated by commas: " IP_WHITELIST
IFS=',' read -r -a WHITELIST_ARRAY <<< "$IP_WHITELIST"

HETZNER_API_IPS=("213.133.107.227" "213.133.107.230" "213.133.107.229" "213.133.99.99" "213.133.100.100" "213.133.101.101")
WHITELIST_ARRAY+=("${HETZNER_API_IPS[@]}")

SERVER_IPS=$(hostname -I)
IFS=' ' read -r -a SERVER_IP_ARRAY <<< "$SERVER_IPS"
WHITELIST_ARRAY+=("${SERVER_IP_ARRAY[@]}")

iptables -F
iptables -X

for IP in "${WHITELIST_ARRAY[@]}"; do
    iptables -A INPUT -s "$IP" -j ACCEPT
done

iptables -A INPUT -i lo -j ACCEPT
iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

iptables -N RATE_LIMIT
iptables -A INPUT -p tcp -m connlimit --connlimit-above 100 -j RATE_LIMIT
iptables -A RATE_LIMIT -j LOG --log-prefix "Rate Limit: " --log-level 7
iptables -A RATE_LIMIT -j DROP

iptables -A INPUT -p tcp -m conntrack --ctstate NEW -m limit --limit 60/s --limit-burst 20 -j ACCEPT
iptables -A INPUT -p tcp -m conntrack --ctstate NEW -j LOG --log-prefix "New Connection: " --log-level 7

iptables -A INPUT -p udp --dport 53 -m limit --limit 10/sec --limit-burst 20 -j ACCEPT
iptables -A INPUT -p tcp --dport 53 -m limit --limit 10/sec --limit-burst 20 -j ACCEPT

iptables -A INPUT -m conntrack --ctstate INVALID -j DROP

iptables -A INPUT -p tcp --dport 443 -m connlimit --connlimit-above 50 -j RATE_LIMIT
iptables -A INPUT -p tcp --dport 443 -m limit --limit 20/sec --limit-burst 40 -j ACCEPT

iptables -N DOCKER || true
iptables -A DOCKER ! -i pterodactyl0 -o pterodactyl0 -p tcp -d 172.18.0.3 --dport 1030 -j ACCEPT

iptables -A INPUT -j ACCEPT

iptables-save > /etc/iptables/rules.v4

sudo systemctl daemon-reload
sudo systemctl restart netfilter-persistent

cat <<EOF > /etc/fail2ban/jail.local
[DEFAULT]
bantime = 600
findtime = 600
maxretry = 5

[sshd]
enabled = true
port = 22
filter = sshd
logpath = /var/log/auth.log
maxretry = 5
EOF

sudo systemctl enable fail2ban
sudo systemctl start fail2ban

sudo systemctl enable crowdsec
sudo systemctl start crowdsec

sudo systemctl enable crowdsec-firewall-bouncer
sudo systemctl start crowdsec-firewall-bouncer

cat <<EOF > /usr/local/bin/kill-switch.sh
#!/bin/bash

THRESHOLD=1000

while true; do
    TOP_IP=\$(sudo iftop -t -s 1 -n | grep -oP '^\s*\d+\.\d+\.\d+\.\d+' | sort | uniq -c | sort -nr | head -n 1 | awk '{print \$2}')
    COUNT=\$(sudo iftop -t -s 1 -n | grep -oP '^\s*\d+\.\d+\.\d+\.\d+' | sort | uniq -c | sort -nr | head -n 1 | awk '{print \$1}')

    if [ "\$COUNT" -gt "\$THRESHOLD" ]; then
        if ! echo "\${WHITELIST_ARRAY[@]}" | grep -w "\$TOP_IP" &> /dev/null; then
            iptables -A INPUT -s "\$TOP_IP" -j DROP
            sleep 60
            iptables -D INPUT -s "\$TOP_IP" -j DROP
        fi
    fi

    sleep 5
done
EOF

chmod +x /usr/local/bin/kill-switch.sh

nohup /usr/local/bin/kill-switch.sh > /dev/null 2>&1 &

cat <<EOF | sudo tee -a /etc/sysctl.conf
net.core.rmem_max=67108864
net.core.wmem_max=67108864
net.core.rmem_default=67108864
net.core.wmem_default=67108864
net.ipv4.tcp_rmem=4096 87380 67108864
net.ipv4.tcp_wmem=4096 65536 67108864
net.ipv4.tcp_mtu_probing=1
net.core.netdev_max_backlog=5000
net.ipv4.tcp_window_scaling=1
net.core.optmem_max=67108864
net.ipv4.tcp_congestion_control=htcp
EOF

sudo sysctl -p

echo "Choose an option for additional configuration:"
echo "1 - Extreme Speed Boost"
echo "2 - Extra Security"
echo "3 - All"
read -r -p "Enter your choice: " OPTION

case $OPTION in
    1)
        sudo apt-get install -y haveged
        sudo systemctl enable haveged
        sudo systemctl start haveged

        echo "vm.swappiness=10" | sudo tee -a /etc/sysctl.conf
        echo "vm.vfs_cache_pressure=50" | sudo tee -a /etc/sysctl.conf
        sudo sysctl -p

        echo "GRUB_CMDLINE_LINUX_DEFAULT=\"quiet splash zswap.enabled=1 zswap.compressor=lz4 zswap.max_pool_percent=20 zswap.zpool=z3fold\"" | sudo tee -a /etc/default/grub
        sudo update-grub
        ;;
    2)
        sudo apt-get install -y apparmor
        sudo systemctl enable apparmor
        sudo systemctl start apparmor

        echo "kernel.dmesg_restrict=1" | sudo tee -a /etc/sysctl.conf
        echo "net.ipv4.conf.all.log_martians=1" | sudo tee -a /etc/sysctl.conf
        sudo sysctl -p

        sudo apt-get install -y ufw
        sudo ufw default deny incoming
        sudo ufw default allow outgoing
        sudo ufw allow ssh
        sudo ufw enable
        ;;
    3)
        sudo apt-get install -y haveged apparmor ufw
        sudo systemctl enable haveged apparmor
        sudo systemctl start haveged apparmor

        echo "vm.swappiness=10" | sudo tee -a /etc/sysctl.conf
        echo "vm.vfs_cache_pressure=50" | sudo tee -a /etc/sysctl.conf
        echo "kernel.dmesg_restrict=1" | sudo tee -a /etc/sysctl.conf
        echo "net.ipv4.conf.all.log_martians=1" | sudo tee -a /etc/sysctl.conf
        sudo sysctl -p

        echo "GRUB_CMDLINE_LINUX_DEFAULT=\"quiet splash zswap.enabled=1 zswap.compressor=lz4 zswap.max_pool_percent=20 zswap.zpool=z3fold\"" | sudo tee -a /etc/default/grub
        sudo update-grub

        sudo ufw default deny incoming
        sudo ufw default allow outgoing
        sudo ufw allow ssh
        sudo ufw enable
        ;;
    *)
        echo "Invalid option. Exiting."
        exit 1
        ;;
esac

read -r -p "Do you want to overclock the CPU, network, memory, and GPU if available? (y/n): " OVERCLOCK

if [[ "$OVERCLOCK" == "y" ]]; then
    sudo cpufreq-set -r -g performance

    echo "net.core.rmem_max=134217728" | sudo tee -a /etc/sysctl.conf
    echo "net.core.wmem_max=134217728" | sudo tee -a /etc/sysctl.conf
    echo "net.core.rmem_default=134217728" | sudo tee -a /etc/sysctl.conf
    echo "net.core.wmem_default=134217728" | sudo tee -a /etc/sysctl.conf
    echo "net.ipv4.tcp_rmem=4096 87380 134217728" | sudo tee -a /etc/sysctl.conf
    echo "net.ipv4.tcp_wmem=4096 65536 134217728" | sudo tee -a /etc/sysctl.conf
    sudo sysctl -p

    echo "vm.swappiness=1" | sudo tee -a /etc/sysctl.conf
    echo "vm.dirty_ratio=10" | sudo tee -a /etc/sysctl.conf
    echo "vm.dirty_background_ratio=5" | sudo tee -a /etc/sysctl.conf
    sudo sysctl -p

    if command -v nvidia-smi &> /dev/null; then
        sudo nvidia-smi -pm ENABLED
        sudo nvidia-smi -ac 3505,1911
    fi

    echo "Overclocking applied."
else
    echo "Overclocking skipped."
fi

sudo reboot

        echo -e "\e[1;32mPremium DDoS protection (Level 1) applied.\e[0m\n"
    else
        echo -e "\e[1;33mPremium DDoS protection setup aborted.\e[0m\n"
    fi
}

# Function to add Premium1 DDoS protection
premium2_ddos_protection() {
if confirm_execution "This will add Premium DDoS protection (Level 2). Do you want to continue?"; then
        echo -e "\n\e[1;34mAdding Premium DDoS protection (Level 2)...\e[0m"

check_system_resources() {
    TOTAL_MEM=$(free -m | awk '/^Mem:/{print $2}')
    TOTAL_CORES=$(nproc)
    echo "Total RAM: $TOTAL_MEM MB"
    echo "Total CPU Cores: $TOTAL_CORES"
}

get_resource_allocation() {
    MAX_RAM=4096
    MAX_CORES=4

    read -p "Enter RAM to allocate (in MB, max $MAX_RAM): " RAM_ALLOC
    if [ "$RAM_ALLOC" = "all" ]; then
        RAM_ALLOC=$((TOTAL_MEM < MAX_RAM ? TOTAL_MEM : MAX_RAM))
    elif [ "$RAM_ALLOC" -gt $MAX_RAM ] || [ "$RAM_ALLOC" -gt "$TOTAL_MEM" ]; then
        RAM_ALLOC=$((TOTAL_MEM < MAX_RAM ? TOTAL_MEM : MAX_RAM))
        echo "RAM allocation adjusted to $RAM_ALLOC MB"
    fi

    read -p "Enter number of CPU cores to use (max $MAX_CORES): " CORE_ALLOC
    if [ "$CORE_ALLOC" = "all" ]; then
        CORE_ALLOC=$((TOTAL_CORES < MAX_CORES ? TOTAL_CORES : MAX_CORES))
    elif [ "$CORE_ALLOC" -gt "$MAX_CORES" ] || [ "$CORE_ALLOC" -gt "$TOTAL_CORES" ]; then
        CORE_ALLOC=$((TOTAL_CORES < MAX_CORES ? TOTAL_CORES : MAX_CORES))
        echo "CPU core allocation adjusted to $CORE_ALLOC"
    fi
}

check_system_resources

get_resource_allocation

sudo apt-get update -y
sudo apt-get install -y iptables-persistent fail2ban haveged apparmor ufw crowdsec crowdsec-firewall-bouncer-iptables nftables conntrack cgroup-tools

# Quick and advanced system optimizations
echo "Applying quick and advanced system optimizations..."

# Increase file descriptor limit
ulimit -n 1000000
echo "fs.file-max = 1000000" | sudo tee -a /etc/sysctl.conf
echo "* soft nofile 1000000" | sudo tee -a /etc/security/limits.conf
echo "* hard nofile 1000000" | sudo tee -a /etc/security/limits.conf

# Increase network performance
echo "net.core.netdev_max_backlog = 50000" | sudo tee -a /etc/sysctl.conf
echo "net.core.rmem_max = 16777216" | sudo tee -a /etc/sysctl.conf
echo "net.core.wmem_max = 16777216" | sudo tee -a /etc/sysctl.conf
echo "net.ipv4.tcp_rmem = 4096 87380 16777216" | sudo tee -a /etc/sysctl.conf
echo "net.ipv4.tcp_wmem = 4096 65536 16777216" | sudo tee -a /etc/sysctl.conf
echo "net.ipv4.tcp_congestion_control = bbr" | sudo tee -a /etc/sysctl.conf
echo "net.ipv4.tcp_fastopen = 3" | sudo tee -a /etc/sysctl.conf
echo "net.ipv4.tcp_mtu_probing = 1" | sudo tee -a /etc/sysctl.conf

# Apply changes
sudo sysctl -p

sudo cgcreate -g cpu,cpuset,memory:fast_container

sudo cgset -r cpu.cfs_quota_us=$((CORE_ALLOC * 100000)) fast_container
sudo cgset -r cpuset.cpus=0-$((CORE_ALLOC - 1)) fast_container
sudo cgset -r memory.limit_in_bytes=$((RAM_ALLOC * 1024 * 1024)) fast_container

# Configure CrowdSec to use port 8081
sudo sed -i 's/port: 8080/port: 8081/' /etc/crowdsec/config.yaml
sudo systemctl restart crowdsec

read -p "Enter IP addresses to whitelist, separated by commas: " IP_WHITELIST
IFS=',' read -r -a WHITELIST_ARRAY <<< "$IP_WHITELIST"

# Configure iptables
iptables -F
iptables -X

for IP in "${WHITELIST_ARRAY[@]}"; do
    iptables -A INPUT -s "$IP" -j ACCEPT
done

iptables -A INPUT -i lo -j ACCEPT
iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

iptables -A INPUT -p icmp --icmp-type echo-request -j DROP

iptables -N PORT_PROTECT
iptables -A INPUT -p tcp -m conntrack --ctstate NEW -m recent --set
iptables -A INPUT -p tcp -m conntrack --ctstate NEW -m recent --update --seconds 60 --hitcount 20 -j PORT_PROTECT
iptables -A PORT_PROTECT -j LOG --log-prefix "Port DDoS attempt: " --log-level 7
iptables -A PORT_PROTECT -j DROP

iptables -N RATE_LIMIT
iptables -A INPUT -p tcp -m connlimit --connlimit-above 100 -j RATE_LIMIT
iptables -A RATE_LIMIT -j LOG --log-prefix "Rate Limit: " --log-level 7
iptables -A RATE_LIMIT -j DROP

iptables -A INPUT -p tcp -m conntrack --ctstate NEW -m limit --limit 60/s --limit-burst 20 -j ACCEPT
iptables -A INPUT -p tcp -m conntrack --ctstate NEW -j LOG --log-prefix "New Connection: " --log-level 7

# Protect all ports (0-65535)
iptables -A INPUT -p tcp --match multiport --dports 0:65535 -m limit --limit 50/sec --limit-burst 100 -j ACCEPT
iptables -A INPUT -p udp --match multiport --dports 0:65535 -m limit --limit 50/sec --limit-burst 100 -j ACCEPT

iptables -A INPUT -p tcp -d 172.18.0.6 --dport 8080 -j ACCEPT
iptables -A OUTPUT -p tcp -s 172.18.0.6 --sport 8080 -j ACCEPT

sudo iptables -t nat -N DOCKER
sudo iptables -t nat -A POSTROUTING -s 172.17.0.0/16 ! -o docker0 -j MASQUERADE
sudo iptables -t filter -A DOCKER ! -i pterodactyl0 -o pterodactyl0 -p tcp -d 172.18.0.6 --dport 1036 -j ACCEPT

iptables -A FORWARD -p tcp -d 172.18.0.6 --dport 8080 -j ACCEPT
iptables -A FORWARD -p tcp -s 172.18.0.6 --sport 8080 -j ACCEPT

sudo iptables -A INPUT -s 172.18.0.6 -j ACCEPT
sudo iptables -A OUTPUT -d 172.18.0.6 -j ACCEPT

iptables -A INPUT -p tcp -d 172.18.0.6 --dport 8080 -j ACCEPT


iptables -A OUTPUT -p tcp -s 172.18.0.6 --sport 8080 -j ACCEPT


iptables -A FORWARD -p tcp -d 172.18.0.6 --dport 8080 -j ACCEPT
iptables -A FORWARD -p tcp -s 172.18.0.6 --sport 8080 -j ACCEPT

iptables -A INPUT -m conntrack --ctstate INVALID -j DROP

# Final rule: drop all other incoming traffic
iptables -A INPUT -j DROP

# Save iptables rules
sudo sh -c "iptables-save > /etc/iptables/rules.v4"

# Enable netfilter-persistent
sudo systemctl enable netfilter-persistent

# Configure fail2ban
cat <<EOF > /etc/fail2ban/jail.local
[DEFAULT]
bantime = 3600
findtime = 300
maxretry = 3
EOF

# Restart and enable services
sudo systemctl enable fail2ban
sudo systemctl start fail2ban
sudo systemctl enable crowdsec
sudo systemctl start crowdsec
sudo systemctl enable crowdsec-firewall-bouncer
sudo systemctl start crowdsec-firewall-bouncer

echo "Configuring Advanced Kill Switch..."

sudo nft add table ip killswitch

sudo nft add chain ip killswitch monitor { type filter hook prerouting priority -300 \; policy accept \; }

sudo nft add rule ip killswitch monitor ct state new counter
sudo nft add rule ip killswitch monitor ip saddr @blacklist counter drop

sudo nft add set ip killswitch blacklist { type ipv4_addr \; flags dynamic,timeout \; timeout 1h \; }

# Create a script for dynamic IP blocking
cat <<EOF > /usr/local/bin/dynamic_block.sh
#!/bin/bash
while read line; do
    IP=\$(echo \$line | cut -d' ' -f3)
    sudo nft add element ip killswitch blacklist { \$IP }
done
EOF

chmod +x /usr/local/bin/dynamic_block.sh

# Configure Suricata to call the dynamic blocking script
echo "output: fast: /var/log/suricata/fast.log" | sudo tee -a /etc/suricata/suricata.yaml

(crontab -l 2>/dev/null; echo "* * * * * tail -n1000 /var/log/suricata/fast.log | /usr/local/bin/dynamic_block.sh") | crontab -

# Configure sysctl for improved network performance
cat <<EOF | sudo tee -a /etc/sysctl.conf
net.core.somaxconn = 65535
net.ipv4.tcp_max_syn_backlog = 65535
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_max_tw_buckets = 2000000
net.ipv4.tcp_fin_timeout = 10
net.ipv4.tcp_slow_start_after_idle = 0
EOF

sudo sysctl -p

sudo systemctl enable suricata
sudo systemctl start suricata

echo "Advanced Kill Switch configuration complete."

save_config() {
    echo "RAM_ALLOC=$RAM_ALLOC" > /etc/suricata_config
    echo "CORE_ALLOC=$CORE_ALLOC" >> /etc/suricata_config
}

load_config() {
    if [ -f /etc/suricata_config]; then
        source /etc/suricata_config
    fi
}

save_config

echo "Configuration complete. Your server has been optimized and secured with an advanced kill switch."
echo "To reconfigure, simply run this script again."

read -p "Do you want to reboot now? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    sudo reboot
fi
        echo -e "\e[1;32mPremium DDoS protection (Level 2) applied.\e[0m\n"
    else
        echo -e "\e[1;33mPremium DDoS protection setup aborted.\e[0m\n"
    fi
}

# Function to add Premium1 DDoS protection
premium3_ddos_protection() {
if confirm_execution "This will add Premium DDoS protection (Level 3). Do you want to continue?"; then
        echo -e "\n\e[1;34mAdding Premium DDoS protection (Level 3)...\e[0m"

check_system_resources() {
    TOTAL_MEM=$(free -m | awk '/^Mem:/{print $2}')
    TOTAL_CORES=$(nproc)
    echo "Total RAM: $TOTAL_MEM MB"
    echo "Total CPU Cores: $TOTAL_CORES"
}

get_resource_allocation() {
    read -p "Enter RAM to allocate (in MB, max 4096, or 'all' for max available up to 4096): " RAM_ALLOC
    if [ "$RAM_ALLOC" = "all" ]; then
        RAM_ALLOC=$((TOTAL_MEM < 4096 ? TOTAL_MEM : 4096))
    elif [ "$RAM_ALLOC" -gt 4096 ] || [ "$RAM_ALLOC" -gt "$TOTAL_MEM" ]; then
        RAM_ALLOC=$((TOTAL_MEM < 4096 ? TOTAL_MEM : 4096))
        echo "RAM allocation adjusted to $RAM_ALLOC MB"
    fi

    read -p "Enter number of CPU cores to use (max $TOTAL_CORES, or 'all' for all available): " CORE_ALLOC
    if [ "$CORE_ALLOC" = "all" ]; then
        CORE_ALLOC=$TOTAL_CORES
    elif [ "$CORE_ALLOC" -gt "$TOTAL_CORES" ]; then
        CORE_ALLOC=$TOTAL_CORES
        echo "CPU core allocation adjusted to $CORE_ALLOC"
    fi
}


check_system_resources


get_resource_allocation


sudo apt-get update
sudo apt-get install -y iptables-persistent fail2ban unbound haveged apparmor ufw crowdsec crowdsec-firewall-bouncer-iptables nftables conntrack suricata cgroup-tools


sudo cgcreate -g cpu,cpuset,memory:suricata


sudo cgset -r cpu.cfs_quota_us=$((CORE_ALLOC * 100000)) suricata
sudo cgset -r cpuset.cpus=0-$((CORE_ALLOC - 1)) suricata
sudo cgset -r memory.limit_in_bytes=$((RAM_ALLOC * 1024 * 1024)) suricata


cat <<EOF | sudo tee /etc/systemd/system/suricata.service
[Unit]
Description=Suricata Intrusion Detection Service
After=network.target

[Service]
ExecStart=/usr/bin/cgexec -g cpu,cpuset,memory:suricata /usr/bin/suricata -c /etc/suricata/suricata.yaml -i eth0
ExecReload=/bin/kill -HUP \$MAINPID
Restart=on-failure
Type=simple

[Install]
WantedBy=multi-user.target
EOF


sudo systemctl daemon-reload


read -p "Enter IP addresses to whitelist, separated by commas: " IP_WHITELIST
IFS=',' read -r -a WHITELIST_ARRAY <<< "$IP_WHITELIST"

# Configure iptables
iptables -F
iptables -X

for IP in "${WHITELIST_ARRAY[@]}"; do
    iptables -A INPUT -s "$IP" -j ACCEPT
done

iptables -A INPUT -i lo -j ACCEPT
iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT


iptables -A INPUT -p icmp --icmp-type echo-request -j DROP


iptables -N PORT_PROTECT
iptables -A INPUT -p tcp -m conntrack --ctstate NEW -m recent --set
iptables -A INPUT -p tcp -m conntrack --ctstate NEW -m recent --update --seconds 60 --hitcount 20 -j PORT_PROTECT
iptables -A PORT_PROTECT -j LOG --log-prefix "Port DDoS attempt: " --log-level 7
iptables -A PORT_PROTECT -j DROP


iptables -N RATE_LIMIT
iptables -A INPUT -p tcp -m connlimit --connlimit-above 100 -j RATE_LIMIT
iptables -A RATE_LIMIT -j LOG --log-prefix "Rate Limit: " --log-level 7
iptables -A RATE_LIMIT -j DROP


iptables -A INPUT -p tcp -m conntrack --ctstate NEW -m limit --limit 60/s --limit-burst 20 -j ACCEPT
iptables -A INPUT -p tcp -m conntrack --ctstate NEW -j LOG --log-prefix "New Connection: " --log-level 7

# Protect all ports (0-65535)
iptables -A INPUT -p tcp --match multiport --dports 0:65535 -m limit --limit 50/sec --limit-burst 100 -j ACCEPT
iptables -A INPUT -p udp --match multiport --dports 0:65535 -m limit --limit 50/sec --limit-burst 100 -j ACCEPT


iptables -A INPUT -m conntrack --ctstate INVALID -j DROP

# Final rule: drop all other incoming traffic
iptables -A INPUT -j DROP

# Save iptables rules
iptables-save > /etc/iptables/rules.v4

# Enable netfilter-persistent
sudo systemctl enable netfilter-persistent

# Configure fail2ban
cat <<EOF > /etc/fail2ban/jail.local
[DEFAULT]
bantime = 3600
findtime = 300
maxretry = 3

[sshd]
enabled = true
port = 22
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
EOF

cat <<EOF > /etc/unbound/unbound.conf
server:
    interface: 0.0.0.0
    access-control: 0.0.0.0/0 refuse
    access-control: 127.0.0.0/8 allow
    verbosity: 1
    do-ip4: yes
    do-ip6: no
    do-udp: yes
    do-tcp: yes
    hide-identity: yes
    hide-version: yes
    harden-glue: yes
    harden-dnssec-stripped: yes
    use-caps-for-id: yes
    edns-buffer-size: 1232
    prefetch: yes
    num-threads: $CORE_ALLOC

forward-zone:
    name: "."
    forward-addr: 1.1.1.1
    forward-addr: 1.0.0.1
EOF

# Restart and enable services
sudo systemctl restart unbound
sudo systemctl enable unbound
sudo systemctl enable crowdsec
sudo systemctl start crowdsec
sudo systemctl enable crowdsec-firewall-bouncer
sudo systemctl start crowdsec-firewall-bouncer


echo "Configuring Advanced Kill Switch..."


sudo nft add table ip killswitch


sudo nft add chain ip killswitch monitor { type filter hook prerouting priority -300 \; policy accept \; }


sudo nft add rule ip killswitch monitor ct state new counter
sudo nft add rule ip killswitch monitor ip saddr @blacklist counter drop


sudo nft add set ip killswitch blacklist { type ipv4_addr \; flags dynamic,timeout \; timeout 1h \; }

sudo sed -i "s/^#run-as:/run-as:\n  user: suricata\n  group: suricata\nmax-pending-packets: 1024\ndetection:\n  threads: $CORE_ALLOC/" /etc/suricata/suricata.yaml

SURICATA_MEM="${RAM_ALLOC}mb"
sudo sed -i "s/^#memory:/memory:\n  memcap: $SURICATA_MEM\n  max-packet-mem: 256mb/" /etc/suricata/suricata.yaml

# Create a script for dynamic IP blocking
cat <<EOF > /usr/local/bin/dynamic_block.sh
#!/bin/bash
while read line; do
    IP=\$(echo \$line | cut -d' ' -f3)
    sudo nft add element ip killswitch blacklist { \$IP }
done
EOF

chmod +x /usr/local/bin/dynamic_block.sh

# Configure Suricata to call the dynamic blocking script
echo "alert http any any -> any any (msg:\"Potential DDoS Attempt\"; flow:established; threshold: type both, track by_src, count 100, seconds 60; sid:1000001; rev:1;)" | sudo tee -a /etc/suricata/rules/local.rules
echo "output: fast: /var/log/suricata/fast.log" | sudo tee -a /etc/suricata/suricata.yaml

suspicious IPs
(crontab -l 2>/dev/null; echo "* * * * * tail -n1000 /var/log/suricata/fast.log | /usr/local/bin/dynamic_block.sh") | crontab -

# Configure sysctl for improved network performance
cat <<EOF | sudo tee -a /etc/sysctl.conf
net.core.somaxconn = 65535
net.ipv4.tcp_max_syn_backlog = 65535
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_max_tw_buckets = 2000000
net.ipv4.tcp_fin_timeout = 10
net.ipv4.tcp_slow_start_after_idle = 0
EOF

sudo sysctl -p


sudo systemctl enable suricata
sudo systemctl start suricata
sudo systemctl restart fail2ban

echo "Advanced Kill Switch configuration complete."


save_config() {
    echo "RAM_ALLOC=$RAM_ALLOC" > /etc/suricata_config
    echo "CORE_ALLOC=$CORE_ALLOC" >> /etc/suricata_config
}


load_config() {
    if [ -f /etc/suricata_config ]; then
        source /etc/suricata_config
    fi
}


save_config

echo "Configuration complete. Your server has been optimized and secured with an advanced kill switch."
echo "To reconfigure, simply run this script again."


read -p "Do you want to reboot now? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
    sudo reboot
fi
        echo -e "\e[1;32mPremium DDoS protection (Level 3) applied.\e[0m\n"
    else
        echo -e "\e[1;33mPremium DDoS protection setup aborted.\e[0m\n"
    fi
}

# Main execution
display_banner
while true; do
    display_menu
    read -r choice
    case "$choice" in
        1) install_packages ;;
        2) block_ip ;;
        3) unblock_ip ;;
        4) setup_firewall ;;
        5) ddos_protection ;;
        6) setup_cloudflare_proxy ;;
        7) enforce_https ;;
        8) install_fail2ban ;;
        9) advanced_ddos_protection ;;
       10) optimize_network ;;
       11) premium1_ddos_protection ;;
       12) premium2_ddos_protection ;;
       13) premium3_ddos_protection ;;
        0) echo -e "\033[1;33mExiting SecureShield.\033[0m"; break ;;
        *) echo -e "\033[1;31mInvalid option. Please try again.\033[0m" ;;
    esac
done