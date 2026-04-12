# Source: https://forum.mikrotik.com/t/checking-recursive-route-values/167746/7
# Topic: Checking Recursive Route values
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

{
:local vlanspecs {vid=10;type="access"}
:put ($vlanspecs->"vid")
:put ($vlanspecs->"type")
:put [:typeof ($vlanspecs->"somethingnotthere")]
}
