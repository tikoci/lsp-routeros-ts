# Source: https://forum.mikrotik.com/t/iterate-over-all-elements-of-an-array-of-unknown-dimension/163033/12
# Topic: iterate over all elements of an array of unknown dimension
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

:global FLATTEN do={
  :global FLATTEN
  :local memo [:toarray $2]
  :local FNPUT true
  :foreach i,k in=$1 do={
    :if ([:typeof $k]="array") do={      
        :if ($FNPUT) do={:put "$[:tostr $i]=(array)"}
        :set memo [$FLATTEN $k $memo]
    } else={
      :if ($FNPUT) do={:put "$[:tostr $i]=$[:tostr $k] ;$[:typeof $k]"}
      :set memo {$memo; [:toarray "$i , $k"]}
    }
  }
  :return $memo
 }
