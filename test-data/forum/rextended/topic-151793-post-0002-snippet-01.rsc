# Source: https://forum.mikrotik.com/t/concatenate-values-to-create-variable-name/151793/2
# Post author: @rextended
# Extracted from: code-block

:global $wan1 1;
:put ("wanSta" . $wan1);
:set ("wanStatus" . $wanIndex) 10
