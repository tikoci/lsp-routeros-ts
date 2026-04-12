# Source: https://forum.mikrotik.com/t/router-crashes-are-wiping-the-config/149189/7
# Post author: @rextended
# Extracted from: code-block

/file remove [find where name="auto_user-manager.umb"]
/user-manager database save name="auto_user-manager"
:set dsubj "Backup User-Manager Database $date $time"
:set dfile "auto_user-manager.umb"
$bymail $sendto $dsubj $dfile
