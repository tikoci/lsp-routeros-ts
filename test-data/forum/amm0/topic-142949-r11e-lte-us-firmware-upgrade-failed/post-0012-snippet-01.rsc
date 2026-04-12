# Source: https://forum.mikrotik.com/t/r11e-lte-us-firmware-upgrade-failed/142949/12
# Topic: R11e-LTE-US Firmware Upgrade "failed"
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

12:25:04 lte,async lte11-att1: sent AT@FOTACHECK="http://upgrade.mikrotik.com/fir
mware/R11e-LTE-US/"
 12:25:09 lte,error lte11-att1: reply timeout for: AT@FOTACHECK="http://upgrade.mi
krotik.com/firmware/R11e-LTE-US/"
 12:25:09 lte,account lte11-att1 session: 365s 298614/516037 bytes 1313/6368 packe
ts
 12:25:09 interface,info lte11-att1 link down
 12:25:09 lte,async lte11-att1: sent AT E0 V1
 12:25:19 lte,error lte11-att1: reply timeout for: AT E0 V1
 12:25:20 lte,async lte11-att1: sent AT E0 V1
 12:25:30 lte,error lte11-att1: reply timeout for: AT E0 V1
 12:25:30 lte,async lte11-att1: sent AT E0 V1
 12:25:35 lte,async lte11-att1: rcvd ERROR
 12:25:35 lte,async lte11-att1: sent AT+CFUN?
 12:25:35 lte,async lte11-att1: rcvd +CFUN: 1
 12:25:35 lte,async lte11-att1: sent AT+CFUN=4
