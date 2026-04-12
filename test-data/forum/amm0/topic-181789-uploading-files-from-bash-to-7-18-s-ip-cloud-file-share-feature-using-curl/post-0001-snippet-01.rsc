# Source: https://forum.mikrotik.com/t/uploading-files-from-bash-to-7-18s-ip-cloud-file-share-feature-using-curl/181789/1
# Topic: uploading files from "bash" to 7.18's /ip/cloud/file-share feature using `curl`
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

ICFS_URL="https://0fak3serial123.routingthecloud.net/s/sEcRetKEYfromRtROS"
copy2router() {
    local files=("$@")
    if [[ -z "$ICFS_URL" ]]; then
	echo "ICFS_URL must be to the 'File Share URL' from a RouterOS /ip/cloud/file-share"
	echo "    The environment variable must be in you shell $0"
	echo "         export ICFS_URL=\"https://sn12345677.routingthecloud.new/s/key123456\"" 
    fi
    local form_data=()
    for file in "${files[@]}"; do
        form_data+=("-F" "file=@$file")
    done
    curl "$ICFS_URL/" "${form_data[@]}"
}
