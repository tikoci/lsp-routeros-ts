# Source: https://forum.mikrotik.com/t/v7-20beta-testing-is-released/183944/77
# Topic: V7.20beta [testing] is released!
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

/interface/veth/print
Flags: X - disabled; R - running 
 0  R name="veth-faucet" address=172.19.7.7/24 gateway=172.19.7.1 gateway6="" 
 1  R name="veth-homebridge-dsi" address=192.168.163.249/24 gateway="" gateway6="" 
 2    name="veth-homebridge-scz" address=192.168.74.249/24 gateway=192.168.74.1 gateway6=""
 /container/print detail 
 1 S ;;; could not acquire interface: veth-homebridge-scz get ifindex failed (6)
     check-certificate=no name="homebridge" 
     tag="registry-1.docker.io/homebridge/homebridge:latest" os="linux" 
     arch="arm" interface=veth-homebridge-dsi,veth-homebridge-scz envlists="" 
     cmd="" entrypoint="" stop-signal=15-SIGTERM root-dir=disk1/homebridge 
     mounts=homebridge hostname="" domain-name="" workdir="/homebridge" 
     logging=yes start-on-boot=yes auto-restart-interval=none 
     memory-high=unlimited devices="" passed-devs="" config-json=...
