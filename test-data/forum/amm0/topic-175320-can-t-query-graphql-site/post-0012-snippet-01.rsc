# Source: https://forum.mikrotik.com/t/cant-query-graphql-site/175320/12
# Topic: Can't Query Graphql site
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

{
# variables for fetch
:local gqlurl "https://somewebsite/api/graphql"
:local query "{\"query\":\"query accountid{accounts(id:2){entities{name}}}\"}"
:local contenttype "application/json"
:local bearer "eyJ0e...LATI"
:local headers "Content-Type: $contenttype,Authorization: Bearer $bearer"

# use variables to make fetch call and store into new "fetched" variable
:local fetched [/tool fetch url=$gqlurl http-method=post http-header-field=$headers http-data=$query output=user as-value]
:put $fetched

# could check results here, skipping for example...

# store the resulted data which is JSON in a string type
:local json ($fetched->"data")
:put $json

# convert JSON string to RouterOS array
:local results [:deserialize $json from=json]
:put $results

# results should be an array key-value map, so should be able to use RouterOS array accessors against the GraphQL query results 
:put ($results->"accountid")
}
