# Source: https://forum.mikrotik.com/t/add-more-logged-detail-to-fetch/178998/5
# Topic: Add more logged detail to fetch?
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

/system/logging/action
add name=fetch target=memory
add name=script target=memory
add memory-lines=20 name=recentonly target=memory
/system logging
add action=script topics=script
add action=echo topics=fetch
add action=fetch topics=fetch
