# Source: https://forum.mikrotik.com/t/script-not-running/176370/3
# Topic: Script not running
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

# if it was {name; email};...
:put [:serialize to=json {{"mateo";"mateo@example.com"};{"sofia";"sofia@example.com"}}]
# [["mateo","mateo@example.com"],["sofia","sofia@example.com"]]

# but the the comma, now a list....within a list
:put [:serialize to=json {{"mateo";"mateo@example.com"},{"sofia";"sofia@example.com"}}]
# [["mateo","mateo@example.com","sofia","sofia@example.com"]]

# so you do need parentheses if you want a one-dim array, without the extra outlist
:put [:serialize to=json ({"mateo";"mateo@example.com"},{"sofia";"sofia@example.com"})]
# ["mateo","mateo@example.com","sofia","sofia@example.com"]

# and you cannot even do this one.
:put [:serialize to=json ({"mateo";"mateo@example.com"};{"sofia";"sofia@example.com"})]
# syntax error (line 1 column 56)

# but it was just two list of emails, always semi-consoles
:put [:serialize to=json ({"igor@example.lv";"mateo@example.com"},{"nadia@example.lv";"sofia@example.com"})]
# ["igor@example.lv","mateo@example.com","nadia@example.lv","sofia@example.com"]
# or
:put [:serialize to=json (("igor@example.lv","mateo@example.com"),("nadia@example.lv","sofia@example.com"))]
# ["igor@example.lv","mateo@example.com","nadia@example.lv","sofia@example.com"]

# just not...
:put [:serialize to=json (("igor@example.lv","mateo@example.com");("nadia@example.lv","sofia@example.com"))]
# syntax error (line 1 column 45)
