# Source: https://forum.mikrotik.com/t/address-lists-downloader-dshield-spamhaus-drop-edrop-etc/133640/88
# Post author: @rextended
# Extracted from: code-block

with mandatory subnet mask
((25[0-5]|(2[0-4]|[01]?[0-9]?)[0-9])\\.){3}(25[0-5]|(2[0-4]|[01]?[0-9]?)[0-9])\\/(3[0-2]|[0-2]?[0-9])

with optional subnet mask
((25[0-5]|(2[0-4]|[01]?[0-9]?)[0-9])\\.){3}(25[0-5]|(2[0-4]|[01]?[0-9]?)[0-9])(\\/(3[0-2]|[0-2]?[0-9])){0,1}

without subnet mask
((25[0-5]|(2[0-4]|[01]?[0-9]?)[0-9])\\.){3}(25[0-5]|(2[0-4]|[01]?[0-9]?)[0-9])
