# Source: https://forum.mikrotik.com/t/deserialize-json-skin-vs-api/176336/4
# Topic: Deserialize .json SKIN vs. API
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

/system script
add name="config.json" source=\
    "{\r\
    \n\"myname\": \"amm0\",\r\
    \n\"branding\": \"mariokart\"\r\
    \n}"

:put [:deserialize from=json [/system/script/get "config.json" source]]
