# Source: https://forum.mikrotik.com/t/foreach-syntax/171579/3
# Topic: Foreach syntax
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

/interface/list {
   add name=ListB
   :delay 1s
}

/interface/list/member {
  :foreach i in=[find where ((interface~"ospf") and (list~"ListA"))] do={
      set $i list="ListB"
  }
}
