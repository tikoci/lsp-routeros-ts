# Source: https://forum.mikrotik.com/t/home-assistant-container-success-stories/181344/4
# Topic: Home Assistant container - success stories?
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

# SSD is at "raid1/" and layer-dir= and tmpdir= explicitly use the "real" disk
/container/config set layer-dir=raid1/layers registry-url=https://registry-1.docker.io tmpdir=raid1/tmpdir
# had to use :latest - otherwise does error
/container add remote-image=homeassistant/home-assistant:latest root-dir=raid1/ha-root interface=veth-lanbridge-203 logging=yes
