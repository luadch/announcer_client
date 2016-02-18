rules = {

    [ 1 ] = {

        [ "active" ] = false,
        [ "alibicheck" ] = false,
        [ "alibinick" ] = "DUMP",
        [ "blacklist" ] = {

            [ "(incomplete)" ] = true,
            [ "(no-sfv)" ] = true,
            [ "(nuked)" ] = true,
            [ "3" ] = true,
            [ "4" ] = true,

        },
        [ "category" ] = "test_category",
        [ "checkage" ] = false,
        [ "checkdirs" ] = true,
        [ "checkdirsnfo" ] = false,
        [ "checkdirssfv" ] = false,
        [ "checkfiles" ] = false,
        [ "checkspaces" ] = false,
        [ "command" ] = "+addrel",
        [ "daydirscheme" ] = false,
        [ "maxage" ] = 0,
        [ "path" ] = "C:/your/path/to/rels",
        [ "rulename" ] = "TEST",
        [ "whitelist" ] = {


        },
        [ "zeroday" ] = false,

    },

}

return rules