# Source: https://forum.mikrotik.com/t/can-someone-give-me-the-command-line-to-delete-pppoe-out1/167597/14
# Topic: Can someone give me the command line, to delete pppoe-out1
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

/interface pppoe-client disable [find interface="ether2"]
:delay 30
/interface pppoe-client set user="XXXX" password="1234" enabled=yes [find interface="ether2"]
