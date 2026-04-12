# Source: https://forum.mikrotik.com/t/zerotier-on-mikrotik-a-rosetta-stone-v7-1-1/155978/5
# Topic: ZeroTier on Mikrotik – a rosetta stone [v7.1.1+]
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

> /zerotier/peer/print 

Columns: INSTANCE, ZT-ADDRESS, LATENCY, ROLE, PATH
# INSTANCE  ZT-ADDRESS  LATENCY  ROLE    PATH                                                            
0 zt1       XXf864ae71  228ms    PLANET  active,preferred,50.7.252.138/9993,recvd:4s515ms,sent:9s789ms   
1 zt1       XX8cde7390  104ms    PLANET  active,preferred,103.195.103.66/9993,recvd:4s629ms,sent:9s789ms 
2 zt1       XXfe04eca9  200ms    PLANET  active,preferred,84.17.53.155/9993,recvd:4s547ms,sent:4s736ms   
3 zt1       XXfe9efea9  48ms     PLANET  active,preferred,104.194.8.134/9993,recvd:4s694ms,sent:17s105ms 
4 zt1       XX799d8a6  82ms     LEAF    active,preferred,35.226.205.67/57571,recvd:7s445ms,sent:7s526ms 
5 zt1       1fceb9a1b0           LEAF                                                                    
6 zt1       XXd56eef8d  58ms     LEAF    active,preferred,162.236.246.88/9993,recvd:17s44ms,sent:17s105ms

> /ip/firewall/connection/print where dst-address~"9993" timeout<30s

Flags: C - CONFIRMED; s - SRCNAT
Columns: PROTOCOL, SRC-ADDRESS, DST-ADDRESS, TIMEOUT, ORIG-RATE, REPL-RATE, ORIG-PACKETS, REPL-PACKETS, ORIG-BYTES, REPL-BYTES
 #    PROTOCOL  SRC-ADDRESS            DST-ADDRESS        TIMEOUT  ORIG-RATE  REPL-RATE  ORIG-PACKETS  R  ORIG-BYTES  REPL-BYTES
13 C  udp       166.XXX.XXX.14:57447   50.7.252.138:9993  0s       0bps       0bps                  2  0         330           0
15 C  udp       166.XXX.XXX.14:57447   84.17.53.155:9993  0s       0bps       0bps                  1  0         165           0
27 Cs udp       192.168.202.197:45463  84.17.53.155:9993  2s       0bps       0bps                  2  0         330           0
28 Cs udp       192.168.202.197:45463  50.7.252.138:9993  2s       0bps       0bps                  2  0         330           0
