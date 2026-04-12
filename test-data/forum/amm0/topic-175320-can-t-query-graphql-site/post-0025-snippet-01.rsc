# Source: https://forum.mikrotik.com/t/cant-query-graphql-site/175320/25
# Topic: Can't Query Graphql site
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

{
:local searchtext "000000000"
:local gurl "...."
:local auth "...."
:local header "Content-Type:application/json, Authorization: $auth"
:local gql [:toarray ""]
:set ($gql->"query") "query inventory{inventory_model_field_data(general_search:\"$searchtext\"{entities{id}}}"
# or using variables, to do variables on the GQL backend....
#:set ($gql->"variables") [:toarray ""]
#:set ($gql->"variables"->"searchtext") $searchtext
#:set ($gql->"query") "query inventory{inventory_model_field_data(general_search: \$searchtext {entities{id}}}"
:local httpdata [:serialize to=json $gql]
:put $httpdata
:local fetched [/tool fetch url=$gurl http-method=post http-header-field=$header http-data=$httpdata mode=https output=user as-value]
:put $fetched
:local results [:deserialize from=json ($fetched->"data")]
:put $results
:put ($results->"data"->"inventory_model_field_data"->"entities"->0->"id")
}
