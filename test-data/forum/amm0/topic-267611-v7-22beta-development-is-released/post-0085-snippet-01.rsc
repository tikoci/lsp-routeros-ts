# Source: https://forum.mikrotik.com/t/v7-22beta-development-is-released/267611/85
# Topic: V7.22beta [development] is released!
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

/system/script remove [find name=setvar]
/system/script add name=setvar source={
/system/note set note="
time: $[:tostr $time]\r\n
topics: $topics\r\n
message: $message\r\n
extra-info: $[:tostr $"extra-info"]\r\n
buffer: $buffer"
}

/system/logging/action remove [find name=setvar]
/system/logging/action add target=script script=setvar name=setvar

/system/logging remove [find action=setvar]
/system/logging add topics="script" action=setvar
