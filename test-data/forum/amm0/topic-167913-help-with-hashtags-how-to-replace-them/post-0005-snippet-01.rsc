# Source: https://forum.mikrotik.com/t/help-with-hashtags-how-to-replace-them/167913/5
# Topic: Help with hashtags, how to replace them
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

{
# from http://forum.mikrotik.com/t/replace-characters-in-string-url-encode/76863/11
:local URLENCODE
:set URLENCODE do={
    :local Chars {" "="%20";"!"="%21";"#"="%23";"%"="%25";"&"="%26";"'"="%27";"("="%28";")"="%29";"*"="%2A";"+"="%2B";","="%2C";"/"="%2F";":"="%3A";";"="%3B";"<"="%3C";"="="%3D";">"="%3E";"@"="%40";"["="%5B";"]"="%5D";"^"="%5E";"`"="%60";"{"="%7B";"|"="%7C";"}"="%7D"}
    :set ($Chars->"\07") "%07"
    :set ($Chars->"\0A") "%0A"
    :set ($Chars->"\0D") "%0D"
    :set ($Chars->"\22") "%22"
    :set ($Chars->"\24") "%24"
    :set ($Chars->"\3F") "%3F"
    :set ($Chars->"\5C") "%5C"
    :local URLEncodeStr
    :local Char
    :local EncChar
    :for i from=0 to=([:len $1]-1) do={
        :set Char [:pick $1 $i]
        :set EncChar ($Chars->$Char)
        :if (any $EncChar) do={
            :set URLEncodeStr "$URLEncodeStr$EncChar"
        } else={
            :set URLEncodeStr "$URLEncodeStr$Char"
        }
    }
    :return $URLEncodeStr
}

:local reportingurl "http://example.com/number=$[$URLENCODE $user]&bid=$[$URLENCODE "BID202202004"]"
:local fetchresult [/tool fetch url=$reportingurl output=none as-value]
/log info "send popoe down to SQL via $reportingurl with result: $[:tostr $fetchresult]"
}
