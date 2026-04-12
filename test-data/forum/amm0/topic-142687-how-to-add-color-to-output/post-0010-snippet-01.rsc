# Source: https://forum.mikrotik.com/t/how-to-add-color-to-output/142687/10
# Topic: How to add color to output
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

do {

:local RED     do={/terminal style error}
:local BLUE    do={/terminal style ambiguous}
:local WHITE   do={/terminal style "syntax-old"}
:local blue    do={/terminal style escaped} 
:local cyan    do={/terminal style "varname-local"}  
:local red     do={/terminal style varname} 
:local plain   do={/terminal style "syntax-val" } 
:local yellow  do={/terminal style "syntax-meta"}  
:local strong  do={/terminal style "syntax-noterm"}
:local nostyle do={/terminal style "none"} 

:local rndhex do={ :return [:rndstr length=6 from=abcdef0123456789] }

{                           :put {"  Press "}; 
  $nostyle; /terminal/cuu;     :put        "\t    key to exit (or use Ctrl-C)"; 
  $RED; /terminal/cuu;         :put        "\tany"; 
}

:local keypress 65535;

while (keypress=65535) do={ 
    :local Nrows (9);
    
    for i from=1 to=$Nrows do={:put ""} 
    for i from=1 to=$Nrows do={/terminal cuu} 
    for i from=1 to=$Nrows do={$RED; :put "   A$i         "} 
    for i from=1 to=$Nrows do={/terminal cuu} 
    for i from=1 to=$Nrows do={$cyan; :put "\t $([$rndhex])"} 
    for i from=1 to=$Nrows do={/terminal cuu} 
    for i from=1 to=$Nrows do={$blue; :put "\t\t $([$rndhex])"} 
    for i from=1 to=$Nrows do={/terminal cuu} 
    for i from=1 to=$Nrows do={$yellow; :put "\t\t\t $([$rndhex])"} 
    for i from=1 to=$Nrows do={/terminal cuu} 
    for i from=1 to=$Nrows do={$WHITE; :put "\t\t\t\t   E$i   "} 
    for i from=1 to=$Nrows do={/terminal cuu}
    
    :set keypress [/terminal inkey timeout=1s]
}
}
