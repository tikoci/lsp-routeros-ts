# Source: https://forum.mikrotik.com/t/router-crashes-are-wiping-the-config/149189/7
# Post author: @rextended
# Extracted from: code-block

:local filelist ""
/file
:foreach file in=[find where type!=disk && type!=directory && !(name~"dude/files/default") && !(name~"^auto_") && !(name~"dude.db\$") && !(name~"db-...\$") && !(name~"user-manager")] do={
:if ($filelist != "") do={:set filelist ($filelist.",")}
:set filelist ($filelist.[get $file name])
}
:set dsubj "Backup all files inside $date $time"
:set dfile $filelist
$bymail
