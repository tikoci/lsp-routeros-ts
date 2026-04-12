# Source: https://forum.mikrotik.com/t/amm0s-manual-for-custom-app-containers-7-22beta/268036/1
# Topic: 📚 Amm0's Manual for "Custom" /app containers (7.22beta+)
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

# List all applications
/app/print

# "Tail" applications during operations
/app/print follow-only where !disabled

# Show specific application
/app/print detail where name=myapp

# If enabled, container will have additional details:
/container/print detail where name=app-myapp

# Enable/disable an application
/app/enable myapp 
/app/disable myapp

# Start/stop an application once "enabled"
/container/start app-myapp
/container/stop app-myapp

# Remove an custom application
/app/cleanup myapp
/app/remove myapp
