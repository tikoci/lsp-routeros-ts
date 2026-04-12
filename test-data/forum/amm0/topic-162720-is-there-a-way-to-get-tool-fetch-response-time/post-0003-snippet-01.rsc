# Source: https://forum.mikrotik.com/t/is-there-a-way-to-get-tool-fetch-response-time/162720/3
# Topic: Is there a way to get /tool/fetch response time?
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

{ 
  :local start [:timestamp]
  /tool/fetch url="https://wttr.in/Riga+LV?T&format=2" output=user
  :local stop [:timestamp]
  :put ($stop-$start)
}
