# Source: https://forum.mikrotik.com/t/sms-timestamp-system-date-and-case-sensitive/158216/13
# Post author: @rextended
# Extracted from: code-block

{
:local searchtoday [:pick [/sys clock get date] 1 11]
/tool sms inbox
:foreach sms in=[find where timestamp~$searchtoday] do={
    :put "timestamp=$[get $sms timestamp] phone=$[get $sms phone] type=$[get $sms type] message=$[get $sms message]"
}
}
