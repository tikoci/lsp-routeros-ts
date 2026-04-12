# Source: https://forum.mikrotik.com/t/experiments-with-convert-for-bits-bytes-csv-from-iot/179268/1
# Topic: Experiments with [:convert] for bits&bytes +CSV from /iot/...
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

# make it readable using new "json.pretty"
:global myDriagoData [$decodeDriago "CBE90A6D019D0109E97FFF"]
:put [:serialize to=json $myDriagoData options=json.pretty]
