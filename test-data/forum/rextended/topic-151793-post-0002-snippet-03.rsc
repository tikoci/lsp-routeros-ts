# Source: https://forum.mikrotik.com/t/concatenate-values-to-create-variable-name/151793/2
# Post author: @rextended
# Extracted from: code-block

:global wan1 1
:global variablename "wanSta$wan1"
[:parse ":global $variablename \"10\""]
:put [[:parse ":global $variablename; :return \$$variablename"]]
