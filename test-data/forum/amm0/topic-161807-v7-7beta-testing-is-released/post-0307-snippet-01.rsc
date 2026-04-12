# Source: https://forum.mikrotik.com/t/v7-7beta-testing-is-released/161807/307
# Topic: v7.7beta [testing] is released!
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

/disk/print detail 
Flags: X - disabled, E - empty, M - mounted, F - formatting; 
f - raid-member-failed; r - raid-member; p - partition; m - manual-partition; 
o - read-only 
 0        slot="sata1" slot-default="sata1" parent=none device="sda" 
          model="FORESEE 64GB SSD" serial="I31214J003472" fw-version="V3.24" 
          size=64 023 257 088 interface="SATA 6.0 Gbps" interface-speed=6.0Gbps 
          raid-master=none nvme-tcp-export=no iscsi-export=no nfs-export=no 
          smb-export=no 

 1 M  p   slot="sata1-part1" slot-default="sata1-part1" parent=sata1 
          device="sda1" uuid="2a20d81d-1b436fbd-ac8bee92-bd0022b2" fs=ext4 
          serial="@512-64017354240" size=64 017 353 728 free=56 592 363 520 
          partition-number=1 partition-offset=512 partition-size=64 017 353 728 
          raid-master=none nvme-tcp-export=no iscsi-export=no nfs-export=no 
          smb-export=no 
[code]
