# Source: https://forum.mikrotik.com/t/my-script-does-not-work-in-v7-10/175543/6
# Topic: "my script does not work" in v7.10
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

{
:local bgwtime [:deserialize from=json ([/tool/fetch url=https://worldtimeapi.org/api/timezone/Asia/Baghdad as-value output=user]->"data")]  
# debug to show output
:put $bgwtime
# print one value from the worldtimeapi.org data
:put ($bgwtime->"day_of_week")

# get it's unixtime as a int
:local bgwunix [:tonum ($bgwtime->"unixtime")]
:put $bgwunix
}
