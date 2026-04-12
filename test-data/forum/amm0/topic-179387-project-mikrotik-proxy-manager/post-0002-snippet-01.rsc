# Source: https://forum.mikrotik.com/t/project-mikrotik-proxy-manager/179387/2
# Topic: Project mikrotik proxy manager
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

/container envs
add key=TRAEFIK_LOG_LEVEL name=traefik-proxy value=DEBUG
add key=TRAEFIK_PROVIDERS_FILE_DIRECTORY name=traefik-proxy value=/etc/traefik
add key=TRAEFIK_PROVIDERS_FILE_WATCH name=traefik-proxy value=true
add key=TRAEFIK_API_INSECURE name=traefik-proxy value=true
add key=TRAEFIK_ENTRYPOINTS_WEB_ADDRESS name=traefik-proxy value=:80
add key=TRAEFIK_ENTRYPOINTS_WEBSECURE_ADDRESS name=traefik-proxy value=:443
add key=TRAEFIK_CERTIFICATESRESOLVERS_LETSENCRYPT_ACME_EMAIL name=traefik-proxy value=null@example.com
add key=TRAEFIK_CERTIFICATESRESOLVERS_LETSENCRYPT_ACME_STORAGE name=traefik-proxy value=acme.json
add key=TRAEFIK_CERTIFICATESRESOLVERS_LETSENCRYPT_ACME_HTTPCHALLENGE_ENTRYPOINT name=traefik-proxy value=web
add key=PROXY_TO_URL name=traefik-proxy value=http://localhost:80/
add key=TRAEFIK_CERTIFICATESRESOLVERS_LETSENCRYPT_ACME name=traefik-proxy value=true
add key=TRAEFIK_ENTRYPOINTS_WEB_HTTP_REDIRECTIONS_ENTRYPOINT_TO name=traefik-proxy value=websecure
add key=TRAEFIK_SERVERSTRANSPORT_INSECURESKIPVERIFY name=traefik-proxy value=true
add key=TRAEFIK_ENTRYPOINTS_WEBSECURE_HTTP_TLS name=traefik-proxy value=true
add key=TRAEFIK_ENTRYPOINTS_WEBSECURE_HTTP_TLS_CERTRESOLVER name=traefik-proxy value=letsencrypt
add key=TRAEFIK_ENTRYPOINTS_WEBSECURE_HTTP_TLS_DOMAINS_1_MAIN name=traefik-proxy value="$[/ip/cloud/get dns-name]"
add key=TRAEFIK_LOG_NOCOLOR name=traefik-proxy value=false
