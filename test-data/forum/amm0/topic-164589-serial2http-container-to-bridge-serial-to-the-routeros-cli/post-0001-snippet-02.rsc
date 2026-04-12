# Source: https://forum.mikrotik.com/t/serial2http-container-to-bridge-serial-to-the-routeros-cli/164589/1
# Topic: "serial2http" — container to bridge serial to the RouterOS CLI
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

FROM python:3.11-alpine
WORKDIR /usr/src/app
RUN pip install --no-cache-dir 'pyserial>=3.5' 
COPY . .
CMD [ "python", "./serial2http-code.py" ]
