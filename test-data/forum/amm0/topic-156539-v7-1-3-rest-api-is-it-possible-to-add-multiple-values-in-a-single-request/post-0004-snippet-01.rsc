# Source: https://forum.mikrotik.com/t/v7-1-3-rest-api-is-it-possible-to-add-multiple-values-in-a-single-request/156539/4
# Topic: V7.1.3 Rest API is it possible to add multiple values in a single request?
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

for addr in "8.8.8.8" "8.8.4.4"; do \
curl ... "https://192.168.88.1/rest/ip/firewall/address-list" --data " { \"address\": \"$addr\" ,\"list\":\"google-dns\"}" -H "content-type: application/json"; \
done;
