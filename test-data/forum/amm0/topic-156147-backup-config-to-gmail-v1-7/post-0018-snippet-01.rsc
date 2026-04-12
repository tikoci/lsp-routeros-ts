# Source: https://forum.mikrotik.com/t/backup-config-to-gmail-v1-7/156147/18
# Topic: Backup config to Gmail v1.7
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

:global rosmajorver [:tonum [:pick [/system resource get version] 0 1]]
:global rtlookup
:set $rtlookup do={
    :if ($rosmajorver>6) do={
        :return [[:parse "/routing table find where name=$1"]]
    } else={
        :return $1
    }
}

# >>  :put [$rtlookup main]
#    *0
