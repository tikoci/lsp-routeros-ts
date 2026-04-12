# Source: https://forum.mikrotik.com/t/feature-request-add-sorting/101313/10
# Topic: Feature request: Add sorting
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

/interface {
    :local sortby "name"
    :local arr [:toarray ""]
    :foreach k,v in=[print as-value] do={
        :set ($arr->($v->$sortby)) $v 
    }
    :foreach k,v in=$arr do={:put "$k \t$[:tostr $v]" }
}
