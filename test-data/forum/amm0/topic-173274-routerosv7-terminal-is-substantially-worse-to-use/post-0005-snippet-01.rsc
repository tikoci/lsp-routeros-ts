# Source: https://forum.mikrotik.com/t/routerosv7-terminal-is-substantially-worse-to-use/173274/5
# Topic: RouterOSv7 - Terminal is substantially worse to use?
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

> /console/inspect request=completion input="pick"
Columns: TYPE, COMPLETION, STYLE, OFFSET, PREFERENCE, SHOW, TEXT
TYPE        COMPLETION  STYLE        OFFSET  PREFERENCE  SHOW  TEXT                                             
completion  pick        cmd               0          95  yes   return range of string characters or array values
completion              none              4          80  no    whitespace                                       
completion  ;           syntax-meta       4          40  no    end of command                                   

 > /console/inspect request=completion input=":pick "
Columns: TYPE, COMPLETION, STYLE, OFFSET, PREFERENCE, SHOW, TEXT
TYPE        COMPLETION  STYLE        OFFSET  PREFERENCE  SHOW  TEXT                                                                                 
completion  !           none              6  80          no    whitespace                                                                           
completion  begin       arg               6  96          yes   index of the first returned element                                                  
completion  counter     arg               6  96          yes   array or string value                                                                
completion  end         arg               6  96          yes   index of the first element that should not be returned                               
completion              none              6  64          no                                                                                         
completion  [           syntax-meta       6  75          no    start of command substitution                                                        
completion  (           syntax-meta       6  75          no    start of expression                                                                  
completion  $           syntax-meta       6  75          no    substitution                                                                         
completion  "           syntax-meta       6  75          no    start of quoted string                                                               
completion  {           syntax-meta       6  75          no    start of array value                                                                 
completion  <value>     none              6  -1          no    literal value that consists only of digits, letters and characters -.,:<>/|+_*&^%#@!~
