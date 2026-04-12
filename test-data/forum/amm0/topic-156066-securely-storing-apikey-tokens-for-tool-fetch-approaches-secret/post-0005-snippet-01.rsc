# Source: https://forum.mikrotik.com/t/securely-storing-apikey-tokens-for-tool-fetch-approaches-secret/156066/5
# Topic: Securely storing apikey/tokens for /tool/fetch... Approaches?  == $SECRET
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

:global ppppwdmax do={
    :for i from=1 to=[:tonum $1] step=($1/10) do={
        /ppp/secret/remove [find where comment="#removeme"]
        :local expected [:rndstr length=$i from=abc]
        /ppp/secret/add name="pwd$i" password=$expected comment="#removeme"
        :local actual [/ppp/secret/get "pwd$i" password]
        :put "/ppp/secret test loop=$i expected=$[:len $expected] actual=$[:len $expected]"
        /terminal/cuu
        :if ($expected!=$actual) do={
            :error "failed to created new /ppp/secret with password lengths of loop=$i expected=$[:len $expected] actual=$[:len $actual] "
        }  
    } 
}

# this will work
$ppppwdmax 60000
# /ppp/secret test loop=54001 expected=54001 actual=54001

# this won't and gets a very clear error with limit
$ppppwdmax 100000
# afraid to create strings larger than 64kB
