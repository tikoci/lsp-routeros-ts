# Source: https://forum.mikrotik.com/t/crs-vlan-add-untagged-interfaces-via-script/150066/10
# Post author: @rextended
# Extracted from: code-block

>

for add also all type of physical ethernet is better this regular experssion than only "sfp*" :

```text
default-name~"(combo|ether|sfp)*"
