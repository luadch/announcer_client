sslparams = {

    [ "certificate" ] = "certs/servercert.pem",
    [ "ciphers" ] = "ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256",
    [ "key" ] = "certs/serverkey.pem",
    [ "mode" ] = "client",
    [ "protocol" ] = "tlsv1_2",

}

return sslparams