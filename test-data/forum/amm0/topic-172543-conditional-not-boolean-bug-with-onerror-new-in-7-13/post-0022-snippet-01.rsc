# Source: https://forum.mikrotik.com/t/conditional-not-boolean-bug-with-onerror-new-in-7-13/172543/22
# Topic: `conditional not boolean` bug with :onerror (new in 7.13)
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

> :put [:typeof [:set zzz 12]]                                    
nil
> :put [:typeof [:put "sometext"]]         
sometext
str
