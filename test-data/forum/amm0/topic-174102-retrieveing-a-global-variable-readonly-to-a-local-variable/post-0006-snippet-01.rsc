# Source: https://forum.mikrotik.com/t/retrieveing-a-global-variable-readonly-to-a-local-variable/174102/6
# Topic: Retrieveing a global variable readonly to a local variable
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

# save url once...
/ip/dns/static/add type=TXT text="http://my-ddns-url" name="_ddns_url"
# get url from a script later...
:put [/ip/dns/static { get [find name="_ddns_url"] text }]
