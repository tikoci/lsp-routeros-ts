# Source: https://forum.mikrotik.com/t/backup-config-to-gmail-v1-7/156147/10
# Topic: Backup config to Gmail v1.7
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

# did not work in V7
  $bymail $dsubj="Certificate $certname $date $time" $dfile="auto_$certname.p12"
# works in V7
 ($bymail $dsubj="Certificate $certname $date $time" $dfile="auto_$certname.p12")
 
# NOTE: I'm not sure the $ in $dsubj= needed
