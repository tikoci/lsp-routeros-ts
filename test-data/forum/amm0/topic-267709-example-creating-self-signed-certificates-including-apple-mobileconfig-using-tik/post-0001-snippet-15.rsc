# Source: https://forum.mikrotik.com/t/example-creating-self-signed-certificates-including-apple-mobileconfig-using-tikbook/267709/1
# Topic: ✍️ Example: Creating self-signed certificates, including Apple `.mobileconfig`, using TikBook
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

# UUIDv4

:global UUIDv4 do={

:local uuid ""

# Part 1: 8 random hex characters (e.g., "xxxxxxxx")

:set uuid ($uuid . [:rndstr from="1234567890ABCDEF" length=8])

:set uuid ($uuid . "-")

# Part 2: 4 random hex characters (e.g., "xxxx")

:set uuid ($uuid . [:rndstr from="1234567890ABCDEF" length=4])

:set uuid ($uuid . "-")

# Part 3: 4xxx (The '4' indicates UUID version 4)

:set uuid ($uuid . "4")

:set uuid ($uuid . [:rndstr from="1234567890ABCDEF" length=4])

:set uuid ($uuid . "-")

# Part 4: yxxx (The 'y' indicates the UUID variant, must be 8, 9, a, or b)

:set uuid ($uuid . [:rndstr from="89AB" length=1])

:set uuid ($uuid . [:rndstr from="1234567890ABCDEF" length=3])

:set uuid ($uuid . "-")

# Part 5: 12 random hex characters (e.g., "xxxxxxxxxxxx")

:set uuid ($uuid . [:rndstr from="1234567890ABCDEF" length=12])

:return $uuid

}

:put [$UUIDv4]
