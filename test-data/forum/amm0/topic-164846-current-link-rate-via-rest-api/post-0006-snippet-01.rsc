# Source: https://forum.mikrotik.com/t/current-link-rate-via-rest-api/164846/6
# Topic: Current link rate via Rest API
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

curl -X POST -sS -u $ROSUSER $ROSREST/interface/ethernet/monitor --json `jo numbers="*1" once="true" ".proplist"="name,status"`  | jq
[
  {
    "name": "ether1",
    "status": "no-link"
  }
]

curl -X POST -sS -u $ROSUSER $ROSREST/interface/ethernet/monitor --json `jo numbers="*1" once="true" ".proplist"="name,status"`  | jq '.[]'
{
  "name": "ether1",
  "status": "no-link"
}

curl -X POST -sS -u $ROSUSER $ROSREST/interface/ethernet/monitor --json `jo numbers="*1" once="true" ".proplist"="name,status"`  | jq '.[].name'
"ether1"
