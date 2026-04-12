# Source: https://forum.mikrotik.com/t/revisiting-ros-7-20-4-toip-command/266374/12
# Topic: Revisiting ROS-7.20.4: ":toip" command?
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

{
    :local baseprefix 10.0.0.0/24
    :local baseip [:toip $baseprefix]
    :put "First IP address is $($baseip + 1)"
}

# First IP address is 10.0.0.1
