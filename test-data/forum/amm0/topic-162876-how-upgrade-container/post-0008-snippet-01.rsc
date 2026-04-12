# Source: https://forum.mikrotik.com/t/how-upgrade-container/162876/8
# Topic: How upgrade container?
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

# find your pihole container's ID (generally 0) that you want to upgrade
/container/print
# remove container
/container/remove 0
# re-add same container 
/container/add file=pihole.tar interface=veth1 envlist=pihole_envs mounts=dnsmasq_pihole,etc_pihole hostname=PiHole
