# Source: https://forum.mikrotik.com/t/base64-and-sha256-function-for-scripting/164889/6
# Post author: @rextended
# Extracted from: code-block

:global base16dec do={
    :local input   [:tostr "$1"]
    :local options [:tostr "$2"]

    :local hex2chr do={:return [[:parse "(\"\\$1\")"]]}
    :local lowerarray {"a"="A";"b"="B";"c"="C";"d"="D";"e"="E";"f"="F"}

    :if (!($input~"^[0-9A-Fa-f]*\$")) do={
        :error "invalid characters: only 0-9, A-F and a-f are valid Base16 values"
    }

    :if (!($options~"ignoreodd")) do={
        :if (([:len $input] % 2) != 0) do={:error "Invalid length, is odd."}
    }

    :local position 0
    :local output   "" ; :local work "" ; :local chk1 "" ; :local chk2 ""
    :while ($position < [:len $input]) do={
        :set chk1 [:pick $input $position       ($position + 1)]
        :set chk2 [:pick $input ($position + 1) ($position + 2)]
        :if ($chk1~"[a-f]") do={:set chk1 ($lowerarray->$chk1)}
        :if ($chk2~"[a-f]") do={:set chk2 ($lowerarray->$chk2)}
        :set work "$chk1$chk2"
        :if ([:len $work] = 2) do={
            :set work [$hex2chr $work]
        } else={
            :set work ""
        }
        :set output   "$output$work"
        :set position ($position + 2)
    }
    :return $output
}
