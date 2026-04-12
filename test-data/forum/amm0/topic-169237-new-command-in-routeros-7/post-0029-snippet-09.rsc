# Source: https://forum.mikrotik.com/t/new-command-in-routeros-7/169237/29
# Topic: New command in RouterOs 7
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

/console/inspect request=completion input="/ip/addr/set "
Columns: TYPE, COMPLETION, STYLE, OFFSET, PREFERENCE, SHOW, TEXT
TYPE        COMPLETION  STYLE        OFFSET  PREFERENCE  SHOW  TEXT                                   
completion  !           none             13  80          no    whitespace                             
completion  address     arg              13  96          yes   Local IP address                       
completion  broadcast   arg              13  95          yes   Broadcast address                      
completion  comment     arg              13  96          yes   Short description of the item          
completion  disabled    arg              13  96          yes   Defines whether item is ignored or used
completion  interface   arg              13  96          yes   Interface name                         
completion  netmask     arg              13  95          yes   Network mask                           
completion  network     arg              13  96          yes   Network prefix                         
completion  numbers     arg              13  96          yes   List of item numbers                   
completion              none             13  64          no                                           
completion  [           syntax-meta      13  75          no    start of command substitution          
completion  (           syntax-meta      13  75          no    start of expression                    
completion  $           syntax-meta      13  75          no    substitution                           
completion  "           syntax-meta      13  75          no    start of quoted string                 
completion  *           none             13  -1          no    id prefix                              
completion  <number>    none             13  -1          no    decimal number
