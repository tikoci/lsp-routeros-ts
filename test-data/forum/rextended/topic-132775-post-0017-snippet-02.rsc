# Source: https://forum.mikrotik.com/t/mkdir-function-for-easy-folder-creation/132775/17
# Post author: @rextended
# Extracted from: code-block

# global for test on terminal
:global results [$createpath ("backup/2021/09/08")]
:put ($results->0)
:put ($results->1)
