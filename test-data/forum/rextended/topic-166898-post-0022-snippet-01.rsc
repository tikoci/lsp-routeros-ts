# Source: https://forum.mikrotik.com/t/log-filter/166898/22
# Post author: @rextended
# Extracted from: code-block

:global anydate2isodate do={
    :local dtime [:tostr $1]
    /system clock
    :local cyear [get date] ; :if ($cyear ~ "....-..-..") do={:set cyear [:pick $cyear 0 4]} else={:set cyear [:pick $cyear 7 11]}
    :if (([:len $dtime] = 10) or ([:len $dtime] = 11)) do={:set dtime "$dtime 00:00:00"}
    :if ([:len $dtime] = 15) do={:set dtime "$[:pick $dtime 0 6]/$cyear $[:pick $dtime 7 15]"}
    :if ([:len $dtime] = 14) do={:set dtime "$cyear-$[:pick $dtime 0 5] $[:pick $dtime 6 14]"}
    :if ([:len $dtime] =  8) do={:set dtime "$[get date] $dtime"}
    :if ([:tostr $1] = "") do={:set dtime ("$[get date] $[get time]")}
    :local vdoff [:toarray "0,4,5,7,8,10,11,19"]
    :local MM    [:pick $dtime ($vdoff->2) ($vdoff->3)]
    :if ($dtime ~ ".../../....") do={
        :set vdoff [:toarray "7,11,1,3,4,6,12,20"]
        :set MM    ([:find "xxanebarprayunulugepctovecANEBARPRAYUNULUGEPCTOVEC" [:pick $dtime ($vdoff->2) ($vdoff->3)] -1] / 2)
        :if ($MM>12) do={:set MM ($MM - 12)} ; :if ($MM<10) do={:set MM "0$MM"}
    }
    :return "$[:pick $dtime ($vdoff->0) ($vdoff->1)]-$MM-$[:pick $dtime ($vdoff->4) ($vdoff->5)] $[:pick $dtime ($vdoff->6) ($vdoff->7)]"
}

:global UTF8toURLencode do={
    :local ascii "\00\01\02\03\04\05\06\07\08\09\0A\0B\0C\0D\0E\0F\
                  \10\11\12\13\14\15\16\17\18\19\1A\1B\1C\1D\1E\1F\
                  \20\21\22\23\24\25\26\27\28\29\2A\2B\2C\2D\2E\2F\
                  \30\31\32\33\34\35\36\37\38\39\3A\3B\3C\3D\3E\3F\
                  \40\41\42\43\44\45\46\47\48\49\4A\4B\4C\4D\4E\4F\
                  \50\51\52\53\54\55\56\57\58\59\5A\5B\5C\5D\5E\5F\
                  \60\61\62\63\64\65\66\67\68\69\6A\6B\6C\6D\6E\6F\
                  \70\71\72\73\74\75\76\77\78\79\7A\7B\7C\7D\7E\7F\
                  \80\81\82\83\84\85\86\87\88\89\8A\8B\8C\8D\8E\8F\
                  \90\91\92\93\94\95\96\97\98\99\9A\9B\9C\9D\9E\9F\
                  \A0\A1\A2\A3\A4\A5\A6\A7\A8\A9\AA\AB\AC\AD\AE\AF\
                  \B0\B1\B2\B3\B4\B5\B6\B7\B8\B9\BA\BB\BC\BD\BE\BF\
                  \C0\C1\C2\C3\C4\C5\C6\C7\C8\C9\CA\CB\CC\CD\CE\CF\
                  \D0\D1\D2\D3\D4\D5\D6\D7\D8\D9\DA\DB\DC\DD\DE\DF\
                  \E0\E1\E2\E3\E4\E5\E6\E7\E8\E9\EA\EB\EC\ED\EE\EF\
                  \F0\F1\F2\F3\F4\F5\F6\F7\F8\F9\FA\FB\FC\FD\FE\FF"
    :local UTF8toURLe {"00";"01";"02";"03";"04";"05";"06";"07";"08";"09";"0A";"0B";"0C";"0D";"0E";"0F";
                       "10";"11";"12";"13";"14";"15";"16";"17";"18";"19";"1A";"1B";"1C";"1D";"1E";"1F";
                       "+";"21";"22";"23";"24";"25";"26";"27";"28";"29";"2A";"2B";"2C";"-";".";"2F";
                       "0";"1";"2";"3";"4";"5";"6";"7";"8";"9";"3A";"3B";"3C";"3D";"3E";"3F";
                       "40";"A";"B";"C";"D";"E";"F";"G";"H";"I";"J";"K";"L";"M";"N";"O";
                       "P";"Q";"R";"S";"T";"U";"V";"W";"X";"Y";"Z";"5B";"5C";"5D";"5E";"_";
                       "60";"a";"b";"c";"d";"e";"f";"g";"h";"i";"j";"k";"l";"m";"n";"o";
                       "p";"q";"r";"s";"t";"u";"v";"w";"x";"y";"z";"7B";"7C";"7D";"~";"7F";
                       "80";"81";"82";"83";"84";"85";"86";"87";"88";"89";"8A";"8B";"8C";"8D";"8E";"8F";
                       "90";"91";"92";"93";"94";"95";"96";"97";"98";"99";"9A";"9B";"9C";"9D";"9E";"9F";
                       "A0";"A1";"A2";"A3";"A4";"A5";"A6";"A7";"A8";"A9";"AA";"AB";"AC";"AD";"AE";"AF";
                       "B0";"B1";"B2";"B3";"B4";"B5";"B6";"B7";"B8";"B9";"BA";"BB";"BC";"BD";"BE";"BF";
                       "C0";"C1";"C2";"C3";"C4";"C5";"C6";"C7";"C8";"C9";"CA";"CB";"CC";"CD";"CE";"CF";
                       "D0";"D1";"D2";"D3";"D4";"D5";"D6";"D7";"D8";"D9";"DA";"DB";"DC";"DD";"DE";"DF";
                       "E0";"E1";"E2";"E3";"E4";"E5";"E6";"E7";"E8";"E9";"EA";"EB";"EC";"ED";"EE";"EF";
                       "F0";"F1";"F2";"F3";"F4";"F5";"F6";"F7";"F8";"F9";"FA";"FB";"FC";"FD";"FE";"FF"
                      }
    :local string $1
    :if (([:typeof $string] != "str") or ($string = "")) do={ :return "" }
    :local lenstr [:len $string]
    :local constr ""
    :for pos from=0 to=($lenstr - 1) do={
        :local urle ($UTF8toURLe->[:find $ascii [:pick $string $pos ($pos + 1)] -1])
        :local sym $urle
        :if ([:len $urle] = 2) do={:set sym "%$[:pick $urle 0 2]" }
        :set constr "$constr$sym"
    }
    :return $constr
}

