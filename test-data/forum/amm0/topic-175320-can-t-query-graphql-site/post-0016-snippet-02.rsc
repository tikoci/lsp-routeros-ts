# Source: https://forum.mikrotik.com/t/cant-query-graphql-site/175320/16
# Topic: Can't Query Graphql site
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

:put ($myarray->"data"->"inventory_model_field_data"->"entities"->0) 
# id=833

:put ($myarray->"data"->"inventory_model_field_data"->"entities"->0->"id")
# 833

# or show it's an array inside the GQL, [:len] will give us the count for it, here just 1
:put [:len ($myarray->"data"->"inventory_model_field_data"->"entities")]        
# 1
