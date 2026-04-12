# Source: https://forum.mikrotik.com/t/amm0s-manual-for-custom-app-containers-7-22beta/268036/3
# Topic: 📚 Amm0's Manual for "Custom" /app containers (7.22beta+)
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

name: wordpress-site
descr: WordPress blog platform
category: productivity
default-credentials: web setup
page: https://wordpress.org

services:
  db:
    image: docker.io/mariadb:10.6
    environment:
      MYSQL_ROOT_PASSWORD: rootpass
      MYSQL_DATABASE: wordpress
    volumes:
      - wordpress/db:/var/lib/mysql
    restart: unless-stopped

  wordpress:
    image: docker.io/wordpress:latest
    ports:
      - 8080:80:web
    environment:
      WORDPRESS_DB_HOST: [accessIP]
      WORDPRESS_DB_NAME: wordpress
    volumes:
      - wordpress/html:/var/www/html
    depends_on:
      - db
    restart: unless-stopped

networks:
  default:
    name: lan
    external: true
