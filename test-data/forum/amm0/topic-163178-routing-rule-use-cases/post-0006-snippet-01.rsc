# Source: https://forum.mikrotik.com/t/routing-rule-use-cases/163178/6
# Topic: Routing rule use cases
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

/routing rule {
    add action=lookup disabled=$norules dst-address=10.0.0.0/8 table=main
    add action=lookup disabled=$norules dst-address=172.16.0.0/12 table=main
    add action=lookup disabled=$norules dst-address=192.168.0.0/16 table=main
}
