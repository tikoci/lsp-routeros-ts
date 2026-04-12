# Source: https://forum.mikrotik.com/t/wgshare-using-ip-cloud-file-share-for-wg-peer-client-config-complaints/182608/1
# Topic: $wgshare - using /ip/cloud file share for WG peer client config & complaints
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

:global wgshare do={
    :local sharedDir "wgshared"
    :local linkExpiresAfter 1d
    :if ($1 = "" or $1 = "help") do={
       :put " $0 - Creates secure file-share link to WG client config "
       :put "\tusage:"
       :put "\t\t$0 <wg-peer-name> [as-value]"
    }
    :local peerid [/interface/wireguard/peers/find name=$1]
    :if ([:len $peerid] = 0) do={ :error " error - peer name $1 not found - see '$0 help' for usage" }
    :local peerconfig ([/interface/wireguard/peers/show-client-config $peerid as-value]->"conf")
    
    # for simplicity use timestamp in config name to make unique
    :local sharedWgConfigFileName "$sharedDir/$1-$[:tonum [:timestamp]].conf"
    
    # the "conf" includes a leading newline, macOS WG does not like that, thus :pick...
    /file/add name=$sharedWgConfigFileName contents=[:pick $peerconfig 1 [:len $peerconfig]]

    # file shares will expire, based on a date, not duration thus [:timestamp]+ 
    :local fileShareId [/ip/cloud/back-to-home-file/add comment="" expires=([:timestamp] + $linkExpiresAfter) path=$sharedWgConfigFileName allow-uploads=no]
    
    # just in case, wait for share creation to actually finish
    :delay 5s
    :local wgconfigUrl [/ip/cloud/back-to-home-file/get $fileShareId direct-url]

    # if using with another command, provide "as-value" to :return the URL
    # for example
    # /tool/email/send ... body="Your WG config can be downloaded here for : '$0 peer1'" ...
    :if ($2 = "as-value") do={
        :return $wgconfigUrl
    }

    # no as-value, output to console
    :put " WireGuard client config for '$1' can be downloaded for $linkExpiresAfter from:"
    :put $wgconfigUrl
}
