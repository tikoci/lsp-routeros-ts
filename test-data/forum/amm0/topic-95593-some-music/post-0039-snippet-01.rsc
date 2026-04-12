# Source: https://forum.mikrotik.com/t/some-music/95593/39
# Topic: Some Music
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

{
:local nms 125ms
:local scale {"c"=262; "C"=277;"d"=294; "D"=311; "e"=330; "f"=349; "F"=370; "g"=392; "G"=415; "a"=440; "A"=466; "b"=493}
:local "ascii-map" {"";"NUL";"SOH";"STX";"ETX";"EOT";"ENQ";"ACK";"back";"back";"tab";"VT";"FF";"enter";"return";"SI";"DLE";"DC1";"DC2";"DC3";"DC4";"NAK";"SYN";"ETB";"CAN";"EM";"SUB";"ESC";"FS";"GS";"RS";"US";"space";"!";"\"";"comment";"\$";"%";"&";"";"(";")";"*";"+";",";"-";".";"/";"0";"1";"2";"3";"4";"5";"6";"7";"8";"9";":";";";"<";"=";">";"\?";"@";"A";"B";"C";"D";"E";"F";"G";"H";"I";"J";"K";"L";"M";"N";"O";"P";"Q";"R";"S";"T";"U";"V";"W";"X";"Y";"Z";"[";"\\";"]";"^";"_";"`";"a";"b";"c";"d";"e";"f";"g";"h";"i";"j";"k";"l";"m";"n";"o";"p";"q";"r";"s";"t";"u";"v";"w";"x";"y";"z";"{";"|";"}";"~";"delete"}
:local lastkey 65535
:put "** ROUTEROS PLAYER PIANO **"
:put "Type a key to play a note...  The note will play for $nms.  Keep holding to continue playing."
:foreach nltr,nfreq in=$scale do={:put "\t$nltr  \t  $nfreq Hz"}
:put "Notes are in the 4th octive of the scientific scale."
:put "Sharp # notes are denoted by using a CAPTIAL letter of the note."
:put "Bonus: To play a longer note, type a number"
:put "   e.g. 2 will play all future notes twice as long so $($nms*2).  Hit 1 to reset to $(nms)"
:put "To QUIT, hit \"q\""
:local lnms $nms
:while (lastkey != 113) do={
    :set lastkey [/terminal inkey]
    :if ($lastkey = 65535) do={:delay $nms} else={
        :if ($lastkey > 48 && $lastkey < 58) do={:set $lnms ($nms*($lastkey - 48))}
        :local lastascii ($"ascii-map"->$lastkey)
        :local freq ($scale->$lastascii)
        :if ([:typeof $freq]="num") do={
            :beep frequency=$freq length=$lnms
        }
        :delay $lnms
        /terminal cuu 
    }
}
}
