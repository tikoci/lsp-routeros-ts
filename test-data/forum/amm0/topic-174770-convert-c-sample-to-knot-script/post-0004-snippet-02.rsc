# Source: https://forum.mikrotik.com/t/convert-c-sample-to-knot-script/174770/4
# Topic: Convert C sample to KNOT script
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

{
:global hex2ints
:local adhex "0dff5900035e42000024684e29e80302e5fe"
:local bytes [$hex2ints $adhex]
:put $bytes
:local temp (($bytes->6) & 0x7f)
:put "y=$($bytes->13) x=$($bytes->14) temp=$temp" 
}
