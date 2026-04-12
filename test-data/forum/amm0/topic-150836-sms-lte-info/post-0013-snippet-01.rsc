# Source: https://forum.mikrotik.com/t/sms-lte-info/150836/13
# Topic: SMS LTE Info
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

/log info [:put "my code is here"]
   # my code is here
/log print where topics~"script" time>5m
   # apr/22 18:13:21 script,info my code is here
