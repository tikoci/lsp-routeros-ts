# Source: https://forum.mikrotik.com/t/feature-request-openapi-for-rest-api/149360/11
# Topic: Feature Request : OpenAPI for REST API
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

:do {
   /console/inspect request=syntax path=ip,address,add,interface
} on-error={:put "got error"}
