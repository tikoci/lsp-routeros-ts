# Source: https://forum.mikrotik.com/t/cant-turn-code-into-a-function/167087/4
# Topic: Can't turn code into a function
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

{
    :local reverseNumber do={
        :local len [:len $number]
        :local tmpNum [:toarray ""]
        :local realNum [:toarray ""]
        :local result

        :local counter 0
        while ( $counter<$len ) do={
            :set $tmpNum ($tmpNum, [:pick $number $counter ($counter+1)] )
            :set $counter ($counter + 1)
        };

        :local counter 0
        while ( $counter<$len ) do={
            :if ( ($counter % 2) = 0) do={
                :set $realNum ($realNum, ($tmpNum->($counter+1) ) )
            } else={
                :set $realNum ($realNum, ($tmpNum->($counter-1) ) )
            }
        :set $counter ($counter + 1)
        };

        :put $realNum
        :foreach num in=$realNum do={
                :set result ($result.$num)
            }

        :return $result
    }


    {
    :local numberarg "8350000048F0"
    $reverseNumber number=$numberarg

    :local result [$reverseNumber number=$numberarg]
    :put $result
    }
}
