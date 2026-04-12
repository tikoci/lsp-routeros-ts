# Source: https://forum.mikrotik.com/t/importing-ip-list-from-file/143071/33
# Post author: @rextended
# Extracted from: code-block

/ip dns static
{
    :local testcounter 0
    :put "Deletion in progress, please wait..."
    :foreach dns in=[find where address=127.0.0.1] do={
        :if (($testcounter % 10) = 0) do={ :put "deleted till now: $testcounter..." }
        :set testcounter ($testcounter + 1)
        remove [find where .id=$dns]
    }
    :put "Done.\r\nTotal deleted: $testcounter"
}
