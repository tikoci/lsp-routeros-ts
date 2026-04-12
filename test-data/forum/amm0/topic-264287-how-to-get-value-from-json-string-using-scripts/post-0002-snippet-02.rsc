# Source: https://forum.mikrotik.com/t/how-to-get-value-from-json-string-using-scripts/264287/2
# Topic: How to get value from json string using scripts
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

:global getSunriseSunset do={
    :local apiUrl "https://api.sunrise-sunset.org/json?lat=$latitude&lng=$longitude&date=today&formatted=0"
    :local fetchResult [/tool fetch url=$apiUrl output=user as-value]
    :local jsonData ($fetchResult->"data")
    :local parsed [:deserialize from=json $jsonData]
    :return $parsed
}