:global lastLog
:if ([:typeof $lastLog] != "num") do={:set lastLog 0}

{
:local tgBot    "XXXXXXXXXXXXXXXX:XXXXXXXXXXX-XXXXXXXXXXXXXXXXXXXXXX"
:local tgChatID "XXXXXXXXX"
:local tgPrefix "\E2\84\B9 MikroTik $[/system identity get name] $[/system resource get board-name]"
:local wtopics  "critical|error|warning"
:local utopics  "ipsec"
:local mkwd     "login failure|logged in|loop|down|fcs|excessive|system|rebooted|ipsec|ike2"
:local ukwd     "unwanted|example|phase1 negotiation failed"
:local trim     256

:local id2num do={:return [:tonum "0x$[:pick $1 1 [:len $1]]"]}
:local tgmessg ""
:local emotico ""
:local temp    ""
:local tempmsg ""

/log
:foreach item in=[find where (((([$id2num $".id"] > $lastLog) and (buffer=memory)) and (!([:tostr $topics]~"($utopics)"))) \
                             and \
                             ((([:tostr $topics]~"($wtopics)") or (message~"($mkwd)")) and (!(message~"($ukwd)"))))] do={
    :set lastLog [$id2num $item]
    :set emotico ""
    :local temp [:tostr [get $item topics]]
    :if ($temp~"critical") do={:set emotico "\E2\98\A0\20"}
    :if ($temp~"error")    do={:set emotico "$emotico\E2\9D\8C\20"}
    :if ($temp~"warning")  do={:set emotico "$emotico\E2\9A\A0\20"}
    :set tempmsg [get $item message]
    :if ([:len $tempmsg] > $trim) do={:set tempmsg ("$[:pick $tempmsg 0 ($trim - 1)]\E2\80\A6") }
    :set tgmessg [$UTF8toURLencode ("$tgPrefix\r\n$[$anydate2isodate [get $item time]] $emotico$tempmsg")]
    /tool fetch url="https://api.telegram.org/bot$tgBot/sendMessage\3Fchat_id=$tgChatID&text=$tgmessg" keep-result=no
}

}
