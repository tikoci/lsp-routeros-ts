# Source: https://forum.mikrotik.com/t/feature-request-openapi-for-rest-api/149360/16
# Topic: Feature Request : OpenAPI for REST API
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

:put [:typeof [/console/inspect request=error input=":put [/system/identity/get name]"]]
# nil
:put [:typeof [/console/inspect request=error input="/somebadcommand"]]                                
# nil
