# Source: https://forum.mikrotik.com/t/some-music/95593/41
# Topic: Some Music
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

{
:local nms 125ms
:local octive 4
:global scalearr {"a"=(33,65,131,262,523,1047,2093,4186,8372) ; 
"w"=(35,69,139,277,554,1109,2217,4435,8870) ;
"s"=(37,73,147,294,587,1175,2349,4699,9397) ;
"e"=(39,78,156,311,622,1245,2489,4978,9956) ;
"d"=(41,82,165,330,659,1319,2637,5274,10548) ;
"f"=(44,87,175,349,698,1397,2794,5588,11175) ;
"t"=(46,92,185,370,740,1480,2960,5920,11840) ; 
"g"=(49,98,196,392,784,1568,3136,6272,12544) ;
"y"=(52,104,208,415,831,1661,3322,6645,13290) ;
"h"=(55,110,220,440,880,1760,3520,7040,14080) ;
"u"=(58,117,233,466,932,1865,3729,7459,14917) ;
"j"=(62,123,247,494,988,1976,3951,7902,15804) ;
"k"=(65,131,262,523,1047,2093,4186,8372,16744) ; 
"o"=(69,139,277,554,1109,2217,4435,8870,17739) ;
"l"=(73,147,294,587,1175,2349,4699,9397,18795) ;
}
:local "ascii-map" {"";"NUL";"SOH";"STX";"ETX";"EOT";"ENQ";"ACK";"back";"back";"tab";"VT";"FF";"enter";"return";"SI";"DLE";"DC1";"DC2";"DC3";"DC4";"NAK";"SYN";"ETB";"CAN";"EM";"SUB";"ESC";"FS";"GS";"RS";"US";"space";"!";"\"";"comment";"\$";"%";"&";"";"(";")";"*";"+";",";"-";".";"/";"0";"1";"2";"3";"4";"5";"6";"7";"8";"9";":";";";"<";"=";">";"\?";"@";"A";"B";"C";"D";"E";"F";"G";"H";"I";"J";"K";"L";"M";"N";"O";"P";"Q";"R";"S";"T";"U";"V";"W";"X";"Y";"Z";"[";"\\";"]";"^";"_";"`";"a";"b";"c";"d";"e";"f";"g";"h";"i";"j";"k";"l";"m";"n";"o";"p";"q";"r";"s";"t";"u";"v";"w";"x";"y";"z";"{";"|";"}";"~";"delete"}

:local lastkey 65535
:put "** ROUTEROS PLAYER PIANO **"
:put "Type a key to play a note...  The note will play for $nms.  Keep holding to continue playing."
:foreach nltr,nfreq in=$scalearr do={:put "\t$nltr  \t  $($nfreq->octive) Hz"}
:put "\t\t\tNotes are in the $($octive) octive of the scientific scale."
:put "\t\t\tSharp # notes are denoted by using a CAPTIAL letter of the note."
:put "\tTo play a longer note, type a number before the note"
:put "\t\te.g. 2 will play all future notes twice as long so $($nms*2).  Hit 1 to reset to $(nms)"
:put "\tCurrent octive is $octive.  Use \"x\" for next higher octive, or \"z\" to lower octive"

:put "\tTo quit, hit \"q\""
:local lnms $nms
:while ($lastkey != 113) do={
    :set lastkey [/terminal inkey]
    :if ($lastkey = 65535) do={:delay $nms} else={
        :if ($lastkey > 48 && $lastkey < 58) do={
            :set $lnms ($nms*($lastkey - 48))
            :put "\t\tnote length = $lnms"
        }
        :local lastascii ($"ascii-map"->$lastkey)
        :if ($lastascii = "x") do={:set octive ($octive+1); :put "\t\toctive = $octive" }
        :if ($lastascii = "z") do={:set octive ($octive-1); :put "\t\toctive = $octive" }
        :local freq ($scalearr->$lastascii->($octive+1))
        :if ([:typeof $freq]="num") do={
            :beep frequency=$freq length=$lnms
            :delay $lnms
            /terminal cuu 
        }
    }
}
}
