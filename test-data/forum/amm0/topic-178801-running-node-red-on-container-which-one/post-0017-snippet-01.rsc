# Source: https://forum.mikrotik.com/t/running-node-red-on-container-which-one/178801/17
# Topic: Running Node Red on container, which one?
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

:global containerImageTag "nodered/node-red:3.1.12-minimal"

:global makeContainer do={
    :local tag $1
    :global containerImageTag
    :if ([:typeof $tag]!="str") do={ :set tag $containerImageTag }
    
    # calc defaults
    :local cid $id
    :if ([:typeof $cid]!="num" or $cid > 0 or $cid < 255) do={ :set cid [:rndnum from=101 to=199] }
    :local basedisk "usb1"
    :local prefix "172.19"

    # final paths/names
    :local rootdir "$basedisk/containers/$tag/root-$cid"
    :local datadir "$basedisk/containers/$tag/data-$cid"
    :local subnet "$prefix.$cid"
    :local label "$tag $cid" 
    :local vethName "veth$cid-$tag"
    
    :put " Before proceeding, review the following is what you expect:"
    :put " - pull '$tag' from $[/container/config/get registry-url]"
    :put " - temporary image will be stored in $[/container/config/get tmpdir]"
    :put " - container will be installed to root-dir=$rootdir"
    :put " - VETH will use IP $subnet.1/24, and assign a gateway at $subnet.254/24"
    :put " - using '$cid-$tag' as envlist, with the id=$cid param in LOCAL_INSTANCE_ID env"    
    :put " - mount for local data to $datadir"    

    :if ([/terminal/ask "Enter 'y' if to continue.  Any other key exits without any action."] = "y") do={
        /interface veth add name=$vethName address="$subnet.1/24" gateway="$subnet.254" comment=$label
        /ip address add address="$subnet.254/24" interface=$vethName comment=$label
        /container env add name="$cid-$tag" key="LOCAL_INSTANCE_ID" value=$cid comment=$label
        /container mounts add name="$cid-$tag" dst="/data" src=$datadir comment=$label
        /container add remote-image=$tag interface=$vethName root-dir=$rootdir mounts="$cid-$tag" logging=yes envlist="$cid-$tag" comment=$label

        /ip/firewall/nat add chain=dstnat action=dst-nat protocol=tcp port=1880 to-addresses=172.19.132.1 to-ports=1880 comment=$label disabled=yes
    }
    /container
    :delay 5s
    print
}

:global removeContainer do={
    # params tag= to search in comment to remove - be careful 
    :local label $tag
    :global containerImageTag
    :if ([:typeof $label] != "str") do={
        :set label $containerImageTag
    }
    /interface veth remove [find comment~$label]
    /ip address remove [find comment~$label]
    /container remove [find comment~$label]
    /container env remove [find comment~$label]
    /container mounts remove [find comment~$label]
    /ip/firewall/nat remove [find comment~$label] 
}
