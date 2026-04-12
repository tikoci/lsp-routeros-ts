# Source: https://forum.mikrotik.com/t/securely-storing-apikey-tokens-for-tool-fetch-approaches-secret/156066/6
# Topic: Securely storing apikey/tokens for /tool/fetch... Approaches?  == $SECRET
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

$SECRET 
#$SECRET
#   uses /ppp/secrets to store stuff like REST apikeys, or other sensative data
#        $SECRET print - prints stored secret passwords
#        $SECRET get <name> - gets a stored secret
#        $SECRET set <name> password="YOUR_SECRET" - sets a secret password
#        $SECRET remove <name> - removes a secret
#$SECRET: bad command

$SECRET print
#Flags: X - disabled 
# #   NAME         SERVICE CALLER-ID      PASSWORD      PROFILE      REMOTE-ADDRESS 

$SECRET add "rest_apikey" password="mikrotik"
#

$SECRET print
#Flags: X - disabled 
# #   NAME         SERVICE CALLER-ID      PASSWORD      PROFILE      REMOTE-ADDRESS 
# 0   ;;; used by $SECRET
#     rest_apikey  async                  mikrotik      null        

:put [$SECRET get rest_apikey]
# mikrotik

$SECRET remove rest_apikey
# 

:put [$SECRET get rest_apikey]
# no such item
