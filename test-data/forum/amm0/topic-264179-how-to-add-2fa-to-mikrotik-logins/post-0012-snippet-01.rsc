# Source: https://forum.mikrotik.com/t/how-to-add-2fa-to-mikrotik-logins/264179/12
# Topic: How to add 2FA to MikroTik logins
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

:global userManagerDisk ""
/user-manager/database set db-path="$userManagerDisk/user-manager"

:global radiusSharedSecret [:rndstr length=40]

/user-manager set enabled=yes
/user-manager/router add address=127.0.0.1 name=SystemUser2FA shared-secret=$radiusSharedSecret disabled=no

/radius add address=127.0.0.1 secret=$radiusSharedSecret service=login
/radius/incoming set accept=yes

/user/aaa set use-radius=yes
