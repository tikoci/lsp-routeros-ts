# Source: https://forum.mikrotik.com/t/routers-coming-with-default-passwords/165186/18
# Topic: Routers Coming with Default Passwords
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

:if (!($defconfPassword = "" || $defconfPassword = nil)) do={
   /user set admin password=$defconfPassword
   :delay 0.5
   /user expire-password admin 
 }
