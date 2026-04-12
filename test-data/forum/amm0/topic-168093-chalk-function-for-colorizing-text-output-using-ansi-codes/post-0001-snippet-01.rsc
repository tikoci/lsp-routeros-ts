# Source: https://forum.mikrotik.com/t/chalk-function-for-colorizing-text-output-using-ansi-codes/168093/1
# Topic: $CHALK - function for colorizing text output using ANSI codes
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

[amm0@Mikrotik] /> $CHALK red debug=yes

\1B[31;49m

[amm0@Mikrotik] /> $CHALK no-style debug=yes

\1B[39;49m

[amm0@Mikrotik] /> :put "\1B[31;49mcut-and-pasted-codes\1B[39;49m"
cut-and-pasted-codes   # (in bold red)
