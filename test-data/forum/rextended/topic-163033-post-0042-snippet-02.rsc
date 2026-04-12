# Source: https://forum.mikrotik.com/t/iterate-over-all-elements-of-an-array-of-unknown-dimension/163033/42
# Post author: @rextended
# Extracted from: code-block

:local at do={
    # array initialized as joining two empty array {}
    :local x ({},{})
    :global arg
    :set ($x->$arg) $arg
    :return $x
}
:put ("result of [\$at arg=1] = $[:tostr [$at arg=1]]")
:put ("result of [\$at arg=2] = $[:tostr [$at arg=2]]")
:put ("result of [\$at arg=3] = $[:tostr [$at arg=3]]")
