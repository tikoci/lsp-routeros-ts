# Source: https://forum.mikrotik.com/t/sorted-array-of-files/151870/2
# Post author: @rextended
# Extracted from: code-block

/file
{
:local maxbackup 5

:local crtime    ""
:local filename  ""
:local filelist  [:toarray ""]
:foreach file in=[find where type="backup"] do={
    :set crtime  [get $file creation-time]
    :local vdoff [:toarray "0,4,5,7,8,10"]
    :local MM    [:pick $crtime ($vdoff->2) ($vdoff->3)]
    :local M     [:tonum $MM]
    :if ($crtime ~ ".../../....") do={
        :set vdoff [:toarray "7,11,1,3,4,6"]
        :set M     ([:find "xxanebarprayunulugepctovecANEBARPRAYUNULUGEPCTOVEC" [:pick $crtime ($vdoff->2) ($vdoff->3)] -1] / 2)
        :if ($M>12) do={:set M ($M - 12)}
        :set MM    [:pick (100 + $M) 1 3]
    }
    :set crtime   "$[:pick $crtime ($vdoff->0) ($vdoff->1)]-$MM-$[:pick $crtime ($vdoff->4) ($vdoff->5)] $[:pick $crtime 12 20]"
    :set filename [get $file name]
    :set filelist ($filelist, [[:parse ":return {\"$crtime\"=\"$filename\"}"]])
    :put "\"$crtime\"=\"$filename\""
}

:local currentbk [:len $filelist]
:local overbackp ($currentbk - $maxbackup)

:if ($currentbk > $maxbackup) do={
    :foreach x,y in=$filelist do={
        :if ($overbackp > 0) do={
            :log info "There are more than $maxbackup backups, $y deleted"
#           remove [find where name="$y"]
            :set overbackp ($overbackp - 1)
        }
    }
}

}
