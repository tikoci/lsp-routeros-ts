# Source: https://forum.mikrotik.com/t/v7-12beta-testing-is-released/168851/202
# Topic: v7.12beta [testing] is released!
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

:global dlros do={
    :local lver "7.11.2"
    :local larch "arm64"
    :if ([:typeof $1]="str") do={
        :set lver $1
        :if ([:typeof $arch]="str") do={
            :set larch $arch
        }
    } 
    :local curl "https://download.mikrotik.com/routeros/$lver/routeros-$lver-$larch.npk"
    :put $curl
    
    /tool fetch url=$curl  
}
$dlros 7.12beta1 arch=arm
