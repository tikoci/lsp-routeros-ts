# Source: https://forum.mikrotik.com/t/current-link-rate-via-rest-api/164846/5
# Topic: Current link rate via Rest API
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

ROSUSER=admin:password
ROSREST=https://192.168.88.1:443/rest
curl -X POST  -u $ROSUSER $ROSREST/interface/ethernet/monitor --json `jo numbers="*1" once="true" ".proplist"="name,status"`
