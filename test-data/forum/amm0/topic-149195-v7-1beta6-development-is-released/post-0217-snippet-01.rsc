# Source: https://forum.mikrotik.com/t/v7-1beta6-development-is-released/149195/217
# Topic: v7.1beta6 [development] is released!
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

/routing/table/add name=ecmp2 comment=ecmp2
/ip/route/add routing-table=ecmp2 gateway=lte1 comment=ecmp2
/ip/route/add routing-table=ecmp2 gateway=lte2 comment=ecmp2
