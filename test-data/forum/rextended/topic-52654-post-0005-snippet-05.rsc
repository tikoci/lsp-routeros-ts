# Source: https://forum.mikrotik.com/t/how-to-covert-int-to-hex-type-value-and-save-it-in-a-string/52654/5
# Post author: @rextended
# Extracted from: code-block

:global SingleWordHexToNum do={
  :local Input [:tostr $1]
  :local Hex "0123456789abcdef_eworm.de_ABCDEF"
  :local Multi 1; :local Return 0
  :for I from=([:len $Input] - 1) to=0 do={
    :set Return ($Return + (([:find $Hex [:pick $Input $I]] % 16) * $Multi))
    :set Multi ($Multi * 16)
  }
  :if ($Return > 32767) do={ :return ($Return - 65536) } else={ :return $Return }
}
:put [$SingleWordHexToNum "0xFF85"]
