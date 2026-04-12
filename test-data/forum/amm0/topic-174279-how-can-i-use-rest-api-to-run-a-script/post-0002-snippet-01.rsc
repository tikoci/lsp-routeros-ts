# Source: https://forum.mikrotik.com/t/how-can-i-use-rest-api-to-run-a-script/174279/2
# Topic: How can i use rest api to run a script?
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

USER='admin:pass' 
ROUTER=192.168.20.1
curl -k -u $USER -X POST -H "Content-Type: application/json" https://$ROUTER/rest/tool/wol --data '{"mac": "AA:AA:AA:AA:AA:AA"}'
