# Source: https://forum.mikrotik.com/t/failover-to-lte-on-ros7-with-ping-check-to-remote-host/153680/4
# Topic: Failover to LTE on ROS7 (with ping-check to remote host) ??
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

/ip/route/
add dst-address=8.8.8.8 scope=10 gateway=10.111.0.1
add dst-address=8.8.4.4 scope=10 gateway=10.112.0.1
