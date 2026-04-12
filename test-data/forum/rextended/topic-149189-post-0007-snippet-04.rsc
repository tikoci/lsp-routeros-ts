# Source: https://forum.mikrotik.com/t/router-crashes-are-wiping-the-config/149189/7
# Post author: @rextended
# Extracted from: code-block

/file remove [find where name="auto_thedude.db"]
/dude export-db backup-file="auto_thedude.db"
:set dsubj "Backup The Dude Database $date $time"
:set dfile "auto_thedude.db"
$bymail $sendto $dsubj $dfile
