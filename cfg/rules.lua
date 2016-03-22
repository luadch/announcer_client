rules = {

    [ 1 ] = {

        [ "active" ] = false,
        [ "alibicheck" ] = false,
        [ "alibinick" ] = "DUMP",
        [ "blacklist" ] = {

            [ "(incomplete)" ] = true,
            [ "(no-sfv)" ] = true,
            [ "(nuked)" ] = true,

        },
        [ "category" ] = "your_freshstuff_category",
        [ "checkage" ] = false,
        [ "checkdirs" ] = true,
        [ "checkdirsnfo" ] = false,
        [ "checkdirssfv" ] = false,
        [ "checkfiles" ] = false,
        [ "checkspaces" ] = false,
        [ "command" ] = "+addrel",
        [ "daydirscheme" ] = false,
        [ "maxage" ] = 0,
        [ "path" ] = "C:/your/path/to/announce",
        [ "rulename" ] = "a",
        [ "whitelist" ] = {


        },
        [ "zeroday" ] = false,

    },

}

return rules