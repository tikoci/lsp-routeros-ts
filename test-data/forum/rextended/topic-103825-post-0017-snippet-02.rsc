# Source: https://forum.mikrotik.com/t/wi-fi-on-off-switch/103825/17
# Post author: @rextended
# Extracted from: code-block

/system routerboard mode-button
set enabled=yes on-event="/system leds\r\
    \n:if ([:len [find where leds=user-led]] < 1) do={add leds=user-led type=on}\r\
    \n:log info \"Premuto Pulsante\"\r\
    \n/interface wireless\r\
    \n:if ([get [find default-name=wlan1] disabled]) do={\r\
    \n :log info \"Wi-Fi Attivato\"\r\
    \n set [find] disabled=no\r\
    \n /sys leds set [find where leds=user-led] type=on\r\
    \n} else={\r\
    \n :log info \"Wi-Fi Disattivato\"\r\
    \n set [find] disabled=yes\r\
    \n /sys leds set [find where leds=user-led] type=off\r\
    \n}\r\
    \n"
