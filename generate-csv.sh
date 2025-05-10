#!/usr/bin/env bash

set -euo pipefail

CIDR_REGEX='[0-9]\{1,3\}\(\.[0-9]\{1,3\}\)\{3\}/[0-9]\{1,2\}'

cd /data

# AWS
cidrs_aws=$(wget -qO- https://ip-ranges.amazonaws.com/ip-ranges.json | grep -o "$CIDR_REGEX" | sort -V)
echo -n "AWS CIDRs: "
echo "$cidrs_aws" | wc -l

# Cloudflare
cidrs_cloudflare=$(wget -qO- https://www.cloudflare.com/ips-v4 | grep -o "$CIDR_REGEX" | sort -V)
echo -n "Cloudflare CIDRs: "
echo "$cidrs_cloudflare" | wc -l

# Google Cloud
cidrs_gcp=$(wget -qO- https://www.gstatic.com/ipranges/cloud.json | grep -o "$CIDR_REGEX" | sort -V)
echo -n "GCP CIDRs: "
echo "$cidrs_gcp" | wc -l

# Oracle Cloud
cidrs_oracle=$(wget -qO- https://docs.oracle.com/iaas/tools/public_ip_ranges.json | grep -o "$CIDR_REGEX" | sort -V)
echo -n "Oracle Cloud CIDRs: "
echo "$cidrs_oracle" | wc -l

# DigitalOcean
cidrs_digitalocean=$(wget -qO- https://digitalocean.com/geo/google.csv | grep -o "$CIDR_REGEX" | sort -V)
echo -n "DigitalOcean CIDRs: "
echo "$cidrs_digitalocean" | wc -l

# Fastly
cidrs_fastly=$(wget -qO- https://api.fastly.com/public-ip-list | grep -o "$CIDR_REGEX" | sort -V)
echo -n "Fastly CIDRs: "
echo "$cidrs_fastly" | wc -l

# Yandex Cloud
cidrs_yandex=$(wget -qO- https://yandex.cloud/en/docs/overview/concepts/public-ips | grep -o "$CIDR_REGEX" | sort -V)
echo -n "Yandex Cloud CIDRs: "
echo "$cidrs_yandex" | wc -l

# Zusammenführen und Duplikate entfernen
echo -e "$cidrs_aws\n$cidrs_cloudflare\n$cidrs_gcp\n$cidrs_oracle\n$cidrs_digitalocean\n$cidrs_fastly\n$cidrs_yandex" | sort -V | uniq > datacenters.txt

# Funktion zur Erstellung der CSV-Datei
get_csv_of_low_and_high_ip_from_cidr_list() {
    cidrs=$1
    vendor=$2
    echo "$cidrs" | while read -r cidr; do
        hostmin=$(ipcalc -n "$cidr" | cut -f2 -d=)
        hostmax=$(ipcalc -b "$cidr" | cut -f2 -d=)
        echo "\"$cidr\",\"$hostmin\",\"$hostmax\",\"$vendor\""
    done
}

# CSV-Datei erstellen
echo '"cidr","hostmin","hostmax","vendor"' > datacenters.csv
get_csv_of_low_and_high_ip_from_cidr_list "$cidrs_aws" "AWS" >> datacenters.csv
get_csv_of_low_and_high_ip_from_cidr_list "$cidrs_cloudflare" "Cloudflare" >> datacenters.csv
get_csv_of_low_and_high_ip_from_cidr_list "$cidrs_gcp" "GCP" >> datacenters.csv
get_csv_of_low_and_high_ip_from_cidr_list "$cidrs_oracle" "Oracle Cloud" >> datacenters.csv
get_csv_of_low_and_high_ip_from_cidr_list "$cidrs_digitalocean" "DigitalOcean" >> datacenters.csv
get_csv_of_low_and_high_ip_from_cidr_list "$cidrs_fastly" "Fastly" >> datacenters.csv
get_csv_of_low_and_high_ip_from_cidr_list "$cidrs_yandex" "Yandex Cloud" >> datacenters.csv

echo "Success!"
