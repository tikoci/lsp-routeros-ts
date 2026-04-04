#!tikbook

/interface/bridge/print

#.

/interface/vlan print

#.

/interface/bridge set [find] vlan-filtering=yes

#.

:put [:serialize to=json options=json.pretty {"a"=1;"b"="8989.898";"dsfa-asdf"=[:nothing];"irir"=true;"str"="string";"undedf"=false;"deep"={"a"=1;"b"="8989.898";"dsfa-asdf"=[:nothing];"irir"=true;"str"="string";"undedf"=false;"deeper"={"a"=1;"b"="8989.898";"dsfa-asdf"=[:nothing];"irir"=true;"str"="string";"undedf"=false}}}]

#.markdown
#  ### CoPilot's results for "VLAN function"...
#.

# Function to add a new VLAN, assign it to a bridge, create an IP subnet, and set up a DHCP server
# Usage: :add-vlan-dhcp vlan-id=30 vlan-name="vlan30" bridge="bridge1" interface="ether2" subnet=5
:global "add-vlan-dhcp" do={
:local vlanId ($vlan-id)
:local vlanName ($vlan-name)
:local bridgeName ($bridge)
:local interfaceName ($interface)
:local subnetNum ($subnet)
:local network ("10.88." . $subnetNum . ".0/24")
:local poolName ("dhcp_pool_" . $vlanName)
:local serverName ("dhcp_server_" . $vlanName)
:local addressName ("ip_" . $vlanName)

/interface/vlan add name=$vlanName vlan-id=$vlanId interface=$interfaceName
/interface/bridge/port add bridge=$bridgeName interface=$vlanName
/ip/address add address=("10.88." . $subnetNum . ".1/24") interface=$vlanName comment=$addressName
/ip/pool add name=$poolName ranges=("10.88." . $subnetNum . ".10-10.88." . $subnetNum . ".254")
/ip/dhcp-server add name=$serverName interface=$vlanName address-pool=$poolName disabled=no
/ip/dhcp-server/network add address=$network gateway=("10.88." . $subnetNum . ".1")
:put ("VLAN " . $vlanId . " (" . $vlanName . ") with DHCP created on bridge " . $bridgeName)
}

# Example usage:
#:add-vlan-dhcp vlan-id=30 vlan-name="vlan30" bridge="bridge1" interface="ether2" subnet=5

