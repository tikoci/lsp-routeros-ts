# Source: https://forum.mikrotik.com/t/how-to-check-if-special-character-is-present-in-the-message/168997/3
# Topic: How to check if special character is present in the message?
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

{
  :local message "!Your message here"
  :local specialChars "[!@#\$%^&*]"
  :local found false

  :if ($message ~ $specialChars) do={
      :set found true
      :log warning "found"
  }
}
