# VSCode Web CORS proxy guide

RouterOS LSP uses RouterOS REST endpoints such as `/rest/console/inspect`.
Browsers enforce same-origin and CORS checks, but RouterOS does not add the CORS
headers needed by `vscode.dev` or `github.dev`. VSCode Desktop does not need this
proxy; VSCode Web does.

## Recommended shape

Put an HTTPS reverse proxy between the browser and RouterOS:

```text
VSCode Web -> https://routeros-proxy.example.net -> http://192.168.88.1
```

Configure `routeroslsp.baseUrl` to the proxy URL, not the raw RouterOS URL. The
proxy must:

- use a certificate trusted by the browser;
- forward `/rest/*` requests to RouterOS;
- forward the `Authorization` header;
- add `Access-Control-Allow-Origin`;
- handle `OPTIONS` preflight requests.

Keep this proxy on a trusted network. It forwards credentials to the router, so
do not expose it publicly unless you have authentication, TLS, and network
controls you are comfortable operating.

## Caddy example

```caddyfile
routeros-proxy.example.net {
	header {
		Access-Control-Allow-Origin "https://vscode.dev"
		Access-Control-Allow-Methods "GET, POST, PATCH, PUT, DELETE, OPTIONS"
		Access-Control-Allow-Headers "Authorization, Content-Type"
	}

	@preflight method OPTIONS
	respond @preflight 204

	reverse_proxy 192.168.88.1:80
}
```

For `github.dev`, either change the origin to `https://github.dev` or use a
trusted internal origin policy that covers both hosts.

## nginx example

```nginx
server {
	listen 443 ssl;
	server_name routeros-proxy.example.net;

	ssl_certificate     /etc/letsencrypt/live/routeros-proxy.example.net/fullchain.pem;
	ssl_certificate_key /etc/letsencrypt/live/routeros-proxy.example.net/privkey.pem;

	location / {
		if ($request_method = OPTIONS) {
			add_header Access-Control-Allow-Origin "https://vscode.dev" always;
			add_header Access-Control-Allow-Methods "GET, POST, PATCH, PUT, DELETE, OPTIONS" always;
			add_header Access-Control-Allow-Headers "Authorization, Content-Type" always;
			return 204;
		}

		add_header Access-Control-Allow-Origin "https://vscode.dev" always;
		add_header Access-Control-Allow-Methods "GET, POST, PATCH, PUT, DELETE, OPTIONS" always;
		add_header Access-Control-Allow-Headers "Authorization, Content-Type" always;

		proxy_pass http://192.168.88.1;
		proxy_set_header Host $host;
		proxy_set_header Authorization $http_authorization;
	}
}
```

## RouterOS user

Use a limited RouterOS account for normal LSP features:

```routeros
/user/group add name=lsp policy=read,api,rest-api
/user add name=lsp password=<strong-password> group=lsp
```

Write-shaped operations such as `routeroslsp.server.router.executeScript` should
use separate explicit per-call credentials with the required write policy.

## Troubleshooting

- If the browser console shows a CORS preflight failure, check the proxy's
  `OPTIONS` handling and `Access-Control-Allow-Headers`.
- If RouterOS returns 401, check the LSP username/password and confirm the proxy
  forwards `Authorization`.
- If the browser rejects TLS, use a publicly trusted certificate or install your
  internal CA in the browser's trust store.
- If VSCode Desktop works but VSCode Web does not, the RouterOS connection is
  probably fine; focus on proxy, CORS, and browser TLS behavior.
