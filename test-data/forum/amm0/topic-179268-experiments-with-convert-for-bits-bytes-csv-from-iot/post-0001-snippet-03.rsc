# Source: https://forum.mikrotik.com/t/experiments-with-convert-for-bits-bytes-csv-from-iot/179268/1
# Topic: Experiments with [:convert] for bits&bytes +CSV from /iot/...
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

# using "$decodeDriago terse=yes" 
:put "... or using 'terse=yes' to not output raws ..."
:put [:serialize to=json [$decodeDriago "CBE90A6D019D0109E97FFF" terse="yes"] options=json.pretty]
