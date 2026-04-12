# Source: https://forum.mikrotik.com/t/cant-query-graphql-site/175320/27
# Topic: Can't Query Graphql site
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

# string that contain only ints or ".", become a floating point number type in JSON
:put [:serialize to=json "123"] 
      # 123.000000
:put [:serialize to=json "123.123"]
      # 123.123000
      
# and specifically to the OP's case...
:put [:serialize to=json "0000000000"]       
      0.000000 

# "num" RouterOS variable types, so remain ints
:put [:serialize to=json 123]       
      # 123
:put [:serialize to=json {a=123}]     
      # {"a":123}

# weird case, since 123.123 is an "ip" variable type in RouterOS...
# an IP address "pre-CIDR" could skip .0 in middle like :: in IPv6)....
# so this is correct since the JSON does not have an "ip" type, thus string
# and 123.123 is same IP address as more common 123.0.0.123 form, which likely be expected in most systems. 
:put [:serialize to=json 123.123]
      # "123.0.0.123"
