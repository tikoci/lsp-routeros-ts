# Source: https://forum.mikrotik.com/t/docker-built-containers-wont-work-on-mikrotik/180943/10
# Topic: Docker built containers won't work on Mikrotik
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

TAG=myimage
BUILDX_PLATFORMS=linux/arm64
BUILDX_BUILDER_NAME=routeros-platforms-builder
docker buildx create --platform=$BUILDX_PLATFORMS --name $BUILDX_BUILDER_NAME 
docker buildx build --builder $BUILDX_BUILDER_NAME  --platform=$BUILDX_PLATFORMS --output "type=oci,dest=$TAG.tar" --tag $TAG .
