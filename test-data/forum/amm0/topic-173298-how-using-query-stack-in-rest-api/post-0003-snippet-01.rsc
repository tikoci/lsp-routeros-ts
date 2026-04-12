# Source: https://forum.mikrotik.com/t/how-using-query-stack-in-rest-api/173298/3
# Topic: How using .query stack in REST API?
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

USER=admin ROUTER=192.168.88.1; curl -l -u $USER -X POST http://$ROUTER/rest/ip/firewall/address-list/print -H "Content-Type: application/json" --data '{".query": ["list=a","list=b","list=c","#|","#|","address=159.148.147.252","#&"]}' -- | jq '.'
[
  {
    ".id": "*A1E70",
    "address": "159.148.147.252",
    "comment": "ftp.mikrotik.com",
    "creation-time": "2024-02-01 19:11:41",
    "disabled": "false",
    "dynamic": "true",
    "list": "a"
  },
  {
    ".id": "*A1E71",
    "address": "159.148.147.252",
    "comment": "ftp.mikrotik.com",
    "creation-time": "2024-02-01 19:11:51",
    "disabled": "false",
    "dynamic": "true",
    "list": "b"
  },
  {
    ".id": "*A1E72",
    "address": "159.148.147.252",
    "comment": "ftp.mikrotik.com",
    "creation-time": "2024-02-01 19:12:12",
    "disabled": "false",
    "dynamic": "true",
    "list": "c"
  }
]
