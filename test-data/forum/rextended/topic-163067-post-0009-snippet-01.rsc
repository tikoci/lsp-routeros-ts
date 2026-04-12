# Source: https://forum.mikrotik.com/t/no-way-ai-writes-mikrotik-scripts/163067/9
# Post author: @rextended
# Extracted from: code-block

# Set the IPv4 address to be converted
:local ipv4Address "192.168.0.1"

# Split the IPv4 address into its octets
:local octets [:toarray $ipv4Address]
