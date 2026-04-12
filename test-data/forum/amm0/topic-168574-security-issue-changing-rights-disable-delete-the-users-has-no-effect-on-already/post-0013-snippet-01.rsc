# Source: https://forum.mikrotik.com/t/security-issue-changing-rights-disable-delete-the-users-has-no-effect-on-already-logged-in-users/168574/13
# Topic: ⚠️Security Issue: Changing rights / disable / delete the users has no effect on already logged in users.
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

/user/active {:local lsess [print as-value where name~".*"]; :foreach i in=$lsess do={:do { 
        request-logout ($i->".id")
    } on-error={}}}
