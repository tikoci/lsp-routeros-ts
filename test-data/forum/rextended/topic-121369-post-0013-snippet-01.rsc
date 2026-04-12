# Source: https://forum.mikrotik.com/t/routeros-snmp-get/121369/13
# Post author: @rextended
# Extracted from: code-block

/file remove [find where name="testgetsnmp.txt"]
{
    :local jobid [:execute file=testgetsnmp.txt \
        script="/tool snmp-get tries=3 try-timeout=3s address=192.168.0.1 port=161 version=2c \
        community=public oid=1.3.6.1.4.1.14988.1.1.3.8.0"]
    :put "Waiting the end of process for file testgetsnmp.txt to be ready, max 20 seconds..."
    :global Gltesec 0
    :while (([:len [/sys script job find where .id=$jobid]] = 1) && ($Gltesec < 20)) do={
        :set Gltesec ($Gltesec + 1)
        :delay 1s
        :put "waiting... $Gltesec"
    }
    :put "Done. Elapsed Seconds: $Gltesec\r\n"
    :if ([:len [/file find where name="testgetsnmp.txt"]] = 1) do={
        :local filecontent [/file get [/file find where name="testgetsnmp.txt"] contents]
        :if ([:len $filecontent] = 83) do={:put "No result"; :return ""}
        :local oidstart ([:find $filecontent "\r\n" -1] + 2)
        :local oidend [:find $filecontent " " $oidstart]
        :local typestart ($oidstart + [:find $filecontent "TYPE" -1])
        :local typeend [:find $filecontent " " $typestart]
        :local valuestart ($oidstart + [:find $filecontent "VALUE" -1])
        :local valueend [:find $filecontent " " $valuestart]
        :local getoid [:pick $filecontent $oidstart $oidend]
        :local gettype [:pick $filecontent $typestart $typeend]
        :local getvalue [:pick $filecontent $valuestart $valueend]
        :put "The >$getoid< return >$gettype< value >$getvalue<"
    } else={
        :put "File not created."
    }
}
