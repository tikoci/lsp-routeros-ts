# Source: https://forum.mikrotik.com/t/searching-for-words-in-an-array/171425/6
# Topic: Searching for words in an array.
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

:global months [ :toarray "jan, feb, mar, apr, may, jun, jul, aug, sep, oct, nov, dec"];
:put [:find $months "feb"]
# 1
:put [:typeof [:find $months "jan, f"]]
# nil
