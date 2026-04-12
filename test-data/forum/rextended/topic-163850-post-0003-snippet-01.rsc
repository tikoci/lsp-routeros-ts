# Source: https://forum.mikrotik.com/t/change-word-in-comment/163850/3
# Post author: @rextended
# Extracted from: code-block

:global searep do={
    :local input [:tostr $1] ; :local search  [:tostr $2] ; :local replace [:tostr $3]
    :local start -1 ; :local tmppos 0 ; :local sx "" ; :local dx ""
    :while ([:typeof [:find $input $search $start]] = "num") do={
        :set tmppos [:find $input $search $start]
        :set sx     [:pick $input 0 $tmppos]
        :set dx     [:pick $input ($tmppos + [:len $search]) [:len $input]]
        :set start  ([:len "$sx$replace"] - 1)
        :set input  "$sx$replace$dx"
    }
    :return $input
}
