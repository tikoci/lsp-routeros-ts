# Source: https://forum.mikrotik.com/t/convert-any-text-to-unicode/164329/17
# Post author: @rextended
# Extracted from: code-block

from
:local CP1252toUTF8 {"00";"01";"02";.....................;"C3BD";"C3BE";"C3BF"}
to
:local CP1252toUTF8 {"\00";"\01";"\02";.....................;"\C3\BD";"\C3\BE";"\C3\BF"}

and from
        :local utf ($CP1252toUTF8->[:find $CP1252testEP [:pick $string $pos ($pos + 2)] -1])
        :local sym ""
        :if ([:len $utf] = 2) do={:set sym "%$[:pick $utf 0 2]" }
        :if ([:len $utf] = 4) do={:set sym "%$[:pick $utf 0 2]%$[:pick $utf 2 4]" }
        :if ([:len $utf] = 6) do={:set sym "%$[:pick $utf 0 2]%$[:pick $utf 2 4]%$[:pick $utf 4 6]" }
        :set constr "$constr$sym"
to
        :local utf ($CP1252toUTF8->[:find $CP1252testEP [:pick $string $pos ($pos + 2)] -1])
        :set constr "$constr$utf"
