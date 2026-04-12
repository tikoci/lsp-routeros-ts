# Source: https://forum.mikrotik.com/t/convert-uptime-to-date-and-time/157724/40
# Post author: @rextended
# Extracted from: code-block

{
:local readut "<uptime>546837</uptime>"
:put [:totime [:pick $readut ([:find $readut ">" -1] + 1) [:find $readut "</" -1]]]
}
