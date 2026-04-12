# Source: https://forum.mikrotik.com/t/using-caddy-server-as-cors-proxy-for-rest-api/261562/1
# Topic: Using Caddy Server as CORS Proxy for REST API
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

:global caddydisk "disk1/caddyserver-root"

    # add VETH to use for caddy
/interface veth add address=192.168.88.7/24 gateway=192.168.88.1 name=veth-caddy

    # add VETH to bridge as LAN port 
/interface bridge port add interface=veth-caddy bridge=([/interface/bridge/find]->0) # if vlans, use pvid=<vlan>
    # do NOT set an IP address on router for VETH if bridged - none is needed

     # add the container 
/container add check-certificate=no interface=veth-caddy logging=yes root-dir=$caddydisk start-on-boot=yes remote-image=registry-1.docker.io/library/caddy:latest

    # for 7.20 beta, the check-certificate=no is required since builtin roots do not have docker's listed
