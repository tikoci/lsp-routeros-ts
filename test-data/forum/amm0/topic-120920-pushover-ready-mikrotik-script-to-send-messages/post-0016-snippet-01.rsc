# Source: https://forum.mikrotik.com/t/pushover-ready-mikrotik-script-to-send-messages/120920/16
# Topic: PUSHOVER - ready MikroTik script to send messages
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

:global npushover do={
    :local url "https://api.pushover.net/1/messages.json"
    :local headers "Content-Type: application/json"
    :local reqdata [:toarray ""]
    :if ([:typeof $1]="array") do={:set reqdata $1} else={
        :error "\$$0 requires an array of values to set, see https://pushover.net/api"
    }
    :local json [:serialize to=json $reqdata]
    :local resp [/tool/fetch url=$url http-data=$json http-header-field=$headers output=user as-value]
    :local respdata [:deserialize from=json ($resp->"data")]
    :if (($respdata->"status")=1) do={
        /log/debug "$0 $[:put "successfully sent request $($respdata->"request")"]"
    } else={
        /log/warning "$0 failed, got: $[:tostr $resp]"
        :error $resp
    }
}
