# Source: https://forum.mikrotik.com/t/routeros-lsp-for-better-syntax-checking-command-completion-in-editors-like-vscode-neovim/184067/2
# Topic: 🧬 RouterOS LSP for better syntax checking & command completion in editors like VSCode & NeoVim
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

:put [:serialize to=json [/console/inspect request=highlight input="/ip/address bad-param" as-value ]]
{"highlight":["dir","dir","dir","dir","dir","dir","dir","dir","dir","dir","dir","none","obj-inactive","obj-inactive","obj-inactive","obj-inactive","obj-inactive","obj-inactive","obj-inactive","obj-inactive","obj-inactive"],"type":"highlight"}
:put [:serialize to=json [/console/inspect request=highlight input="/ip/address add bad-param" as-value ]]         
{"highlight":["dir","dir","dir","dir","dir","dir","dir","dir","dir","dir","dir","none","cmd","cmd","cmd","none","error","none","none","none","none","none","none","none","none"],"type":"highlight"}
:put [:serialize to=json [/console/inspect request=highlight input="/ip/address add address " as-value ]]
{"highlight":["dir","dir","dir","dir","dir","dir","dir","dir","dir","dir","dir","none","cmd","cmd","cmd","none","arg","arg","arg","arg","arg","arg","arg","syntax-obsolete"],"type":"highlight"}
:put [:serialize to=json [/console/inspect request=highlight input="/ip/address add address=" as-value ]]  
{"highlight":["dir","dir","dir","dir","dir","dir","dir","dir","dir","dir","dir","none","cmd","cmd","cmd","none","arg","arg","arg","arg","arg","arg","arg","syntax-meta"],"type":"highlight"}
:put [:serialize to=json [/console/inspect request=highlight input="/ip/address add address2=" as-value ]]
{"highlight"":["dir","dir","dir","dir","dir","dir","dir","dir","dir","dir","dir","none","cmd","cmd","cmd","none","error","none","none","none","none","none","none","none","none"],"type":"highlight"}
