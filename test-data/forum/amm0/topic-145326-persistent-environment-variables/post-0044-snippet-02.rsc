# Source: https://forum.mikrotik.com/t/persistent-environment-variables/145326/44
# Topic: Persistent Environment Variables
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

:global optype (>[:do {:put "$1"}])

:put [:typeof $optype]             
# op

$optype "hmm"                      
# hmm

:put $optype
# (evl (evl /docommand=;(evl (evl /putmessage=$1))))
