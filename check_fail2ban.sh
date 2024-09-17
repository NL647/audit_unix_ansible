#!/usr/bin/env bash
# -*- coding: utf-8 -*-


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
FAILCONF=$(cat /etc/fail2ban/jail.local | grep -i "maxretry=4" )


# Write collected data to CSV
printf "%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,\"%s\",%s,%s,%s,%s\n" \
"$HOSTNAME" "$IP" "$OS_NAME" "$OS_VERSION" "$APACHE_PRESENT" "$NGINX_PRESENT"  "$FAILCONF"> "$OUTPUT_FILE"
