# Source: https://forum.mikrotik.com/t/convert-any-text-to-unicode/164329/3
# Topic: Convert any text to UNICODE
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

# global flag to output UTF-8
:global "use-unicode" 1

# Tilde over lowercase N
:global tildan do={
   :global "use-unicode" 
   :if ($"use-unicode" = 1) do={
       return "\C3\B1"
    } else={
       return "n"
    }
}

# output as unicode
:set "use-unicode" 1
:put "espa$([$tildan])ola"

# output as ascii
:set "use-unicode" 0
:put "espa$([$tildan])ola"
