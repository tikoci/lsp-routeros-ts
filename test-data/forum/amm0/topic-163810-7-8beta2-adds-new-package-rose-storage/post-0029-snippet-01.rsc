# Source: https://forum.mikrotik.com/t/7-8beta2-adds-new-package-rose-storage/163810/29
# Topic: 7.8beta2 adds new package ROSE-storage
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

[user@mt] /disk> /console/inspect request=syntax path=disk
Columns: TYPE, SYMBOL, SYMBOL-TYPE, NESTED, NONORM, TEXT
TYPE    SYMBOL           SYMBOL-TYPE  NESTED  NONORM  TEXT                                                                    
syntax                   collection        0  yes                                                                             
syntax  ..               explanation       1  no      go up to root                                                           
syntax  add              explanation       1  no      Create a new item                                                       
syntax  comment          explanation       1  no      Set comment for items                                                   
syntax  copy             explanation       1  no                                                                              
syntax  disable          explanation       1  no      Disable items                                                           
syntax  edit             explanation       1  no                                                                              
syntax  eject-drive      explanation       1  no                                                                              
syntax  enable           explanation       1  no      Enable items                                                            
syntax  export           explanation       1  no      Print or save an export script that can be used to restore configuration
syntax  find             explanation       1  no      Find items by value                                                     
syntax  format-drive     explanation       1  no                                                                              
syntax  get              explanation       1  no      Gets value of item's property                                           
syntax  monitor-traffic  explanation       1  no                                                                              
syntax  nvme-discover    explanation       1  no                                                                              
syntax  print            explanation       1  no      Print values of item properties                                         
syntax  raid-scrub       explanation       1  no                                                                              
syntax  remove           explanation       1  no      Remove item                                                             
syntax  reset            explanation       1  no                                                                              
syntax  reset-counters   explanation       1  no                                                                              
syntax  set              explanation       1  no      Change item properties                                                  
syntax  unset            explanation       1  no                                                                              

[user@mt] /disk> /console/inspect request=syntax path=disk,set
Columns: TYPE, SYMBOL, SYMBOL-TYPE, NESTED, NONORM, TEXT
TYPE    SYMBOL                    SYMBOL-TYPE  NESTED  NONORM  TEXT                                   
syntax                            collection        0  yes                                            
syntax  <numbers>                 explanation       1  no      List of item numbers                   
syntax  comment                   explanation       1  no      Short description of the item          
syntax  crypted-backend           explanation       1  no                                             
syntax  disabled                  explanation       1  no      Defines whether item is ignored or used
syntax  encryption-key            explanation       1  no                                             
syntax  iscsi-address             explanation       1  no                                             
syntax  iscsi-export              explanation       1  no                                             
syntax  iscsi-iqn                 explanation       1  no                                             
syntax  iscsi-port                explanation       1  no                                             
syntax  nfs-address               explanation       1  no                                             
syntax  nfs-export                explanation       1  no                                             
syntax  nfs-share                 explanation       1  no                                             
syntax  nvme-tcp-address          explanation       1  no                                             
syntax  nvme-tcp-export           explanation       1  no                                             
syntax  nvme-tcp-name             explanation       1  no                                             
syntax  nvme-tcp-port             explanation       1  no                                             
syntax  parent                    explanation       1  no                                             
syntax  partition-offset          explanation       1  no                                             
syntax  partition-size            explanation       1  no                                             
syntax  raid-chunk-size           explanation       1  no                                             
syntax  raid-device-count         explanation       1  no                                             
syntax  raid-master               explanation       1  no                                             
syntax  raid-max-component-size   explanation       1  no                                             
syntax  raid-member-failed        explanation       1  no                                             
syntax  raid-role                 explanation       1  no                                             
syntax  raid-type                 explanation       1  no                                             
syntax  ramdisk-size              explanation       1  no                                             
syntax  self-encryption-password  explanation       1  no                                             
syntax  slot                      explanation       1  no                                             
syntax  smb-address               explanation       1  no                                             
syntax  smb-export                explanation       1  no                                             
syntax  smb-password              explanation       1  no                                             
syntax  smb-share                 explanation       1  no                                             
syntax  smb-user                  explanation       1  no                                             
syntax  tmpfs-max-size            explanation       1  no                                             
syntax  type                      explanation       1  no
