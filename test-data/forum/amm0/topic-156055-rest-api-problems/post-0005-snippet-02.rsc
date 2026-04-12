# Source: https://forum.mikrotik.com/t/rest-api-problems/156055/5
# Topic: REST API problems
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

# setting no charset works...

$fetchrest type="application/json"

#       status: finished
#   downloaded: 0KiBC-z pause]
#        total: 0KiB
#     duration: 1s

$fetchrest type="application/json;charset=utf-8"
#   status: failed
# failure: closing connection: <415 Unsupported Media Type> 127.0.0.1:443 (5)

$fetchrest type="application/json; charset=utf-8"
#   status: failed
# failure: closing connection: <415 Unsupported Media Type> 127.0.0.1:443 (5)

$fetchrest type="application/json; charset=utf-16"
#   status: failed
# failure: closing connection: <415 Unsupported Media Type> 127.0.0.1:443 (5)

$fetchrest type="application/json; charset=iso-8859-1"
#   status: failed
# failure: closing connection: <415 Unsupported Media Type> 127.0.0.1:443 (5)

$fetchrest type="application/json; charset=iso-8859-2"
#   status: failed
# failure: closing connection: <415 Unsupported Media Type> 127.0.0.1:443 (5)

$fetchrest type="application/json; charset=ISO-8859-1"
#   status: failed
# failure: closing connection: <415 Unsupported Media Type> 127.0.0.1:443 (5)

$fetchrest type="application/json; charset=ISO-8859-2"
#   status: failed
# failure: closing connection: <415 Unsupported Media Type> 127.0.0.1:443 (5)

$fetchrest type="application/json; charset=us-ascii"
#   status: failed
# failure: closing connection: <415 Unsupported Media Type> 127.0.0.1:443 (5)

$fetchrest type="application/json;charset=us-ascii"
#   status: failed
# failure: closing connection: <415 Unsupported Media Type> 127.0.0.1:443 (5)
