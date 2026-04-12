# Source: https://forum.mikrotik.com/t/iterate-over-all-elements-of-an-array-of-unknown-dimension/163033/42
# Post author: @rextended
# Extracted from: code-block

:local as do={
    # array initialized as joining empty array {} with "undefined"
    :local x ({})
    :global arg
    :set ($x->$arg) $arg
    :return $x
}
:put ("result of [\$as arg=1] = $[:tostr [$as arg=1]]")
:put ("result of [\$as arg=2] = $[:tostr [$as arg=2]]")
:put ("result of [\$as arg=3] = $[:tostr [$as arg=3]]")
