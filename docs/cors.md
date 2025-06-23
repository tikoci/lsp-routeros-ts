### 🚧 Help system is under construction


### What is a CORS Proxy?

Web browsers require \"same-origin\" for REST calls, unless CORS headers are provided.  RouterOS REST APU, used by the LSP, does not provide the needed the CORS support.  A workaround is to install a CORS proxy somewhere on your network that add the required CORS headers and \"proxies\" calls to RouterOS.

# How to run a CORS Proxy?

See documentation for most web servers, which can typically proxy CORS requests.  Some simpler solutions include:
  * [Caddy Server]()
  * [NGNIX Proxy Server]()
