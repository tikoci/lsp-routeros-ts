# Source: https://forum.mikrotik.com/t/address-lists-downloader-dshield-spamhaus-drop-edrop-etc/133640/158
# Post author: @rextended
# Extracted from: code-block

{
    :local url        "https://snort.org/downloads/ip-block-list"
    :local filename   "ip_filter.blf"

    :local testresult [$checkurl $url]
    :local returncode  ($testresult->"cod")
    :local returntext  ($testresult->"txt")
    :if ($returncode = "200") do={
        # can be downloaded directly
        $update url=$url
    } else={
        :if ($returncode = "302") do={
            # use redirected URL
            $update url=$returntext
        } else={
            # some error happen
            :log error "Error checking $url: $returncode $returntext"
        }
    }
}
