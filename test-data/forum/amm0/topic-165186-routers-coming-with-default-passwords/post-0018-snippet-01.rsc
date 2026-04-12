# Source: https://forum.mikrotik.com/t/routers-coming-with-default-passwords/165186/18
# Topic: Routers Coming with Default Passwords
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

/interface wifiwave2 {
   set $ifcId security.authentication-types=wpa2-psk,wpa3-psk security.passphrase=$defconfWifiPassword
 }
