# Unicode-heavy script — tests replaceNonAscii handling
# Contains characters from various non-ASCII ranges

:local café "espresso"
:local naïve "simple"
:local résumé "document"
:put "Héllo Wörld"
:put "Ünïcödé tëst"
:put "日本語テスト"
:put "中文测试"
:put "Ελληνικά"
:put "العربية"
:put "emoji: 🎉🚀💡"

# RouterOS escape sequences for UTF-8 (these stay ASCII)
:put "\E2\9A\99\EF\B8\8F"
:put "\F0\9F\93\85"

:local price "€100"
:local temp "25°C"
:put "£50 or ¥1000"
