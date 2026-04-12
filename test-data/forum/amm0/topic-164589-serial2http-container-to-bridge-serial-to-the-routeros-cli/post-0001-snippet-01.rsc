# Source: https://forum.mikrotik.com/t/serial2http-container-to-bridge-serial-to-the-routeros-cli/164589/1
# Topic: "serial2http" — container to bridge serial to the RouterOS CLI
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

/container/envs {
    # HTTP port the container listens for commands on...
    add name="$containertag" key="PORT" value=80 
    # PySerial "URL" to use to connect to serial device via RFC2217
    add name="$containertag" key="SERIALURL" value="rfc2217://172.22.17.254:22171?ign_set_control&logging=debug&timeout=3"
    # while most options can be set in the pyserial's url, BAUDRATE must be explicit 
    add name="$containertag" key="BAUDRATE" value=115200
}
/container/mounts {
    # serial2http doesn't use mounts
}
