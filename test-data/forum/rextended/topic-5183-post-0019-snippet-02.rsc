# Source: https://forum.mikrotik.com/t/changing-the-mmm-dd-yyyy-date-format/5183/19
# Post author: @rextended
# Extracted from: code-block

:if ($1 = "HH:mm") do={ :return "$HH:$mm"}
    :if ($1 = "Unix" ) do={ :return "$Unix"  }
