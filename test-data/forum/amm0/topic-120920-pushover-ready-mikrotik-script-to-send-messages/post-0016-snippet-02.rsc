# Source: https://forum.mikrotik.com/t/pushover-ready-mikrotik-script-to-send-messages/120920/16
# Topic: PUSHOVER - ready MikroTik script to send messages
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

$npushover ({ 
        user="u8xxxxxxxxxxx"
        token="acyqxxxxxxxxxxxxxxx"
        message="Perhaps some <b>HTML</b>"
        title="Test Message"
        html=1
        sound="magic"
        priority=0
        url="https://router.lan/rest/system/resource"
        "url_title"="/system/resources"
})
