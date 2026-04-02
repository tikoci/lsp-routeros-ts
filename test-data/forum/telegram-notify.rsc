# Source: MikroTik forum — Telegram notification pattern
# https://forum.mikrotik.com/
# Used as test data for RouterOS LSP

:local botToken "123456:ABC-DEF1234ghIkl-zyx57W2v1u123ew11"
:local chatID "-1001234567890"
:local message "RouterOS alert: interface ether1 went down"

:local url "https://api.telegram.org/bot$botToken/sendMessage"
:local payload "{\"chat_id\":\"$chatID\",\"text\":\"$message\",\"parse_mode\":\"HTML\"}"

:do {
  /tool fetch url=$url http-method=post http-data=$payload output=none
  :log info "Telegram notification sent"
} on-error={
  :log error "Failed to send Telegram notification"
}
