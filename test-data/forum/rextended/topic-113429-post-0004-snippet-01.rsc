# Source: https://forum.mikrotik.com/t/help-with-error-in-script-to-import-the-ipv4-full-bogons-list-from-www-team-cymru-org/113429/4
# Post author: @rextended
# Extracted from: code-block

/ip firewall address-list
{
:log info "Remove old bogon list"
remove [find where list="bogons"]

:log info "Fetching bogon list"
:local content ([/tool fetch url="https://www.team-cymru.org/Services/Bogons/fullbogons-ipv4.txt" mode=https output=user as-value]->"data")

:local contentLen [:len $content]
:local lineEnd -1
:local line ""
:local lastEnd -1

:log info "Adding bogons from memory"
:do { :set lineEnd [:find $content "\n" $lastEnd]
      :set line    [:pick $content $lastEnd $lineEnd]
      :set lastEnd ($lineEnd + 1)

      :if ([:typeof [:toip $line]] = "ip") do={
          add list="bogons" timeout=1w address=$line
      } else={
          :do {
              :local xparse ([[:parse ":return $line"]])
              :if ([:typeof $xparse] = "ip-prefix") do={
                  add list="bogons" timeout=1w address=$line
              }
          } on-error={}
      }

} while=($lineEnd < ($contentLen - 1))

:log info "Done."
}
