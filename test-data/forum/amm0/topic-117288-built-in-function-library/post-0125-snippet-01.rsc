# Source: https://forum.mikrotik.com/t/built-in-function-library/117288/125
# Topic: Built in function library
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

:if (([/system/check-installation as-value]->"status")~"ok") do={
	:put "good"
} else={
	:put "bad"
}
