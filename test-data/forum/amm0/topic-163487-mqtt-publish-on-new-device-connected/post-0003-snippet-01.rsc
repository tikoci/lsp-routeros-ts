# Source: https://forum.mikrotik.com/t/mqtt-publish-on-new-device-connected/163487/3
# Topic: MQTT publish on new device connected
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

/iot mqtt publish broker=YOUR_BROKER topic=NAME_OF_DHCP_TOPIC message="{\"leaseBound\": \"$leaseBound\",
\"leaseServerName\": \"$leaseServerName\",
\"leaseActMAC\": \"$leaseActMAC\",
\"leaseActIP\": \"$leaseActIP\".
\"lease-hostname\": \"$lease-hostname\",
\"lease-options\": \"$lease-options\"}"
