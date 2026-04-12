# Source: https://forum.mikrotik.com/t/proposal-event-driven-scripting/168643/9
# Topic: [PROPOSAL] Event driven scripting
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

/log print follow do={ 
     :put "$.dead $.id  $.nextid  $buffer $message $time $topics"
} where topics~container
