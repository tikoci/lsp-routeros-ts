# Source: https://forum.mikrotik.com/t/how-to-download-only-one-piece-of-file-at-a-time-with-tool-fetch-and-put-it-inside-a-variable/151020/1
# Post author: @rextended
# Extracted from: code-block

{
    :local url "https://www.iwik.org/ipcountry/US.cidr"
    :local filesize ([/tool fetch url=$url as-value output=none]->"downloaded")
# 64512 is the max size of RouterOS text variables.
# To insert the incomplete end of the previous file at the beginning of the next file, reduce the size of each piece accordingly.
    :local maxsize 64512
    :local start 0
    :local end ($maxsize - 1)
    :local partnumber ($filesize / ($maxsize / 1024))
    :local reminder ($filesize % ($maxsize / 1024))
    :if ($reminder > 0) do={ :set partnumber ($partnumber + 1) }
    :for x from=1 to=$partnumber step=1 do={
         /tool fetch url=$url http-header-field="Range: bytes=$start-$end" keep-result=yes dst-path="/part$x.txt"
         :set start ($start + $maxsize)
         :set end ($end + $maxsize)
    }
}
