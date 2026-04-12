# Source: https://forum.mikrotik.com/t/ip-route-check-command-disappeared/141645/14
# Topic: /ip/route/check command disappeared?
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

:global ipcheck
:set $ipcheck do={
    :local ip2check [:toip $1]
    :local typeip [:typeof $ip2check]
    :if (typeip~"ip|ip6") do={
        :local lookup [/ip/route/find where $ip2check in dst-address and active]
        :local lastone ($lookup->([:len $lookup]-1))
        :local rv [/ip/route/get $lastone immediate-gw]
        :return $rv
    } else={
        :error "\$ipcheck requires an IP address/range as input"
    }
}

# TEST
:put [$ipcheck 1.1.1.1]
