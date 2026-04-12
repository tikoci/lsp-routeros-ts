# Source: https://forum.mikrotik.com/t/rextended-fragments-of-snippets/151033/49
# Post author: @rextended
# Extracted from: code-block

:global HexGSM7toCP1252 do={
    :local cp1252 {"\40";"\A3";"\24";"\A5";"\E8";"\E9";"\F9";"\EC";"\F2";"\C7";"\0A";"\D8";"\F8";"\0D";"\C5";"\E5";
                   "\20";"\5F";"\20";"\20";"\20";"\20";"\20";"\20";"\20";"\20";"\20";"\1B";"\C6";"\E6";"\DF";"\C9";
                   "\20";"\21";"\22";"\23";"\A4";"\25";"\26";"\27";"\28";"\29";"\2A";"\2B";"\2C";"\2D";"\2E";"\2F";
                   "\30";"\31";"\32";"\33";"\34";"\35";"\36";"\37";"\38";"\39";"\3A";"\3B";"\3C";"\3D";"\3E";"\3F";
                   "\A1";"\41";"\42";"\43";"\44";"\45";"\46";"\47";"\48";"\49";"\4A";"\4B";"\4C";"\4D";"\4E";"\4F";
                   "\50";"\51";"\52";"\53";"\54";"\55";"\56";"\57";"\58";"\59";"\5A";"\C4";"\D6";"\D1";"\DC";"\A7";
                   "\BF";"\61";"\62";"\63";"\64";"\65";"\66";"\67";"\68";"\69";"\6A";"\6B";"\6C";"\6D";"\6E";"\6F";
                   "\70";"\71";"\72";"\73";"\74";"\75";"\76";"\77";"\78";"\79";"\7A";"\E4";"\F6";"\F1";"\FC";"\E0";
                   "\20";"\20";"\20";"\20";"\20";"\20";"\20";"\20";"\20";"\20";"\0C";"\20";"\20";"\0D";"\20";"\20";
                   "\20";"\20";"\20";"\20";"\5E";"\20";"\20";"\20";"\20";"\20";"\20";"\1B";"\20";"\20";"\20";"\20";
                   "\20";"\20";"\20";"\20";"\20";"\20";"\20";"\20";"\7B";"\7D";"\20";"\20";"\20";"\20";"\20";"\5C";
                   "\20";"\20";"\20";"\20";"\20";"\20";"\20";"\20";"\20";"\20";"\20";"\20";"\5B";"\7E";"\5D";"\20";
                   "\7C";"\20";"\20";"\20";"\20";"\20";"\20";"\20";"\20";"\20";"\20";"\20";"\20";"\20";"\20";"\20";
                   "\20";"\20";"\20";"\20";"\20";"\20";"\20";"\20";"\20";"\20";"\20";"\20";"\20";"\20";"\20";"\20";
                   "\20";"\20";"\20";"\20";"\20";"\80";"\20";"\20";"\20";"\20";"\20";"\20";"\20";"\20";"\20";"\20";
                   "\20";"\20";"\20";"\20";"\20";"\20";"\20";"\20";"\20";"\20";"\20";"\20";"\20";"\20";"\20";"\20"
                  }

    :local input   [:tostr "$1"]
    :local options [:tostr "$2"]

    :local lowerarray {"a"="A";"b"="B";"c"="C";"d"="D";"e"="E";"f"="F"}

    :if (!($input~"^[0-9A-Fa-f]*\$")) do={
        :error "invalid characters: only 0-9, A-F and a-f are valid HexGSM7 values"
    }

    :if (!($options~"ignoreodd")) do={
        :if (([:len $input] % 2) != 0) do={:error "Invalid length, is odd."}
    }

    :local position 0
    :local output   "" ; :local work "" ; :local worknum 0 ; :local chk1 "" ; :local chk2 ""
    :while ($position < [:len $input]) do={
        :set chk1 [:pick $input $position       ($position + 1)]
        :set chk2 [:pick $input ($position + 1) ($position + 2)]
        :if ($chk1~"[a-f]") do={:set chk1 ($lowerarray->$chk1)}
        :if ($chk2~"[a-f]") do={:set chk2 ($lowerarray->$chk2)}
        :set work "$chk1$chk2"
        :if ([:len $work] = 2) do={
            :set worknum [:tonum "0x$work"]
            :if ($worknum > 0x7F) do={:error "Invalid 7-bit value ($worknum)"}
            :if ($work = "1B") do={
                :set chk1 [:pick $input ($position + 2) ($position + 3)]
                :set chk2 [:pick $input ($position + 3) ($position + 4)]
                :if ($chk1~"[a-f]") do={:set chk1 ($lowerarray->$chk1)}
                :if ($chk2~"[a-f]") do={:set chk2 ($lowerarray->$chk2)}
                :set work "$chk1$chk2"
                :if ([:len $work] = 2) do={
                    :set worknum [:tonum "0x$work"]
                    :if ($worknum > 0x7F) do={:error "Invalid 7-bit value after Escape (1B$worknum)"}
                    :if ($work = "1B") do={:error "Invalid Double Escape value"}
                    :set work ($cp1252->($worknum | 0x80))
                } else={:set work ""}
                :set position ($position + 2)
            } else={
                :set work ($cp1252->$worknum)
            }
        } else={:set work ""}
        :set output   "$output$work"
        :set position ($position + 2)
    }
    :return $output
}
