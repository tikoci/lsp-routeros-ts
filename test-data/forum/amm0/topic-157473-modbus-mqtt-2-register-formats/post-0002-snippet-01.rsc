# Source: https://forum.mikrotik.com/t/modbus-mqtt-2-register-formats/157473/2
# Topic: Modbus MQTT 2 Register Formats
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

[admin@device] > {:local output [/iot modbus read-holding-registers slave-id=0x03 num-regs=0x1 reg-addr=0x0 as-value once];:put [($output->"values")]}
2349
[admin@device] > {:local output [/iot modbus read-holding-registers slave-id=0x03 num-regs=0x5 reg-addr=0x0 as-value once];:put [($output->"values")]}
2353;3;500;75;38
