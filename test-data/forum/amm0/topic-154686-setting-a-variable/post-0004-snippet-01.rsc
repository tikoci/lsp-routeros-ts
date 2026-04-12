# Source: https://forum.mikrotik.com/t/setting-a-variable/154686/4
# Topic: Setting a variable
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

:global cellulardata [/interface/lte/monitor  [/interface/lte find running] once as-value]
:log info "*LTE signal report*  CQI:  $($cellulardata->"cqi")  RSRQ: $($cellulardata->"rsrq")  RSRP: $($cellulardata->"rsrp") "

# you can also assign the various parts to a variable, which makes using them in a string easier
:global enb ($cellulardata->"enb-id")
:global sector ($cellulardata->"sector-id")
:global carrier ($cellulardata->"current-operator")
:global band ($cellulardata->"primary-band")
:global caband ($cellulardata->"ca-band")

:put "And, with https://cellmapper.net you can find location etc., checking '$carrier' for enb: $enb finding the sector $sector and/or $($cellulardata->"phy-cellid")"
:put "*LTE CA report*.  PRIMARY $band. with $([:len $caband]) subcarriers $caband"
# scripting tip: if you create new variable use only lowercase letters, the "string interpolation" is WAY cleaner see above vs first line with $($var->"attribute-name") stuff
