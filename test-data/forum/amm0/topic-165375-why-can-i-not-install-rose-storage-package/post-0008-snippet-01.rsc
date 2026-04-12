# Source: https://forum.mikrotik.com/t/why-can-i-not-install-rose-storage-package/165375/8
# Topic: Why can I not install rose-storage package
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

/system/package { 
  update/check-for-updates duration=10s
  enable rose-storage
  apply-changes 
}
/system/reboot
