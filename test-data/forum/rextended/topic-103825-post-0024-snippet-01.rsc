# Source: https://forum.mikrotik.com/t/wi-fi-on-off-switch/103825/24
# Post author: @rextended
# Extracted from: code-block

/interface wireless set wlan1 disabled=(![get wlan1 disabled])
