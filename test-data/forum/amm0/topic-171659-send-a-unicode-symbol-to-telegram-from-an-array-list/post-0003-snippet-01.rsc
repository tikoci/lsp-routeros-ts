# Source: https://forum.mikrotik.com/t/send-a-unicode-symbol-to-telegram-from-an-array-list/171659/3
# Topic: Send a unicode symbol to Telegram from an array list
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

# Function $SymbolByUnicodeName by @eworm
:global SymbolByUnicodeName do={
    :local Symbols {
        "abacus"="\F0\9F\A7\AE";
        "alarm-clock"="\E2\8F\B0";
        "calendar"="\F0\9F\93\85";
        "card-file-box"="\F0\9F\97\83";
        "chart-decreasing"="\F0\9F\93\89";
        "chart-increasing"="\F0\9F\93\88";
        "cloud"="\E2\98\81";
        "cross-mark"="\E2\9D\8C";
        "earth"="\F0\9F\8C\8D";
        "fire"="\F0\9F\94\A5";
        "floppy-disk"="\F0\9F\92\BE";
        "high-voltage-sign"="\E2\9A\A1";
        "incoming-envelope"="\F0\9F\93\A8";
        "information"="\E2\84\B9";
        "large-orange-circle"="\F0\9F\9F\A0";
        "large-red-circle"="\F0\9F\94\B4";
        "link"="\F0\9F\94\97";
        "lock-with-ink-pen"="\F0\9F\94\8F";
        "memo"="\F0\9F\93\9D";
        "mobile-phone"="\F0\9F\93\B1";
        "pushpin"="\F0\9F\93\8C";
        "scissors"="\E2\9C\82";
        "sparkles"="\E2\9C\A8";
        "speech-balloon"="\F0\9F\92\AC";
        "up-arrow"="\E2\AC\86";
        "warning-sign"="\E2\9A\A0";
        "white-heavy-check-mark"="\E2\9C\85"
    }
    :local symnames [:toarray $1]
    :local retval ""
    :foreach symname in=$symnames do={
        :set retval ($retval . ($Symbols->$symname))   
    }
    :return ($retval . "\EF\B8\8F");
}
