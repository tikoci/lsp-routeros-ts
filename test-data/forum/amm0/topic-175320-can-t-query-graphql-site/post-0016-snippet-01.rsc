# Source: https://forum.mikrotik.com/t/cant-query-graphql-site/175320/16
# Topic: Can't Query Graphql site
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

# string here, but results from ([/tool/fetch ...]->"data") as "myjson" variable...
 :global myjson "{\"data\":{\"inventory_model_field_data\":{\"entities\":[{\"id\":\"833\"}]}}}"

# in V7.13+, :deserialize get the RouterOS array from the \$myjson
:global myarray [:deserialize from=json $myjson]

# NOW... if you just print it, it does not look like an array 
:put $myarray
#data=inventory_model_field_data=entities=id=833
# i.e. This is how RouterOS compact them...
