# Source: https://forum.mikrotik.com/t/v7-12beta-testing-is-released/168851/243
# Topic: v7.12beta [testing] is released!
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

/iot mqtt { 
    :local mytopic "mikrotik/mqtt"
    :local myhost "test.mosquitto.org"
    
    # clear existing message
    # /iot mqtt subscriptions recv clear

    # setup new broker
    brokers add address=$myhost name=mosquitto-test port=1883
    
    # add subscription with "on-message"
    subscriptions add broker=mosquitto-test topic=$mytopic on-message=":log info \"test \$msgTopic \$msgData\""
    :delay 1s
    
    # create 10 message with different "seq:" with UTF-8 encoded emoji.
    :for i from=1 to=10 do={ 
        publish topic=$mytopic broker=mosquitto-test message="{ \"seq\": $i;  \"msg\": \"\F0\9F\A7\90\"}"
        :delay 1s
    }

    # show them on screen
    subscriptions recv print

    # remove out broker (to force a disconnect since test server has timeouts)
    broker remove [find name="mosquitto-test"]
}
