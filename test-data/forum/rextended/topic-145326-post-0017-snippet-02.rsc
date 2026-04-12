# Source: https://forum.mikrotik.com/t/persistent-environment-variables/145326/17
# Post author: @rextended
# Extracted from: code-block

:if ($vtype="bool") do={:execute ":global $vname [:tobool $vvalue]"}
