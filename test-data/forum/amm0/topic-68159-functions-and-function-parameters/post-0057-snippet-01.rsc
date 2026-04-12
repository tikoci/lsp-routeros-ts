# Source: https://forum.mikrotik.com/t/functions-and-function-parameters/68159/57
# Topic: Functions and function parameters
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

:global fnOuter do={
   :local outer 1
   :local fnInner do={
       :local inner 2
       :put "outer local inside fnInner is '$outer' of type $[:typeof $outer] = should be nothing"
       # below would be invalid - since the outer local is not available inside a local function
       # :set outer "I am a script error"
       :return $inner
    }
    :put "outer is '$outer' of type $[:typeof $outer]"
    :put "calling fnInner got $([$fnInner])"
     :put "outer after call to local function fnInner is '$outer' of type $[:typeof $outer]"
     :put "inner from the local function fnInner is not valid:  '$inner' with type $[:typeof $inner]"
    :return [:nothing]
}
$fnOuter
