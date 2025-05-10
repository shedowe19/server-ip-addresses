#!/usr/bin/env bash

set -euo pipefail

CIDR_REGEX='[0-9]\{1,3\}\(\.[0-9]\{1,3\}\)\{3\}/[0-9]\{1,2\}'

cd /data

# Funktion zur Extraktion via URL
extract_cidrs_from_url() {
  url="$1"
  wget -qO- "$url" | grep -o "$CIDR_REGEX" | sort -V || true
}

# Anbieter & Quellen
cidrs_aws=$(extract_cidrs_from_url "https://ip-ranges.amazonaws.com/ip-ranges.json")
cidrs_cloudflare=$(extract_cidrs_from_url "https://www.cloudflare.com/ips-v4")
cidrs_gcp=$(extract_cidrs_from_url "https://www.gstatic.com/ipranges/cloud.json")
azure_url=$(wget -qO- -U Mozilla https://www.microsoft.com/en-us/download/confirmation.aspx?id=56519 | grep -Eo 'https://download\.microsoft\.com/download/[^\"]+\.json' | head -n 1)
cidrs_azure=$(extract_cidrs_from_url "$azure_url")
cidrs_oracle=$(extract_cidrs_from_url "https://docs.oracle.com/iaas/tools/public_ip_ranges.json")
cidrs_digitalocean=$(extract_cidrs_from_url "https://digitalocean.com/geo/google.csv")
cidrs_fastly=$(extract_cidrs_from_url "https://api.fastly.com/public-ip-list")
cidrs_linode=$(extract_cidrs_from_url "https://geoip.linode.com/")
cidrs_alibaba=$(extract_cidrs_from_url "https://raw.githubusercontent.com/rezmoss/cloud-provider-ip-addresses/main/alibaba/alibaba_ips.txt")
cidrs_tencent=$(extract_cidrs_from_url "https://raw.githubusercontent.com/rezmoss/cloud-provider-ip-addresses/main/tencent/tencent_ips.txt")
cidrs_ovh=$(extract_cidrs_from_url "https://raw.githubusercontent.com/rezmoss/cloud-provider-ip-addresses/main/ovh/ovh_ips.txt")
cidrs_hetzner=$(extract_cidrs_from_url "https://raw.githubusercontent.com/rezmoss/cloud-provider-ip-addresses/main/hetzner/hetzner_ips.txt")
cidrs_bingbot=$(extract_cidrs_from_url "https://raw.githubusercontent.com/lord-alfred/ipranges/main/bing/ipv4.txt")
cidrs_cachefly=$(extract_cidrs_from_url "https://cachefly.cachefly.net/ips/rproxy.txt")
cidrs_cdn77=$(extract_cidrs_from_url "https://prefixlists.tools.cdn77.com/public_lmax_prefixes.json")
cidrs_gcore=$(extract_cidrs_from_url "https://api.gcore.com/cdn/public-ip-list")
cidrs_imperva=$(extract_cidrs_from_url "https://my.imperva.com/api/integration/v1/ips")
cidrs_medianova=$(extract_cidrs_from_url "https://cloud.medianova.com/api/v1/ip/blocks-list")

# Weitere Anbieter (nur ASNs bekannt, CIDRs ggf. manuell oder via whois)
# Akamai, Bunny.net, Edgecast, Edgio, Limelight, Qrator, StackPath, StormWall, Sucuri (ASNs bekannt, CIDRs nicht direkt abrufbar)

# Alles zusammenführen
all_cidrs=$(echo -e "$cidrs_aws\n$cidrs_cloudflare\n$cidrs_gcp\n$cidrs_azure\n$cidrs_oracle\n$cidrs_digitalocean\n$cidrs_fastly\n$cidrs_linode\n$cidrs_alibaba\n$cidrs_tencent\n$cidrs_ovh\n$cidrs_hetzner\n$cidrs_bingbot\n$cidrs_cachefly\n$cidrs_cdn77\n$cidrs_gcore\n$cidrs_imperva\n$cidrs_medianova" | sort -V | uniq)
echo "$all_cidrs" > datacenters.txt

# CSV-Ausgabe
get_csv_of_low_and_high_ip_from_cidr_list() {
  cidrs="$1"
  vendor="$2"
  echo "$cidrs" | while read -r cidr; do
    hostmin=$(ipcalc -n "$cidr" | cut -f2 -d=)
    hostmax=$(ipcalc -b "$cidr" | cut -f2 -d=)
    echo "\"$cidr\",\"$hostmin\",\"$hostmax\",\"$vendor\""
  done
}

echo '"cidr","hostmin","hostmax","vendor"' > datacenters.csv

for provider in \
  AWS Cloudflare GCP Azure OracleCloud DigitalOcean Fastly Linode \
  AlibabaCloud Tencent OVHcloud Hetzner Bingbot CacheFly CDN77 Gcore Imperva Medianova; do
  var="cidrs_${provider,,}"
  get_csv_of_low_and_high_ip_from_cidr_list "${!var:-}" "$provider" >> datacenters.csv
  echo "$provider CIDRs: $(echo "${!var:-}" | wc -l)"
done

echo "Success!"
