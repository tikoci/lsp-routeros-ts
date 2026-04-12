# Source: https://forum.mikrotik.com/t/scripting-in-the-context-of-netwatch/183585/19
# Topic: Scripting in the context of Netwatch
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

{
:local got [/tool/netwatch get [find host=8.8.8.8]]       
:log info "status $($got->"status") stdev $($got->"rtt-stdev") / $($got->"thr-stdev") max $($got->"rtt-max") / $($got->"thr-max") "
}
