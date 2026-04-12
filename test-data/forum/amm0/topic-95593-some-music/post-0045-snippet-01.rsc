# Source: https://forum.mikrotik.com/t/some-music/95593/45
# Topic: Some Music
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

:global PIANO do={
:local nms 125ms
:if ([:typeof [:totime $1]]="time") do={:set nms [:totime $1]}
:local octive 4
:local scalearr {"a"=(33,65,131,262,523,1047,2093,4186,8372) ; 
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
:local lnms $nms
:local lastkey 65535

:put "\t\t** ROUTEROS PLAYER PIANO **"
:put "Type a key to play a note...  The note will play for $nms."
:put "To play a longer note, type a number before the note"
:put "e.g. 2 will play all future notes twice. Hit 1 to reset to $(nms)"
:put "Current octive is $octive.  Use \"x\" for next higher octive, or \"z\" to lower octive"
:put "To quit, hit \"q\""
:put ""
:put "\t\1B[2;31mLENGTH \1B[1;31m1x\1B[0m \1B[1;31m2x\1B[0m \1B[1;31m3x\1B[0m \1B[1;31m4x\1B[0m \1B[1;31m5x\1B[0m \1B[1;31m6x\1B[0m \1B[1;31m7x\1B[0m \1B[1;31m8x\1B[0m" 
:put "\t\1B[0m    `  1  2  3  4  5  6  7  8  9  0  -  = del"
:put "\t      \1B[2;7mQUIT\1B[0m \1B[1;7mC#\1B[0m \1B[1;7mD#\1B[0m    \1B[1;7mF#\1B[0m \1B[1;7mG#\1B[0m \1B[1;7mA#\1B[0m    \1B[1;7mC#\1B[0m"
:put "\t\1B[0m   tab  q  w  e  r  t  y  u  i  o  p  [  ]  \\"
:put "\t         \1B[1;7mC\1B[0m  \1B[1;7mD\1B[0m  \1B[1;7mE\1B[0m  \1B[1;7mF\1B[0m  \1B[1;7mG\1B[0m  \1B[1;7mA\1B[0m  \1B[1;7mB\1B[0m  \1B[1;7mC\1B[0m  \1B[1;7mD\1B[0m "
:put "\t\1B[0m   caps  a  s  d  f  g  h  j  k  l  ;  '  ret"
:put "\t\1B[1;31m          <  >        "
:put "\t\1B[0m   shft   z  x  c  v  b  n  m  ,  .  /  shft"
:put "\t         \1B[2;31mOCTIVE \1B[1m$octive\1B[0m    \1B[2;31mNOTE \1B[1m$lnms\1B[0m "

:while ($lastkey != 113) do={
    :set lastkey [/terminal inkey]
    :if ($lastkey = 65535) do={:delay $nms} else={
        :if ($lastkey > 48 && $lastkey < 58) do={
            :set $lnms ($nms*($lastkey - 48))
            /terminal cuu
            :put "\t         \1B[2;31mOCTIVE \1B[1m$octive\1B[0m    \1B[2;31mBEAT \1B[1m$lnms\1B[0m "
        }
        :local lastascii ($"ascii-map"->$lastkey)
        :if ($lastascii ~ "x|z") do={
            :if ($lastascii = "z") do={ :set octive ($octive-1); } else={ :set octive ($octive+1); } 
            /terminal cuu
            :put "\t         \1B[2;31mOCTIVE \1B[1m$octive\1B[0m    \1B[2;31mBEAT \1B[1m$lnms\1B[0m "
        }
        :local freq ($scalearr->$lastascii->($octive+1))
        :if ([:typeof $freq]="num") do={
            :beep frequency=$freq length=$lnms
            :delay $lnms
            /terminal cuu 
        }
    }
}
}
$PIANO 125ms
