# Source: https://forum.mikrotik.com/t/fetch-capable-of-following-redirects/151723/7
# Post author: @rextended
# Extracted from: code-block

/file remove [find where name="testfetch.txt"]
{
    :local jobid [:execute file=testfetch.txt script="/tool fetch url=http://mikrotik.com"]
    :put "Waiting the end of process for file testfetch.txt to be ready, max 20 seconds..."
    :global Gltesec 0
    :while (([:len [/sys script job find where .id=$jobid]] = 1) && ($Gltesec < 20)) do={
        :set Gltesec ($Gltesec + 1)
        :delay 1s
        :put "waiting... $Gltesec"
    }
    :put "Done. Elapsed Seconds: $Gltesec\r\n"
    :if ([:len [/file find where name="testfetch.txt"]] = 1) do={
        :local filecontent [/file get [/file find where name="testfetch.txt"] contents]
        :put "Result of Fetch:\r\n****************************\r\n$filecontent\r\n****************************"
    } else={
        :put "File not created."
    }
}
