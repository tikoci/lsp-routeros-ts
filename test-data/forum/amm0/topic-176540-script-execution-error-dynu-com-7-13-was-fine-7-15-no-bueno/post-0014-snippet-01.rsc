# Source: https://forum.mikrotik.com/t/script-execution-error-dynu-com-7-13-was-fine-7-15-no-bueno/176540/14
# Topic: Script Execution Error - Dynu.com 7.13 was fine 7.15 no bueno
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

:global anyorder do={ 
    :put "\$1 is $1"
    :put "\$arg1 is $arg1"
    :put "\$arg2 is $arg2"
}
