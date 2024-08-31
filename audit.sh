#!/bin/bash

# Define output file
OUTPUT_FILE="/tmp/{{ csv_name }}"

# Collect information
HOSTNAME=$(hostname)
OS_NAME=$(lsb_release -si)
OS_VERSION=$(lsb_release -sr)

# Apache info
if command -v apache2 &> /dev/null; then
    APACHE_PRESENT="Yes"
    APACHE_VERSION=$(apache2 -v | grep "Server version" | awk '{print $3}' | cut -d/ -f2)
else
    APACHE_PRESENT="No"
    APACHE_VERSION="N/A"
fi

# Nginx info
if command -v nginx &> /dev/null; then
    NGINX_PRESENT="Yes"
    NGINX_VERSION=$(nginx -v 2>&1 | cut -d/ -f2)
else
    NGINX_PRESENT="No"
    NGINX_VERSION="N/A"
fi

# PHP version
PHP_VERSION=$(php -v | head -n 1 | awk '{print $2}') || PHP_VERSION="N/A"

# UFW info
if command -v ufw &> /dev/null; then
    UFW_PRESENT="Yes"
    UFW_PORTS=$(ufw status | grep -i 'open' | awk '{print $1}' | paste -sd "," -)
    [[ -z "$UFW_PORTS" ]] && UFW_PORTS="None"
else
    UFW_PRESENT="No"
    UFW_PORTS="N/A"
fi

# Fail2Ban info
if command -v fail2ban-server &> /dev/null; then
    FAIL2BAN_PRESENT="Yes"
    FAIL2BAN_ACTIVE=$(systemctl is-active fail2ban)
    ACTIVE_JAILS=$(fail2ban-client status | grep "Jail list" | cut -d: -f2 | tr -d ' ') || ACTIVE_JAILS="None"
else
    FAIL2BAN_PRESENT="No"
    FAIL2BAN_ACTIVE="N/A"
    ACTIVE_JAILS="N/A"
fi

# Check if reboot required
if [ -f /var/run/reboot-required ]; then
    REBOOT_REQUIRED="Yes"
else
    REBOOT_REQUIRED="No"
fi

# Check if unattended upgrades installed
if dpkg -l | grep -q unattended-upgrades; then
    UNATTENDED_UPGRADES_INSTALLED="Yes"
else
    UNATTENDED_UPGRADES_INSTALLED="No"
fi

# List users with sudo rights
SUDO_USERS=$(getent group sudo | cut -d: -f4 | tr ',' ' ') || SUDO_USERS="None"

# Docker info
if command -v docker &> /dev/null; then
    DOCKER_PRESENT="Yes"
    DOCKER_VERSION=$(docker --version | awk '{print $3}' | tr -d ',')
else
    DOCKER_PRESENT="No"
    DOCKER_VERSION="N/A"
fi

# Root login permitted
ROOT_LOGIN=$(grep "^PermitRootLogin" /etc/ssh/sshd_config | awk '{print $2}') || ROOT_LOGIN="N/A"

# Write collected data to CSV
printf "%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,\"%s\",%s,%s,%s\n" \
"$HOSTNAME" "$OS_NAME" "$OS_VERSION" "$APACHE_PRESENT" "$APACHE_VERSION" "$NGINX_PRESENT" \
"$NGINX_VERSION" "$PHP_VERSION" "$UFW_PRESENT" "$UFW_PORTS" "$FAIL2BAN_PRESENT" \
"$FAIL2BAN_ACTIVE" "$ACTIVE_JAILS" "$REBOOT_REQUIRED" "$UNATTENDED_UPGRADES_INSTALLED" \
"$SUDO_USERS" "$DOCKER_PRESENT" "$DOCKER_VERSION" "$ROOT_LOGIN" > "$OUTPUT_FILE"
