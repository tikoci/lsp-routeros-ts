# Source: https://forum.mikrotik.com/t/how-to-add-2fa-to-mikrotik-logins/264179/12
# Topic: How to add 2FA to MikroTik logins
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

:global username "forumadmin"
:global password "forumpassword"
:global authgroup "full"

# Generates a 40 char length string to mimic SHA1 (which `:convert tranform=` does not support)
:global otpsecret [:pick [:convert to=base32 [:rndstr length=40]] 0 40]

# Add new RouterOS user to user-manager (works via AAA in /user)
/user-manager/user add attributes="Mikrotik-Group:$authgroup" name="$username" password="$password" otp-secret="$otpsecret"

# Output new user information

:put "New AAA user with 2FA created:"
:put $username
:put $password
:put ""
:put "To setup in 2FA TOTP Authenticator, include Apple Password user the following URL"

:global url "otpauth://totp/$username?secret=$otpsecret&issuer=RouterOS&algorithm=SHA1&digits=6&period=30"
:put $url

# or if use SSH from a real terminal, the following will create a clickable link in terminal using ANSI codes:

:put "\1B]8;;$url\07$url\1B]8;;\07"
