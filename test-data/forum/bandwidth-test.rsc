# Source: MikroTik forum — bandwidth test / traffic generator pattern
# https://forum.mikrotik.com/
# Used as test data for RouterOS LSP

:global bwTestResults [:toarray ""]
:local targetIP "192.168.88.2"
:local duration 10
:local direction "both"

:for i from=1 to=5 do={
  :local result [/tool bandwidth-test address=$targetIP duration=$duration direction=$direction]
  :set ($bwTestResults->[:len $bwTestResults]) {
    "run"=$i;
    "tx"=($result->"tx-current");
    "rx"=($result->"rx-current")
  }
  :log info "Run $i: TX=$[:pick ($result->\"tx-current\") 0 10] RX=$[:pick ($result->\"rx-current\") 0 10]"
  :delay 2s
}

:log info "Bandwidth test complete — $[:len $bwTestResults] runs"
