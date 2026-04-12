# Source: https://forum.mikrotik.com/t/add-more-logged-detail-to-fetch/178998/3
# Topic: Add more logged detail to fetch?
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

:global safeFetch do={
    :local resp
    :local httperror [ :onerror err in={
        :set resp [/tool fetch url=$url output=user-with-headers as-value]
        :if (($resp->"status") != "finished") do={
            /log warn "fetch did not finish: $[:tostr $resp]"
            return true
        }
        return false
        } do={ 
            /log warn "fetch got hard error: $[:tostr $err]" 
        } ] 
    :if $httperror do={
        :error "fetch failed, check logs"
    }
    return $resp
}
# works:
:put [$safeFetch url="https://wttr.in/@mikrotik.com?format=4"]
# hard error - bad url:
:put [$safeFetch url="https://wttr.in?"]
# hard error - redirect:
:put [$safeFetch url="http://wttr.in/@mikrotik.com?format=4"]
# hard error - HTTP 500 status code
:put [$safeFetch url="https://postman-echo.com/status/500"]
#
