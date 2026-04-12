# Source: https://forum.mikrotik.com/t/zerotier-added-to-routeros-v7-1rc2/151475/63
# Topic: ZeroTier added to RouterOS v7.1rc2
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

[skyfi@hap94] /system/resource/cpu> print
Columns: CPU, LOAD, IRQ, DISK
#  CPU   LOAD  IRQ  DISK
0  cpu0  3%    0%   0%  
1  cpu1  1%    0%   0%  
2  cpu2  5%    0%   0%  
3  cpu3  7%    2%   0%  
[skyfi@hap94] /system/resource/cpu> /tool/profile 
Columns: NAME, USAGE
NAME          USAGE
ethernet      0.1% 
console       0.1% 
networking    0.2% 
winbox        0.2% 
management    0.7% 
profiling     0%   
telnet        0%   
unclassified  1.1% 
total         2.4% 
[skyfi@hap94] /system/health/settings> /system/resource/print 
                   uptime: 13h35m12s
                  version: 7.1rc2 (testing)
               build-time: Aug/31/2021 08:07:46
         factory-software: 6.43.10
              free-memory: 52.5MiB
             total-memory: 128.0MiB
                      cpu: ARMv7
                cpu-count: 4
            cpu-frequency: 448MHz
                 cpu-load: 1%
           free-hdd-space: 1292.0KiB
          total-hdd-space: 15.2MiB
  write-sect-since-reboot: 322
         write-sect-total: 11436
               bad-blocks: 0%
        architecture-name: arm
               board-name: hAP ac^2
                 platform: SkyFi-alpha1
                 
[skyfi@hap94] /system/resource/cpu> /interface/lte/monitor 0
            status: connected
             model: MC7455
          revision: SWI9X30C_02.32.11.00
  current-operator: AT&T
        data-class: LTE
    session-uptime: 13h39m16s
              imei: [redacted]
              imsi: [redacted]
              uicc: [redacted]
              rssi: -101dBm
