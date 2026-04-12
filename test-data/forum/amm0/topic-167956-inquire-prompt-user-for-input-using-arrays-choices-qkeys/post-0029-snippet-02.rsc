# Source: https://forum.mikrotik.com/t/inquire-prompt-user-for-input-using-arrays-choices-qkeys/167956/29
# Topic: $INQUIRE - prompt user for input using arrays +$CHOICES +$QKEYS
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

:global count 0
$QKEYS ({
       "+"={"+1";(>[{:global count; :set count ($count+1); :return $count}])}
       "-"={"-1";(>[{:global count; :set count ($count-1); :return $count}])} 
})
