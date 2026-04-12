# Source: https://forum.mikrotik.com/t/serial2http-container-to-bridge-serial-to-the-routeros-cli/164589/1
# Topic: "serial2http" — container to bridge serial to the RouterOS CLI
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

{
:local containernum 1
:local containername "serial2http" 
:local containeripbase "172.22.17"
:local containerprefix "24"
:local containergw "$(containeripbase).254"
:local containerip "$(containeripbase).1"
:local containertag "$(containername)$(containernum)"
:local containerethname "veth-$(containertag)"

/interface/veth {
    remove [find comment~"$containertag"]
    :local veth [add name="$containerethname" address="$(containerip)/$(containerprefix)" gateway=$containergw comment="#$containertag"]
    :put "added VETH - $containerethname address=$(containerip)/$(containerprefix) gateway=$containergw "
}
/ip/address {
    remove [find comment~"$containertag"]
    :local ipaddr [add interface="$containerethname" address="$(containergw)/$(containerprefix)" comment="#$containertag"]
    :put "added IP address=$(containergw)/$(containerprefix) interface=$containerethname"
}
/container/envs {
    remove [find name="$containertag"]
    add name="$containertag" key="PORT" value=80 
    add name="$containertag" key="SERIALURL" value="rfc2217://$(containergw):2217$(containernum)?ign_set_control&logging=debug&timeout=3"
    add name="$containertag" key="BAUDRATE" value=115200
}
/container/mounts {
    # serial2http doesn't use mounts
    remove [find comment~"$containertag"]
}
}
