# Source: https://forum.mikrotik.com/t/no-lte-connection-with-sxt-nor-atl-but-within-range-of-tower-bands-13-66/169189/16
# Topic: No LTE connection with SXT nor ATL, but within range of tower; bands 13 & 66.
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

# set package update channel (other option is "channel=testing")
/system package update set channel=stable

# always update boot firmware after router version update
/system routerboard settings set auto-upgrade=yes

# download RouterOS (will skip if already up-to-date)
/system package update download 

# if install is needed, reboot
/system reboot

# and after reboot, reboot again to update boot firmware (set above, 2nd reboot will cause a /system/routerboard/update)
/system reboot

# update lte fireware - again will not update if already up-to-date
/interface lte firmware-upgrade [find] upgrade=yes

# set upstream DNS server (e.g. you likely do not want to use LTE carrier's)
/ip dns set servers=208.67.222.222,1.1.1.1,8.8.8.8,9.9.9.9

# try using SIM's store APN which is control use-network-apn=yes)
/interface lte apn set [find default] use-network-apn=yes use-peer-dns=no add-default-route=yes default-route-distance=11
/interface lte { set [find] apn-profile=[apn find default] }

# restart LTE interface
/interface lte { disable [find]; :delay 5s; enable [find]; :delay 5s }

# check internet is working
/tool ping 8.8.8.8 count=10
/tool ping [:resolve www.mikrotik.com] count=10

# if failed, sometime the SIM may not have the APN to use automatically...

# add carrier APN profiles to select, here ones for the United States:
/interface lte apn add apn=vzwinternet default-route-distance=11 name="Verizon" use-peer-dns=no use-network-apn=no
/interface lte apn add apn=broadband default-route-distance=11 name="AT&T" use-peer-dns=no use-network-apn=no
/interface lte apn add apn=fast.t-mobile.com default-route-distance=11 name="T-Mobile" use-peer-dns=no use-network-apn=no

# and set LTE to use the right one...
/interface/lte { set [find] apn-profile="AT&T" }

# restart LTE & test again...
/interface lte { disable [find]; :delay 5s; enable [find]; :delay 5s }
/tool ping 8.8.8.8 count=10
/tool ping [:resolve www.mikrotik.com] count=10

# still doesn't work or show status...
/interface lte monitor [find]

# to show LTE config...
/interface lte export

# to enable LTE "debug" logging 
/system/logging/add topics=lte,!packet,!raw
