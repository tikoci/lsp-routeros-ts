# Source: https://forum.mikrotik.com/t/help-decimal-value-in-tool-netwatch-script/169571/3
# Topic: [HELP] Decimal value in tool netwatch script
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

{
:local ns 25543
:put [:totime "$($ns/1000000).$($ns/1000)$($ns%1000)"]
}
# 00:00:00.255340
