# Source: https://forum.mikrotik.com/t/v7-16beta-testing-is-released/176494/19
# Topic: v7.16beta [testing] is released!
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

# fetch Mikrotik's "Product Matrix CSV" from website
    :global productDsvRaw ([/tool/fetch url="https://mikrotik.com/products/matrix" http-data="ax=matrix" output=user as-value]->"data")

    # use NEW "DSV" support to convert it to an RouterOS array
    :global productsArray [:deserialize from=dsv $productDsvRaw delimiter=";" options=dsv.plain]

    # as an array, you can use it a loops etc...
        # so to print first 20 devices from the downloaded (to memory) CSV
    :foreach k,v in=$productsArray do={ :if ($k<20) do={:put "\$productsArray->$k = $($v->1)"}}
        
        # or perhaps the count of them
    :put "\r\nNumber of devices: $([:len $productsArray] / 2 - 1)"

    # OR... the new add-on the to=json, which does a pretty print of JSON text
    :global prettyProductJson [:serialize to=json options=json.pretty $productsArray]
    :put [:pick $prettyProductJson 0 512]
        # this also useful since :put <array> is hard to read...
        # for example the array looks like
    :put [:pick [:tostr $productsArray] 0 512]
