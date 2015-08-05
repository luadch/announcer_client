rules = {

    [ 1 ] = {

        [ "active" ] = false,
        [ "blacklist" ] = {

            [ "(incomplete)" ] = true,
            [ "(no-sfv)" ] = true,
            [ "(nuked)" ] = true,

        },
        [ "category" ] = "<your_freshstuff_category>",
        [ "checkdirs" ] = true,
        [ "checkfiles" ] = false,
        [ "command" ] = "+addrel",
        [ "daydirscheme" ] = false,
        [ "path" ] = "C:/your/path/to/announce",
        [ "rulename" ] = "TEST",
        [ "whitelist" ] = {


        },
        [ "zeroday" ] = false,

    },

}

return rules