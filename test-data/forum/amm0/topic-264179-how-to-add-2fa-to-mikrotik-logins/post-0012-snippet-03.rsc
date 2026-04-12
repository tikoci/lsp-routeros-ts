# Source: https://forum.mikrotik.com/t/how-to-add-2fa-to-mikrotik-logins/264179/12
# Topic: How to add 2FA to MikroTik logins
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

/user-manager/router remove [find]
/user-manager/user remove [find]
/radius remove [find]
