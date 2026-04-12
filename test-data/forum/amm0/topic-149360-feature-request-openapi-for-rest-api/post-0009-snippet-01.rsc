# Source: https://forum.mikrotik.com/t/feature-request-openapi-for-rest-api/149360/9
# Topic: Feature Request : OpenAPI for REST API
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

:global ast [:toarray ""]

:global mkast do={
    :global mkast
    :global ast
    :local path "" 
    :if ([:typeof $1] ~ "str|array") do={ :set path $1 }
    :local pchild [/console/inspect as-value request=child path=$path]
    :foreach k,v in=$pchild do={
        :if (($v->"type") = "child") do={
            :local astkey ""
            :local arrpath [:toarray $path]
            :foreach part in=$arrpath do={
                :set astkey "$astkey/$part"
            }
            :set ($ast->$astkey->($v->"name")) $v
            :put "Processing: $astkey $($v->"name") $($v->"node-type")"
            :local newpath "$($path),$($v->"name")"
    		# TODO use [/console/inspect as-value request=syntax path=$path]
            [$mkast $newpath]
        }
    }
    return $ast
}

# & this call start the recursion 
:put [$mkast]
