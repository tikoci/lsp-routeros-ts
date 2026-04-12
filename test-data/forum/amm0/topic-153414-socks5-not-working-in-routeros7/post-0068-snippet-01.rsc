# Source: https://forum.mikrotik.com/t/socks5-not-working-in-routeros7/153414/68
# Topic: socks5 not working in routeros7 !
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

/system/device-mode/update mode=enterprise socks=no pptp=no l2tp=no proxy=no romon=no smb=no 
# physically hit the reset or mode button 
# note: instruction say unplugging, but that didn't work on RB5009, Audience - hit [i]some[/i] button..
# after coming back...
/system/device-mode/print
#         mode: enterprise
#         socks: no
#         pptp: no
#         l2tp: no
#         romon: no
#         proxy: no
#         smb: no
/ip/socks/set enabled=yes 
/ip/socks/print
#        ;;; inactivated, not allowed by device-mode
#         enabled: yes
