# Source: https://forum.mikrotik.com/t/decimals/21737/11
# Topic: Decimals ?
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

:put  "$([$tobase 1]) $([$tobase 10]) $([$tobase 16]) $([$tobase 16 base=32])" 

:put "stripchar $([$strip char=":" "1:1:1:1" ])"

:put [$fromfloat [toip6 "1000:1::1"]]
:put [$fromfloat [toip6 "1001:1::1"]]
:put [$fromfloat [toip6 "1000:10::10"]]
:put [$fromfloat [toip6 "1001:10::10"]]
:put [$fromfloat [:toip6 "1001:03e9::1"]]
:put [$fromfloat [:toip6 "1001:1::03e9"]]
:put [$fromfloat [:toip6 "1000:540::10f7"]]

:put [$tofloat 0]
:put [$tofloat 1.1]
:put [$tofloat -1.1]
:put [$tofloat -123.-123]
:put [$tofloat 4343.1344]

:put [$fromfloat [$tofloat 0]]
:put [$fromfloat [$tofloat 1.1]]
:put [$fromfloat [$tofloat -1.1]]
:put [$fromfloat [$tofloat -123.123]]
:put [$fromfloat [$tofloat 4343.1344]]
