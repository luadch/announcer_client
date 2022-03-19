sslparams = {

    [ "certificate" ] = "certs/servercert.pem",
    [ "ciphers" ] = "HIGH",
    [ "ciphersuites" ] = "TLS_AES_256_GCM_SHA384:TLS_CHACHA20_POLY1305_SHA256:TLS_AES_128_GCM_SHA256",
    [ "key" ] = "certs/serverkey.pem",
    [ "mode" ] = "client",
    [ "protocol" ] = "tlsv1_3",

}

return sslparams