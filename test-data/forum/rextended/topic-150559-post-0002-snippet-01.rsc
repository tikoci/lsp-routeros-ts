# Source: https://forum.mikrotik.com/t/incomprehensible-behavior-of-netwatch-and-a-script-that-imitates-it/150559/2
# Post author: @rextended
# Extracted from: code-block

:if ($checkvds = 0) do={  # $ must used for call variables:if ($vdsdown != true) do={
	/log warning "Host $host is offline"; # useless ";" :set $vdsdown true # $ must not be used on set}
} else={
	:if ($vdsdown != false = true) do={ # better != false instead of =true/log info "Host $host is online"; # useless ";" :set $vdsdown false # $ must not be used on set}
}
