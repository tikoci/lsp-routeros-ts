# Source: https://forum.mikrotik.com/t/iterate-over-all-elements-of-an-array-of-unknown-dimension/163033/3
# Post author: @rextended
# Extracted from: code-block

:global test {{"A";"D";"I";"P";"Y"};{"B";"C";"H";"O";"X"};{"E";"F";"G";"N";"W"};{"J";"K";"L";"M";"V"};{"Q";"R";"S";"T";"U"}}
:put $x
:put ($test->0->0)
:put ($test->0->1)
:put ($test->0->2)
:put ($test->0->3)
:put ($test->0->4)
:put ($test->1->0)
:put ($test->1->1)
:put ($test->1->2)
:put ($test->1->3)
:put ($test->1->4)
:put ($test->2->0)
:put ($test->2->1)
:put ($test->2->2)
:put ($test->2->3)
:put ($test->2->4)
:put ($test->3->0)
:put ($test->3->1)
:put ($test->3->2)
:put ($test->3->3)
:put ($test->3->4)
:put ($test->4->0)
:put ($test->4->1)
:put ($test->4->2)
:put ($test->4->3)
:put ($test->4->4)
