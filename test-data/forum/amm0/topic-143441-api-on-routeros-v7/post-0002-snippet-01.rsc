# Source: https://forum.mikrotik.com/t/api-on-routeros-v7/143441/2
# Topic: API on RouterOS v7
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

const RouterOSClient = require('routeros-client').RouterOSClient;

let testROSv7 = function (ip = process.env.MT_IP || '192.168.88.1') {
    const api = new RouterOSClient({
        host: ip,
        user: process.env.MT_USER || "admin",
        password:  process.env.MT_PASSWD || "",
        tls: { rejectUnauthorized: false }, // api-ssl uses self-signed cert, for testing ROSv7, any form of SSL will do
        port: 8729
    });

    api.connect().then((client) => {
    	// in ROSv7, route table and rules have moved from "/ip/route/rule" to "/routing/table" & "/routing/rule"
    	// assuming the API worked the same, it should be able read it using the new "ROS URL" for it
        client.menu("/routing/table").getOnly().then((result) => {
            console.log(result); 
            api.close();
        }).catch((err) => {
            console.log(err); // Some error...
        });
    }).catch((err) => {
        console.log(err)
        // Connection error
    });
}

testROSv7()
