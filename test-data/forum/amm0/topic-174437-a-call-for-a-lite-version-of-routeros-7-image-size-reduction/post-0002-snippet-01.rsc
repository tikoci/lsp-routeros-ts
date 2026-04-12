# Source: https://forum.mikrotik.com/t/a-call-for-a-lite-version-of-routeros-7-image-size-reduction/174437/2
# Topic: A call for a "lite" version of routeros 7 (image size reduction)
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

find . -type f -exec ls -lh {} + | awk '{print $5, $9}' | sort -hr
1.9M ./nova/lib/console/1073741824.mem
1.4M ./nova/bin/route
1.2M ./nova/bin/net
1.1M ./lib/libcrypto.so.1.0.0
703K ./nova/bin/sys2
673K ./lib/modules/5.6.3/drivers/net/prestera_dx_mac.ko
634K ./bndl/wifi/nova/bin/ww2
576K ./nova/bin/parser
480K ./bndl/ppp/nova/bin/ppp
449K ./bndl/security/nova/bin/ipsec
411K ./lib/modules/5.6.3/kernel/fs/ext4/ext4.ko
407K ./lib/modules/5.6.3/kernel/net/ipv6/ipv6.ko
393K ./lib/libumsg.so
267K ./nova/bin/bridge2
234K ./lib/libc.so
227K ./bndl/hotspot/nova/bin/hotspot
211K ./lib/libucrypto.so
210K ./nova/bin/lcdstat
201K ./lib/modules/5.6.3/kernel/drivers/usb/mu3h/mu3h-xhci-hcd.ko
199K ./nova/bin/cerm
178K ./nova/bin/snmp
176K ./lib/modules/5.6.3/kernel/drivers/ata/libata.ko
175K ./bndl/dhcp/nova/bin/dhcp
173K ./lib/modules/5.6.3/kernel/drivers/usb/core/usbcore.ko
171K ./bndl/security/nova/bin/ssh
171K ./bndl/ipv6/nova/lib/console/1212153856.mem
169K ./nova/etc/pciinfo/system.x3
166K ./nova/bin/smb
166K ./nova/bin/diskd
166K ./bndl/wifi/nova/lib/console/1275068416.mem
162K ./lib/modules/5.6.3/drivers/net/packet_hook.ko
155K ./lib/modules/5.6.3/net/bridge/bridge2.ko
148K ./lib/modules/5.6.3/drivers/net/quectel_mhi.ko
139K ./nova/bin/wproxy
139K ./nova/bin/login
138K ./nova/bin/graphing
138K ./lib/librappsup.so
134K ./nova/bin/quickset
131K ./bndl/ppp/nova/lib/console/1090519040.mem
124K ./nova/etc/leds/system.x3
121K ./lib/modules/5.6.3/kernel/drivers/net/bonding/bonding.ko
121K ./etc/license
118K ./nova/bin/cloud
116K ./lib/modules/5.6.3/kernel/drivers/scsi/scsi_mod.ko
115K ./lib/modules/5.6.3/kernel/net/netfilter/nf_conntrack.ko
106K ./nova/bin/www
106K ./nova/bin/upnp
103K ./lib/modules/5.6.3/kernel/drivers/mmc/core/mmc_core.ko
102K ./nova/bin/ssld
102K ./nova/bin/resolver
101K ./lib/modules/5.6.3/drivers/net/usb/mbim.ko
100K ./lib/modules/5.6.3/kernel/drivers/usb/serial/option.ko
100K ./lib/modules/5.6.3/kernel/drivers/usb/host/xhci-hcd.ko
