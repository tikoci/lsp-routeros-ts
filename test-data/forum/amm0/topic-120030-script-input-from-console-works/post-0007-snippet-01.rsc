# Source: https://forum.mikrotik.com/t/script-input-from-console-works/120030/7
# Topic: Script input from console ... works!
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

{
  :local myhelp "You can ask questions now!"
  :local myquestion "What do you want to ask?"
  :local myanswer [/terminal/ask preinput=$myhelp prompt=$myquestion]
  :put $myanswer
}
