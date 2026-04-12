# Source: https://forum.mikrotik.com/t/v7-13beta-testing-is-released/171132/26
# Topic: v7.13beta [testing] is released!
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

{
  :local arr {a=1;b="abc"}
  :local json [:serialize $arr to=json]
  :local arrFromJson [:deserialize $json from=json]
  :put "serialized json: $json"
  :put "deserialized json:"
  :put $arrFromJson
  :put "type of deserialized json: $[:typeof $arrFromJson]"
}
