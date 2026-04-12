# Source: https://forum.mikrotik.com/t/import-adguard-dns-container-image-problem/164536/12
# Topic: import adguard dns container image problem
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

# ...
   - name: Build and push
      uses: docker/build-push-action@v4
      with:
        context: .
        push: true
        sbom: false
        provenance: false
        platforms: linux/arm64,linux/arm/v7
