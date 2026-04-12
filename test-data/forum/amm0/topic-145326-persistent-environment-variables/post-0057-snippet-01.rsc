# Source: https://forum.mikrotik.com/t/persistent-environment-variables/145326/57
# Topic: Persistent Environment Variables
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

{
    # an array with most types, including a JSON "float" 
    :local arr {
        "num"=0;
        "str"="mystr";
        "emptystr"="";
        "ip4"=1.1;
        "ip6"=1::1;
        "prefix4"=1.0.0.1/31;
        "prefix6"=1::1/69;
        "float"="1.1";
        "time"=1s;
        "now"=[:timestamp];
        "null"=[:nothing];
        "list"=(1,2,"three");
        "listlist"={(1,2,3);("a","b","c")}
        "dict"={"a"=1;"b"="z"};
        "dictlist"={{"m"="M"};{"z"="Z"}};
        "dictdict"={"b"={"one"=1;"two"=2};"w"={"1"="one";"2"="two"}};    
        "optype"=(>[:put "echo"]);
        "bignum"=[:tonsec [:timestamp]];
        "bigneg"=(0-[:tonsec [:timestamp]]);
    }
    # helpers for test
    :local prettyprint do={:put [:serialize to=json options=json.pretty $1]}
    :local addtypes do={:local rv $1; :foreach n,a in=$1 do={ :set ($rv->"$n-type") [:typeof $a] }; :return $rv }

    :put "\r\narray BEFORE serialization"
    $prettyprint [$addtypes $arr]

    :put "\r\nconvert to JSON"
    :local json [:serialize to=json $arr]

    :put "\r\nconvert to base64 for storage as RouterOS string"
    :local base64out [:convert to=base64 $json]
    $prettyprint $base64out

    :put "\r\nsave to base64 JSON as unused L7 FW rule"
    :local storename "example-base64-json-to-save-vars"
    :local storeid [/ip/firewall/layer7-protocol/find name=$storename] 
    :if ([:len $storeid]=1) do={
    /ip/firewall/layer7-protocol set $storeid regexp=$base64out 
    } else={
    /ip/firewall/layer7-protocol add name=$storename regexp=$base64out  
    }

    :put "\r\nPRETEND you reboot and come back...so wait 3 seconds"
    :delay 3s

    :put "\r\nsave to base64 JSON as unused L7 FW rule"
    :local base64in [/ip/firewall/layer7-protocol get [find name=$storename] regexp]

    :put "\r\nif base64, restore it to JSON"
    :local newjson [:convert from=base64 $base64in]

    :put "\r\nfinally get the array back, with types perserved by :deserialize JSON" 
    :local arr2 [:deserialize from=json $newjson]

    :put "\r\narray AFTER deserialization"
    $prettyprint [$addtypes $arr2]

    :put "\r\nBONUS: simulate using RESTORED array variables using 'activate-in-context' and 'op' types"
    ((>[:put "now: $now  listlen: $[:len $list] bignum: $bignum  prefix6: $prefix6"]) <%% $arr2)
    :put "... even though its array, you can use them as normal variables without the -> if you use the <%% to unwrap them"
}
