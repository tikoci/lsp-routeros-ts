# Source: https://forum.mikrotik.com/t/feature-request-tool-fetch-http-post-can-send-a-file/154710/21
# Topic: Feature request: /tool fetch HTTP-POST can send a file
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

:global sendFormDataFile do={
    :local urlf $url
    :local formFieldName $field
    :local fileName $file
    :local mimeSeperator "--$[:rndstr]" 
    :local contentType "Content-Type: multipart/form-data; boundary=$mimeSeperator"
    :local fileMimeType "application/octet-stream"

    :local formdataMime "\
    $mimeSeperator\n\
    Content-Disposition: form-data; name=\"$formFieldName\"; filename=\"$formName\"\n\
    Content-Type: $fileMimeType\n\
    Content-Transfer-Encoding: base64\n\n\
    $[:convert from=raw to=base64 [/file/get $fileName content]]\n\n\
    $mimeSeperator--\n"

    /tool/fetch http-method=post url=$urlf http-header-field=$contentType http-data=$formdataMime output=user
}

$sendFormDataFile url="http://192.168.88.1:80/upload" file=myrouterfile field=formfieldname
