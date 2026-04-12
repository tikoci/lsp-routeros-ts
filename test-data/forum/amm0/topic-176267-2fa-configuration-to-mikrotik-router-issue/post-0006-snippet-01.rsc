# Source: https://forum.mikrotik.com/t/2fa-configuration-to-mikrotik-router-issue/176267/6
# Topic: 2FA Configuration to Mikrotik router issue
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

# on user manager you point need to add the "Mikrotik-Group" attribute at least (perhaps more attributes?)
/user-manager user [find name="user-manager-admin-with-2fa-stuff-set"] attributes=Mikrotik-Group:write

# on routeros users, create a default group with no permissions as the default if Mikrotik-Group is not set
/user group add name=none

# tell routeros to use the radius server (user-manager)
/user/aaa/set use-radius=yes default-group=none 

# if desired, to prevent radius from create a full admin
/user/aaa/set exclude-groups=full
