# Source: https://forum.mikrotik.com/t/how-to-mass-configure-50-hap-units/164588/18
# Topic: How to mass configure 50 hAP units ?
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

# force apply if loaded via CLI 
:if ([:typeof $action]!="str") do={ 
  :log info "no action, assuming: apply"
  :set action "apply"
} else={
  :log info "performing config action: $action"
}
