# Source: https://forum.mikrotik.com/t/script-to-add-ip-to-list-based-on-log-help-needed/156344/4
# Post author: @rextended
# Extracted from: code-block

/log print where message~"((25[0-5]|(2[0-4]|[01]\?[0-9]\?)[0-9])\\.){3}(25[0-5]|(2[0-4]|[01]\?[0-9]\?)[0-9])"
