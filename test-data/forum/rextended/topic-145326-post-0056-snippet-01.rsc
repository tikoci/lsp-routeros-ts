# Source: https://forum.mikrotik.com/t/persistent-environment-variables/145326/56
# Post author: @rextended
# Extracted from: code-block

:if ($varName = "") do={ :return [:nothing] }

:local varID [find where name=$varName]

:if ($delete = "yes") do={ remove $varID ; :return [:nothing] }

:if ($valuePresent) do={ 
    :if ([:len $varID] = 0) do={
        add name=$varName regexp=$varNewValue
        :set varID [find where name=$varName]
    } else={
        set $varID regexp=$varNewValue
    }
}

:if ([:len $varID] != 0) do={ :return [get $varID regexp] }

:return [:nothing]
