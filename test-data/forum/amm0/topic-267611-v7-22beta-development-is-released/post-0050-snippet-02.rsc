# Source: https://forum.mikrotik.com/t/v7-22beta-development-is-released/267611/50
# Topic: V7.22beta [development] is released!
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

/ip/service/print where name=www-ssl or name=reverse-pr
oxy or name=rproxy
Flags: D - DYNAMIC; X - DISABLED, I - INVALID; c - CONNECTION
Columns: NAME, PORT, PROTO, CERTIFICATE, VRF, MAX-SESSIONS
#     NAME            PORT  PROTO  CERTIFICATE             VRF   MA
0  X  www-ssl          443  tcp    Lets encrypt1767817675  main  20
1     reverse-proxy    443  tcp    Lets encrypt1767817675  main  20
2 D c reverse-proxy    443  tcp                                    
3 D c reverse-proxy    443  tcp                                    
4 D c rproxy         44730  tcp                                    
5 D c rproxy         44732  tcp
