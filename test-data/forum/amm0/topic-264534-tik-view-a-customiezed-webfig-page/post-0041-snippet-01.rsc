# Source: https://forum.mikrotik.com/t/tik-view-a-customiezed-webfig-page/264534/41
# Topic: Tik View - a customiezed webfig page
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

var activeUsers = {}
var serverSentEventListener = new EventSource('http://192.168.88.1/rest/user/active/listen')
serverSentEventListener.onmessage = function (event) {
  activeUsers[event.data[".id"]] = event.data
}
