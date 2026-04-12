# Source: https://forum.mikrotik.com/t/ros-scripting-question/179108/5
# Topic: ROS Scripting question
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

:foreach i in=$interfaceConfigs do={
    :local config $i
    :local currentInterfaceName ($i->0)
    :local currentListenPort ($i->1)
    :local currentNetshieldValue ($i->2)
    :local currentPrivateKey ($i->3)
    :local currentServer ($i->4)
    :local currentNetworkID ($i->5)
    :local currentInterfaceAddress ($i->6)
    :local currentPeerServer($i->7)
    :local currentEndpoint($i->8)
    :local currentGateway ($i->9)
    :local currentReversedGateway ($i->10)
    :local currentPublicKey ($i->11)

    # Add WireGuard interface
    /interface wireguard add comment=("$protonid " . $currentNetworkID . " Netshield " . $currentNetshieldValue . " " . $currentServer) listen-port=$currentListenPort mtu=1420 \
        name=$currentInterfaceName private-key=$currentPrivateKey

    # ...
}
