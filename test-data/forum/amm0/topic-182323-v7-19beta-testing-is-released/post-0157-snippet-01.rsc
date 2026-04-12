# Source: https://forum.mikrotik.com/t/v7-19beta-testing-is-released/182323/157
# Topic: v7.19beta [testing] is released!
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

:global findFirstEvenNumber do={
    :local firstEven [:nothing]
    :foreach i in=$1 do={
        :if ($i % 2 = 0) do={:set firstEven $i}
    } on-error={
        # allows early exit without traversing entire list
    }
    :return $firstEven
}
:put [$findFirstEvenNumber ({1;1;2;1;1;1;1;1;1;4})]
