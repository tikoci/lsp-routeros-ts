# Source: https://forum.mikrotik.com/t/container-traefik-on-rb5009/165849/7
# Topic: Container "Traefik" (on RB5009)
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

log:
  level: debug
providers:
  file:
    directory: /etc/traefik
    watch: true
api:
  insecure: true
entryPoints:
  web:
    address: ":80"
  websecure:
    address: ":443"
certificatesResolvers:
  lets-encrypt:
    acme:
      email: REPLACE_WITH_VALID_EMAIL=me@example.com 
      storage: acme.json
      #caServer: "https://acme-staging-v02.api.letsencrypt.org/directory"
      httpChallenge:
        entryPoint: web
serversTransport:
  insecureSkipVerify: true
http:
  routers:
    bigdude-redirect-http:
      rule: "Host(`REPLACE_ME_WITH_IP_CLOUD_NAME_OR_YOUR_OWN=snXXXXXXX.mynetname.net`)"
      service: routeros-web
      entryPoints:
        - web
      middlewares:
        - redirect-https
    bigdude-https:
      rule: "Host(`REPLACE_ME_WITH_SAME_AS_ABOVE`)"
      service: routeros-web
      entryPoints:
        - websecure
      middlewares:
        - cors-routeros
      tls:
        certResolver: "lets-encrypt"
  services:
    routeros-web:
      loadBalancer:
        passHostHeader: false
        servers:
          - url: "http://172.18.18.1"
  middlewares:
    redirect-https:
      redirectScheme:
        scheme: https
        permanent: true 
    cors-routeros:
      headers:
        accessControlAllowCredentials: true
        accessControlAllowMethods:
          - GET
          - OPTIONS
          - PUT
          - POST
          - PATCH
          - DELETE
        accessControlAllowHeaders: "*"
        accessControlAllowOriginList:
          - https://localhost:3000
          - https://REPLACE_ME_WITH_SAME_AS_ABOVE=snXXXXXX.mynetname.net
        accessControlMaxAge: 100
        addVaryHeader: true
