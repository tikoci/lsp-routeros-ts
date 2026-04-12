# Source: https://forum.mikrotik.com/t/how-to-read-line-by-line-from-a-file-using-a-script/179893/13
# Topic: How to Read line by line from a file using a script?
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

:put [:serialize to=json options=json.pretty [:deserialize "test\rte<!>st\ntest" delimiter="<!>" from=dsv options=dsv.plain]] 
[
    [
        "test"
    ],
    [
        "te",
        "st"
    ],
    [
        "test"
    ]
]
