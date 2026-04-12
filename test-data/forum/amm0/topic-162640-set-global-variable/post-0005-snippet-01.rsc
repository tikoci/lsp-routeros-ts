# Source: https://forum.mikrotik.com/t/set-global-variable/162640/5
# Topic: Set global variable
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

:global activeCh first
:global auxCh second

:global setActiveCh do={
   :global activeCh
   :global auxCh
  :if ($activeCh = $"ch") do={
    :log info "Keep $activeCh"
  } else={
    :log info "Switch $activeCh to $ch"

    :set auxCh $activeCh
    :set activeCh $ch
  }
}
