#!/bin/bash

# Function to display usage
usage() {
    printf "Usage: %s -f output_filename.csv\n" "$(basename "$0")"
    exit 1
}

# Parse command line arguments
while getopts "f:" opt; do
    case "$opt" in
        f) OUTPUT_FILE="$OPTARG" ;;
        *) usage ;;
    esac
done

# Ensure the output file is specified
if [[ -z "$OUTPUT_FILE" ]]; then
    printf "Error: Output file name is required.\n" >&2
    usage
fi

# Collect information
HOSTNAME=$(hostname)
OS_NAME=$(lsb_release -si)
OS_VERSION=$(lsb_release -sr)
IP=$(hostname -I)

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
if command -v php &> /dev/null; then
    PHP_VERSION=$(php -v | head -n 1 | awk '{print $2}')
else
    PHP_VERSION="N/A"
fi

# UFW info
if command -v ufw &> /dev/null; then
    UFW_PRESENT="Yes"
    UFW_PORTS=$(ufw status | grep -i 'allow' | awk '{print $1}' | paste -sd "--" -)
    [[ -z "$UFW_PORTS" ]] && UFW_PORTS="None"
else
    UFW_PRESENT="No"
    UFW_PORTS="N/A"
fi

# Fail2Ban info
if command -v fail2ban-server &> /dev/null; then
    FAIL2BAN_PRESENT="Yes"
    FAIL2BAN_ACTIVE=$(systemctl is-active fail2ban)
    ACTIVE_JAILS=$(fail2ban-client status | grep "Jail list" | cut -d: -f2 | tr -d ' ' tr  ',' '__') || ACTIVE_JAILS="None"
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

# Check for CIS Hardening file
if [ -f /etc/default/cis-hardening ]; then
    CIS_HARDENING="Present"
else
    CIS_HARDENING="Absent"
fi

# Write collected data to CSV
printf "%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,\"%s\",%s,%s,%s,%s\n" \
"$HOSTNAME" "$IP" "$OS_NAME" "$OS_VERSION" "$APACHE_PRESENT" "$APACHE_VERSION" "$NGINX_PRESENT" \
"$NGINX_VERSION" "$PHP_VERSION" "$UFW_PRESENT" "$UFW_PORTS" "$FAIL2BAN_PRESENT" \
"$FAIL2BAN_ACTIVE" "$ACTIVE_JAILS" "$REBOOT_REQUIRED" "$UNATTENDED_UPGRADES_INSTALLED" \
"$SUDO_USERS" "$DOCKER_PRESENT" "$DOCKER_VERSION" "$ROOT_LOGIN" "$CIS_HARDENING" > "$OUTPUT_FILE"
