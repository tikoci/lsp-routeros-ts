# Source: https://forum.mikrotik.com/t/please-i-need-help-for-understanding-funcions/165917/13
# Topic: Please i need help for understanding funcions
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

:global UPL do={
:local logftp "ftp/$aID_ftp.log"
:execute file=$logftp script="/tool fetch upload=yes url=\"sftp://$aIP/dude_rsa.pub\" src-path=\"server.pub\" user=\"admin-ssh\" keep-result=no"
}

$UPL aIP="10.50.0.191" aID="Test"
