# Source: https://forum.mikrotik.com/t/suppress-output-from-ping-in-script/79536/6
# Post author: @rextended
# Extracted from: code-block

:global pingResult -1
{
    :local jobID [:execute ":set pingResult [:ping count=5 1.1.1.1]"]
    :while ([:len [/system script job find where .id=$jobID]] > 0) do={
        :delay 1s
    }
}
:put $pingResult
