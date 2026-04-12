# Source: https://forum.mikrotik.com/t/modbus-mqtt-2-register-formats/157473/3
# Topic: Modbus MQTT 2 Register Formats
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

{
:local modbusread [/iot modbus read-holding-registers slave-id=1 num-regs=2 reg-addr=514 as-value once];
:local reg514 ( ( ($modbusread->"values"->0) * 65536 ) + ($modbusread->"values"->1) )
:put $reg514
}
