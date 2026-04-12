# Source: https://forum.mikrotik.com/t/new-command-in-routeros-7/169237/29
# Topic: New command in RouterOs 7
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

/console/inspect request=syntax path=ip,address

Columns: TYPE, SYMBOL, SYMBOL-TYPE, NESTED, NONORM, TEXT
TYPE    SYMBOL   SYMBOL-TYPE  N  NON  TEXT                                                                    
syntax           collection   0  yes                                                                          
syntax  ..       explanation  1  no   go up to ip                                                             
syntax  add      explanation  1  no   Create a new item                                                       
syntax  comment  explanation  1  no   Set comment for items                                                   
syntax  disable  explanation  1  no   Disable items                                                           
syntax  edit     explanation  1  no                                                                           
syntax  enable   explanation  1  no   Enable items                                                            
syntax  export   explanation  1  no   Print or save an export script that can be used to restore configuration
syntax  find     explanation  1  no   Find items by value                                                     
syntax  get      explanation  1  no   Gets value of item's property                                           
syntax  print    explanation  1  no   Print values of item properties                                         
syntax  remove   explanation  1  no   Remove item                                                             
syntax  reset    explanation  1  no                                                                           
syntax  set      explanation  1  no   Change item properties
