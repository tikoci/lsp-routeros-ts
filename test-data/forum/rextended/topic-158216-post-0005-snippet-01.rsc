# Source: https://forum.mikrotik.com/t/sms-timestamp-system-date-and-case-sensitive/158216/5
# Post author: @rextended
# Extracted from: code-block

:global engdate2int do={
    :local input    [:tostr $1]
    :local intYear  ([:tonum [:pick $input 7 11]] * 10000)
    :local M ([:find "xxanebarprayunulugepctovecANEBARPRAYUNULUGEPCTOVEC" [:pick $input 1 3] -1] / 2); :if ($M>12) do={:set M ($M - 12)}
    :set   M ($M * 100)
    :local intDay   [:tonum [:pick $input 4 6]]

    :return ($intYear + $M + $intDay)
}
