# Source: https://forum.mikrotik.com/t/can-a-script-be-created-if-a-wrong-login-name-is-used/132192/39
# Post author: @rextended
# Extracted from: code-block

from:
:foreach rlog in=[find where message~"((25[0-5]|(2[0-4]|[01]\?[0-9]\?)[0-9])\\.){3}(25[0-5]|(2[0-4]|[01]\?[0-9]\?)[0-9])"] do={

to:
:foreach rlog in=[find where !(message~" via ssh") and \
    message~"((25[0-5]|(2[0-4]|[01]\?[0-9]\?)[0-9])\\.){3}(25[0-5]|(2[0-4]|[01]\?[0-9]\?)[0-9])"] do={
