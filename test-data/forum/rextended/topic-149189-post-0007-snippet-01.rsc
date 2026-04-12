# Source: https://forum.mikrotik.com/t/router-crashes-are-wiping-the-config/149189/7
# Post author: @rextended
# Extracted from: code-block

:local sendto   "address@mail.ext"
:local certpass "myprivatepass"

/system clock
:local date   [get date]
:local time   [get time]

:local dsubj  ""
:local dfile  ""
:local bymail do={/delay 20s;/tool e-mail send to=$1 subject=$2 body=$2 file=$3}

/certificate
:foreach cert in=[find] do={
 :local certname [get $cert name]
 export-certificate $cert file-name="auto_$certname" type=pkcs12 export-passphrase=$certpass
 :set dsubj "Backup Certificate $certname $date $time"
 :set dfile "auto_$certname.p12"
 $bymail $sendto $dsubj $dfile
}

/ip ssh export-host-key key-file-prefix=auto_host-key
:set dsubj "Backup Host Key $date $time"
:set dfile "auto_host-key_dsa,auto_host-key_dsa.pub,auto_host-key_rsa,auto_host-key_rsa.pub"
$bymail $sendto $dsubj $dfile

/system license output
:set dsubj "Backup Licence Key $date $time"
:set dfile "$[/system license get software-id].key"
$bymail $sendto $dsubj $dfile

/export file="auto_export"
:set dsubj "Backup Export $date $time"
:set dfile "auto_export.rsc"
$bymail $sendto $dsubj $dfile

/user export file="auto_user_export"
:set dsubj "Backup Export User $date $time"
:set dfile "auto_user_export.rsc"
$bymail $sendto $dsubj $dfile

/system backup save name="auto_backup" dont-encrypt=yes
:set dsubj "Backup Binary $date $time"
:set dfile "auto_backup.backup"
$bymail $sendto $dsubj $dfile
