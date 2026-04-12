# Source: https://forum.mikrotik.com/t/the-irrationality-of-find/179114/18
# Topic: the irrationality of [find]
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

/ip hotspot user reset-counters [find name="a"];
/ip hotspot user remove a;
/ip hotspot user reset-counters [find name="a"]; -> resets counters of ->ALL<- users
