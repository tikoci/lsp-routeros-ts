# Source: https://forum.mikrotik.com/t/add-minutes-in-time-variable/141665/6
# Topic: add minutes in time variable
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

{
    # get current time into a variable
    :local start [:timestamp]
    # wait 5 seconds
    :delay 5s
    # show difference between now and the start (e.g. +5 seconds)
    :put ([:timestamp] - $start)
    # time can also be compared... so this is "true"
    :put ([:timestamp] > $start)
}
