# Source: https://forum.mikrotik.com/t/snmpwalk-snmpget-cant-read-global-variable/174305/10
# Topic: snmpwalk/snmpget can't read global variable
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

:global savestate do={
    :do {  /file set "state$[:jobname].json" contents=[:serialize to=json $1]  } on-error={
           /file add name="state$[:jobname].json" contents=[:serialize to=json $1]
    }
}

:global getstate do={
    :return [:deserialize from=json [/file get "state$[:jobname].json" contents]]
}

# examples:
# an array to persist
:global myvars {a="123";b="something"}

# call \$savestate which write the RouterOS array as JSON to a file name state[:jobname].json
$savestate $myvars
:put [$getstate]

# the state is override if saved state is called again.
$savestate "mydata"
:put [$getstate]

# note: script depends on [:jobname] so the persisted variables should be scoped to each /system/script plus CLI has one state.
