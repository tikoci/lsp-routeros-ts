# Source: https://forum.mikrotik.com/t/get-variables-from-file/178928/2
# Topic: get variables from file
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

{
  :local kvtxt "SCRIPT_VERSION=1.2.1\r\nREQ_ID=01J8C5ZV2AY6V6HWEB6F4HQJW5\r\nREQ_IP=172.21.104.34\r\nREQ_FAMILY=1\r\nREQ_CREATED=2024-09-22 06:16:32"

  # now use :deserialize to get an RouterOS array from file txt
  :local kvarray [:deserialize delimiter=("=") from=dsv options=dsv.plain [:tocrlf $kvtxt]]
  
   # yes, it's an array
  :put [:typeof $kvarray]
  :put $kvarray

  # to better see what got parsed, :serialize's "pretty json" provides a nice output of the array:
  :put [:serialize to=json options=json.pretty $kvarray]

  # and can use scripting to find the values using ->0 for the key, and ->1 to get to useful form:
  :local myconfig [:toarray ""]
  :foreach v in=$kvarray do={ :set ($myconfig->($v->0)) ($v->1) }
  :put $myconfig     
  :put ($myconfig->"SCRIPT_VERSION")
}
