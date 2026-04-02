# intentional-errors.rsc — deliberately broken script for diagnostic testing
# Used by token tests to verify error detection via variable-undefined tokens

# This variable is declared (should be fine)
:local defined "hello"
:put $defined

# This variable is NOT declared — should produce variable-undefined token
:put $undeclaredVariable

# Ambiguous / invalid command — should produce error token
:foobar
