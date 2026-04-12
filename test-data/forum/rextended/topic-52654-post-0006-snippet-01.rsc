# Source: https://forum.mikrotik.com/t/how-to-covert-int-to-hex-type-value-and-save-it-in-a-string/52654/6
# Post author: @rextended
# Extracted from: code-block

:global num2hex do={
  :local number  [:tonum $1]
  :local hexadec "0"
  :local remainder 0
  :local hexChars "0123456789ABCDEF"
  :if ($number > 0) do={:set hexadec ""}
  :while ( $number > 0 ) do={
        :set remainder ($number % 16)
        :set number (($number-$remainder) / 16)
        :set hexadec ([:pick $hexChars $remainder].$hexadec)
  } 
  :if ([:len $hexadec] = 1) do={:set hexadec "0$hexadec"}
  :return "0x$hexadec"
}
:put [$num2hex 7366]
