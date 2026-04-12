# Source: https://forum.mikrotik.com/t/how-to-get-value-from-json-string-using-scripts/264287/2
# Topic: How to get value from json string using scripts
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

{
    :local mySunriseSunset [$getSunriseSunset latitude="54.3520" longitude="18.6464"]
    :put "sunrise: $($mySunriseSunset->"results"->"sunrise")"
    :put "sunset: $($mySunriseSunset->"results"->"sunset")"
}
