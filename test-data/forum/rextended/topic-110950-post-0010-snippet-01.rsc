# Source: https://forum.mikrotik.com/t/send-mikrotik-notification-via-whatsapp/110950/10
# Post author: @rextended
# Extracted from: code-block

/log warning "callmebot 392*******: Service [Probe.Name] on [Device.Name] is now [Service.Status] ([Service.ProblemDescription])";
/tool fetch http-method=get mode=https url="https://api.callmebot.com/whatsapp.php?phone=+39392*******&apikey=******&text=Service [Probe.Name] on [Device.Name] is now [Service.Status] ([Service.ProblemDescription])";
