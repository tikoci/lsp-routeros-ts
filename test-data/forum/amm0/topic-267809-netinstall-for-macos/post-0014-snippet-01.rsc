# Source: https://forum.mikrotik.com/t/netinstall-for-macos/267809/14
# Topic: NetInstall for MacOS?
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

(initramfs)  ip link set enp0s1 up
(initramfs)  ip addr add 192.168.88.99/24 dev enp0s1
(initramfs)   mkdir /app
(initramfs)  mount /dev/vdb /app
[   19.748968] EXT4-fs (vdb): mounting ext2 file system using the ext4 subsystem
[   19.750767] EXT4-fs (vdb): warning: mounting unchecked fs, running e2fsck is recommended
[   19.761391] EXT4-fs (vdb): mounted filesystem without journal. Opts: (null). Quota mode: none.
(initramfs)  cd /app
(initramfs)  ./netinstall-cli -r -v -b -a 192.168.88.101 *-arm.npk
[   20.637695] process '/netinstall-cli' started with executable stack
Version: 7.21(2026-01-12 14:08:02)
Will remove branding
Will reset to default config
Using interface enp0s1
Using interface enp0s1
Waiting for Link-UP on enp0s1
Waiting for RouterBOARD...
Could not determine architecture for BOOTP request from 00:E0:4C:04:14:9D
Could not determine architecture for BOOTP request from 00:E0:4C:04:14:9D
Could not determine architecture for BOOTP request from 74:4D:28:8F:E4:85
Could not determine architecture for BOOTP request from 00:E0:4C:04:14:9D
Could not determine architecture for BOOTP request from 00:E0:4C:04:14:9D
Received a BOOTP request from 74:4D:28:8F:E4:85 (arm)
Assigned 192.168.88.101 to 74:4D:28:8F:E4:85
Booting device 74:4D:28:8F:E4:85 into setup mode
Formatting device 74:4D:28:8F:E4:85
Could not determine architecture for BOOTP request from 00:E0:4C:04:14:9D
Sending packages to device 74:4D:28:8F:E4:85
Packages sent to device 74:4D:28:8F:E4:85
Rebooting device 74:4D:28:8F:E4:85
Successfully finished installing device 74:4D:28:8F:E4:85
