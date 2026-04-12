# Source: https://forum.mikrotik.com/t/routeros-rest-api-requests-running-in-series/266665/2
# Topic: RouterOS rest API requests running in series
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

ROSUSER=admin
ROSPASSWD=changeme
ROSURL=http://192.168.88.1

# Array of public DNS servers 
IPS=(
    8.8.8.8           # Google
    8.8.4.4           # Google
    1.1.1.1           # Cloudflare
    1.0.0.1           # Cloudflare
    208.67.222.222    # OpenDNS
    208.67.220.220    # OpenDNS
    9.9.9.9           # Quad9
    149.112.112.112   # Quad9
    8.26.56.26        # Comodo Secure DNS
    8.20.247.20       # Comodo Secure DNS
    94.140.14.14      # AdGuard DNS
    94.140.15.15      # AdGuard DNS
    185.228.168.9     # CleanBrowsing
    185.228.169.9     # CleanBrowsing
    64.6.64.6         # Verisign
    64.6.65.6         # Verisign
    84.200.69.80      # DNS.Watch
    84.200.70.40      # DNS.Watch
    156.154.70.1      # Neustar / UltraDNS
    156.154.71.1      # Neustar / UltraDNS
)

for ip in "${IPS[@]}"; do
  {
    /usr/bin/time curl -k -sS -u "$ROSUSER:$ROSPASSWD" \
    -H 'Content-Type: application/json' \
    -X POST '$ROSURL/rest/ping' \
    --data-raw "{\"address\":\"$ip\",\"count\":4}" \
    | jq -r '.[-1] | "\(.host) \(."avg-rtt") \(.sent) \(.received) \(."packet-loss")"'
  } 2>&1 &
done
wait
