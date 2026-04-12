# Source: https://forum.mikrotik.com/t/fetch-seems-to-behave-different-when-called-in-function/174004/8
# Topic: fetch seems to behave different when called in function
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

:global funcA do={
  :put "func A"
}

:local funcB do={
  :global funcA
  $funcA

  :put "func B"
}

$funcB
