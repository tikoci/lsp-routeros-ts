# Source: https://forum.mikrotik.com/t/need-some-scripting-help-bounty-available/162737/4
# Topic: need some scripting help, bounty available
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

:global FLATPUT do={
  :global FLATPUT
  :foreach i,k in=$1 do={
    :if ([:typeof $k]="array") do={
      :if ($i != "ipAddresses") do={
        :put "$[:tostr $i]=(array)"
        $FLATPUT $k
      } else={
        :put "$[:tostr $i]=$[:tostr $k] ;$[:typeof $k]"
      }
    } else={
      :put "$[:tostr $i]=$[:tostr $k] ;$[:typeof $k]"
    }
  }
}
