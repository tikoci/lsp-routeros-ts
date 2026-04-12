# Source: https://forum.mikrotik.com/t/user-manager-export-users/180659/3
# Topic: User Manager export users
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

:foreach k,v in=[/user-manager/user/print detail as-value]  do={
    :local attrs ([/user-manager/user/monitor ($v->".id") once as-value], $v)
    :put $attrs
}
