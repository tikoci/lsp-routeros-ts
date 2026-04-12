# Source: https://forum.mikrotik.com/t/v7-9beta-testing-is-released/165419/59
# Topic: v7.9beta [testing] is released!
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

[XXXX@Router-8802] > /console/inspect request=syntax path=task          
Columns: TYPE, SYMBOL, SYMBOL-TYPE, NESTED, NONORM, TEXT
TYPE    SYMBOL     SYMBOL-TYPE  NESTED  NONORM  TEXT                              
syntax             collection        0  yes                                       
syntax  ..         explanation       1  no      go up to root                     
syntax  add        explanation       1  no      Create a new item                 
syntax  find       explanation       1  no      Find items by value               
syntax  get        explanation       1  no      Gets value of item's property     
syntax  next       explanation       1  no      switch to the next background task
syntax  print      explanation       1  no      Print values of item properties   
syntax  remove     explanation       1  no      Remove item                       
syntax  terminate  explanation       1  no      terminate a background task       
syntax  unset      explanation       1  no                                        
[XXXX@Router-8802] > /console/inspect request=syntax path=task,add
Columns: TYPE, SYMBOL, SYMBOL-TYPE, NESTED, NONORM, TEXT
TYPE    SYMBOL            SYMBOL-TYPE  NESTED  NONORM  TEXT                                             
syntax                    collection        0  yes                                                      
syntax  append            explanation       1  no      append output to file                            
syntax  copy-from         explanation       1  no      Item number                                      
syntax  file-name         explanation       1  no      default filename for output                      
syntax  max-lines         explanation       1  no      maximum buffer lines                             
syntax  max-size          explanation       1  no      maximum save file size                           
syntax  no-header-paging  explanation       1  no      don't page header to output                      
syntax  save-interval     explanation       1  no      autosave interval for when filename is set       
syntax  save-timestamp    explanation       1  no      add a timestamp to the saved file                
syntax  source            explanation       1  no      command that should be executed in the background
syntax  switch-to         explanation       1  no      switch to background view immediately
