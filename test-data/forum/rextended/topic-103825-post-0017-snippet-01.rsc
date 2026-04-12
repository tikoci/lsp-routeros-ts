# Source: https://forum.mikrotik.com/t/wi-fi-on-off-switch/103825/17
# Post author: @rextended
# Extracted from: code-block

/system leds
:if ([:len [find where leds=user-led]] < 1) do={add leds=user-led type=on}
:log info "Premuto Pulsante"
/interface wireless
:if ([get [find default-name=wlan1] disabled]) do={
    :log info "Wi-Fi Attivato"
    set [find] disabled=no
    /sys leds set [find where leds=user-led] type=on
} else={
    :log info "Wi-Fi Disattivato"
    set [find] disabled=yes
    /sys leds set [find where leds=user-led] type=off
}
