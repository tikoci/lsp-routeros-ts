# Source: https://forum.mikrotik.com/t/is-there-a-way-to-get-tool-fetch-response-time/162720/4
# Topic: Is there a way to get /tool/fetch response time?
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

{ :local start [:timestamp]; /tool/fetch url="https://wttr.in/Riga+LV?T&format=2" output=none; :local stop [:timestamp]; :put ($stop-$start)}

      status: finished
  downloaded: 0KiBC-z pause]
       total: 0KiB
    duration: 0s

00:00:01.099018660
