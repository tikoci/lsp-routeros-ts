# Source: https://forum.mikrotik.com/t/address-lists-downloader-dshield-spamhaus-drop-edrop-etc/133640/116
# Post author: @rextended
# Extracted from: code-block

search for valid DNS
(([a-zA-Z0-9][a-zA-Z0-9-]{0,61}){0,1}[a-zA-Z]\\.){1,9}[a-zA-Z][a-zA-Z0-9-]{0,28}[a-zA-Z]

IP-Prefix: IP with mandatory subnet mask
((25[0-5]|(2[0-4]|[01]?[0-9]?)[0-9])\\.){3}(25[0-5]|(2[0-4]|[01]?[0-9]?)[0-9])\\/(3[0-2]|[0-2]?[0-9])

IP or IP-Prefix if present optional subnet mask
((25[0-5]|(2[0-4]|[01]?[0-9]?)[0-9])\\.){3}(25[0-5]|(2[0-4]|[01]?[0-9]?)[0-9])(\\/(3[0-2]|[0-2]?[0-9])){0,1}

IP without prefix
((25[0-5]|(2[0-4]|[01]?[0-9]?)[0-9])\\.){3}(25[0-5]|(2[0-4]|[01]?[0-9]?)[0-9])
