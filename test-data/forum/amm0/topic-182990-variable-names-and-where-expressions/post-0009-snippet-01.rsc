# Source: https://forum.mikrotik.com/t/variable-names-and-where-expressions/182990/9
# Topic: Variable names and where expressions
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

/ip/arp/find [{
  :put $address
  :put $interface
}]
