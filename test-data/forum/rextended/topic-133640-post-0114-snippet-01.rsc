# Source: https://forum.mikrotik.com/t/address-lists-downloader-dshield-spamhaus-drop-edrop-etc/133640/114
# Post author: @rextended
# Extracted from: code-block

POSIX syntax:
^(([a-zA-Z0-9][a-zA-Z0-9-]{0,61}){0,1}[a-zA-Z]\.){1,9}[a-zA-Z][a-zA-Z0-9-]{0,28}[a-zA-Z]$

for MikroTik:
$line~"^(([a-zA-Z0-9][a-zA-Z0-9-]{0,61}){0,1}[a-zA-Z]\\.){1,9}[a-zA-Z][a-zA-Z0-9-]{0,28}[a-zA-Z]\$"
