# Source: https://forum.mikrotik.com/t/prevent-the-script-from-running-if-it-is-already-running/167618/3
# Post author: @rextended
# Extracted from: code-block

:local UniqueScriptID "QnJhdm8h"
:local ThisScriptName [/system script get ([find where source~"$UniqueScriptID"]->0) name]
:local AlreadyRunning "Script $ThisScriptName already running"

:if ([:len [/system script job find where script=$ThisScriptName]] > 1) do={:log error $AlreadyRunning; :error $AlreadyRunning}

# simulating script running for 60 seconds
:delay 60s
