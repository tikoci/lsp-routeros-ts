# Source: https://forum.mikrotik.com/t/a-very-simple-redirect-to-an-http-page-after-join-wifi/165960/21
# Topic: A very simple redirect (to an http page) after join WiFi
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

https: {
      key: require("fs").readFileSync('/data/privkey.pem'),
      cert: require("fs").readFileSync('/data/cert.pem')
    },
