# Source: https://forum.mikrotik.com/t/changing-the-mmm-dd-yyyy-date-format/5183/17
# Post author: @rextended
# Extracted from: code-block

:local hostname [/system identity get name]
:local date [/system clock get date]
:local localfilename "$hostname-Backup-Daily";
:local remotefilename "$hostname-$date";
