# Source: https://forum.mikrotik.com/t/functions-and-function-parameters/68159/45
# Topic: Functions and function parameters
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

:global "how-many-args-passed" do={
    :local argv [:toarray "$1,$2,$3,$4,$5,$6,$7,$8"]
    :put "I got $[:len $argv] unnamed arguments"
}

$"how-many-args-passed" one
	# I got 1 unnamed arguments
$"how-many-args-passed" one two
	# I got 2 unnamed arguments
$"how-many-args-passed" one two 3
	# I got 3 unnamed arguments
$"how-many-args-passed" one two 3 four
	# I got 4 unnamed arguments
