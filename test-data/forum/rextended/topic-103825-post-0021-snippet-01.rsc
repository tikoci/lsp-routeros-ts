# Source: https://forum.mikrotik.com/t/wi-fi-on-off-switch/103825/21
# Post author: @rextended
# Extracted from: code-block

:log info "Button Pressed"
/interface wireless
:if ([get [find where default-name=wlan1] disabled]) do={
    :log info "Wi-Fi ON"
    set [find] disabled=no
} else={
    :log info "Wi-Fi OFF"
    set [find] disabled=yes
}
