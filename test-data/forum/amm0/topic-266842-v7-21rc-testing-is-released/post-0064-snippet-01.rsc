# Source: https://forum.mikrotik.com/t/v7-21rc-testing-is-released/266842/64
# Topic: V7.21rc [testing] is released!
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

[admin@MikroTik] > /app/setup
Choose disk to install apps to. Disk needs to be formatted with ext4 or btrfs 
filesystem and mounted, you can format your disk in /disk menu. Note that disk 
needs to perform reasonably well for optimum experience. At least 100MB/s 
sequential read/write speed and 10K random iops recommended. You can verify 
your disk performance with /disk/test command. If you don't see your disk here 
as an option, it means it is not formatted with suitable filesystem or not 
mounted, check /disk menu. 

apps disk: *FFFFFFFF

[admin@MikroTik] > /disk/print
Flags: B - BLOCK-DEVICE; M - MOUNTED
Columns: SLOT, MOUNT-POINT, MODEL, SERIAL, INTERFACE, SIZE, FREE, USE, FS
#    SLOT   MOUNT  MODEL   SER  INTE            SIZE            FREE  USE  FS  
0 BM pcie1  pcie1  virtio  vda  PCIe  10 737 418 240  10 463 997 952  0%   ext4
