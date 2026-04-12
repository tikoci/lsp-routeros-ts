# Source: https://forum.mikrotik.com/t/address-lists-downloader-dshield-spamhaus-drop-edrop-etc/133640/158
# Post author: @rextended
# Extracted from: code-block

# 301 permanent redirect example
:put [$checkurl "http://forum.mikrotik.com"]
cod=301;txt=https://forum.mikrotik.com/

# 302 CDN redirect example:
:put [$checkurl "h ttps://snort.org/downloads/ip-block-list"]
cod=302;txt=https://snort-org-site.s3.amazonaws.com/.../ip_filter.blf?X-Amz-Algorithm=...

# 404 not found example
:put [$checkurl "https://forum.mikrotik.com/not-exist"]
cod=404;txt=Not Found
