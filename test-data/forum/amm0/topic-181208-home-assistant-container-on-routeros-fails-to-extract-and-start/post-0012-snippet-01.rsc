# Source: https://forum.mikrotik.com/t/home-assistant-container-on-routeros-fails-to-extract-and-start/181208/12
# Topic: Home Assistant container on RouterOS - fails to extract and start
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

# ... add veth and networking config ...
# SSD is at "raid1/" and layer-dir= and tmpdir= explicitly use the "real" disk
/container/config set layer-dir=raid1/layers registry-url=https://registry-1.docker.io tmpdir=raid1/tmpdir
# had to use :latest - otherwise does error
/container add remote-image=homeassistant/home-assistant:latest root-dir=raid1/ha-root interface=veth-ha logging=yes
