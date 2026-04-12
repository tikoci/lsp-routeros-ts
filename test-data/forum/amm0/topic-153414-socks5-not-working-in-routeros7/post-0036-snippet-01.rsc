# Source: https://forum.mikrotik.com/t/socks5-not-working-in-routeros7/153414/36
# Topic: socks5 not working in routeros7 !
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

[skyfi@M171-Yizi] > /system/device-mode/print
       mode: enterprise
      socks: no
       pptp: no
       l2tp: no
      proxy: no
        smb: no
  container: no
[skyfi@M171-Yizi] > /ip/socks/set enabled=yes 
# NOTE: it doesn't warn that it does nothing, but "print" does
[skyfi@M171-Yizi] > /ip/socks/print
                       ;;; inactivated, not allowed by device-mode
                  enabled: yes
                     port: 1080
  connection-idle-timeout: 2m
          max-connections: 200
                  version: 4
              auth-method: none
[skyfi@M171-Yizi] >
