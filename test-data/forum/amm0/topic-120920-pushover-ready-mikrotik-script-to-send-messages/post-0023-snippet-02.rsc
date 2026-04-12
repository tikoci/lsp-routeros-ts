# Source: https://forum.mikrotik.com/t/pushover-ready-mikrotik-script-to-send-messages/120920/23
# Topic: PUSHOVER - ready MikroTik script to send messages
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

{
:global npushover
:local mdata [/interface/lte/monitor lte1 once as-value]
$npushover ({ 
        user="private"
        token="private"
        message="Mikrotik SXT Rebooted <b>nPushover</b><br><pre>$($mdata->"primary-band") sinr: $($mdata->"sinr") rsrq: $($mdata->"rsrq") rsrp: $($mdata->"rsrp")</pre>"
        title="MikroTik SXTR"
        html=1
        sound="magic"
        priority=0
        url="https://192.168.x.1"
        "url_title"="MikroTik"
})
}
