# Source: https://forum.mikrotik.com/t/how-to-check-if-special-character-is-present-in-the-message/168997/2
# Topic: How to check if special character is present in the message?
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

:global messageText "bad string!!! & *even bad word d@c% or s#\$%"
:if ($messageText~"[!@#\$%^&*]") do={
    :error "bad char detected"
}
