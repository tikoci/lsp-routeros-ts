# Source: https://forum.mikrotik.com/t/v7-20beta-testing-is-released/183944/42
# Topic: V7.20beta [testing] is released!
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

/interface/list add name=REQUIRE_PROXY
/interface/list/member add list=REQUIRE_PROXY interface=<what-interface-to-force-sock-proxy>
/ip/firewall/nat/add action=socksify socks5-port=1080 socks5-server=127.0.0.1 in-interface-list=REQUIRE_PROXY chain=<input-or-srcnat>
