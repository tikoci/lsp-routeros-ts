# Source: https://forum.mikrotik.com/t/how-to-get-the-avg-rtt-value-of-command-ping/63496/5
# Post author: @rextended
# Extracted from: code-block

/file remove [find where name="testmacping.txt"]
{
    :local jobid [:execute file=testmacping.txt script="/ping address=64:D1:54:55:FF:CC arp-ping=yes interface=bridge count=10"]
    :put "Waiting the end of process for file testmacping.txt to be ready, max 20 seconds..."
    :global Gltesec 0
    :while (([:len [/sys script job find where .id=$jobid]] = 1) && ($Gltesec < 20)) do={
        :set Gltesec ($Gltesec + 1)
        :delay 1s
        :put "waiting... $Gltesec"
    }
    :put "Done. Elapsed Seconds: $Gltesec\r\n"
    :if ([:len [/file find where name="testmacping.txt"]] = 1) do={
        :local filecontent [/file get [/file find where name="testmacping.txt"] contents]
        :if ($filecontent ~ "received=0") do={:put "Unreachable"; :return ""}
        :if ($filecontent ~ "input does not match any value of interface") do={:put "Wrong Interface"; :return ""}
        :local resultstart [:find $filecontent "sent" -1]
        :local resultend [:find $filecontent " \r\n\r\n" $resultstart]
        :local getresult [:pick $filecontent $resultstart $resultend]
        :local getavgrtt [:pick $getresult ([:find $getresult "avg-rtt=" -1] + 8) [:find $getresult " max-rtt" -1] ]
        :put "Result: >$getresult<"
        :put "only avg-rtt: >$getavgrtt<"
    } else={
        :put "File not created."
    }
}
