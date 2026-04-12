# Source: https://forum.mikrotik.com/t/how-to-download-only-one-piece-of-file-at-a-time-with-tool-fetch-and-put-it-inside-a-variable/151020/1
# Post author: @rextended
# Extracted from: code-block

{
:local test ([fetch url="https://www.iwik.org/ipcountry/US.cidr" http-header-field="Range: bytes=0-64511" as-value output=user]->"data")
:put $test
}
