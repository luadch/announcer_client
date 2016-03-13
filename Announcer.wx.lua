--[[

    Luadch Announcer Client

        Author:         pulsar
        Members:        jrock
        License:        GNU GPLv3
        Environment:    wxLua-2.8.12.3-Lua-5.1.5-MSW-Unicode

]]--


-------------------------------------------------------------------------------------------------------------------------------------
--// IMPORTS //----------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------

local filetype = ( os.getenv( "COMSPEC" ) and os.getenv( "WINDIR" and ".dll" ) ) or ".so"

package.path = package.path .. ";"
    .. "././core/?.lua;"
    .. "././lib/?/?.lua;"
    .. "././lib/luasocket/lua/?.lua;"
    .. "././lib/luasec/lua/?.lua;"
    .. "././lib/jit/?.lua;"

package.cpath = package.cpath .. ";"
    .. "././lib/?/?" .. filetype .. ";"
    .. "././lib/luasocket/?/?" .. filetype .. ";"
    .. "././lib/luasec/?/?" .. filetype .. ";"
    .. "././lib/lfs/?" .. ".dll" .. ";"

dofile( "core/const.lua" )

local wx   = require( "wx" )
local util = require( CORE_PATH .. "util" )
local lfs  = require( "lfs" )

--// defaults
local control
local timer = nil
local pid = 0
local need_save = { }
local rules_listview, categories_listview

-------------------------------------------------------------------------------------------------------------------------------------
--// BASIC CONST //------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------

local app_name         = "Luadch Announcer Client"
local app_copyright    = "Copyright © by pulsar"
local app_license      = "License: GPLv3"

local app_width        = 800
local app_height       = 720

local notebook_width   = 795
local notebook_height  = 388

local log_width        = 795
local log_height       = 233

local refresh_timer    = 60000

local menu_title       = "Menu"
local menu_exit        = "Exit"
local menu_about       = "About"

--// file path
local files = {
    [ "tbl" ] = {
        [ "cfg" ]           = CFG_PATH .. "cfg.lua",
        [ "sslparams" ]     = CFG_PATH .. "sslparams.lua",
        [ "hub" ]           = CFG_PATH .. "hub.lua",
        [ "rules" ]         = CFG_PATH .. "rules.lua",
        [ "categories" ]    = CFG_PATH .. "categories.lua",
        [ "freshstuff" ]    = CFG_PATH .. "ptx_freshstuff_categories.dat",
    },
    [ "core" ] = {
        [ "status" ]        = CORE_PATH .. "status.lua",
    },
    [ "res" ] = {
        [ "icon1" ]         = RES_PATH .. "res1.dll",
        [ "icon2" ]         = RES_PATH .. "res2.dll",
        [ "client_app" ]    = RES_PATH .. "client.dll",
        [ "png_gpl" ]       = RES_PATH .. "png/GPLv3_160x80.png",
        [ "png_applogo" ]   = RES_PATH .. "png/applogo_96x96.png",
    },
    [ "log" ] = {
        [ "announced" ]     = LOG_PATH .. "announced.txt",
        [ "logfile" ]       = LOG_PATH .. "logfile.txt",
        [ "exception" ]     = LOG_PATH .. "exception.txt",
    },
}

--// table cache
local tables = {
    [ "cfg" ]           = util.loadtable( files[ "tbl" ][ "cfg" ] ),
    [ "sslparams" ]     = util.loadtable( files[ "tbl" ][ "sslparams" ] ),
    [ "hub" ]           = util.loadtable( files[ "tbl" ][ "hub" ] ),
    [ "rules" ]         = util.loadtable( files[ "tbl" ][ "rules" ] ) or { },
    [ "categories" ]    = util.loadtable( files[ "tbl" ][ "categories" ] ) or { },
}

--// control default values
local defaults = {
    [ "botdesc" ]           = "Luadch Announcer Client",
    [ "botshare" ]          = 0,
    [ "botslots" ]          = 0,
    [ "announceinterval" ]  = 300,
    [ "sleeptime" ]         = 10,
    [ "sockettimeout" ]     = 60,
    [ "logfilesize" ]       = 2097152,
    [ "logfilesizemax" ]    = 6291456
}
-------------------------------------------------------------------------------------------------------------------------------------
--// IDS //--------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------

local id_counter = wx.wxID_HIGHEST + 1
local new_id = function()
    id_counter = id_counter + 1
    return id_counter
end

id_integrity_dialog            = new_id()
id_integrity_dialog_btn        = new_id()

id_helper_dialog               = new_id()
id_helper_dialog_btn           = new_id()

id_start_client                = new_id()
id_stop_client                 = new_id()
id_control_tls                 = new_id()

id_save_hub                    = new_id()
id_save_cfg                    = new_id()
id_save_rules                  = new_id()

id_treebook                    = new_id()

id_activate                    = new_id()
id_rulename                    = new_id()
id_daydirscheme                = new_id()
id_zeroday                     = new_id()
id_maxage                      = new_id()
id_checkspaces                 = new_id()
id_checkdirs                   = new_id()
id_checkdirsnfo                = new_id()
id_checkdirssfv                = new_id()
id_checkfiles                  = new_id()
id_checkage                    = new_id()

id_command                     = new_id()
id_alibicheck                  = new_id()
id_alibinick                   = new_id()
id_category                    = new_id()

id_blacklist                   = new_id()
id_blacklist_button            = new_id()
id_blacklist_textctrl          = new_id()
id_blacklist_add_button        = new_id()
id_blacklist_listbox           = new_id()
id_blacklist_del_button        = new_id()

id_whitelist                   = new_id()
id_whitelist_button            = new_id()
id_whitelist_textctrl          = new_id()
id_whitelist_add_button        = new_id()
id_whitelist_listbox           = new_id()
id_whitelist_del_button        = new_id()

id_dirpicker_path              = new_id()
id_dirpicker                   = new_id()
id_filepicker_file             = new_id()
id_filepicker                  = new_id()

id_rules_listview              = new_id()
id_rule_add                    = new_id()
id_rule_del                    = new_id()
id_rule_clone                  = new_id()
id_dialog_add_rule             = new_id()
id_textctrl_add_rule           = new_id()
id_choicectrl_add_rule         = new_id()
id_button_add_rule             = new_id()
id_button_cancel_rule          = new_id()

id_categories_listview         = new_id()
id_category_add                = new_id()
id_category_del                = new_id()
id_category_imp                = new_id()
id_category_exp                = new_id()
id_dialog_add_category         = new_id()
id_textctrl_add_category       = new_id()
id_button_add_category         = new_id()
id_button_cancel_category      = new_id()

id_button_load_logfile         = new_id()
id_button_clear_logfile        = new_id()
id_button_load_announced       = new_id()
id_button_clear_announced      = new_id()
id_button_load_exception       = new_id()
id_button_clear_exception      = new_id()

-------------------------------------------------------------------------------------------------------------------------------------
--// HELPER //-----------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------

local validate, dialog = { }, { }
local check_for_whitespaces_textctrl, parse_address_input, parse_rules_listview_selection, parse_categories_listview_selection
local check_for_empty_and_reset_to_default, check_for_number_or_reset_to_default
local disable_save_buttons, save_changes, undo_changes

-------------------------------------------------------------------------------------------------------------------------------------
--// TAB ELEMENTS //-----------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------

--// Tab 1
local control_hubname, control_hubaddress, control_hubport, control_nickname, control_password, control_keyprint, control_tls
--// Tab 2
local control_bot_desc, control_bot_slots, control_bot_share, control_sleeptime, control_announceinterval, control_sockettimeout, control_logfilesize, checkbox_trayicon
--// Tab 3
--// Tab 4
local rule_listview_create, rule_listitem_add, rule_listview_fill
local rule_add_button, rule_del_button, rule_clone_button
--// Tab 5
local category_listview_create, category_listitem_add, category_listview_fill
local category_add_button, category_del_button, category_imp_button, category_exp_button

-------------------------------------------------------------------------------------------------------------------------------------
--// EVENT HANDLER //----------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------

local save_hub, save_cfg, save_rules

local HandleEvents = function( event ) local name = event:GetEventObject():DynamicCast( "wxWindow" ):GetName() end
local HandleChangeTab1 = function( event ) save_hub:Enable( true ) need_save.hub = true end
local HandleChangeTab2 = function( event ) save_cfg:Enable( true ) need_save.cfg = true end
local HandleChangeTab3 = function( event ) save_rules:Enable( true ) need_save.rules = true end

local HandleAppExit

-------------------------------------------------------------------------------------------------------------------------------------
--// FONTS //------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------

local log_font = wx.wxFont( 8, wx.wxMODERN, wx.wxNORMAL, wx.wxNORMAL, false, "Lucida Console" )
local default_font = wx.wxFont( 8, wx.wxMODERN, wx.wxNORMAL, wx.wxNORMAL, false, "Verdana" )
local about_normal_1 = wx.wxFont( 9, wx.wxMODERN, wx.wxNORMAL, wx.wxNORMAL, false, "Verdana" )
local about_normal_2 = wx.wxFont( 10, wx.wxMODERN, wx.wxNORMAL, wx.wxNORMAL, false, "Verdana" )
local about_bold = wx.wxFont( 10, wx.wxMODERN, wx.wxNORMAL, wx.wxFONTWEIGHT_BOLD, false, "Verdana" )

-------------------------------------------------------------------------------------------------------------------------------------
--// ICONS //------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------

--// icons for app titlebar and taskbar
local icons = wx.wxIconBundle()
icons:AddIcon( wx.wxIcon( files[ "res" ][ "icon1" ], 3, 16, 16 ) )
icons:AddIcon( wx.wxIcon( files[ "res" ][ "icon1" ], 3, 32, 32 ) )

--// icons for menubar
local mb_bmp_about_16x16 = wx.wxArtProvider.GetBitmap( wx.wxART_INFORMATION, wx.wxART_TOOLBAR )
local mb_bmp_exit_16x16  = wx.wxArtProvider.GetBitmap( wx.wxART_QUIT,        wx.wxART_TOOLBAR )

--// icons for taskbar
local tb_bmp_about_16x16 = wx.wxArtProvider.GetBitmap( wx.wxART_INFORMATION, wx.wxART_TOOLBAR )
local tb_bmp_exit_16x16  = wx.wxArtProvider.GetBitmap( wx.wxART_QUIT,        wx.wxART_TOOLBAR )

--// icons for tabs
local tab_1_ico = wx.wxIcon( files[ "res" ][ "icon2" ] .. ";0", wx.wxBITMAP_TYPE_ICO, 16, 16 )
local tab_2_ico = wx.wxIcon( files[ "res" ][ "icon2" ] .. ";1", wx.wxBITMAP_TYPE_ICO, 16, 16 )
local tab_3_ico = wx.wxIcon( files[ "res" ][ "icon2" ] .. ";2", wx.wxBITMAP_TYPE_ICO, 16, 16 )
local tab_4_ico = wx.wxIcon( files[ "res" ][ "icon2" ] .. ";3", wx.wxBITMAP_TYPE_ICO, 16, 16 )
local tab_5_ico = wx.wxIcon( files[ "res" ][ "icon2" ] .. ";3", wx.wxBITMAP_TYPE_ICO, 16, 16 )
local tab_6_ico = wx.wxIcon( files[ "res" ][ "icon2" ] .. ";4", wx.wxBITMAP_TYPE_ICO, 16, 16 )

local tab_1_bmp = wx.wxBitmap(); tab_1_bmp:CopyFromIcon( tab_1_ico )
local tab_2_bmp = wx.wxBitmap(); tab_2_bmp:CopyFromIcon( tab_2_ico )
local tab_3_bmp = wx.wxBitmap(); tab_3_bmp:CopyFromIcon( tab_3_ico )
local tab_4_bmp = wx.wxBitmap(); tab_4_bmp:CopyFromIcon( tab_4_ico )
local tab_5_bmp = wx.wxBitmap(); tab_5_bmp:CopyFromIcon( tab_5_ico )
local tab_6_bmp = wx.wxBitmap(); tab_6_bmp:CopyFromIcon( tab_6_ico )

local notebook_image_list = wx.wxImageList( 16, 16 )

local tab_1_img = notebook_image_list:Add( wx.wxBitmap( tab_1_bmp ) )
local tab_2_img = notebook_image_list:Add( wx.wxBitmap( tab_2_bmp ) )
local tab_3_img = notebook_image_list:Add( wx.wxBitmap( tab_3_bmp ) )
local tab_4_img = notebook_image_list:Add( wx.wxBitmap( tab_4_bmp ) )
local tab_5_img = notebook_image_list:Add( wx.wxBitmap( tab_5_bmp ) )
local tab_6_img = notebook_image_list:Add( wx.wxBitmap( tab_6_bmp ) )

-------------------------------------------------------------------------------------------------------------------------------------
--// CREATE LOG BROADCAST FUNCTION //------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------

--// generate cmd for log broadcast
local repeats
repeats = function( s, n ) return n > 0 and s .. repeats( s, n - 1 ) or "" end
local log_window, log_broadcast, log_broadcast_header, log_broadcast_footer
log_broadcast = function( control, msg, color )
    if msg == "false" or msg == false then return end
    if type( msg ) == "table" then
        if #msg == 0 then return end
        for k, v in pairs( msg ) do
            first = k == 1
            last = k == #msg
            if first then
                log_broadcast_header( control, msg[ 1 ] )
            else
                if type( v ) == "table" then
                    log_broadcast( control, v )
                else
                    log_broadcast( control, tostring( v ) )
                end
            end
        end
        if last then
            log_broadcast_footer( control, msg[ 1 ] )
        end
        return
    end

    local timestamp = "[" .. os.date( "%Y-%m-%d/%H:%M:%S" ) .. "] "
    local before, after
    local color_text = {
        [ "GREEN" ]  = { "Added", "Deleted", "Import", "Saved", "Set", "Try", "Wait" },
        [ "ORANGE" ] = { "Info", "Please", "Warn", "Lock", "Unlock" },
        [ "RED" ]    = { "Error", "Fail", "Unable" },
        [ "WHITE" ]  = { "Tab", "Rules", "Categories", "---" }
    }
    local get_color = function ( c )
        if not c then c = "CYAN" end
        if ( c == "GREEN" )  then return wx.wxGREEN end
        if ( c == "ORANGE" ) then return wx.wxColour( 254, 96, 1 ) end
        if ( c == "RED" )    then return wx.wxRED end
        if ( c == "WHITE" )  then return wx.wxWHITE end
        if ( c == "CYAN" )   then return wx.wxCYAN end
    end
    local log_color = function( l, m, c )
        c = get_color( c )
        before = l:GetNumberOfLines()
        l:SetInsertionPointEnd()
        l:SetDefaultStyle( wx.wxTextAttr( wx.wxLIGHT_GREY ) )
        l:WriteText( timestamp )
        after = l:GetNumberOfLines()
        l:ScrollLines( before - after + 2 )
        before = l:GetNumberOfLines()
        l:SetInsertionPointEnd()
        l:SetDefaultStyle( wx.wxTextAttr( c ) )
        l:WriteText( ( m .. "\n" ) )
        after = l:GetNumberOfLines()
        l:ScrollLines( before - after + 2 )
    end
    local print_in_color = function( control, line )
        for color, cases in pairs( color_text ) do
            for i, pattern in pairs( cases ) do
                if line:find( "^" .. pattern ) then 
                    log_color( control, line, color )
                    return true
                end
            end
        end
        log_color( control, line )
        return true
    end
    if color then
        log_color( control, msg, color )
    else
        print_in_color( control, msg )
    end
end
log_broadcast_header = function( control, msg )
    log_broadcast( control, "--- " .. msg .. " " .. repeats( "-", 57 - string.len( msg ) ) )
end
log_broadcast_footer = function( control, msg )
    log_broadcast( control, repeats( "-", 57 - string.len( msg ) ) .. " " .. msg .. " ---" )
end

-------------------------------------------------------------------------------------------------------------------------------------
--// ABOUT WINDOW //-----------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------

--// about window
local show_about_window = function( frame )
    --// dialog window
    local di = wx.wxDialog(
        frame,
        wx.wxID_ANY,
        "About" .. " " .. app_name,
        wx.wxDefaultPosition,
        wx.wxSize( 320, 505 ),
        wx.wxSTAY_ON_TOP + wx.wxDEFAULT_DIALOG_STYLE - wx.wxCLOSE_BOX - wx.wxMAXIMIZE_BOX - wx.wxMINIMIZE_BOX
    )
    di:SetBackgroundColour( wx.wxColour( 255, 255, 255 ) )
    di:SetMinSize( wx.wxSize( 320, 505 ) )
    di:SetMaxSize( wx.wxSize( 320, 505 ) )

    --// app logo
    local bmp_applogo = wx.wxBitmap():ConvertToImage()
    bmp_applogo:LoadFile( files[ "res" ][ "png_applogo" ] )
    local X, Y = bmp_applogo:GetWidth(), bmp_applogo:GetHeight()
    control = wx.wxStaticBitmap( di, wx.wxID_ANY, wx.wxBitmap( bmp_applogo ), wx.wxPoint( 0, 5 ), wx.wxSize( X, Y ) )
    control:Centre( wx.wxHORIZONTAL )
    bmp_applogo:Destroy()

    --// app name / version
    control = wx.wxStaticText(
        di,
        wx.wxID_ANY,
        app_name .. " " .. _VERSION,
        wx.wxPoint( 0, 110 )
    )
    control:SetFont( about_bold )
    control:Centre( wx.wxHORIZONTAL )

    --// app copyright
    control = wx.wxStaticText(
        di,
        wx.wxID_ANY,
        app_copyright,
        wx.wxPoint( 0, 130 )
    )
    control:SetFont( about_normal_2 )
    control:Centre( wx.wxHORIZONTAL )

    --// app members
    control = wx.wxStaticText(
        di,
        wx.wxID_ANY,
        "Members: jrock",
        wx.wxPoint( 0, 150 )
    )
    control:SetFont( about_normal_2 )
    control:Centre( wx.wxHORIZONTAL )

    --// horizontal line
    control = wx.wxStaticLine( di, wx.wxID_ANY, wx.wxPoint( 0, 180 ), wx.wxSize( 275, 1 ) )
    control:Centre( wx.wxHORIZONTAL )

    --// gpl text
    control = wx.wxStaticText(
        di,
        wx.wxID_ANY,
        app_license,
        wx.wxPoint( 0, 195 )
    )
    control:SetFont( about_normal_2 )
    control:Centre( wx.wxHORIZONTAL )

    --// gpl logo
    local gpl_logo = wx.wxBitmap():ConvertToImage()
    gpl_logo:LoadFile( files[ "res" ][ "png_gpl" ] )
    control = wx.wxStaticBitmap(
        di,
        wx.wxID_ANY,
        wx.wxBitmap( gpl_logo ),
        wx.wxPoint( 0, 215 ),
        wx.wxSize( gpl_logo:GetWidth(), gpl_logo:GetHeight() )
    )
    control:Centre( wx.wxHORIZONTAL )
    gpl_logo:Destroy()

    --// horizontal line
    control = wx.wxStaticLine( di, wx.wxID_ANY, wx.wxPoint( 0, 310 ), wx.wxSize( 275, 1 ) )
    control:Centre( wx.wxHORIZONTAL )

    --// credits text
    control = wx.wxStaticText(
        di,
        wx.wxID_ANY,
        "Credits:",
        wx.wxPoint( 0, 325 )
    )
    control:SetFont( about_normal_2 )
    control:Centre( wx.wxHORIZONTAL )

    --// credits
    control = wx.wxTextCtrl(
        di,
        wx.wxID_ANY,
        "Greets fly out to:\n\nblastbeat, Sopor, Peccator, Demonlord\nand all the others for testing the client.\nThanks.",
        wx.wxPoint( 0, 350 ),
        wx.wxSize( 275, 90 ),
        wx.wxTE_READONLY + wx.wxTE_MULTILINE + wx.wxTE_RICH + wx.wxSUNKEN_BORDER + wx.wxHSCROLL + wx.wxTE_CENTRE
    )
    control:SetBackgroundColour( wx.wxColour( 245, 245, 245 ) )
    control:SetForegroundColour( wx.wxBLACK )
    control:Centre( wx.wxHORIZONTAL )

    --// button
    local about_btn_close = wx.wxButton( di, wx.wxID_ANY, "Close", wx.wxPoint( 0, 449 ), wx.wxSize( 80, 20 ) )
    about_btn_close:SetBackgroundColour( wx.wxColour( 255, 255, 255 ) )
    about_btn_close:Centre( wx.wxHORIZONTAL )

    --// events
    about_btn_close:Connect( wx.wxID_ANY, wx.wxEVT_COMMAND_BUTTON_CLICKED,
    function( event )
        di:Destroy()
    end )

    --// show dialog
    di:ShowModal()
end

-------------------------------------------------------------------------------------------------------------------------------------
--// DIFFERENT FUNCS //--------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------

--// trim whitespaces from both ends of a string
local trim = function( s )
    return string.find( s, "^%s*$" ) and "" or string.match( s, "^%s*(.*%S)" )
end

--// check for whitespaces in wxTextCtrl
check_for_whitespaces_textctrl = function( parent, control, skip )
    local s = control:GetValue()
    local new, n = string.gsub( s, " ", "" )
    if n ~= 0 then
        log_broadcast(
            log_window,
            {
                "Control 'Name'",
                "Removed whitespaces: " .. n,
                "Error: Whitespaces not allowed!"
            }
        )
        if skip ~= true then
            control:SetValue( new )
        end
    end
end

--// check for type in control or set default
check_for_empty_and_reset_to_default = function( current, default )
    if type( current ) == "userdata" then
        if trim( control:GetValue() ) == "" then
            control:SetValue( tostring( default ) )
            return default
        end
        return control:GetValue()
    else
        if current == "" then
            return default
        end
        return current
    end
end

--// check for empty string and reset to default ( if current is an textCtrl, update textCtrl before return default )
check_for_empty_and_reset_to_default = function( current, default )
    local control
        if type( current ) == "userdata" then
        control = current
        current = control:GetValue()
    end
    if current == "" then
        if type( control ) == "userdata" then
            control:SetValue( tostring( default ) )
        end
        return default
    end
    return current
end

--// check for number or reset to default ( if current is an textCtrl, update textCtrl before return default )
check_for_number_or_reset_to_default = function( current, default )
    local control
        if type( current ) == "userdata" then
        control = current
        current = control:GetValue()
    end
    if not string.match( current, "^[0-9]+$" ) then
        if type( control ) == "userdata" then
            control:SetValue( tostring( default ) )
        end
        return default
    end
    return current
end

--// parse input from address field and splitt the informations if possible
local parse_address_input = function( parent, control, control2, control3 )
    local url, chunk, protocol, hostport, host, port, keyp

    url = control:GetValue()
    if url == "" then return end

    chunk = url:match( "^([a-z0-9+]+://)" )
    url = url:sub( ( chunk and #chunk or 0 ) + 1 )
    hostport = url:match( "^([^/|?]+)" )
    if hostport then
        host = hostport:match( "^([^:/]+)" )
        port = hostport:match( ":(%d+)$" )
    end
    url = url:sub( ( hostport and #hostport or 0 ) + 1 )
    keyp = url:match( "kp=SHA256/(%w+)$" )

    if control:GetValue() == host then
        return
    end

    local dialog_title, dialog_msg = "Imported by 'Hubaddress' control:", { }
    if host then
        table.insert( dialog_msg, "Address: " .. host )
        control:SetValue( host )
    end
    if port then
        table.insert( dialog_msg, "Port: " .. port )
        control2:SetValue( port )
    end
    if keyp then
        table.insert( dialog_msg, "Keyprint: " .. keyp )
        control3:SetValue( keyp )
    end
    if #dialog_msg > 1 then
        table.insert( dialog_msg, 1, "Hubaddress" )
        table.insert( dialog_msg, 2, dialog_title )
        log_broadcast( log_window, dialog_msg )
    end

end

--// helper parse rules + categories listview selection
parse_listview_selection = function( control )
    local selected = control:GetFirstSelected()
    if selected == -1 then return -1 end

    local tbl = { }
    for column = 0, control:GetColumnCount() - 1 do
        local li = wx.wxListItem()
        li:SetId( selected )
        li:SetColumn( column )
        li:SetMask( wx.wxLIST_MASK_TEXT )
        control:GetItem( li )
        if tonumber( li:GetText() ) ~= nil then
            table.insert( tbl, tonumber( li:GetText() ) )
        else
            table.insert( tbl, li:GetText() )
        end
    end
    return tbl
end

--// parse listview selection and return id + active + name + category
parse_rules_listview_selection = function( control )
    local tbl = parse_listview_selection( control )
    if tbl == -1 then return end
    return tbl[ 1 ], tbl[ 2 ], tbl[ 3 ], tbl[ 4 ]
end

--// parse listview selection and return id + cnt + name
parse_categories_listview_selection = function( control )
    local tbl = parse_listview_selection( control )
    if tbl == -1 then return end
    return tbl[ 1 ], tbl[ 2 ], tbl[ 3 ]
end

--// set values from "cfg/hub.lua"
local set_hub_values = function( log_window, control_hubname, control_hubaddress, control_hubport, control_nickname, control_password, control_keyprint )

    local hubname = tables[ "hub" ][ "name" ] or "Luadch Testhub"
    local hubaddr = tables[ "hub" ][ "addr" ] or "your.dynaddy.org"
    local hubport = tables[ "hub" ][ "port" ] or 5001
    local hubnick = tables[ "hub" ][ "nick" ] or "Announcer"
    local hubpass = tables[ "hub" ][ "pass" ] or "test"
    local hubkeyp = tables[ "hub" ][ "keyp" ] or "unknown"

    control_hubname:SetValue( hubname )
    control_hubaddress:SetValue( hubaddr )
    control_hubport:SetValue( hubport )
    control_nickname:SetValue( hubnick )
    control_password:SetValue( hubpass )
    control_keyprint:SetValue( hubkeyp )

    log_broadcast( log_window, "Import data from: '" .. files[ "tbl" ][ "hub" ] .. "'" )
end

--// save values to "cfg/hub.lua"
local save_hub_values = function( log_window, control_hubname, control_hubaddress, control_hubport, control_nickname, control_password, control_keyprint )

    local hubname = trim( control_hubname:GetValue() )
    local hubaddr = trim( control_hubaddress:GetValue() )
    local hubport = trim( control_hubport:GetValue() )
    local hubnick = trim( control_nickname:GetValue() )
    local hubpass = trim( control_password:GetValue() )
    local hubkeyp = trim( control_keyprint:GetValue() )

    tables[ "hub" ][ "name" ] = hubname
    tables[ "hub" ][ "addr" ] = hubaddr
    tables[ "hub" ][ "port" ] = hubport
    tables[ "hub" ][ "nick" ] = hubnick
    tables[ "hub" ][ "pass" ] = hubpass
    tables[ "hub" ][ "keyp" ] = hubkeyp

    util.savetable( tables[ "hub" ], "hub", files[ "tbl" ][ "hub" ] )
    log_broadcast( log_window, "Saved data to: '" .. files[ "tbl" ][ "hub" ] .. "'" )
end

--// protect hub values "cfg/cfg.lua"
local protect_hub_values = function( log_window, notebook, button_clear_logfile, button_clear_announced, button_clear_exception )

    local p
    for p = 0, notebook:GetPageCount() - 1 do
        --// tab_6: only manual disable
        if p == 5 then
            button_clear_logfile:Disable()
            button_clear_announced:Disable()
            button_clear_exception:Disable()
        else
            notebook:GetPage( p ):Disable()
        end
        log_broadcast( log_window, "Lock '" .. validate.getTab( p + 1 ) .. "' controls" )
    end
end

--// unprotect hub values "cfg/cfg.lua"
local unprotect_hub_values = function( log_window, notebook, button_clear_logfile, button_clear_announced, button_clear_exception )

    local p
    for p = 0, notebook:GetPageCount() - 1 do
        --// tab_6: only manual disable
        if p == 5 then
            button_clear_logfile:Enable( true )
            button_clear_announced:Enable( true )
            button_clear_exception:Enable( true )
        else
            notebook:GetPage( p ):Enable( true )
        end
        log_broadcast( log_window, "Unlock '" .. validate.getTab( p + 1 ) .. "' controls" )
    end
end

--// set values from "cfg/cfg.lua"
local set_cfg_values = function( log_window, control_bot_desc, control_bot_share, control_bot_slots, control_announceinterval,
                                 control_sleeptime, control_sockettimeout, control_logfilesize, checkbox_trayicon )

    local botdesc = check_for_empty_and_reset_to_default( tables[ "cfg" ][ "botdesc" ], defaults[ "botdesc" ] )
    local botshare = check_for_empty_and_reset_to_default( tables[ "cfg" ][ "botshare" ], defaults[ "botshare" ] )
    local botslots = check_for_empty_and_reset_to_default( tables[ "cfg" ][ "botslots" ], defaults[ "botslots" ] )
    local announceinterval = check_for_empty_and_reset_to_default( tables[ "cfg" ][ "announceinterval" ], defaults[ "announceinterval" ] )
    local sleeptime = check_for_empty_and_reset_to_default( tables[ "cfg" ][ "sleeptime" ], defaults[ "sleeptime" ] )
    local sockettimeout = check_for_empty_and_reset_to_default( tables[ "cfg" ][ "sockettimeout" ], defaults[ "sockettimeout" ] )
    local logfilesize = check_for_empty_and_reset_to_default( tables[ "cfg" ][ "logfilesize" ], defaults[ "logfilesize" ] )
    local trayicon = tables[ "cfg" ][ "trayicon" ] or false

    control_bot_desc:SetValue( botdesc )
    control_bot_share:SetValue( tostring( botshare ) )
    control_bot_slots:SetValue( tostring( botslots ) )
    control_announceinterval:SetValue( tostring( announceinterval ) )
    control_sleeptime:SetValue( tostring( sleeptime ) )
    control_sockettimeout:SetValue( tostring( sockettimeout ) )
    control_logfilesize:SetValue( tostring( logfilesize ) )
    if tables[ "cfg" ][ "trayicon" ] == true then checkbox_trayicon:SetValue( true ) else checkbox_trayicon:SetValue( false ) end

    log_broadcast( log_window, "Import data from: '" .. files[ "tbl" ][ "cfg" ] .. "'" )
    need_save.cfg = false
end

--// save freshstuff version value to "cfg/cfg.lua"
local save_cfg_freshstuff_value = function()
    tables[ "cfg" ][ "freshstuff_version" ] = true
    util.savetable( tables[ "cfg" ], "cfg", files[ "tbl" ][ "cfg" ] )
end

--// save values to "cfg/cfg.lua"
local save_cfg_values = function( log_window, control_bot_desc, control_bot_share, control_bot_slots, control_announceinterval,
                                  control_sleeptime, control_sockettimeout, control_logfilesize, checkbox_trayicon )

    local botdesc = check_for_empty_and_reset_to_default( control_bot_desc, defaults[ "botdesc" ] )
    local botshare = check_for_empty_and_reset_to_default( control_bot_share, defaults[ "botshare" ] )
    local botslots = check_for_empty_and_reset_to_default( control_bot_slots, defaults[ "botslots" ] )
    local announceinterval = check_for_empty_and_reset_to_default( control_announceinterval, defaults[ "announceinterval" ] )
    local sleeptime = check_for_empty_and_reset_to_default( control_sleeptime, defaults[ "sleeptime" ] )
    local sockettimeout = check_for_empty_and_reset_to_default( control_sockettimeout, defaults[ "sockettimeout" ] )
    local logfilesize = check_for_empty_and_reset_to_default( control_logfilesize, defaults[ "logfilesize" ] )

    tables[ "cfg" ][ "botdesc" ] = botdesc
    tables[ "cfg" ][ "botshare" ] = botshare
    tables[ "cfg" ][ "botslots" ] = botslots
    tables[ "cfg" ][ "announceinterval" ] = announceinterval
    tables[ "cfg" ][ "sleeptime" ] = sleeptime
    tables[ "cfg" ][ "sockettimeout" ] = sockettimeout
    tables[ "cfg" ][ "trayicon" ] = trayicon
    tables[ "cfg" ][ "logfilesize" ] = logfilesize
    tables[ "cfg" ][ "freshstuff_version" ] = freshstuff_version

    util.savetable( tables[ "cfg" ], "cfg", files[ "tbl" ][ "cfg" ] )
    log_broadcast( log_window, "Saved data to: '" .. files[ "tbl" ][ "cfg" ] .. "'" )
end

--// set values from "cfg/sslparams.lua"
local set_sslparams_value = function( log_window, control )
    local protocol = tables[ "sslparams" ].protocol
    if protocol == "tlsv1" then
        control:SetSelection( 0 )
    else
        control:SetSelection( 1 )
    end
    log_broadcast( log_window, "Import data from: '" .. files[ "tbl" ][ "sslparams" ] .. "'" )
end

--// save values to "cfg/sslparams.lua"
local save_sslparams_values = function( log_window, control )
    local mode = control:GetSelection()

    local tls1_tbl = {
        mode = "client",
        key = "certs/serverkey.pem",
        certificate = "certs/servercert.pem",
        protocol = "tlsv1",
        ciphers = "ECDHE-ECDSA-AES256-SHA:" ..
                  "ECDHE-RSA-AES256-SHA:" ..
                  "ECDHE-ECDSA-AES128-SHA:" ..
                  "ECDHE-RSA-AES128-SHA",
    }

    local tls12_tbl = {
        mode = "client",
        key = "certs/serverkey.pem",
        certificate = "certs/servercert.pem",
        protocol = "tlsv1_2",
        ciphers = "ECDHE-ECDSA-AES256-GCM-SHA384:" ..
                  "ECDHE-RSA-AES256-GCM-SHA384:" ..
                  "ECDHE-ECDSA-AES128-GCM-SHA256:" ..
                  "ECDHE-RSA-AES128-GCM-SHA256",
    }

    if mode == 0 then
        util.savetable( tls1_tbl, "sslparams", files[ "tbl" ][ "sslparams" ] )
        log_broadcast( log_window, "Saved TLSv1 data to: '" .. files[ "tbl" ][ "sslparams" ] .. "'" )
    else
        util.savetable( tls12_tbl, "sslparams", files[ "tbl" ][ "sslparams" ] )
        log_broadcast( log_window, "Saved TLSv1.2 data to: '" .. files[ "tbl" ][ "sslparams" ] .. "'" )
    end
end

--// save values to "cfg/cfg.lua"
local save_config_values = function( log_window )
    util.savetable( tables[ "cfg" ], "cfg", files[ "tbl" ][ "cfg" ] )
    log_broadcast( log_window, "Saved data to: '" .. files[ "tbl" ][ "cfg" ] .. "'" )
end

--// save values to "cfg/rules.lua"
local save_rules_values = function( log_window, skip_listview_fill )
    util.savetable( tables[ "rules" ], "rules", files[ "tbl" ][ "rules" ] )
    log_broadcast( log_window, "Saved data to: '" .. files[ "tbl" ][ "rules" ] .. "'" )
    
    if not skip_listview_fill then
        rule_listview_fill( rules_listview )
        category_listview_fill( categories_listview )
    end
end

--// insert or remove value to "cfg/rules.lua" without saving other maybe unsaved changes
local update_saved_rules_values = function( log_window, action, target )
    local tbl = util.loadtable( files[ "tbl" ][ "rules" ] )
    if action == "insert" then
        table.insert( tbl, target )
    end
    if action == "remove" then
        table.remove( tbl, target )
    end

    util.savetable( tbl, "rules", files[ "tbl" ][ "rules" ] )
    log_broadcast( log_window, "Saved data to: '" .. files[ "tbl" ][ "rules" ] .. "'" )
    
    rule_listview_fill( rules_listview )
    category_listview_fill( categories_listview )

end

--// save values to "cfg/categories.lua"
local save_categories_values = function( log_window )
    util.savetable( tables[ "categories" ], "categories", files[ "tbl" ][ "categories" ] )
    log_broadcast( log_window, "Saved data to: '" .. files[ "tbl" ][ "categories" ] .. "'" )
end

--// get status from status.lua
local get_status = function( file, key )
    local tbl, err = util.loadtable( file )
    if tbl then
        return tbl[ key ] or ""
    else
        return err
    end
end

--// reset status entrys from "core/status.lua"
local reset_status = function( file )
    local tbl = {

        [ "cipher" ] = "",
        [ "hubconnect" ] = "",
        [ "hubhandshake" ] = "",
        [ "hubinf" ] = "",
        [ "hubkeyp" ] = "",
        [ "hublogin" ] = "",
        [ "hubosnr" ] = "",
        [ "hubsalt" ] = "",
        [ "hubsid" ] = "",
        [ "hubsupport" ] = "",
        [ "owninf" ] = "",
        [ "passwd" ] = "",
        [ "support" ] = "",
    }
    util.savetable( tbl, "status", file )
end

--// kill childprocess
local kill_process = function( pid, log_window )
    if pid > 0 then
        local exists = wx.wxProcess.Exists( pid )
        if exists then
            local ret = wx.wxProcess.Kill( pid, wx.wxSIGKILL, wx.wxKILL_CHILDREN )
            if ret ~= wx.wxKILL_OK then
                log_broadcast( log_window, "Unable to kill process: " .. pid .. "  |  code: " .. tostring( ret ), "RED" )
                log_broadcast( log_window, app_name .. " " .. _VERSION .. " ready.", "ORANGE" )
            else
                log_broadcast( log_window, "Announcer stopped. (Killed process: " .. pid .. ")", "WHITE" )
                log_broadcast( log_window, app_name .. " " .. _VERSION .. " ready.", "ORANGE" )
            end
        end
        pid = 0
    end
    reset_status( files[ "core" ][ "status" ] )
end

function table.getCategories()
    local categories_arr, categories_key = { }, { }
    categories_key = { "#", "Exists", "Name" }
    for k,v in spairs( tables[ "categories" ], "asc", "categoryname" ) do
        local cnt = table.countValue( tables[ "rules" ], v[ "categoryname" ], "category" )
        if cnt == 0 then cnt = "" else cnt = cnt .. "x" end
        table.insert( categories_arr, { k , cnt, v[ "categoryname" ] } )
    end
    return categories_arr, categories_key
end

function table.getRules()
    local rules_arr, rules_key = { }, { }
    rules_key = { "#", "Status", "Name", "Category" }
    for k,v in spairs( tables[ "rules" ], "asc", "rulename" ) do
        local active
        if v[ "active" ] == true then active = "On" else active = "Off" end
        table.insert( rules_arr, { k , active, v[ "rulename" ], v[ "category" ] } )
    end
    return rules_arr, rules_key
end

--// get ordered categories table entrys as array
local list_categories_tbl = function()
    local categories_arr = { }
    for k,v in spairs( tables[ "categories" ], "asc", "categoryname" ) do
        table.insert( categories_arr, v[ "categoryname" ] )
    end
    return categories_arr
end

--// helper to check if value exists on table
function table.hasValue( tbl, item, field, id )
    if type( field ) == "string" then
        for key, value in pairs( tbl ) do
            if value[ field ] == item and key ~= id then return true end
        end
    else
        for key, value in pairs( tbl ) do
            if value == item and key ~= id then return true end
        end
    end
    return false
end

--// helper to cout if value exists on table
function table.countValue( tbl, item, field )
    local cnt = 0
    if type( field ) == "string" then
        for key, value in pairs( tbl ) do
            if value[ field ] == item then cnt = cnt + 1 end
        end
    else
        for key, value in pairs( tbl ) do
            if value[ item ] then cnt = cnt + 1 end
        end
    end
    return cnt
end

--// helper to check if key exists on table
function table.hasKey( tbl, item, field )
    if type( field ) == "string" then
        for key, value in pairs( tbl ) do
            if value[ field ][ item ] then return true end
        end
    else
        for key, value in pairs( tbl ) do
            if key == item then return true end
        end
    end
    return false
end

--// helper to get id if key exists on table
function table.getKey( tbl, item, field )
    if type( field ) == "string" then
        for key, value in pairs( tbl ) do
            if value[ field ] == item then return key end
        end
    else
        for key, value in pairs( tbl ) do
            if value[ item ] then return key end
        end
    end
    return -1
end

--// helper to clone a table
function table.copy( tbl, id )
  local u = { }
  if id then
    tbl = tbl[ id ]
  end
  for key, value in pairs( tbl ) do u[ key ] = value end
  return setmetatable( u, getmetatable( tbl ) )
end

--// helper to diff a table by keys
function table.diff( tbl1, tbl2 )
    local tbl3 = { }
    for key, value in pairs( tbl1 ) do
        if table.hasKey( tbl2, key ) == false then
           tbl3[ key ] = value
        end
    end
    return tbl3
end

--// helper to order list by field
function spairs( tbl, order, field )
    local keys = { }
    for k in pairs( tbl ) do table.insert( keys, k ) end
    if order then
        if type( order ) == "function" then
            table.sort( keys, function( a, b ) return order( tbl, a, b ) end )
        else
            if order == "asc" then
                if type( field ) == "string" then
                    table.sort( keys, function( a, b ) return string.lower( tbl[ b ][ field ] ) > string.lower( tbl[ a ][ field ] ) end )
                else
                    table.sort( keys, function( a, b ) return string.lower( tbl[ b ] ) > string.lower( tbl[ a ] ) end )
                end
            end
            if order == "desc" then
                if  type( field ) == "string" then
                    table.sort( keys, function( a, b ) return string.lower( tbl[ b ][ field ] ) < string.lower( tbl[ a ][ field ] ) end )
                else
                
                    table.sort( keys, function( a, b ) return string.lower( tbl[ b ] ) < string.lower( tbl[ a ] ) end )
                end
            end
        end
    else
        table.sort( keys )
    end

    local i = 0
    return function()
        i = i + 1
        if keys[ i ] then
            return keys[ i ], tbl[ keys[ i ] ]
        end
    end
end

--// check if all required files exists on startup
local integrity_check = function()
    local tbl = {
        [ "certs" ] = "directory",
        [ "cfg" ] = "directory",
        [ "core" ] = "directory",
        [ "lib" ] = "directory",
        [ "log" ] = "directory",
        [ "libeay32.dll" ] = "file",
        [ "lua.dll" ] = "file",
        [ "lua5.1.dll" ] = "file",
        [ "ssleay32.dll" ] = "file",
        [ "core/adc.lua" ] = "file",
        [ "core/announce.lua" ] = "file",
        [ "core/const.lua" ] = "file",
        [ "core/init.lua" ] = "file",
        [ "core/log.lua" ] = "file",
        [ "core/net.lua" ] = "file",
        [ "core/status.lua" ] = "file",
        [ "core/util.lua" ] = "file",
        [ "cfg/categories.lua" ] = "file",
        [ "cfg/cfg.lua" ] = "file",
        [ "cfg/hub.lua" ] = "file",
        [ "cfg/rules.lua" ] = "file",
        [ "cfg/sslparams.lua" ] = "file",
        [ "lib/adclib/adclib.dll" ] = "file",
        [ "lib/basexx/basexx.lua" ] = "file",
        [ "lib/lfs/lfs.dll" ] = "file",
        [ "lib/luasec/lua/https.lua" ] = "file",
        [ "lib/luasec/lua/options.lua" ] = "file",
        [ "lib/luasec/lua/ssl.lua" ] = "file",
        [ "lib/luasec/ssl/ssl.dll" ] = "file",
        [ "lib/luasocket/lua/ftp.lua" ] = "file",
        [ "lib/luasocket/lua/http.lua" ] = "file",
        [ "lib/luasocket/lua/ltn12.lua" ] = "file",
        [ "lib/luasocket/lua/mime.lua" ] = "file",
        [ "lib/luasocket/lua/smtp.lua" ] = "file",
        [ "lib/luasocket/lua/socket.lua" ] = "file",
        [ "lib/luasocket/lua/tp.lua" ] = "file",
        [ "lib/luasocket/lua/url.lua" ] = "file",
        [ "lib/luasocket/mime/mime.dll" ] = "file",
        [ "lib/luasocket/socket/socket.dll" ] = "file",
        [ "lib/ressources/client.dll" ] = "file",
        [ "lib/ressources/res1.dll" ] = "file",
        [ "lib/ressources/res2.dll" ] = "file",
        [ "lib/ressources/png/applogo_96x96.png" ] = "file",
        [ "lib/ressources/png/GPLv3_160x80.png" ] = "file",
        [ "lib/unicode/unicode.dll" ] = "file",
    }
    local path = wx.wxGetCwd() .. "\\"
    local mode, err
    local missing = { }
    local start, goal = 1 ,0
    for k, v in pairs( tbl ) do goal = goal + 1 end

    wx.wxBeginBusyCursor()

    local progressDialog = wx.wxProgressDialog(
        app_name .. " - Integrity Check",
        "",
        goal,
        wx.NULL,
        wx.wxPD_AUTO_HIDE + wx.wxPD_APP_MODAL + wx.wxPD_SMOOTH
    )
    progressDialog:SetSize( wx.wxSize( 600, 130 ) )
    progressDialog:Centre( wx.wxBOTH )

    for k, v in pairs( tbl ) do
        mode, err = lfs.attributes( path .. k, "mode" )
        progressDialog:Update( start, "Check: '" .. k .. "'" )
        if mode ~= v then
            missing[ k ] = v
        end
        start = start + 1
        wx.wxMilliSleep( 30 )
    end

    progressDialog:Destroy()
    wx.wxEndBusyCursor()

    if next( missing ) ~= nil then
        local di = wx.wxDialog(
            wx.NULL,
            id_integrity_dialog,
            "ERROR",
            wx.wxDefaultPosition,
            wx.wxSize( 250, 300 ),
            wx.wxSTAY_ON_TOP + wx.wxDEFAULT_DIALOG_STYLE - wx.wxCLOSE_BOX - wx.wxMAXIMIZE_BOX - wx.wxMINIMIZE_BOX
        )
        di:SetBackgroundColour( wx.wxColour( 255, 255, 255 ) )
        di:Centre( wx.wxBOTH )

        control = wx.wxStaticText( di, wx.wxID_ANY, "The following files were not found:", wx.wxPoint( 20, 25 ) )

        local dialog_integrity_textctrl = wx.wxTextCtrl(
            di,
            wx.wxID_ANY,
            "",
            wx.wxPoint( 20, 50 ),
            wx.wxSize( 200, 180 ),
            wx.wxTE_READONLY + wx.wxTE_MULTILINE + wx.wxTE_RICH + wx.wxSUNKEN_BORDER + wx.wxHSCROLL
        )
        dialog_integrity_textctrl:SetBackgroundColour( wx.wxColour( 245, 245, 245 ) )
        dialog_integrity_textctrl:SetForegroundColour( wx.wxBLACK )
        dialog_integrity_textctrl:Centre( wx.wxHORIZONTAL )

        for k, v in pairs( missing ) do
            dialog_integrity_textctrl:AppendText( "Type: " .. v .. "\n" )
            dialog_integrity_textctrl:AppendText( "Path: " .. k .. "\n\n" )
        end

        local dialog_integrity_button = wx.wxButton( di, id_integrity_dialog_btn, "CLOSE", wx.wxPoint( 75, 242 ), wx.wxSize( 60, 20 ) )
        dialog_integrity_button:Centre( wx.wxHORIZONTAL )
        dialog_integrity_button:Connect( id_integrity_dialog_btn, wx.wxEVT_COMMAND_BUTTON_CLICKED, function( event ) di:Destroy() end )
        di:ShowModal()
        return false
    end
    return true
end

--// add statusbar (on the bottom)
local sb
local add_statusbar = function( parent )
    sb = parent:CreateStatusBar( 1 ); parent:SetStatusText( "Welcome to " .. app_name .. " " .. _VERSION, 0 )
end

--// helper function for menu items (menubar, taskbar)
local menu_item = function( menu, id, name, status, bmp )
    local mi = wx.wxMenuItem( menu, id, name, status )
    mi:SetBitmap( bmp )
    bmp:delete()
    return mi
end

--// add menubar (on the top)
local mb
local add_menubar = function( parent )
    local menu = wx.wxMenu()
    menu:Append( menu_item( menu, wx.wxID_ABOUT, menu_about .. "\tF1",     menu_about .. " " .. app_name, mb_bmp_about_16x16 ) )
    menu:Append( menu_item( menu, wx.wxID_EXIT,  menu_exit  ..  "\tAlt-X", menu_exit ..  " " .. app_name, mb_bmp_exit_16x16 ) )
    mb = wx.wxMenuBar()
    mb:Append( menu, menu_title )
    parent:SetMenuBar( mb )
end

--// add taskbar (systemtrray)
local taskbar = nil
local add_taskbar = function( frame, checkbox_trayicon )
    if checkbox_trayicon:IsChecked() then
        taskbar = wx.wxTaskBarIcon()
        local icon = wx.wxIcon( files[ "res" ][ "icon1" ], 3, 16, 16 )
        taskbar:SetIcon( icon, app_name .. " " .. _VERSION )

        tb_bmp_about_16x16 = wx.wxArtProvider.GetBitmap( wx.wxART_INFORMATION, wx.wxART_TOOLBAR )
        tb_bmp_exit_16x16  = wx.wxArtProvider.GetBitmap( wx.wxART_QUIT,        wx.wxART_TOOLBAR )

        local menu = wx.wxMenu()
        menu:Append( menu_item( menu, wx.wxID_ABOUT, menu_about .. "\tF1",     menu_about .. " " .. app_name, tb_bmp_about_16x16 ) )
        menu:Append( menu_item( menu, wx.wxID_EXIT,  menu_exit  ..  "\tAlt-X", menu_exit ..  " " .. app_name, tb_bmp_exit_16x16 ) )

        menu:Connect( wx.wxID_ABOUT, wx.wxEVT_COMMAND_MENU_SELECTED,
            function( event )
                show_about_window( frame )
            end
        )
        menu:Connect( wx.wxID_EXIT, wx.wxEVT_COMMAND_MENU_SELECTED, HandleAppExit )
        taskbar:Connect( wx.wxEVT_TASKBAR_RIGHT_DOWN,
            function( event )
                taskbar:PopupMenu( menu )
            end
        )
        taskbar:Connect( wx.wxEVT_TASKBAR_LEFT_DOWN,
            function( event )
                frame:Iconize( not frame:IsIconized() )
                local show = not frame:IsIconized()
                if show then
                    frame:Raise( true )
                end
            end
        )
        frame:Connect( wx.wxEVT_ICONIZE,
            function( event )
                local show = not frame:IsIconized()
                frame:Show( show )
                if show then
                    frame:Raise( true )
                end
            end
        )
    else
        if taskbar then
            frame:Connect( wx.wxEVT_ICONIZE,
                function( event )
                    local show = not frame:IsIconized()
                    frame:Show( true )
                    if show then
                        frame:Raise( true )
                    end
                end
            )
            taskbar:delete()
        end
        taskbar = nil
    end
    return taskbar
end

--// get file size of logfiles
local get_logfilesize = function()
    local size_log = 0
    local size_log_success, size_log_error = lfs.attributes( files[ "log" ][ "logfile" ], "mode" )
    if size_log_success then
          size_log = wx.wxFileSize( files[ "log" ][ "logfile" ] )
    end
    local size_ann = 0
    local size_ann_success, size_ann_error = lfs.attributes( files[ "log" ][ "announced" ], "mode" )
    if size_ann_success then
          size_ann = wx.wxFileSize( files[ "log" ][ "announced" ] )
    end
    local size_exc = 0
    local size_exc_success, size_exc_error = lfs.attributes( files[ "log" ][ "exception" ], "mode" )
    if size_exc_success then
          size_exc = wx.wxFileSize( files[ "log" ][ "exception" ] )
    end
    return size_log, size_ann, size_exc
end

--// set file size gauge values on tab 6
local set_logfilesize = function( control1, control2, control3 )
    local res1, res2, res3 = get_logfilesize()
    control1:SetValue( res1 )
    control2:SetValue( res2 )
    control3:SetValue( res3 )
end

-------------------------------------------------------------------------------------------------------------------------------------
--// FRAME //------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------

if integrity_check() then

local frame = wx.wxFrame(
    wx.NULL,
    wx.wxID_ANY,
    app_name .. " " .. _VERSION,
    wx.wxPoint( 0, 0 ),
    wx.wxSize( app_width, app_height ),
    wx.wxMINIMIZE_BOX + wx.wxSYSTEM_MENU + wx.wxCAPTION + wx.wxCLOSE_BOX + wx.wxCLIP_CHILDREN
)
frame:Centre( wx.wxBOTH )
frame:SetIcons( icons )

local panel = wx.wxPanel( frame, wx.wxID_ANY, wx.wxPoint( 0, 0 ), wx.wxSize( app_width, app_height ) )
panel:SetBackgroundColour( wx.wxColour( 240, 240, 240 ) )

local notebook = wx.wxNotebook( panel, wx.wxID_ANY, wx.wxPoint( 0, 30 ), wx.wxSize( notebook_width, notebook_height ) )
notebook:SetFont( default_font )
notebook:SetBackgroundColour( wx.wxColour( 225, 225, 225 ) )

local tab_1 = wx.wxPanel( notebook, wx.wxID_ANY )
tabsizer_1 = wx.wxBoxSizer( wx.wxVERTICAL )
tab_1:SetSizer( tabsizer_1 )
tabsizer_1:SetSizeHints( tab_1 )

local tab_2 = wx.wxPanel( notebook, wx.wxID_ANY )
tabsizer_2 = wx.wxBoxSizer( wx.wxVERTICAL )
tab_2:SetSizer( tabsizer_2 )
tabsizer_2:SetSizeHints( tab_2 )

local tab_3 = wx.wxPanel( notebook, wx.wxID_ANY )
tabsizer_3 = wx.wxBoxSizer( wx.wxVERTICAL )
tab_3:SetSizer( tabsizer_3 )
tabsizer_3:SetSizeHints( tab_3 )

local tab_4 = wx.wxPanel( notebook, wx.wxID_ANY )
tabsizer_4 = wx.wxBoxSizer( wx.wxVERTICAL )
tab_4:SetSizer( tabsizer_4 )
tabsizer_4:SetSizeHints( tab_4 )

local tab_5 = wx.wxPanel( notebook, wx.wxID_ANY )
tabsizer_5 = wx.wxBoxSizer( wx.wxVERTICAL )
tab_5:SetSizer( tabsizer_5 )
tabsizer_5:SetSizeHints( tab_5 )

local tab_6 = wx.wxPanel( notebook, wx.wxID_ANY )
tabsizer_6 = wx.wxBoxSizer( wx.wxVERTICAL )
tab_6:SetSizer( tabsizer_6 )
tabsizer_6:SetSizeHints( tab_6 )

notebook:AddPage( tab_1, "Hub Account" )
notebook:AddPage( tab_2, "Announcer Config" )
notebook:AddPage( tab_3, "Announcer Rules" )
notebook:AddPage( tab_4, "Add/Remove Rules" )
notebook:AddPage( tab_5, "Add/Remove Categories" )
notebook:AddPage( tab_6, "Logfiles" )

notebook:SetImageList( notebook_image_list )

notebook:SetPageImage( 0, tab_1_img )
notebook:SetPageImage( 1, tab_2_img )
notebook:SetPageImage( 2, tab_3_img )
notebook:SetPageImage( 3, tab_4_img )
notebook:SetPageImage( 4, tab_5_img )
notebook:SetPageImage( 5, tab_6_img )

--// statusbar
add_statusbar( frame )

--// menubar
add_menubar( frame )

--// helper unction for menu:exit + taskbar:exit
HandleAppExit = function( event )
    --// todo: clean up here with exit check
    local quit = dialog.question( "Really quit?" )
    if quit == wx.wxID_YES then
        if need_save.cfg or need_save.hub or need_save.rules then
            local dialog_question = "Save changes?\n"
            local save = dialog.question( dialog_question )
            if save == wx.wxID_YES then
                if validate.save( true ) then
                    return
                else
                    save_changes( log_window )
                end
            end
        end
        if ( pid > 0 ) then
            local exists = wx.wxProcess.Exists( pid )
            if exists then
                local ret = wx.wxProcess.Kill( pid, wx.wxSIGKILL, wx.wxKILL_CHILDREN )
            end
            pid = 0
        end
        frame:Destroy()
        if taskbar then taskbar:delete() end
        if timer then
            timer:Stop()
            timer:delete()
            timer = nil
        end
    end
end

-------------------------------------------------------------------------------------------------------------------------------------
--// LOG WINDOW //-------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------

log_window = wx.wxTextCtrl( panel, wx.wxID_ANY, "", wx.wxPoint( 0, 418 ), wx.wxSize( log_width, log_height ),
                                  wx.wxTE_READONLY + wx.wxTE_MULTILINE + wx.wxTE_RICH + wx.wxSUNKEN_BORDER + wx.wxHSCROLL )

log_window:SetBackgroundColour( wx.wxColour( 0, 0, 0 ) )
log_window:SetFont( log_font )

-------------------------------------------------------------------------------------------------------------------------------------
--// DIALOG //-----------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------

--// dialog helper msg
dialog.msg = function( title, text, name )
    local di = wx.wxDialog(
        wx.NULL,
        id_helper_dialog,
        name or "INFO",
        wx.wxDefaultPosition,
        wx.wxSize( 300, 300 ),
        wx.wxSTAY_ON_TOP + wx.wxDEFAULT_DIALOG_STYLE - wx.wxCLOSE_BOX - wx.wxMAXIMIZE_BOX - wx.wxMINIMIZE_BOX
    )
    di:Centre( wx.wxBOTH )

    dialog.title = wx.wxStaticText( di, wx.wxID_ANY, title, wx.wxPoint( 20, 10 ) )
    dialog.title:Wrap( 250 )

    dialog.text = wx.wxStaticText( di, wx.wxID_ANY, "", wx.wxPoint( 20, 50 ), wx.wxSize( 250, 50 ) )
    dialog.text:SetLabel( text )
    
    local wxPointButtonTop = 40 + dialog.text:GetSize():GetHeight() + 22
    local wxSizeDialog = wxPointButtonTop + 20 + 38
    di:SetSize( wx.wxSize( 300, wxSizeDialog ) )

    dialog.button = wx.wxButton( di, id_helper_dialog_btn, "OK", wx.wxPoint( 100, wxPointButtonTop ), wx.wxSize( 60, 20 ) )
    dialog.button:Centre( wx.wxHORIZONTAL )
    dialog.button:Connect( id_helper_dialog_btn, wx.wxEVT_COMMAND_BUTTON_CLICKED, function( event ) di:Destroy() end )
    dialog.button:SetFocus()

    di:ShowModal()
end

--// dialog helper info
dialog.info = function( info, name )
    local di = wx.wxMessageDialog( frame, info, name or "INFO", wx.wxOK + wx.wxCENTRE )
    local result = di:ShowModal()
    di:Destroy()
    return result
end

--// dialog helper question
dialog.question = function( question, name )
    local di = wx.wxMessageDialog( frame, question, name or "INFO", wx.wxYES_NO + wx.wxICON_QUESTION + wx.wxCENTRE )
    local result = di:ShowModal()
    di:Destroy()
    return result
end

-------------------------------------------------------------------------------------------------------------------------------------
--// VALIDATE //---------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------

--// validate cert: general
validate.cert = function( dialog_show )
    local ssl_mode, ssl_err = lfs.attributes( tables[ "sslparams" ]["certificate"], "mode" )
    local check_failed = type( ssl_err ) == "string" or ssl_mode == "nil"
    if check_failed then
        log_broadcast(
            log_window,
            {
                "Client Certificate",
                "Please generate your certificate files before connect!",
                "Howto instructions: docs/README.txt",
                "Error: Certificate file not found!"
            }
        )
        return check_failed
    end
end

--// validate helper number
validate.number = function( control )
    return tonumber( control:GetValue() ) == nil
end
--// validate helper number
validate.empty = function( control )
    return trim( control:GetValue() ) == ""
end

validate.getTab = function( tab )
    if tab == "hub" then tab = 1 end
    if tab == "cfg" then tab = 2 end
    if tab == "rules" then tab = 3 end
    return "Tab " .. tab .. ": " .. notebook:GetPageText( tab - 1 )
end

--// validate hub: Tab 1
validate._hub = function( dialog_event )
    local empty_address, number_port, empty_nickname, empty_password = validate.empty( control_hubaddress ), validate.number( control_hubport ), validate.empty( control_nickname ), validate.empty( control_password )
    local check_failed = empty_address or number_port or empty_nickname or empty_password
    return check_failed, empty_address, number_port, empty_nickname, empty_password
end
validate.hub = function( dialog_show, dialog_event )
    local check_failed, empty_address, number_port, empty_nickname, empty_password = validate._hub()
    local dialog_title, dialog_info, dialog_msg = "", "", { }
    dialog_name = validate.getTab( 1 )
    if check_failed then
        dialog_title = "Please solve the following issue(s) your changes before continue!"
        if dialog_event ~= "save" and need_save.hub then
            table.insert( dialog_msg, "Warn: Unsaved changes" )
        end
        if dialog_event == "connect" then
            if empty_address then
                table.insert( dialog_msg, "Error: No Hub address!" )
            end
            if number_port then
                table.insert( dialog_msg, "Error: No Hub port!" )
            end
            if empty_nickname then
                table.insert( dialog_msg, "Error: No Hub nickname!" )
            end
            if empty_password then
                table.insert( dialog_msg, "Error: No Hub password!" )
            end
        end
        if #dialog_msg > 0 then
            table.insert( dialog_msg, 1, dialog_name )
            table.insert( dialog_msg, 2, dialog_title )
            if dialog_show then
                log_broadcast( log_window, dialog_msg )
            end
            return dialog_msg
        end
    elseif dialog_event ~= "save" and need_save.hub then
        table.insert( dialog_msg, "Please save your changes before continue!" )
        table.insert( dialog_msg, "Warn: Unsaved changes" )
        if dialog_show then
            log_broadcast( log_window, dialog_msg )
        end
        return dialog_msg
    end
    return false
end

--// validate cfg: Tab 2
validate.cfg = function( dialog_show, dialog_event )
    if dialog_event ~= "save" and need_save.cfg then
        if dialog_show then
            --// todo: redo
            local dialog_info = "Please save your changes before continue!"
            dialog.info( dialog_info, dialog_name )
        end
        return { dialog_name, "Warn: Unsaved changes" }
    end
    return false
end

--// validate helper multiple rule: Tab 3
validate.rule_unique_name = function( dialog_show )
    local dialog_msg = { }
    for k, v in ipairs( tables[ "rules" ] ) do
        if table.hasValue( tables[ "rules" ], v[ "rulename" ], "rulename", k ) then
            table.insert( dialog_msg, "Rule #" .. k .. ": '" .. v[ "rulename" ] .. "'" )
        end
    end
    if #dialog_msg > 0 then
        table.insert( dialog_msg, 1, validate.getTab( 3 ) )
        table.insert( dialog_msg, 2, "Error: Rule(s) name are not unique!" )
        if dialog_show then
            log_broadcast( log_window, dialog_msg )
        end
        return dialog_msg
    end
    return false
end

--// validate helper active rule: Tab 3
validate.rule_check_active = function( dialog_show )
    local dialog_msg = { }
    for k, v in ipairs( tables[ "rules" ] ) do
        if table.hasValue( tables[ "rules" ], true, "active" ) then
            return false
        else
            table.insert( dialog_msg, "Rule #" .. k .. ": '" .. v[ "rulename" ] .. "'" )
        end
    end
    if #dialog_msg > 0 then
        table.insert( dialog_msg, 1, validate.getTab( 3 ) )
        table.insert( dialog_msg, 2, "Error: No Rule(s) are activated" )
        if dialog_show then
            log_broadcast( log_window, dialog_msg )
        end
        return dialog_msg
    end
    return false
end

--// validate rules: Tab 3
validate._rules = function( event )
    local unique_name, check_active = validate.rule_unique_name( false ), validate.rule_check_active( false )
    local check_failed = ( event == "connect" ) and ( unique_name or check_active ) or unique_name
    return check_failed, unique_name, check_active
end
validate.rules = function( dialog_show, dialog_event )
    local check_failed, unique_name, check_active = validate._rules( dialog_event )
    local dialog_title, dialog_info, dialog_msg = "", "", { }
    local dialog_name = validate.getTab( 3 )
    if check_failed then
        dialog_title = "Please solve the following issue(s) before continue!"
        if dialog_event ~= "save" and need_save.rules then
            table.insert( dialog_msg, "Warn: Unsaved changes" )
        end
        if unique_name then
            table.remove( unique_name, 1 )
            table.insert( dialog_msg, table.remove( unique_name, 1 ) )
            for k, v in ipairs( unique_name ) do
                table.insert( dialog_msg, v )
            end
        end
        if dialog_event == "connect" and check_active then
            table.remove( check_active, 1 )
            table.insert( dialog_msg, table.remove( check_active, 1 ) )
            for k, v in ipairs( check_active ) do
                table.insert( dialog_msg, v )
            end
        end

        if #dialog_msg > 0 then
            table.insert( dialog_msg, 1, dialog_name )
        end
        if dialog_show then
            log_broadcast( log_window, dialog_msg )
        end
        return dialog_msg
    elseif dialog_event ~= "save" and need_save.rules then
        if dialog_show and #dialog_msg > 0 then
            table.insert( dialog_msg, 1, dialog_name )
            if dialog_name == validate.getTab( 3 ) then
                table.insert( dialog_msg, "Please save your changes before continue!" )
            else
                table.insert( dialog_msg, "Please save your changes on '" .. validate.getTab( 3 ) .. "' before continue!" )
            end
            log_broadcast( log_window, dialog_msg )
        end
        return { dialog_name, "Warn: Unsaved changes" }
    end
    return false
end

--// validate save: Tab 1 + Tab 2 + Tab 3
validate.save = function( dialog_show, dialog_page )
    local dialog_msg = { }
    local hub_msg, cfg_msg, rules_msg = validate.hub( false, "save" ), validate.cfg( false, "save" ), validate.rules( false, "save" )
    local check_failed = false
    if dialog_show then
        if hub_msg ~= false and ( not dialog_page or dialog_page == "hub" ) then
            table.insert( dialog_msg, hub_msg )
        end
        if cfg_msg ~= false and ( not dialog_page or dialog_page == "cfg" ) then
            table.insert( dialog_msg, cfg_msg )
        end
        if rules_msg ~= false and ( not dialog_page or dialog_page == "rules" ) then
            table.insert( dialog_msg, rules_msg )
        end
        if dialog_show and #dialog_msg > 0 then
            table.insert( dialog_msg, 1, "Save Validator" )
            table.insert( dialog_msg, 2, "Please solve the following issue(s) before continue:" )
            log_broadcast( log_window, dialog_msg )
            return true
        end

    end
    return false
end

--// validate connect: Tab 1 + Tab 2 + Tab 3
validate.connect = function( dialog_show )
    local dialog_msg = { }
    local hub_msg, cfg_msg, rules_msg = validate.hub( false, "connect" ), validate.cfg( false, "connect" ), validate.rules( false, "connect" )
    local check_failed = type( hub_msg ) == "table" or type( cfg_msg ) == "table" or type( rules_msg ) == "table"
    if dialog_show then
        if hub_msg ~= false then
            table.insert( dialog_msg, hub_msg )
        end
        if cfg_msg ~= false then
            table.insert( dialog_msg, cfg_msg )
        end
        if rules_msg ~= false then
            table.insert( dialog_msg, rules_msg )
        end
        if dialog_show and #dialog_msg > 0 then
            table.insert( dialog_msg, 1, "Connect Validator" )
            table.insert( dialog_msg, 2, "Please solve the following issue(s) before continue:" )
            log_broadcast( log_window, dialog_msg )
            return true
        end

    end
    return false
end

-------------------------------------------------------------------------------------------------------------------------------------
--// Tab 1 //------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------

--// hubname
control = wx.wxStaticBox( tab_1, wx.wxID_ANY, "Hubname", wx.wxPoint( 5, 5 ), wx.wxSize( 775, 43 ) )
control_hubname = wx.wxTextCtrl( tab_1, wx.wxID_ANY, "", wx.wxPoint( 20, 21 ), wx.wxSize( 745, 20 ), wx.wxSUNKEN_BORDER )
control_hubname:SetBackgroundColour( wx.wxColour( 255, 255, 255 ) )
control_hubname:SetMaxLength( 100 )
control_hubname:Connect( wx.wxID_ANY, wx.wxEVT_ENTER_WINDOW, function( event ) sb:SetStatusText( "Enter your Hubname", 0 ) end )
control_hubname:Connect( wx.wxID_ANY, wx.wxEVT_LEAVE_WINDOW, function( event ) sb:SetStatusText( "", 0 ) end )

--// hubaddress
control = wx.wxStaticBox( tab_1, wx.wxID_ANY, "Hubaddress", wx.wxPoint( 5, 55 ), wx.wxSize( 692, 43 ) )
control_hubaddress = wx.wxTextCtrl( tab_1, wx.wxID_ANY, "", wx.wxPoint( 20, 71 ), wx.wxSize( 662, 20 ), wx.wxSUNKEN_BORDER )
control_hubaddress:SetBackgroundColour( wx.wxColour( 255, 255, 255 ) )
control_hubaddress:SetMaxLength( 170 )
control_hubaddress:Connect( wx.wxID_ANY, wx.wxEVT_ENTER_WINDOW, function( event ) sb:SetStatusText( "Enter your Hubaddress, you can use the complete address with adcs://addy:port/keyprint the informations will be auto-split", 0 ) end )
control_hubaddress:Connect( wx.wxID_ANY, wx.wxEVT_LEAVE_WINDOW, function( event ) sb:SetStatusText( "", 0 ) end )

--// port
control = wx.wxStaticBox( tab_1, wx.wxID_ANY, "Port", wx.wxPoint( 698, 55 ), wx.wxSize( 82, 43 ) )
control_hubport = wx.wxTextCtrl( tab_1, wx.wxID_ANY, "", wx.wxPoint( 713, 71 ), wx.wxSize( 52, 20 ), wx.wxSUNKEN_BORDER )
control_hubport:SetBackgroundColour( wx.wxColour( 255, 255, 255 ) )
control_hubport:SetMaxLength( 5 )
control_hubport:Connect( wx.wxID_ANY, wx.wxEVT_ENTER_WINDOW, function( event ) sb:SetStatusText( "Enter your Hubport", 0 ) end )
control_hubport:Connect( wx.wxID_ANY, wx.wxEVT_LEAVE_WINDOW, function( event ) sb:SetStatusText( "", 0 ) end )

--// nickname
control = wx.wxStaticBox( tab_1, wx.wxID_ANY, "Nickname", wx.wxPoint( 5, 105 ), wx.wxSize( 775, 43 ) )
control_nickname = wx.wxTextCtrl( tab_1, wx.wxID_ANY, "", wx.wxPoint( 20, 121 ), wx.wxSize( 745, 20 ) )
control_nickname:SetBackgroundColour( wx.wxColour( 255, 255, 255 ) )
control_nickname:SetMaxLength( 70 )
control_nickname:Connect( wx.wxID_ANY, wx.wxEVT_ENTER_WINDOW, function( event ) sb:SetStatusText( "Enter your Nickname", 0 ) end )
control_nickname:Connect( wx.wxID_ANY, wx.wxEVT_LEAVE_WINDOW, function( event ) sb:SetStatusText( "", 0 ) end )

--// password
control = wx.wxStaticBox( tab_1, wx.wxID_ANY, "Password", wx.wxPoint( 5, 155 ), wx.wxSize( 775, 43 ) )
control_password = wx.wxTextCtrl( tab_1, wx.wxID_ANY, "", wx.wxPoint( 20, 171 ), wx.wxSize( 745, 20 ), wx.wxSUNKEN_BORDER + wx.wxTE_PASSWORD )
control_password:SetBackgroundColour( wx.wxColour( 255, 255, 255 ) )
control_password:SetMaxLength( 70 )
control_password:Connect( wx.wxID_ANY, wx.wxEVT_ENTER_WINDOW, function( event ) sb:SetStatusText( "Enter your Password", 0 ) end )
control_password:Connect( wx.wxID_ANY, wx.wxEVT_LEAVE_WINDOW, function( event ) sb:SetStatusText( "", 0 ) end )

--// keyprint
control = wx.wxStaticBox( tab_1, wx.wxID_ANY, "Hub Keyprint (optional)", wx.wxPoint( 5, 205 ), wx.wxSize( 775, 43 ) )
control_keyprint = wx.wxTextCtrl( tab_1, wx.wxID_ANY, "", wx.wxPoint( 20, 221 ), wx.wxSize( 745, 20 ), wx.wxSUNKEN_BORDER )
control_keyprint:SetBackgroundColour( wx.wxColour( 255, 255, 255 ) )
control_keyprint:SetMaxLength( 80 )
control_keyprint:Connect( wx.wxID_ANY, wx.wxEVT_ENTER_WINDOW, function( event ) sb:SetStatusText( "Enter your Hub Keyprint. (optional)", 0 ) end )
control_keyprint:Connect( wx.wxID_ANY, wx.wxEVT_LEAVE_WINDOW, function( event ) sb:SetStatusText( "", 0 ) end )

--//  tsl mode
control_tls = wx.wxRadioBox( tab_1, id_control_tls, "TLS Mode", wx.wxPoint( 352, 260 ), wx.wxSize( 83, 60 ), { "TLSv1", "TLSv1.2" }, 1, wx.wxSUNKEN_BORDER )

--// button save
save_hub = wx.wxButton( tab_1, id_save_hub, "Save", wx.wxPoint( 352, 332 ), wx.wxSize( 83, 25 ) )
save_hub:SetBackgroundColour( wx.wxColour( 200, 200, 200 ) )
save_hub:Connect( id_save_hub, wx.wxEVT_COMMAND_BUTTON_CLICKED,
    function( event )
        if not validate.save( true, "hub" ) then
            save_changes( log_window, "hub" )
        end
    end )

--// event - hubname
control_hubname:Connect( wx.wxID_ANY, wx.wxEVT_COMMAND_TEXT_UPDATED, HandleChangeTab1 )

--// event - hubaddress
control_hubaddress:Connect( wx.wxID_ANY, wx.wxEVT_COMMAND_TEXT_UPDATED, HandleChangeTab1 )
control_hubaddress:Connect( wx.wxID_ANY, wx.wxEVT_KILL_FOCUS, function( event ) check_for_whitespaces_textctrl( frame, control_hubaddress ) parse_address_input( frame, control_hubaddress, control_hubport, control_keyprint ) end )

--// event - port
control_hubport:Connect( wx.wxID_ANY, wx.wxEVT_COMMAND_TEXT_UPDATED, HandleChangeTab1 )
control_hubport:Connect( wx.wxID_ANY, wx.wxEVT_KILL_FOCUS, function( event ) check_for_whitespaces_textctrl( frame, control_hubport ) check_for_number_or_reset_to_default( control_hubport, "" ) end )

--// event - nickname
control_nickname:Connect( wx.wxID_ANY, wx.wxEVT_COMMAND_TEXT_UPDATED, HandleChangeTab1 )
control_nickname:Connect( wx.wxID_ANY, wx.wxEVT_KILL_FOCUS, function( event ) check_for_whitespaces_textctrl( frame, control_nickname ) end )

--// event - password
control_password:Connect( wx.wxID_ANY, wx.wxEVT_COMMAND_TEXT_UPDATED, HandleChangeTab1 )
control_password:Connect( wx.wxID_ANY, wx.wxEVT_KILL_FOCUS, function( event ) check_for_whitespaces_textctrl( frame, control_password ) end )

--// event - keyprint
control_keyprint:Connect( wx.wxID_ANY, wx.wxEVT_COMMAND_TEXT_UPDATED, HandleChangeTab1 )
control_keyprint:Connect( wx.wxID_ANY, wx.wxEVT_KILL_FOCUS, function( event ) check_for_whitespaces_textctrl( frame, control_keyprint ) end )

--// event - tls mode
control_tls:Connect( wx.wxID_ANY, wx.wxEVT_COMMAND_RADIOBOX_SELECTED, HandleChangeTab1 )

-------------------------------------------------------------------------------------------------------------------------------------
--// Tab 2 //------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------

--// add new table entrys on app start (to prevent errors on update)
local check_new_cfg_entrys = function()
    local add_new = false
    if type( tables[ "cfg" ][ "logfilesize" ] ) == "nil" then tables[ "cfg" ][ "logfilesize" ] = defaults[ "logfilesize" ] add_new = true end
    if type( tables[ "cfg" ][ "freshstuff_version" ] ) == "nil" then tables[ "cfg" ][ "freshstuff_version" ] = false add_new = true end
    if add_new then save_config_values( log_window ) end
end
check_new_cfg_entrys()

--// bot description
control = wx.wxStaticBox( tab_2, wx.wxID_ANY, "Bot description", wx.wxPoint( 5, 5 ), wx.wxSize( 380, 43 ) )
control_bot_desc = wx.wxTextCtrl( tab_2, wx.wxID_ANY, "", wx.wxPoint( 20, 21 ), wx.wxSize( 350, 20 ), wx.wxSUNKEN_BORDER )
control_bot_desc:SetBackgroundColour( wx.wxColour( 255, 255, 255 ) )
control_bot_desc:SetMaxLength( 40 )
control_bot_desc:Connect( wx.wxID_ANY, wx.wxEVT_ENTER_WINDOW, function( event ) sb:SetStatusText( "Enter a Bot Description (optional)", 0 ) end )
control_bot_desc:Connect( wx.wxID_ANY, wx.wxEVT_LEAVE_WINDOW, function( event ) sb:SetStatusText( "", 0 ) end )

--//  bot slots
control = wx.wxStaticBox( tab_2, wx.wxID_ANY, "Bot slots (to bypass hub min slots rules)", wx.wxPoint( 5, 55 ), wx.wxSize( 380, 43 ) )
control_bot_slots = wx.wxTextCtrl( tab_2, wx.wxID_ANY, "", wx.wxPoint( 20, 71 ), wx.wxSize( 350, 20 ), wx.wxSUNKEN_BORDER )
control_bot_slots:SetBackgroundColour( wx.wxColour( 255, 255, 255 ) )
control_bot_slots:SetMaxLength( 2 )
control_bot_slots:Connect( wx.wxID_ANY, wx.wxEVT_ENTER_WINDOW, function( event ) sb:SetStatusText( "Amount of Slots, to bypass hub min slots rules (empty = default)", 0 ) end )
control_bot_slots:Connect( wx.wxID_ANY, wx.wxEVT_LEAVE_WINDOW, function( event ) sb:SetStatusText( "", 0 ) end )

--//  bot share
control = wx.wxStaticBox( tab_2, wx.wxID_ANY, "Bot share (in MBytes, to bypass hub min share rules)", wx.wxPoint( 5, 105 ), wx.wxSize( 380, 43 ) )
control_bot_share = wx.wxTextCtrl( tab_2, wx.wxID_ANY, "", wx.wxPoint( 20, 121 ), wx.wxSize( 350, 20 ), wx.wxSUNKEN_BORDER )
control_bot_share:SetBackgroundColour( wx.wxColour( 255, 255, 255 ) )
control_bot_share:SetMaxLength( 40 )
control_bot_share:Connect( wx.wxID_ANY, wx.wxEVT_ENTER_WINDOW, function( event ) sb:SetStatusText( "Amount of Share (in MBytes), to bypass hub min share rules (empty = default)", 0 ) end )
control_bot_share:Connect( wx.wxID_ANY, wx.wxEVT_LEAVE_WINDOW, function( event ) sb:SetStatusText( "", 0 ) end )

--// sleeptime
control = wx.wxStaticBox( tab_2, wx.wxID_ANY, "Sleeptime after connect (seconds)", wx.wxPoint( 400, 5 ), wx.wxSize( 380, 43 ) )
control_sleeptime = wx.wxTextCtrl( tab_2, wx.wxID_ANY, "", wx.wxPoint( 415, 21 ), wx.wxSize( 350, 20 ), wx.wxSUNKEN_BORDER )
control_sleeptime:SetBackgroundColour( wx.wxColour( 255, 255, 255 ) )
control_sleeptime:SetMaxLength( 6 )
control_sleeptime:Connect( wx.wxID_ANY, wx.wxEVT_ENTER_WINDOW, function( event ) sb:SetStatusText( "Sleeptime after connect to the hub, before firt scan (empty = default)", 0 ) end )
control_sleeptime:Connect( wx.wxID_ANY, wx.wxEVT_LEAVE_WINDOW, function( event ) sb:SetStatusText( "", 0 ) end )

--//  announce interval
control = wx.wxStaticBox( tab_2, wx.wxID_ANY, "Announce interval (seconds)", wx.wxPoint( 400, 55 ), wx.wxSize( 380, 43 ) )
control_announceinterval = wx.wxTextCtrl( tab_2, wx.wxID_ANY, "", wx.wxPoint( 415, 71 ), wx.wxSize( 350, 20 ), wx.wxSUNKEN_BORDER )
control_announceinterval:SetBackgroundColour( wx.wxColour( 255, 255, 255 ) )
control_announceinterval:SetMaxLength( 6 )
control_announceinterval:Connect( wx.wxID_ANY, wx.wxEVT_ENTER_WINDOW, function( event ) sb:SetStatusText( "Announce interval in seconds (empty = default)", 0 ) end )
control_announceinterval:Connect( wx.wxID_ANY, wx.wxEVT_LEAVE_WINDOW, function( event ) sb:SetStatusText( "", 0 ) end )

--// timeout
control = wx.wxStaticBox( tab_2, wx.wxID_ANY, "Socket Timeout (seconds)", wx.wxPoint( 400, 105 ), wx.wxSize( 380, 43 ) )
control_sockettimeout = wx.wxTextCtrl( tab_2, wx.wxID_ANY, "", wx.wxPoint( 415, 121 ), wx.wxSize( 350, 20 ), wx.wxSUNKEN_BORDER )
control_sockettimeout:SetBackgroundColour( wx.wxColour( 255, 255, 255 ) )
control_sockettimeout:SetMaxLength( 3 )
control_sockettimeout:Connect( wx.wxID_ANY, wx.wxEVT_ENTER_WINDOW, function( event ) sb:SetStatusText( "Socket timeout, you shouldn't change this if you not know what you do (empty = default)", 0 ) end )
control_sockettimeout:Connect( wx.wxID_ANY, wx.wxEVT_LEAVE_WINDOW, function( event ) sb:SetStatusText( "", 0 ) end )

--// max logfile size
control = wx.wxStaticBox( tab_2, wx.wxID_ANY, "Max Logfile size (bytes)", wx.wxPoint( 320, 160 ), wx.wxSize( 150, 43 ) )
control_logfilesize = wx.wxSpinCtrl( tab_2, wx.wxID_ANY, "", wx.wxPoint( 335, 176 ), wx.wxSize( 120, 20 ) )
control_logfilesize:Connect( wx.wxID_ANY, wx.wxEVT_ENTER_WINDOW, function( event ) sb:SetStatusText( "Set maximum size of logfiles, you should leave it as it is (empty = default)", 0 ) end )
control_logfilesize:Connect( wx.wxID_ANY, wx.wxEVT_LEAVE_WINDOW, function( event ) sb:SetStatusText( "", 0 ) end )
control_logfilesize:SetRange( defaults[ "logfilesize" ], defaults[ "logfilesizemax" ] )
control_logfilesize:SetValue( defaults[ "logfilesize" ] )

--// minimize to tray
checkbox_trayicon = wx.wxCheckBox( tab_2, wx.wxID_ANY, "Minimize to tray", wx.wxPoint( 335, 245 ), wx.wxDefaultSize )
checkbox_trayicon:Connect( wx.wxID_ANY, wx.wxEVT_ENTER_WINDOW, function( event ) sb:SetStatusText( "Minimize the App to systemtray", 0 ) end )
checkbox_trayicon:Connect( wx.wxID_ANY, wx.wxEVT_LEAVE_WINDOW, function( event ) sb:SetStatusText( "", 0 ) end )

--// save button
save_cfg = wx.wxButton( tab_2, id_save_cfg, "Save", wx.wxPoint( 352, 270 ), wx.wxSize( 83, 25 ) )
save_cfg:SetBackgroundColour( wx.wxColour( 200, 200, 200 ) )
save_cfg:Connect( id_save_cfg, wx.wxEVT_COMMAND_BUTTON_CLICKED,
    function( event )
        if not validate.save( true, "cfg" ) then
            save_changes( log_window, "cfg" )
        end
    end )

--// events - bot description
control_bot_desc:Connect( wx.wxID_ANY, wx.wxEVT_COMMAND_TEXT_UPDATED, HandleChangeTab2 )
control_bot_desc:Connect( wx.wxID_ANY, wx.wxEVT_KILL_FOCUS, function( event ) check_for_empty_and_reset_to_default( control_bot_desc, defaults[ "botdesc" ] ) end )

--// events - bot share
control_bot_share:Connect( wx.wxID_ANY, wx.wxEVT_COMMAND_TEXT_UPDATED, HandleChangeTab2 )
control_bot_share:Connect( wx.wxID_ANY, wx.wxEVT_KILL_FOCUS, function( event ) check_for_whitespaces_textctrl( frame, control_bot_share ) check_for_number_or_reset_to_default( control_bot_share, defaults[ "botdesc" ] ) end )

--// events - bot slots
control_bot_slots:Connect( wx.wxID_ANY, wx.wxEVT_COMMAND_TEXT_UPDATED, HandleChangeTab2 )
control_bot_slots:Connect( wx.wxID_ANY, wx.wxEVT_KILL_FOCUS, function( event ) check_for_whitespaces_textctrl( frame, control_bot_slots ) check_for_number_or_reset_to_default( control_bot_slots, defaults[ "botslots" ] ) end )

--// events - announce interval
control_announceinterval:Connect( wx.wxID_ANY, wx.wxEVT_COMMAND_TEXT_UPDATED, HandleChangeTab2 )
control_announceinterval:Connect( wx.wxID_ANY, wx.wxEVT_KILL_FOCUS, function( event ) check_for_whitespaces_textctrl( frame, control_announceinterval ) check_for_number_or_reset_to_default( control_announceinterval, defaults[ "announceinterval" ] ) end )

--// events - sleeptime
control_sleeptime:Connect( wx.wxID_ANY, wx.wxEVT_COMMAND_TEXT_UPDATED, HandleChangeTab2 )
control_sleeptime:Connect( wx.wxID_ANY, wx.wxEVT_KILL_FOCUS, function( event ) check_for_whitespaces_textctrl( frame, control_sleeptime ) check_for_number_or_reset_to_default( control_sleeptime, defaults[ "sleeptime" ] ) end )

--// events - timeout
control_sockettimeout:Connect( wx.wxID_ANY, wx.wxEVT_COMMAND_TEXT_UPDATED, HandleChangeTab2 )
control_sockettimeout:Connect( wx.wxID_ANY, wx.wxEVT_KILL_FOCUS, function( event ) check_for_whitespaces_textctrl( frame, control_sockettimeout ) check_for_number_or_reset_to_default( control_sockettimeout, defaults[ "sockettimeout" ] ) end )

--// events - max logfile size
control_logfilesize:Connect( wx.wxID_ANY, wx.wxEVT_COMMAND_TEXT_UPDATED, HandleChangeTab2 )

--// events - minimize to tray
checkbox_trayicon:Connect( wx.wxID_ANY, wx.wxEVT_COMMAND_CHECKBOX_CLICKED,
    function( event )
        HandleChangeTab2( event )
        add_taskbar( frame, checkbox_trayicon )
    end )

-------------------------------------------------------------------------------------------------------------------------------------
--// Tab 3 //------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------

--// add new table entrys on app start (to prevent errors on update)
local check_new_rule_entrys = function()
    local add_new = false
    for k, v in ipairs( tables[ "rules" ] ) do
        if type( v[ "checkdirs" ] ) == "nil" then v[ "checkdirs" ] = true add_new = true end
        if type( v[ "checkdirsnfo" ] ) == "nil" then v[ "checkdirsnfo" ] = false add_new = true end
        if type( v[ "checkdirssfv" ] ) == "nil" then v[ "checkdirssfv" ] = false add_new = true end
        if type( v[ "checkfiles" ] ) == "nil" then v[ "checkfiles" ] = false add_new = true end
        if type( v[ "alibinick" ] ) == "nil" then v[ "alibinick" ] = "DUMP" add_new = true end
        if type( v[ "alibicheck" ] ) == "nil" then v[ "alibicheck" ] = false add_new = true end
        if type( v[ "checkage" ] ) == "nil" then v[ "checkage" ] = false add_new = true end
        if type( v[ "maxage" ] ) == "nil" then v[ "maxage" ] = 0 add_new = true end
        if type( v[ "checkspaces" ] ) == "nil" then v[ "checkspaces" ] = false add_new = true end
        if type( v[ "category" ] ) == "nil" then v[ "category" ] = "" add_new = true end
    end
    if add_new then save_rules_values( log_window, true ) end
end
check_new_rule_entrys()

--// save button
save_rules = wx.wxButton( tab_3, id_save_rules, "Save", wx.wxPoint( 15, 330 ), wx.wxSize( 83, 25 ) )
save_rules:SetBackgroundColour( wx.wxColour( 200, 200, 200 ) )
save_rules:Connect( id_save_rules, wx.wxEVT_COMMAND_BUTTON_CLICKED,
    function( event )
        if not validate.save( true, "rules" ) then
            save_changes( log_window, "rules" )
        end
    end )
save_rules:Disable()

--// treebook
local treebook, set_rules_values
local make_treebook_page = function( )
    treebook = wx.wxTreebook(
        tab_3,
        wx.wxID_ANY,
        wx.wxPoint( 0, 0 ),
        wx.wxSize( notebook_width, 320 ),
        wx.wxBK_LEFT
    )

    local first_page = true
    local i = 1

    set_rules_values = function()
        for k, v in ipairs( tables[ "rules" ] ) do
            local str = tostring( i )

            local panel = "panel_" .. str
            panel = wx.wxPanel( treebook, wx.wxID_ANY )
            panel:SetBackgroundColour( wx.wxColour( 225, 225, 225 ) )

            local sizer = wx.wxBoxSizer( wx.wxVERTICAL )
            sizer:SetMinSize( notebook_width, 235 )
            panel:SetSizer( sizer )
            sizer:SetSizeHints( panel )

            --// avoid to long rulename
            local rulename = tables[ "rules" ][ k ].rulename
            if string.len( rulename ) > 15 then
                rulename = string.sub( rulename, 1, 15 ) .. ".."
            end

            --// set short rulename
            if tables[ "rules" ][ k ].active == true then
                treebook:AddPage( panel, "" .. i .. ": " .. rulename .. " (on)", first_page, i - 1 )
            else
                treebook:AddPage( panel, "" .. i .. ": " .. rulename .. " (off)", first_page, i - 1 )
            end

            first_page = false

            --// activate
            local checkbox_activate = "checkbox_activate_" .. str
            checkbox_activate = wx.wxCheckBox( panel, id_activate + i, "Activate", wx.wxPoint( 5, 15 ), wx.wxDefaultSize )
            checkbox_activate:SetForegroundColour( wx.wxRED )
            checkbox_activate:Connect( wx.wxID_ANY, wx.wxEVT_ENTER_WINDOW, function( event ) sb:SetStatusText( "Activate this rule", 0 ) end )
            checkbox_activate:Connect( wx.wxID_ANY, wx.wxEVT_LEAVE_WINDOW, function( event ) sb:SetStatusText( "", 0 ) end )
            if tables[ "rules" ][ k ].active == true then
                checkbox_activate:SetValue( true )
                checkbox_activate:SetForegroundColour( wx.wxColour( 0, 128, 0 ) )
            else
                checkbox_activate:SetValue( false )
            end

            --// rulename
            local textctrl_rulename = "textctrl_rulename_" .. str
            textctrl_rulename = wx.wxTextCtrl( panel, id_rulename + i, "", wx.wxPoint( 80, 11 ), wx.wxSize( 350, 20 ), wx.wxSUNKEN_BORDER )
            textctrl_rulename:SetBackgroundColour( wx.wxColour( 255, 255, 255 ) )
            textctrl_rulename:SetMaxLength( 25 )
            textctrl_rulename:SetValue( tables[ "rules" ][ k ].rulename )
            textctrl_rulename:Connect( wx.wxID_ANY, wx.wxEVT_ENTER_WINDOW, function( event ) sb:SetStatusText( "Rulename, you can rename it if you like", 0 ) end )
            textctrl_rulename:Connect( wx.wxID_ANY, wx.wxEVT_LEAVE_WINDOW, function( event ) sb:SetStatusText( "", 0 ) end )

            --// announcing path
            control = wx.wxStaticBox( panel, wx.wxID_ANY, "Announcing path", wx.wxPoint( 5, 40 ), wx.wxSize( 520, 43 ) )
            local dirpicker_path = "dirpicker_path_" .. str
            dirpicker_path = wx.wxTextCtrl( panel, id_dirpicker_path + i, "", wx.wxPoint( 20, 55 ), wx.wxSize( 410, 20 ), wx.wxTE_PROCESS_ENTER + wx.wxSUNKEN_BORDER )
            dirpicker_path:SetValue( tables[ "rules" ][ k ].path )
            dirpicker_path:Connect( wx.wxID_ANY, wx.wxEVT_ENTER_WINDOW, function( event ) sb:SetStatusText( "Set source path for files/directorys to announce", 0 ) end )
            dirpicker_path:Connect( wx.wxID_ANY, wx.wxEVT_LEAVE_WINDOW, function( event ) sb:SetStatusText( "", 0 ) end )

            --// announcing path dirpicker
            local dirpicker = "dirpicker_" .. str
            dirpicker = wx.wxDirPickerCtrl( panel, id_dirpicker + i, tables[ "rules" ][ k ].path, "Choose announcing folder:", wx.wxPoint( 438, 55 ), wx.wxSize( 80, 22 ), wx.wxDIRP_DIR_MUST_EXIST )

            --// command
            control = wx.wxStaticBox( panel, wx.wxID_ANY, "Hub command", wx.wxPoint( 5, 91 ), wx.wxSize( 240, 43 ) )
            local textctrl_command = "textctrl_command_" .. str
            textctrl_command = wx.wxTextCtrl( panel, id_command + i, "", wx.wxPoint( 20, 107 ), wx.wxSize( 210, 20 ), wx.wxSUNKEN_BORDER )
            textctrl_command:SetBackgroundColour( wx.wxColour( 255, 255, 255 ) )
            textctrl_command:SetMaxLength( 30 )
            textctrl_command:SetValue( tables[ "rules" ][ k ].command )
            textctrl_command:Connect( wx.wxID_ANY, wx.wxEVT_ENTER_WINDOW, function( event ) sb:SetStatusText( "Freshstuff hubcommand, default: +addrel", 0 ) end )
            textctrl_command:Connect( wx.wxID_ANY, wx.wxEVT_LEAVE_WINDOW, function( event ) sb:SetStatusText( "", 0 ) end )

            --// alibi nick border
            control = wx.wxStaticBox( panel, wx.wxID_ANY, "Hub nickname", wx.wxPoint( 5, 141 ), wx.wxSize( 240, 67 ) )

            --// alibi nick
            local textctrl_alibinick = "textctrl_alibinick_" .. str
            textctrl_alibinick = wx.wxTextCtrl( panel, id_alibinick + i, "", wx.wxPoint( 20, 181 ), wx.wxSize( 210, 20 ), wx.wxSUNKEN_BORDER )
            textctrl_alibinick:SetBackgroundColour( wx.wxColour( 255, 255, 255 ) )
            textctrl_alibinick:SetMaxLength( 30 )
            textctrl_alibinick:SetValue( tables[ "rules" ][ k ].alibinick )
            textctrl_alibinick:Connect( wx.wxID_ANY, wx.wxEVT_ENTER_WINDOW, function( event ) sb:SetStatusText( "Alibi nick, you can announce releases with an other nickname, requires ptx_freshstuff_v0.7 or higher", 0 ) end )
            textctrl_alibinick:Connect( wx.wxID_ANY, wx.wxEVT_LEAVE_WINDOW, function( event ) sb:SetStatusText( "", 0 ) end )

            --// alibi nick checkbox
            local checkbox_alibicheck = "checkbox_alibicheck_" .. str
            checkbox_alibicheck = wx.wxCheckBox( panel, id_alibicheck + i, "Use alternative nick", wx.wxPoint( 20, 158 ), wx.wxDefaultSize )
            checkbox_alibicheck:Connect( wx.wxID_ANY, wx.wxEVT_ENTER_WINDOW, function( event ) sb:SetStatusText( "Alibi nick, you can announce releases with an other nickname, requires ptx_freshstuff_v0.7 or higher", 0 ) end )
            checkbox_alibicheck:Connect( wx.wxID_ANY, wx.wxEVT_LEAVE_WINDOW, function( event ) sb:SetStatusText( "", 0 ) end )
            if tables[ "rules" ][ k ].alibicheck == true then
                checkbox_alibicheck:SetValue( true )
            else
                checkbox_alibicheck:SetValue( false )
                textctrl_alibinick:Disable()
            end

            --// category border
            control = wx.wxStaticBox( panel, wx.wxID_ANY, "Category", wx.wxPoint( 5, 216 ), wx.wxSize( 240, 43 ) )

            --// category choice
            local choicectrl_category = "choice_category_" .. str
            choicectrl_category = wx.wxChoice( panel, id_category + i, wx.wxPoint( 20, 232 ), wx.wxSize( 210, 20 ), list_categories_tbl() )
            choicectrl_category:Select( choicectrl_category:FindString( tables[ "rules" ][ k ].category, true ) )
            choicectrl_category:Connect( wx.wxID_ANY, wx.wxEVT_ENTER_WINDOW, function( event ) sb:SetStatusText( "Choose a Freshstuff category", 0 ) end )
            choicectrl_category:Connect( wx.wxID_ANY, wx.wxEVT_LEAVE_WINDOW, function( event ) sb:SetStatusText( "", 0 ) end )

            -------------------------------------------------------------------------------------------------------------------------
            --// blacklist | whitelist border
            control = wx.wxStaticBox( panel, wx.wxID_ANY, "", wx.wxPoint( 5, 266 ), wx.wxSize( 205, 43 ) )

            --// Button - Blacklist
            local blacklist_button = "blacklist_button_" .. str
            blacklist_button = wx.wxButton( panel, id_blacklist_button + i, "Blacklist", wx.wxPoint( 15, 281 ), wx.wxSize( 90, 20 ) )
            blacklist_button:Connect( wx.wxID_ANY, wx.wxEVT_ENTER_WINDOW, function( event ) sb:SetStatusText( "Use the Blacklist to exclude files/folders", 0 ) end )
            blacklist_button:Connect( wx.wxID_ANY, wx.wxEVT_LEAVE_WINDOW, function( event ) sb:SetStatusText( "", 0 ) end )
            blacklist_button:Connect( id_blacklist_button + i, wx.wxEVT_COMMAND_BUTTON_CLICKED,
                function( event )
                    --// send dialog msg
                    local di = "di_" .. str
                    di = wx.wxDialog( frame, id_blacklist + i, "Blacklist", wx.wxDefaultPosition, wx.wxSize( 215, 365 ) )
                    di:SetBackgroundColour( wx.wxColour( 255, 255, 255 ) )
                    --// events - dialog blacklist
                    di:Connect( id_blacklist + i, wx.wxEVT_INIT_DIALOG,
                        function( event )
                            frame:Disable()
                        end
                    )
                    --// events - dialog blacklist
                    di:Connect( id_blacklist + i, wx.wxEVT_CLOSE_WINDOW,
                        function( event )
                            frame:Enable( true )
                            di:Destroy()
                        end
                    )

                    control = wx.wxStaticBox( di, wx.wxID_ANY, "Forbidden TAG's", wx.wxPoint( 5, 5 ), wx.wxSize( 200, 325 ) )
                    control = wx.wxStaticText( di, wx.wxID_ANY, "Add Term:", wx.wxPoint( 20, 25 ) )

                    --// wxTextCtrl
                    local blacklist_textctrl = "blacklist_textctrl_" .. str
                    blacklist_textctrl = wx.wxTextCtrl( di, id_blacklist_textctrl + i, "", wx.wxPoint( 20, 38 ), wx.wxSize( 170, 20 ), wx.wxTE_PROCESS_ENTER )
                    blacklist_textctrl:Connect( wx.wxID_ANY, wx.wxEVT_ENTER_WINDOW, function( event ) sb:SetStatusText( "Choose a TAG name", 0 ) end )
                    blacklist_textctrl:Connect( wx.wxID_ANY, wx.wxEVT_LEAVE_WINDOW, function( event ) sb:SetStatusText( "", 0 ) end )
                    blacklist_textctrl:SetBackgroundColour( wx.wxColour( 200, 200, 200 ) )
                    blacklist_textctrl:Connect( id_blacklist_textctrl + i, wx.wxEVT_KILL_FOCUS,
                        function( event )
                            check_for_whitespaces_textctrl( frame, blacklist_textctrl )
                        end
                    )

                    --// get blacklist table entrys as array
                    local sorted_skip_tbl = function()
                        local skip_lst = { }
                        local i = 1
                        for k, v in pairs( tables[ "rules" ][ k ].blacklist ) do
                            table.insert( skip_lst, i, k )
                            i = i + 1
                        end
                        table.sort( skip_lst )
                        return skip_lst
                    end

                    --// add new table entry to blacklist
                    local add_folder = function( blacklist_textctrl, blacklist_listbox, blacklist_del_button )
                        local selection = blacklist_listbox:GetSelection()
                        local selected  = blacklist_listbox:GetStringSelection()
                        local folder = blacklist_textctrl:GetValue()
                        if folder == "" then
                            local result = dialog.info( "Error: please enter a name for the TAG" )
                        else
                            if table.hasKey( tables[ "rules" ], folder, "blacklist" ) then
                                local result = dialog.info( "Error: TAG name '" .. folder .. "' already taken" )
                                return
                            end
                            tables[ "rules" ][ k ].blacklist[ folder ] = true
                            blacklist_textctrl:SetValue( "" )
                            blacklist_textctrl:SetFocus()
                            blacklist_listbox:Set( sorted_skip_tbl() )

                            --// set selection
                            if selection ~= -1 and selected ~= "" then
                                blacklist_listbox:SetStringSelection( selected )
                            end
                            blacklist_del_button:Enable( selection ~= -1 )

                            log_broadcast( log_window, "The following TAG was added to Blacklist table: " .. folder, "CYAN" )
                        end
                    end

                    --// remove table entry from blacklist
                    local del_folder = function( blacklist_textctrl, blacklist_listbox, blacklist_del_button )
                        local selection = blacklist_listbox:GetSelection()
                        if selection == -1 then
                            local result = dialog.info( "Error: No TAG selected" )
                            return
                        end
                        local folder = blacklist_listbox:GetString( selection )
                        if folder then tables[ "rules" ][ k ].blacklist[ folder ] = nil end

                        blacklist_listbox:Set( sorted_skip_tbl() )
                        if selection == blacklist_listbox:GetCount() then
                            selection = selection - 1
                        end
                        blacklist_listbox:SetSelection( selection )
                        sb:SetStatusText( "", 0 )

                        blacklist_del_button:Enable( blacklist_listbox:GetSelection() ~= -1 )
                        log_broadcast( log_window, "The following TAG was removed from Blacklist table: " .. folder, "CYAN" )
                    end

                    control = wx.wxStaticBox( di, wx.wxID_ANY, "", wx.wxPoint( 20, 78 ), wx.wxSize( 170, 215 ) )

                    --// init listbox add + del button
                    local blacklist_listbox = "blacklist_listbox_" .. str
                    local blacklist_add_button = "blacklist_add_button_" .. str
                    local blacklist_del_button = "blacklist_del_button_" .. str

                    --// wxListBox
                    blacklist_listbox = wx.wxListBox(

                        di,
                        id_blacklist_listbox + i,
                        wx.wxPoint( 30, 93 ),
                        wx.wxSize( 150, 192 ),
                        sorted_skip_tbl(),
                        wx.wxLB_SINGLE + wx.wxLB_HSCROLL + wx.wxLB_SORT
                    )

                    --// Button - Add Folder
                    blacklist_add_button = wx.wxButton( di, id_blacklist_add_button + i, "add", wx.wxPoint( 20, 60 ), wx.wxSize( 169, 18 ) )
                    blacklist_add_button:Disable()
                    blacklist_add_button:Connect( wx.wxID_ANY, wx.wxEVT_ENTER_WINDOW, function( event ) sb:SetStatusText( "Add '" .. trim( blacklist_textctrl:GetValue() ) .. "' to Blacklist", 0 ) end )
                    blacklist_add_button:Connect( wx.wxID_ANY, wx.wxEVT_LEAVE_WINDOW, function( event ) sb:SetStatusText( "", 0 ) end )
                    blacklist_add_button:Connect( id_blacklist_add_button + i, wx.wxEVT_COMMAND_BUTTON_CLICKED,
                        function( event )
                            add_folder( blacklist_textctrl, blacklist_listbox, blacklist_del_button )
                            HandleChangeTab3( event )
                        end
                    )

                    --// Button - Delete Folder
                    blacklist_del_button = wx.wxButton( di, id_blacklist_del_button + i, "delete", wx.wxPoint( 20, 298 ), wx.wxSize( 169, 18 ) )
                    blacklist_del_button:Enable( blacklist_listbox:GetSelection() ~= -1 )
                    blacklist_del_button:Connect( wx.wxID_ANY, wx.wxEVT_ENTER_WINDOW, function( event ) sb:SetStatusText( "Remove selected '" .. blacklist_listbox:GetString( blacklist_listbox:GetSelection() ) .. "' from Blacklist", 0 ) end )
                    blacklist_del_button:Connect( wx.wxID_ANY, wx.wxEVT_LEAVE_WINDOW, function( event ) sb:SetStatusText( "", 0 ) end )
                    blacklist_del_button:Connect( id_blacklist_del_button + i, wx.wxEVT_COMMAND_BUTTON_CLICKED,
                        function( event )
                            del_folder( blacklist_textctrl, blacklist_listbox, blacklist_del_button )
                            HandleChangeTab3( event )
                        end
                    )
                    
                    --// wxTextCtrl - Events
                    blacklist_textctrl:Connect( id_blacklist_textctrl + i, wx.wxEVT_COMMAND_TEXT_UPDATED,
                        function( event )
                            local tag = trim( blacklist_textctrl:GetValue() ) or ""
                            local enabled = ( tag ~= "" )
                            if enabled then
                                if table.hasKey( tables[ "rules" ], tag, "blacklist" ) then
                                    sb:SetStatusText( "Blacklist TAG '" .. tag .. "' already taken", 0 )
                                    enabled = false
                                else
                                    sb:SetStatusText( "Blacklist TAG '" .. tag .. "' is unique", 0 )
                                end
                            else
                                sb:SetStatusText( "Choose a TAG ", 0 )
                            end
                            blacklist_add_button:Enable( enabled )
                        end
                    )
                    blacklist_textctrl:Connect( id_blacklist_textctrl + i, wx.wxEVT_COMMAND_TEXT_ENTER,
                        function(event)
                            blacklist_add_button:SetFocus()
                        end
                    )
                    
                    --// wxListBox - Events
                    blacklist_listbox:Connect( id_blacklist_listbox + i, wx.wxEVT_COMMAND_LISTBOX_SELECTED,
                        function( event )
                            blacklist_del_button:Enable( true )
                        end
                    )

                    di:ShowModal()
                end
            )

            -------------------------------------------------------------------------------------------------------------------------
            --// Button - Whitelist
            local whitelist_button = "whitelist_button_" .. str
            whitelist_button = wx.wxButton( panel, id_whitelist_button + i, "Whitelist", wx.wxPoint( 110, 281 ), wx.wxSize( 90, 20 ) )
            whitelist_button:Connect( wx.wxID_ANY, wx.wxEVT_ENTER_WINDOW, function( event ) sb:SetStatusText( "Use the Whitelist to protect files/folders from the Blacklist check", 0 ) end )
            whitelist_button:Connect( wx.wxID_ANY, wx.wxEVT_LEAVE_WINDOW, function( event ) sb:SetStatusText( "", 0 ) end )
            whitelist_button:Connect( id_whitelist_button + i, wx.wxEVT_COMMAND_BUTTON_CLICKED,
                function( event )
                    --// send dialog msg
                    local di = "di_" .. str
                    di = wx.wxDialog( frame, id_whitelist + i, "Whitelist", wx.wxDefaultPosition, wx.wxSize( 215, 365 ) )
                    di:SetBackgroundColour( wx.wxColour( 255, 255, 255 ) )
                    --// events - dialog Whitelist
                    di:Connect( id_whitelist + i, wx.wxEVT_INIT_DIALOG,
                        function( event )
                            frame:Disable()
                        end
                    )
                    --// events - dialog Whitelist
                    di:Connect( id_whitelist + i, wx.wxEVT_CLOSE_WINDOW,
                        function( event )
                            frame:Enable( true )
                            di:Destroy()
                        end
                    )

                    control = wx.wxStaticBox( di, wx.wxID_ANY, "Necessary TAG's", wx.wxPoint( 5, 5 ), wx.wxSize( 200, 325 ) )
                    control = wx.wxStaticText( di, wx.wxID_ANY, "Add Term:", wx.wxPoint( 20, 25 ) )

                    --// wxTextCtrl
                    local whitelist_textctrl = "whitelist_textctrl_" .. str
                    whitelist_textctrl = wx.wxTextCtrl( di, id_whitelist_textctrl + i, "", wx.wxPoint( 20, 38 ), wx.wxSize( 170, 20 ), wx.wxTE_PROCESS_ENTER )
                    whitelist_textctrl:Connect( wx.wxID_ANY, wx.wxEVT_ENTER_WINDOW, function( event ) sb:SetStatusText( "Choose a TAG name", 0 ) end )
                    whitelist_textctrl:Connect( wx.wxID_ANY, wx.wxEVT_LEAVE_WINDOW, function( event ) sb:SetStatusText( "", 0 ) end )
                    whitelist_textctrl:SetBackgroundColour( wx.wxColour( 200, 200, 200 ) )
                    whitelist_textctrl:Connect( id_whitelist_textctrl + i, wx.wxEVT_KILL_FOCUS,
                        function( event )
                            check_for_whitespaces_textctrl( frame, whitelist_textctrl )
                        end
                    )

                    --// get whitelist table entrys as array
                    local sorted_skip_tbl = function()
                        local skip_lst = { }
                        local i = 1
                        for k, v in pairs( tables[ "rules" ][ k ].whitelist ) do
                            table.insert( skip_lst, i, k )
                            i = i + 1
                        end
                        table.sort( skip_lst )
                        return skip_lst
                    end

                    --// add new table entry to whitelist
                    local add_folder = function( whitelist_textctrl, whitelist_listbox, whitelist_del_button )
                        local selection = whitelist_listbox:GetSelection()
                        local selected  = whitelist_listbox:GetStringSelection()
                        local folder = whitelist_textctrl:GetValue()
                        if folder == "" then
                            local result = dialog.info( "Error: please enter a name for the TAG" )
                        else
                            if table.hasKey( tables[ "rules" ], folder, "whitelist" ) then
                                local result = dialog.info( "Error: TAG name '" .. folder .. "' already taken" )
                                return
                            end
                            tables[ "rules" ][ k ].whitelist[ folder ] = true
                            whitelist_textctrl:SetValue( "" )
                            whitelist_textctrl:SetFocus()
                            whitelist_listbox:Set( sorted_skip_tbl() )

                            --// set selection
                            if selection ~= -1 and selected ~= "" then
                                whitelist_listbox:SetStringSelection( selected )
                            end
                            whitelist_del_button:Enable( selection ~= -1 )
                        
                            sb:SetStatusText( "Whitelist TAG '" .. folder .. "' was added", 0 )
                            log_broadcast( log_window, "The following TAG was added to Whitelist table: " .. folder, "CYAN" )
                        end
                    end

                    --// remove table entry from whitelist
                    local del_folder = function( whitelist_textctrl, whitelist_listbox, whitelist_del_button )
                        local selection = whitelist_listbox:GetSelection()
                        if selection == -1 then
                            local result = dialog.info( "Error: No TAG selected" )
                            return
                        end
                        local folder = whitelist_listbox:GetString( selection )
                        if folder then tables[ "rules" ][ k ].whitelist[ folder ] = nil end
                        whitelist_listbox:Set( sorted_skip_tbl() )

                        if selection == whitelist_listbox:GetCount() then
                            selection = selection - 1
                        end
                        whitelist_listbox:SetSelection( selection )
                        whitelist_del_button:Enable( selection ~= -1 )

                        sb:SetStatusText( "Whitelist TAG '" .. folder .. "' was removed", 0 )
                        log_broadcast( log_window, "The following TAG was removed from Whitelist table: " .. folder, "CYAN" )
                    end

                    control = wx.wxStaticBox( di, wx.wxID_ANY, "", wx.wxPoint( 20, 78 ), wx.wxSize( 170, 215 ) )

                    --// init listbox add + del button
                    local whitelist_listbox = "whitelist_listbox_" .. str
                    local whitelist_add_button = "whitelist_add_button_" .. str
                    local whitelist_del_button = "whitelist_del_button_" .. str
                    
                    --// wxListBox
                    whitelist_listbox = wx.wxListBox(

                        di,
                        id_whitelist_listbox + i,
                        wx.wxPoint( 30, 93 ),
                        wx.wxSize( 150, 192 ),
                        sorted_skip_tbl(),
                        wx.wxLB_SINGLE + wx.wxLB_HSCROLL + wx.wxLB_SORT
                    )

                    --// Button - Add Folder
                    whitelist_add_button = wx.wxButton( di, id_whitelist_add_button + i, "add", wx.wxPoint( 20, 60 ), wx.wxSize( 169, 18 ) )
                    whitelist_add_button:Disable()
                    whitelist_add_button:Connect( wx.wxID_ANY, wx.wxEVT_ENTER_WINDOW, function( event ) sb:SetStatusText( "Add '" .. trim( whitelist_textctrl:GetValue() ) .. "' to Whitelist", 0 ) end )
                    whitelist_add_button:Connect( wx.wxID_ANY, wx.wxEVT_LEAVE_WINDOW, function( event ) sb:SetStatusText( "", 0 ) end )
                    whitelist_add_button:Connect( id_whitelist_add_button + i, wx.wxEVT_COMMAND_BUTTON_CLICKED,
                        function( event )
                            add_folder( whitelist_textctrl, whitelist_listbox, whitelist_del_button )
                            HandleChangeTab3( event )
                        end
                    )

                    --// Button - Delete Folder
                    whitelist_del_button = wx.wxButton( di, id_whitelist_del_button + i, "delete", wx.wxPoint( 20, 298 ), wx.wxSize( 169, 18 ) )
                    whitelist_del_button:Enable( whitelist_listbox:GetSelection() ~= -1 )
                    whitelist_del_button:Connect( wx.wxID_ANY, wx.wxEVT_ENTER_WINDOW, function( event ) sb:SetStatusText( "Remove selected '" .. whitelist_listbox:GetString( whitelist_listbox:GetSelection() ) .. "' from Whitelist", 0 ) end )
                    whitelist_del_button:Connect( wx.wxID_ANY, wx.wxEVT_LEAVE_WINDOW, function( event ) sb:SetStatusText( "", 0 ) end )
                    whitelist_del_button:Connect( id_whitelist_del_button + i, wx.wxEVT_COMMAND_BUTTON_CLICKED,
                        function( event )
                            del_folder( whitelist_textctrl, whitelist_listbox, whitelist_del_button )
                            HandleChangeTab3( event )
                        end
                    )
                    
                    --// wxTextCtrl - Events
                    whitelist_textctrl:Connect( id_whitelist_textctrl + i, wx.wxEVT_COMMAND_TEXT_UPDATED,
                        function( event )
                            local tag = trim( whitelist_textctrl:GetValue() ) or ""
                            local enabled = ( tag ~= "" )
                            if enabled then
                                if table.hasKey( tables[ "rules" ], tag, "whitelist" ) then
                                    sb:SetStatusText( "Whtielist TAG '" .. tag .. "' already taken", 0 )
                                    enabled = false
                                else
                                    sb:SetStatusText( "Whitelist TAG '" .. tag .. "' is unique", 0 )
                                end
                            else
                                sb:SetStatusText( "Choose a TAG name", 0 )
                            end
                            whitelist_add_button:Enable( enabled )
                        end
                    )
                    whitelist_textctrl:Connect( id_whitelist_textctrl + i, wx.wxEVT_COMMAND_TEXT_ENTER,
                        function(event)
                            whitelist_add_button:SetFocus()
                        end
                    )
                    
                    --// wxListBox - Events
                    whitelist_listbox:Connect( id_whitelist_listbox + i, wx.wxEVT_COMMAND_LISTBOX_SELECTED,
                        function( event )
                            whitelist_del_button:Enable( true )
                        end
                    )

                    di:ShowModal()
                end
            )

            -------------------------------------------------------------------------------------------------------------------------
            --// different checkboxes border
            control = wx.wxStaticBox( panel, wx.wxID_ANY, "Options", wx.wxPoint( 260, 91 ), wx.wxSize( 265, 218 ) )

            --// daydir scheme
            local checkbox_daydirscheme = "checkbox_daydirscheme_" .. str
            checkbox_daydirscheme = wx.wxCheckBox( panel, id_daydirscheme + i, "Use daydir scheme (mmdd)", wx.wxPoint( 270, 108 ), wx.wxDefaultSize )
            checkbox_daydirscheme:Connect( wx.wxID_ANY, wx.wxEVT_ENTER_WINDOW, function( event ) sb:SetStatusText( "To announce releases in daydirs", 0 ) end )
            checkbox_daydirscheme:Connect( wx.wxID_ANY, wx.wxEVT_LEAVE_WINDOW, function( event ) sb:SetStatusText( "", 0 ) end )
            if tables[ "rules" ][ k ].daydirscheme == true then checkbox_daydirscheme:SetValue( true ) else checkbox_daydirscheme:SetValue( false ) end

            --// daydir current day
            local checkbox_zeroday = "checkbox_zeroday_" .. str
            checkbox_zeroday = wx.wxCheckBox( panel, id_zeroday + i, "Check only current daydir", wx.wxPoint( 280, 128 ), wx.wxDefaultSize )
            checkbox_zeroday:Connect( wx.wxID_ANY, wx.wxEVT_ENTER_WINDOW, function( event ) sb:SetStatusText( "To announce only releases in daydirs from today", 0 ) end )
            checkbox_zeroday:Connect( wx.wxID_ANY, wx.wxEVT_LEAVE_WINDOW, function( event ) sb:SetStatusText( "", 0 ) end )
            if tables[ "rules" ][ k ].zeroday == true then checkbox_zeroday:SetValue( true ) else checkbox_zeroday:SetValue( false ) end
            if tables[ "rules" ][ k ].daydirscheme == true then checkbox_zeroday:Enable( true ) else checkbox_zeroday:Disable() end

            --// check dirs
            local checkbox_checkdirs = "checkbox_checkdirs_" .. str
            checkbox_checkdirs = wx.wxCheckBox( panel, id_checkdirs + i, "Announce Directories", wx.wxPoint( 270, 153 ), wx.wxDefaultSize )
            checkbox_checkdirs:Connect( wx.wxID_ANY, wx.wxEVT_ENTER_WINDOW, function( event ) sb:SetStatusText( "Announce directorys?", 0 ) end )
            checkbox_checkdirs:Connect( wx.wxID_ANY, wx.wxEVT_LEAVE_WINDOW, function( event ) sb:SetStatusText( "", 0 ) end )
            if tables[ "rules" ][ k ].checkdirs == true then checkbox_checkdirs:SetValue( true ) else checkbox_checkdirs:SetValue( false ) end

            --// check dirs nfo
            local checkbox_checkdirsnfo = "checkbox_checkdirsnfo_" .. str
            checkbox_checkdirsnfo = wx.wxCheckBox( panel, id_checkdirsnfo + i, "Only if it contains a NFO file", wx.wxPoint( 280, 173 ), wx.wxDefaultSize )
            checkbox_checkdirsnfo:Connect( wx.wxID_ANY, wx.wxEVT_ENTER_WINDOW, function( event ) sb:SetStatusText( "To announce only releases containing a NFO File", 0 ) end )
            checkbox_checkdirsnfo:Connect( wx.wxID_ANY, wx.wxEVT_LEAVE_WINDOW, function( event ) sb:SetStatusText( "", 0 ) end )
            if tables[ "rules" ][ k ].checkdirsnfo == true then checkbox_checkdirsnfo:SetValue( true ) else checkbox_checkdirsnfo:SetValue( false ) end
            if tables[ "rules" ][ k ].checkdirs == true then checkbox_checkdirsnfo:Enable( true ) else checkbox_checkdirsnfo:Disable() end

            --// check dirs sfv
            local checkbox_checkdirssfv = "checkbox_checkdirssfv_" .. str
            checkbox_checkdirssfv = wx.wxCheckBox( panel, id_checkdirssfv + i, "Only if it contains a validated SFV file", wx.wxPoint( 280, 195 ), wx.wxDefaultSize )
            checkbox_checkdirssfv:Connect( wx.wxID_ANY, wx.wxEVT_ENTER_WINDOW, function( event ) sb:SetStatusText( "To announce only releases containing a validated SFV File", 0 ) end )
            checkbox_checkdirssfv:Connect( wx.wxID_ANY, wx.wxEVT_LEAVE_WINDOW, function( event ) sb:SetStatusText( "", 0 ) end )
            if tables[ "rules" ][ k ].checkdirssfv == true then checkbox_checkdirssfv:SetValue( true ) else checkbox_checkdirssfv:SetValue( false ) end
            if tables[ "rules" ][ k ].checkdirs == true then checkbox_checkdirssfv:Enable( true ) else checkbox_checkdirssfv:Disable() end

            --// check files
            local checkbox_checkfiles = "checkbox_checkfiles_" .. str
            checkbox_checkfiles = wx.wxCheckBox( panel, id_checkfiles + i, "Announce Files", wx.wxPoint( 270, 221 ), wx.wxDefaultSize )
            checkbox_checkfiles:Connect( wx.wxID_ANY, wx.wxEVT_ENTER_WINDOW, function( event ) sb:SetStatusText( "Announce files?", 0 ) end )
            checkbox_checkfiles:Connect( wx.wxID_ANY, wx.wxEVT_LEAVE_WINDOW, function( event ) sb:SetStatusText( "", 0 ) end )
            if tables[ "rules" ][ k ].checkfiles == true then checkbox_checkfiles:SetValue( true ) else checkbox_checkfiles:SetValue( false ) end

            --// check whitespaces
            local checkbox_checkspaces = "checkbox_checkspaces_" .. str
            checkbox_checkspaces = wx.wxCheckBox( panel, id_checkspaces + i, "Disallow whitespaces", wx.wxPoint( 270, 241 ), wx.wxDefaultSize )
            checkbox_checkspaces:Connect( wx.wxID_ANY, wx.wxEVT_ENTER_WINDOW, function( event ) sb:SetStatusText( "Do not announce if the files/folders containing whitespaces", 0 ) end )
            checkbox_checkspaces:Connect( wx.wxID_ANY, wx.wxEVT_LEAVE_WINDOW, function( event ) sb:SetStatusText( "", 0 ) end )
            if tables[ "rules" ][ k ].checkspaces == true then checkbox_checkspaces:SetValue( true ) else checkbox_checkspaces:SetValue( false ) end

            --// check age
            local checkbox_checkage = "checkbox_checkage_" .. str
            checkbox_checkage = wx.wxCheckBox( panel, id_checkage + i, "Max age of dirs/files (days)", wx.wxPoint( 270, 261 ), wx.wxDefaultSize )
            checkbox_checkage:Connect( wx.wxID_ANY, wx.wxEVT_ENTER_WINDOW, function( event ) sb:SetStatusText( "Set a maximum age in days for the files/folders to announce", 0 ) end )
            checkbox_checkage:Connect( wx.wxID_ANY, wx.wxEVT_LEAVE_WINDOW, function( event ) sb:SetStatusText( "", 0 ) end )
            if tables[ "rules" ][ k ].checkage == true then
                checkbox_checkage:SetValue( true )
            else
                checkbox_checkage:SetValue( false )
            end

            --// maxage spin
            local spinctrl_maxage = "spin_maxage_" .. str
            spinctrl_maxage = wx.wxSpinCtrl( panel, id_maxage + i, "", wx.wxPoint( 280, 281 ), wx.wxSize( 100, 20 ) )
            spinctrl_maxage:Connect( wx.wxID_ANY, wx.wxEVT_ENTER_WINDOW, function( event ) sb:SetStatusText( "Set a maximum age in days for the files/folders to announce", 0 ) end )
            spinctrl_maxage:Connect( wx.wxID_ANY, wx.wxEVT_LEAVE_WINDOW, function( event ) sb:SetStatusText( "", 0 ) end )
            spinctrl_maxage:SetRange( 0, 999 )
            spinctrl_maxage:SetValue( tables[ "rules" ][ k ].maxage )
            spinctrl_maxage:Enable( tables[ "rules" ][ k ].checkage )

            --// events - rulename
            textctrl_rulename:Connect( id_rulename + i, wx.wxEVT_COMMAND_TEXT_UPDATED,
                function( event )
                    local rulename = trim( textctrl_rulename:GetValue() )
                    local id = treebook:GetSelection()

                    --// avoid to long rulename
                    local short_rulename = rulename
                    if string.len( rulename ) > 15 then
                        short_rulename = string.sub( rulename, 1, 15 ) .. ".."
                    end

                    if tables[ "rules" ][ id + 1 ].active == true then
                        treebook:SetPageText( id, "" .. id + 1 .. ": " .. short_rulename .. " (on)" )
                    else
                        treebook:SetPageText( id, "" .. id + 1 .. ": " .. short_rulename .. " (off)" )
                    end
                    if rulename == "" then
                        sb:SetStatusText( "Rulename, you can rename it if you like", 0 )
                    else
                        if table.hasValue( tables[ "rules" ], rulename, "rulename", k ) then
                            sb:SetStatusText( "Rule name '" .. rulename .. "' already taken", 0 )
                        else
                            sb:SetStatusText( "Rule name '" .. rulename .. "' is unique", 0 )
                        end
                    end
                    tables[ "rules" ][ k ].rulename = rulename
                    HandleChangeTab3( event )
                    rule_listview_fill( rules_listview )
                end
            )

            textctrl_rulename:Connect( id_rulename + i, wx.wxEVT_KILL_FOCUS,
                function( event )
                    local rulename = check_for_empty_and_reset_to_default( textctrl_rulename, "Rule #" .. k )
                    if table.hasValue( tables[ "rules" ], rulename, "rulename", k ) then
                        -- validate.rule_unique_name( false )
                    end
                end
            )

            --// events - command
            textctrl_command:Connect( id_command + i, wx.wxEVT_COMMAND_TEXT_UPDATED,
                function( event )
                    HandleChangeTab3( event )
                end
            )

            textctrl_command:Connect( id_command + i, wx.wxEVT_KILL_FOCUS,
                function( event )
                    check_for_whitespaces_textctrl( frame, textctrl_command )
                    local value = textctrl_command:GetValue()
                    tables[ "rules" ][ k ].command = value
                end
            )

            --// events - alibi nick
            checkbox_alibicheck:Connect( id_alibicheck + i, wx.wxEVT_COMMAND_CHECKBOX_CLICKED,
                function( event )
                    if checkbox_alibicheck:IsChecked() then
                        if tables[ "cfg" ]["freshstuff_version"] ~= true then
                            log_broadcast(
                                log_window,
                                {
                                    "Freshstuff Version",
                                    "Info: Needs ptx_freshstuff_v0.7 or higher"
                                }
                            )
                            save_cfg_freshstuff_value()
                        end
                        textctrl_alibinick:Enable( true )
                        textctrl_command:SetValue( "+announcerel" )
                        tables[ "rules" ][ k ].alibicheck = true
                        tables[ "rules" ][ k ].command = "+announcerel"
                        HandleChangeTab3( event )
                    else
                        textctrl_alibinick:Disable()
                        textctrl_command:SetValue( "+addrel" )
                        tables[ "rules" ][ k ].alibicheck = false
                        tables[ "rules" ][ k ].command = "+addrel"
                        HandleChangeTab3( event )
                    end
                end
            )

            textctrl_alibinick:Connect( id_alibinick + i, wx.wxEVT_COMMAND_TEXT_UPDATED,
                function( event )
                    HandleChangeTab3( event )
                end
            )

            textctrl_alibinick:Connect( id_alibinick + i, wx.wxEVT_KILL_FOCUS,
                function( event )
                    check_for_whitespaces_textctrl( frame, textctrl_alibinick )
                    local value = textctrl_alibinick:GetValue()
                    tables[ "rules" ][ k ].alibinick = value
                end
            )

            --// events - category choice
            choicectrl_category:Connect( id_category + i, wx.wxEVT_COMMAND_CHOICE_SELECTED,
                function( event )
                    if tables[ "rules" ][ k ].category ~= choicectrl_category:GetStringSelection() then
                        tables[ "rules" ][ k ].category = choicectrl_category:GetStringSelection()
                        HandleChangeTab3( event )
                        rule_listview_fill( rules_listview )
                        category_listview_fill( categories_listview )
                    end
                end
            )

            --// events - activate
            checkbox_activate:Connect( id_activate + i, wx.wxEVT_COMMAND_CHECKBOX_CLICKED,
                function( event )
                    if checkbox_activate:IsChecked() then
                        tables[ "rules" ][ k ].active = true
                        checkbox_activate:SetForegroundColour( wx.wxColour( 0, 128, 0 ) )
                    else
                        tables[ "rules" ][ k ].active = false
                        checkbox_activate:SetForegroundColour( wx.wxRED )
                    end
                    local id = treebook:GetSelection()

                    --// avoid to long rulename
                    local rulename = tables[ "rules" ][ id + 1 ].rulename
                    if string.len( rulename ) > 15 then
                        rulename = string.sub( rulename, 1, 15 ) .. ".."
                    end

                    if tables[ "rules" ][ id + 1 ].active == true then
                        treebook:SetPageText( id, "" .. id + 1 .. ": " .. rulename .. " (on)" )
                    else
                        treebook:SetPageText( id, "" .. id + 1 .. ": " .. rulename .. " (off)" )
                    end
                    HandleChangeTab3( event )
                    rule_listview_fill( rules_listview )
                end
            )

            --// events - daydir
            checkbox_daydirscheme:Connect( id_daydirscheme + i, wx.wxEVT_COMMAND_CHECKBOX_CLICKED,
                function( event )
                    if checkbox_daydirscheme:IsChecked() then
                        checkbox_zeroday:Enable( true )
                        tables[ "rules" ][ k ].daydirscheme = true
                    else
                        checkbox_zeroday:Disable()
                        tables[ "rules" ][ k ].daydirscheme = false
                    end
                    HandleChangeTab3( event )
                end
            )

            checkbox_zeroday:Connect( id_zeroday + i, wx.wxEVT_COMMAND_CHECKBOX_CLICKED,
                function( event )
                    if checkbox_zeroday:IsChecked() then
                        tables[ "rules" ][ k ].zeroday = true
                    else
                        tables[ "rules" ][ k ].zeroday = false
                    end
                    HandleChangeTab3( event )
                end
            )

            --// events - check dirs
            checkbox_checkdirs:Connect( id_checkdirs + i, wx.wxEVT_COMMAND_CHECKBOX_CLICKED,
                function( event )
                    if checkbox_checkdirs:IsChecked() then
                        checkbox_checkdirsnfo:Enable( true )
                        checkbox_checkdirssfv:Enable( true )
                        tables[ "rules" ][ k ].checkdirs = true
                    else
                        checkbox_checkdirsnfo:Disable()
                        checkbox_checkdirssfv:Disable()
                        tables[ "rules" ][ k ].checkdirs = false
                    end
                    HandleChangeTab3( event )
                end
            )

            --// events - check dirs nfo
            checkbox_checkdirsnfo:Connect( id_checkdirsnfo + i, wx.wxEVT_COMMAND_CHECKBOX_CLICKED,
                function( event )
                    if checkbox_checkdirsnfo:IsChecked() then
                        tables[ "rules" ][ k ].checkdirsnfo = true
                    else
                        tables[ "rules" ][ k ].checkdirsnfo = false
                    end
                    HandleChangeTab3( event )
                end
            )

            --// events - check dirs sfv
            checkbox_checkdirssfv:Connect( id_checkdirssfv + i, wx.wxEVT_COMMAND_CHECKBOX_CLICKED,
                function( event )
                    if checkbox_checkdirssfv:IsChecked() then
                        tables[ "rules" ][ k ].checkdirssfv = true
                    else
                        tables[ "rules" ][ k ].checkdirssfv = false
                    end
                    HandleChangeTab3( event )
                end
            )

            --// events - check files
            checkbox_checkfiles:Connect( id_checkfiles + i, wx.wxEVT_COMMAND_CHECKBOX_CLICKED,
                function( event )
                    if checkbox_checkfiles:IsChecked() then
                        tables[ "rules" ][ k ].checkfiles = true
                    else
                        tables[ "rules" ][ k ].checkfiles = false
                    end
                    HandleChangeTab3( event )
                end
            )

            --// events - check age
            checkbox_checkage:Connect( id_checkage + i, wx.wxEVT_COMMAND_CHECKBOX_CLICKED,
                function( event )
                    if checkbox_checkage:IsChecked() then
                        tables[ "rules" ][ k ].checkage = true
                        spinctrl_maxage:Enable( true )
                    else
                        tables[ "rules" ][ k ].checkage = false
                        spinctrl_maxage:SetValue( 0 )
                        tables[ "rules" ][ k ].maxage = 0
                        spinctrl_maxage:Disable()
                    end
                    HandleChangeTab3( event )
                end
            )

            --// events - maxage spin
            spinctrl_maxage:Connect( id_maxage + i, wx.wxEVT_COMMAND_TEXT_UPDATED,
                function( event )
                    tables[ "rules" ][ k ].maxage = spinctrl_maxage:GetValue()
                    HandleChangeTab3( event )
                end
            )

            --// events - check spaces
            checkbox_checkspaces:Connect( id_checkspaces + i, wx.wxEVT_COMMAND_CHECKBOX_CLICKED,
                function( event )
                    if checkbox_checkspaces:IsChecked() then
                        tables[ "rules" ][ k ].checkspaces = true
                    else
                        tables[ "rules" ][ k ].checkspaces = false
                    end
                    HandleChangeTab3( event )
                end
            )

            --// events - dirpicker
            dirpicker_path:Connect( id_dirpicker_path + i, wx.wxEVT_COMMAND_TEXT_UPDATED,
                function( event )
                    HandleChangeTab3( event )
                end
            )

            dirpicker_path:Connect( id_dirpicker_path + i, wx.wxEVT_KILL_FOCUS,
                function( event )
                    local path = trim( dirpicker_path:GetValue():gsub( "\\", "/" ) )
                    tables[ "rules" ][ k ].path = path
                    dirpicker:SetPath( path )
                end
            )

            dirpicker:Connect( id_dirpicker + i, wx.wxEVT_COMMAND_DIRPICKER_CHANGED,
                function( event )
                    local path = trim( dirpicker:GetPath():gsub( "\\", "/" ) )
                    dirpicker_path:SetValue( path )
                    log_broadcast( log_window, "Set announcing path to: '" .. path .. "'" )
                    tables[ "rules" ][ k ].path = path
                    dirpicker:SetPath( path )
                    HandleChangeTab3( event )
                end
            )

            i = i + 1
        end
    end
    set_rules_values()
    log_broadcast( log_window, "Import data from: '" .. files[ "tbl" ][ "rules" ] .. "'" )
end

-------------------------------------------------------------------------------------------------------------------------------------
--// Tab 4 //------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------

--// add new table entry to rules
local add_rule = function( rules_listview, treebook, t )
    if ( type(t) ~= "table" ) then
        t = {

            [ "active" ] = false,
            [ "alibicheck" ] = false,
            [ "alibinick" ] = "DUMP",
            [ "blacklist" ] = {
                [ "(incomplete)" ] = true,
                [ "(no-sfv)" ] = true,
                [ "(nuked)" ] = true,
            },
            [ "category" ] = "",
            [ "command" ] = "+addrel",
            [ "daydirscheme" ] = false,
            [ "path" ] = "C:/your/path/to/announce",
            [ "rulename" ] = "",
            [ "whitelist" ] = { },
            [ "zeroday" ] = false,
            [ "checkdirs" ] = true,
            [ "checkdirsnfo" ] = false,
            [ "checkdirssfv" ] = false,
            [ "checkfiles" ] = false,
            [ "checkspaces" ] = false,
            [ "checkage" ] = false,
            [ "maxage" ] = 0,

        }
    end

    local di = wx.wxDialog(
        frame,
        id_dialog_add_rule,
        "Enter rule name",
        wx.wxDefaultPosition,
        wx.wxSize( 290, 130 )
    )
    di:SetBackgroundColour( wx.wxColour( 255, 255, 255 ) )
    di:Centre( wx.wxBOTH )

    --// rulename text
    local dialog_rule_add_textctrl = wx.wxTextCtrl( di, id_textctrl_add_rule, "", wx.wxPoint( 25, 10 ), wx.wxSize( 230, 20 ), wx.wxSUNKEN_BORDER + wx.wxTE_CENTRE )
    dialog_rule_add_textctrl:Connect( wx.wxID_ANY, wx.wxEVT_ENTER_WINDOW, function( event ) sb:SetStatusText( "Choose a rule name", 0 ) end )
    dialog_rule_add_textctrl:Connect( wx.wxID_ANY, wx.wxEVT_LEAVE_WINDOW, function( event ) sb:SetStatusText( "", 0 ) end )
    dialog_rule_add_textctrl:SetBackgroundColour( wx.wxColour( 200, 200, 200 ) )
    dialog_rule_add_textctrl:SetMaxLength( 25 )

    --// category choice
    local dialog_rule_add_choicectrl = wx.wxChoice( di, id_choicectrl_add_rule, wx.wxPoint( 25, 40 ), wx.wxSize( 230, 20 ), list_categories_tbl() )
    dialog_rule_add_choicectrl:Connect( wx.wxID_ANY, wx.wxEVT_ENTER_WINDOW, function( event ) sb:SetStatusText( "Choose a category name", 0 ) end )
    dialog_rule_add_choicectrl:Connect( wx.wxID_ANY, wx.wxEVT_LEAVE_WINDOW, function( event ) sb:SetStatusText( "", 0 ) end )
    dialog_rule_add_choicectrl:Select( dialog_rule_add_choicectrl:FindString( t.category or "", true ) )

    --// add button
    local dialog_rule_add_button = wx.wxButton( di, id_button_add_rule, "OK", wx.wxPoint( 85, 70 ), wx.wxSize( 60, 20 ) )
    dialog_rule_add_button:Disable()
    dialog_rule_add_button:Connect( wx.wxID_ANY, wx.wxEVT_ENTER_WINDOW, function( event ) sb:SetStatusText( "Add '" .. trim( dialog_rule_add_textctrl:GetValue() ) .. "' to Rules", 0 ) end )
    dialog_rule_add_button:Connect( wx.wxID_ANY, wx.wxEVT_LEAVE_WINDOW, function( event ) sb:SetStatusText( "", 0 ) end )
    
    --// cancel button
    local dialog_rule_cancel_button = wx.wxButton( di, id_button_cancel_rule, "Cancel", wx.wxPoint( 145, 70 ), wx.wxSize( 60, 20 ) )

    --// add + cancel button clicked event
    dialog_rule_add_button:Connect( id_button_add_rule, wx.wxEVT_COMMAND_BUTTON_CLICKED,
        function( event )
            t.rulename = trim( dialog_rule_add_textctrl:GetValue() ) or ""
            t.category = dialog_rule_add_choicectrl:GetStringSelection()
            if t.rulename == "" then di:Destroy() end
            if table.hasValue( tables[ "rules" ], t.rulename, "rulename" ) then
                log_broadcast(
                    log_window,
                    {
                        validate.getTab( 4 ),
                        "Add Rule",
                        "Error: Rule name '" .. t.rulename .. "' already taken!"
                    }
                )
            else
                table.insert( tables[ "rules" ], t )
                local info = ""
                log_broadcast(
                    log_window,
                    {
                        validate.getTab( 4 ),
                        "Add Rule",
                        "Added: New Rule #" .. #tables[ "rules" ] .. ": '" .. t.rulename .. "'",
                        "Rules list was renumbered"
                    }
                )
                log_broadcast_header( log_window, "Save to file" )
                update_saved_rules_values( log_window, "insert", t )
                category_listview_fill( categories_listview )
                treebook:Destroy()
                make_treebook_page()
                log_broadcast_footer( log_window, "Save to file" )
                di:Destroy()
            end
        end
    )
    dialog_rule_cancel_button:Connect( id_button_cancel_rule, wx.wxEVT_COMMAND_BUTTON_CLICKED, function( event ) di:Destroy() end )

    --// events - dialog_rule_add_textctrl
    local dialog_rule_add_event = function( event, enabled )
        local rulename = trim( dialog_rule_add_textctrl:GetValue() )
        local categoryname = dialog_rule_add_choicectrl:GetSelection()
        if type( enabled ) == "nil" then
            enabled = ( rulename ~= "" and not table.hasValue( tables[ "rules" ], rulename, "rulename" ) and categoryname ~= -1 )
        end
        dialog_rule_add_button:Enable( enabled )
    end
    dialog_rule_add_textctrl:Connect( id_textctrl_add_rule, wx.wxEVT_COMMAND_TEXT_UPDATED,
        function( event )
            local rulename = trim( dialog_rule_add_textctrl:GetValue() ) or ""
            if table.hasValue( tables[ "rules" ], rulename, "rulename" ) then
                sb:SetStatusText( "Rule name '" .. rulename .. "' already taken", 0 )
                dialog_rule_add_event( event, false )
            else
                sb:SetStatusText( "Rule name '" .. rulename .. "' is unique", 0 )
                dialog_rule_add_event( event )
            end
            dialog_rule_add_textctrl:Connect( id_textctrl_add_rule, wx.wxEVT_COMMAND_TEXT_ENTER,
                function(event)
                    dialog_rule_add_choicectrl:SetFocus()
                end
            )
        end
    )
    dialog_rule_add_choicectrl:Connect( id_choicectrl_add_rule, wx.wxEVT_COMMAND_CHOICE_SELECTED, 
        function( event )
            dialog_rule_add_event( event)
            --[[--
            dialog_rule_add_choicectrl:Connect( id_choicectrl_add_rule, wx.wxEVT_COMMAND_TEXT_ENTER,
                function(event)
                    dialog_rule_add_button:SetFocus()
                end
            )
            --]]--
        end
    )

    local result = di:ShowModal()
end

--// remove table entry from rules
local del_rule = function( rules_listview, treebook )
    local nr, active, name, category = parse_rules_listview_selection( rules_listview )
    if nr == -1 then
        log_broadcast(
            log_window,
            {
                validate.getTab( 4 ),
                "Delete Rule",
                "Error: No rule selected!"
            }
        )
    elseif nr > rules_listview:GetItemCount() then
        log_broadcast(
            log_window,
            {
                validate.getTab( 4 ),
                "Delete Rule",
                "Error: Rule selection out of range!"
            }
        )
    elseif rules_listview:GetItemCount() == 1 then
        log_broadcast(
            log_window,
            {
                validate.getTab( 4 ),
                "Delete Rule",
                "Error: Last rule can not be deleted!"
            }
        )
    else
        log_broadcast(
            log_window,
            {
                validate.getTab( 4 ),
                "Delete Rule",
                "Deleted: Rule #" .. nr .. ": '" .. name .. "'",
                "Rules list was renumbered"
            }
        )
        table.remove( tables[ "rules" ], nr )
        log_broadcast_header( log_window, "Save to file" )
        update_saved_rules_values( log_window, "remove", nr )
        category_listview_fill( categories_listview )
        treebook:Destroy()
        make_treebook_page()
        log_broadcast_footer( log_window, "Save to file" )
    end
end

--// clone table entry from rules
local clone_rule = function( rules_listview, treebook )
    local nr, active, name, category = parse_rules_listview_selection( rules_listview )
    if nr == -1 then
        log_broadcast(
            log_window,
            {
                validate.getTab( 4 ),
                "Clone Rule", "Error: No rule selected!"
            }
        )
    else
        if table.hasKey( tables[ "rules" ], nr ) then
            add_rule( rules_listview, treebook, table.copy( tables[ "rules" ], nr ) )
        else
            log_broadcast(
                log_window,
                {
                    validate.getTab( 4 ),
                    "Clone Rule", "Error: Clone rule #'" .. nr .. "' failed!"
                }
            )
        end
    end
end

--// wxListCtrl
rules_listview = wx.wxListView( tab_4, id_rules_listview, wx.wxPoint( 5, 5 ), wx.wxSize( 778, 330 ), wx.wxLC_REPORT + wx.wxLC_SINGLE_SEL + wx.wxLC_HRULES + wx.wxLC_VRULES )

--// Button - Add Rule
rule_add_button = wx.wxButton( tab_4, id_rule_add, "Add", wx.wxPoint( 305, 338 ), wx.wxSize( 60, 20 ) )
rule_add_button:Connect( wx.wxID_ANY, wx.wxEVT_ENTER_WINDOW, function( event ) sb:SetStatusText( "Add a new rule", 0 ) end )
rule_add_button:Connect( wx.wxID_ANY, wx.wxEVT_LEAVE_WINDOW, function( event ) sb:SetStatusText( "", 0 ) end )
rule_add_button:Connect( id_rule_add, wx.wxEVT_COMMAND_BUTTON_CLICKED,
    function( event )
        add_rule( rules_listview, treebook )
    end
)

--// Button - Delete Rule
rule_del_button = wx.wxButton( tab_4, id_rule_del, "Delete", wx.wxPoint( 365, 338 ), wx.wxSize( 60, 20 ) )
rule_del_button:Connect( wx.wxID_ANY, wx.wxEVT_ENTER_WINDOW, function( event ) sb:SetStatusText( "Delete an existing rule", 0 ) end )
rule_del_button:Connect( wx.wxID_ANY, wx.wxEVT_LEAVE_WINDOW, function( event ) sb:SetStatusText( "", 0 ) end )
rule_del_button:Connect( id_rule_del, wx.wxEVT_COMMAND_BUTTON_CLICKED,
    function( event )
        del_rule( rules_listview, treebook )
    end
)

--// Button - Clone Rule
rule_clone_button = wx.wxButton( tab_4, id_rule_clone, "Clone", wx.wxPoint( 425, 338 ), wx.wxSize( 60, 20 ) )
rule_clone_button:Connect( wx.wxID_ANY, wx.wxEVT_ENTER_WINDOW, function( event ) sb:SetStatusText( "Clone an existing rule with all settings", 0 ) end )
rule_clone_button:Connect( wx.wxID_ANY, wx.wxEVT_LEAVE_WINDOW, function( event ) sb:SetStatusText( "", 0 ) end )
rule_clone_button:Connect( id_rule_clone, wx.wxEVT_COMMAND_BUTTON_CLICKED,
    function( event )
        clone_rule( rules_listview, treebook )
    end
)

--// helper wxListView
rule_listview_create = function( listCtrl )
    rules_arr, rules_key = table.getRules()
    listCtrl:InsertColumn( 0, rules_key[ 1 ], wx.wxLIST_FORMAT_RIGHT, -1 )
    listCtrl:InsertColumn( 1, rules_key[ 2 ], wx.wxLIST_FORMAT_LEFT, -1 )
    listCtrl:InsertColumn( 2, rules_key[ 3 ], wx.wxLIST_FORMAT_LEFT, -1 )
    listCtrl:InsertColumn( 3, rules_key[ 4 ], wx.wxLIST_FORMAT_LEFT, -1 )

    listCtrl:SetColumnWidth( 0, wx.wxLIST_AUTOSIZE_USEHEADER )
    listCtrl:SetColumnWidth( 1, wx.wxLIST_AUTOSIZE_USEHEADER )
    listCtrl:SetColumnWidth( 2, wx.wxLIST_AUTOSIZE_USEHEADER )
    listCtrl:SetColumnWidth( 3, wx.wxLIST_AUTOSIZE_USEHEADER )
    
    rule_listview_fill( rules_listview, rules_arr )
end
rule_listitem_add = function( listCtrl, colTable )
    local lc_item = listCtrl:GetItemCount()
    lc_item = listCtrl:InsertItem( lc_item, tostring( colTable[ 1 ] ) )
    listCtrl:SetItem( lc_item, 1, tostring( colTable[ 2 ] ) )
    listCtrl:SetItem( lc_item, 2, tostring( colTable[ 3 ] ) )
    listCtrl:SetItem( lc_item, 3, tostring( colTable[ 4 ] ) )
    return lc_item
end
rule_listview_fill = function( listCtrl, colTable )
    rule_del_button:Disable()
    rule_clone_button:Disable()
    listCtrl:DeleteAllItems()
    for k, v in pairs( colTable or table.getRules() ) do
        rule_listitem_add( listCtrl, { v[ 1 ], v[ 2 ], v[ 3 ], v[ 4 ] } )
    end
    listCtrl:SetColumnWidth( 0, wx.wxLIST_AUTOSIZE_USEHEADER )
    listCtrl:SetColumnWidth( 1, wx.wxLIST_AUTOSIZE_USEHEADER )
    listCtrl:SetColumnWidth( 2, wx.wxLIST_AUTOSIZE_USEHEADER )
    listCtrl:SetColumnWidth( 3, wx.wxLIST_AUTOSIZE_USEHEADER )
end

rules_listview:Connect( id_rules_listview, wx.wxEVT_COMMAND_LIST_ITEM_SELECTED,
    function( event )
        if #tables[ "rules" ] > 1 then
            rule_del_button:Enable( true )
        end
        rule_clone_button:Enable( true )
    end
)
rules_listview:Connect( id_rules_listview, wx.wxEVT_COMMAND_LIST_ITEM_DESELECTED,
    function( event )
        rule_del_button:Disable()
        rule_clone_button:Disable()
    end
)
rules_listview:Connect( id_rules_listview, wx.wxEVT_COMMAND_LIST_COL_BEGIN_DRAG,
    function( event )
        event:Veto()
    end
)

rule_listview_create( rules_listview )

-------------------------------------------------------------------------------------------------------------------------------------
--// Tab 5 //------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------

--// import categories from "cfg/rules.lua" to "cfg/categories.lua"
local import_categories_tbl = function()
    if type( tables[ "categories" ] ) == "nil" then
        tables[ "categories" ] = { }
    end
    local affected = { }
    for k, v in spairs( tables[ "rules" ], "asc", "category" ) do
        if table.hasValue( tables[ "categories" ], tables[ "rules" ][ k ].category, "categoryname" ) == false then
            if tables[ "rules" ][ k ].category ~= "" then
                table.insert( tables[ "categories" ], { categoryname = tables[ "rules" ][ k ].category } )
                table.insert( affected, "Added: New Category #" .. #tables[ "categories" ] .. ": '" .. tables[ "rules" ][ k ].category .. "'" )
            end
        end
    end
    if #affected > 0 then
        table.insert( affected, 1, "Initial Categories Import" )
        table.insert( affected, 2, "Import new categories from: '" .. files[ "tbl" ][ "rules" ] .. "'" )
        log_broadcast( log_window, affected )
        save_categories_values( log_window )
        category_listview_fill( categories_listview )
    end
end

--// add new table entry to categories
local add_category = function( categories_listview )
    local di = wx.wxDialog(
        frame,
        id_dialog_add_category,
        "Enter category name",
        wx.wxDefaultPosition,
        wx.wxSize( 290, 90 )
    )
    di:SetBackgroundColour( wx.wxColour( 255, 255, 255 ) )

    --// categoryname text
    local dialog_category_add_textctrl = wx.wxTextCtrl( di, id_textctrl_add_category, "", wx.wxPoint( 25, 10 ), wx.wxSize( 230, 20 ), wx.wxSUNKEN_BORDER + wx.wxTE_CENTRE )
    dialog_category_add_textctrl:Connect( wx.wxID_ANY, wx.wxEVT_ENTER_WINDOW, function( event ) sb:SetStatusText( "Choose a category name", 0 ) end )
    dialog_category_add_textctrl:Connect( wx.wxID_ANY, wx.wxEVT_LEAVE_WINDOW, function( event ) sb:SetStatusText( "", 0 ) end )
    dialog_category_add_textctrl:SetBackgroundColour( wx.wxColour( 200, 200, 200 ) )
    dialog_category_add_textctrl:SetMaxLength( 25 )

    --// add button
    local dialog_category_add_button = wx.wxButton( di, id_button_add_category, "OK", wx.wxPoint( 85, 36 ), wx.wxSize( 60, 20 ) )
    dialog_category_add_button:Disable()
    dialog_category_add_button:Connect( wx.wxID_ANY, wx.wxEVT_ENTER_WINDOW, function( event ) sb:SetStatusText( "Add '" .. trim( dialog_category_add_textctrl:GetValue() ) .. "' to Categories", 0 ) end )
    dialog_category_add_button:Connect( wx.wxID_ANY, wx.wxEVT_LEAVE_WINDOW, function( event ) sb:SetStatusText( "", 0 ) end )

    --// cancel button
    local dialog_category_cancel_button = wx.wxButton( di, id_button_cancel_category, "Cancel", wx.wxPoint( 145, 36 ), wx.wxSize( 60, 20 ) )
    dialog_category_cancel_button:Connect( id_button_cancel_category, wx.wxEVT_COMMAND_BUTTON_CLICKED,  function( event ) di:Destroy() end )

    --// add + cancel button event
    dialog_category_add_button:Connect( id_button_add_category, wx.wxEVT_COMMAND_BUTTON_CLICKED,
        function( event )
            check_for_whitespaces_textctrl( frame, dialog_category_add_textctrl )
            local categoryname = trim( dialog_category_add_textctrl:GetValue() ) or ""
            if categoryname == "" then di:Destroy() end
            if table.hasValue( tables[ "categories" ], categoryname, "categoryname" ) then
                log_broadcast(
                    log_window,
                    {
                        validate.getTab( 5 ),
                        "Add Category", "Error: Category name '" .. categoryname .. "' already taken!"
                    }
                )
            else
                table.insert( tables[ "categories" ], { } )
                tables[ "categories" ][ #tables[ "categories" ] ].categoryname = categoryname
                category_listview_fill( categories_listview )
                log_broadcast(
                    log_window,
                    {
                        validate.getTab( 5 ),
                        "Add Category",
                        "Added: New Category #" .. #tables[ "categories" ] .. ": '" .. tables[ "categories" ][ #tables[ "categories" ] ].categoryname .. "'",
                        "Categories list was renumbered"
                    }
                )
                log_broadcast_header( log_window, "Save to file" )
                save_categories_values( log_window )
                treebook:Destroy()
                make_treebook_page()
                log_broadcast_footer( log_window, "Save to file" )
                di:Destroy()
            end
        end
    )

    --// categoryname text event
    dialog_category_add_textctrl:Connect( id_textctrl_add_category, wx.wxEVT_COMMAND_TEXT_UPDATED,
        function( event )
            local categoryname = trim( dialog_category_add_textctrl:GetValue() ) or ""
            local enabled = ( categoryname ~= "" )
            if enabled then
                if table.hasValue( tables[ "categories" ], categoryname, "categoryname" ) then
                    sb:SetStatusText( "Category name '" .. categoryname .. "' already taken", 0 )
                    enabled = false
                else
                    sb:SetStatusText( "Category name '" .. categoryname .. "' is unique", 0 )
                end
            else
                sb:SetStatusText( "Enter category name", 0 )
            end
            dialog_category_add_button:Enable( enabled )
        end
    )
    dialog_category_add_textctrl:Connect( id_textctrl_add_category, wx.wxEVT_COMMAND_TEXT_ENTER,
        function(event)
            dialog_category_add_button:SetFocus()
        end
    )
    local result = di:ShowModal()
end

--// remove table entry from categories
local del_category = function( categories_listview )
    local nr, cnt, name = parse_categories_listview_selection( categories_listview )
    if nr == -1 then
        log_broadcast(
            log_window,
            {
                validate.getTab( 5 ),
                "Delete Category",
                "Error: No category selected!"
            }
        )
    elseif nr > categories_listview:GetItemCount() then
        log_broadcast(
            log_window,
            {
                validate.getTab( 5 ),
                "Delete Category",
                "Error: Category selection out of range!"
            }
        )
    else
        if not cnt == "" then
            log_broadcast(
                log_window,
                {
                    validate.getTab( 5 ),
                    "Delete Category",
                    "Error: Selected category '" .. name .. "' is in use!"
                }
            )
        else
            table.remove( tables[ "categories" ], nr )
            log_broadcast(
                log_window,
                {
                    validate.getTab( 5 ),
                    "Delete Category",
                    "Deleted: Category #" .. nr .. ": '" .. name .. "'",
                    "Categories list was renumbered"
                }
            )
            log_broadcast_header( log_window, "Save to file" )
            save_categories_values( log_window )            
            rule_listview_fill( rules_listview )
            category_listview_fill( categories_listview )
            treebook:Destroy()
            make_treebook_page()
            log_broadcast_footer( log_window, "Save to file" )
        end
    end
end

--// import table entries from categories.tbl
local imp_category = function( categories_listview )
    local categories_fresh, categories_err = {}
    local di = wx.wxDialog(
        frame,
        id_dialog_add_category,
        "Import categories from a 'freshstuff.tbl' file",
        wx.wxDefaultPosition,
        wx.wxSize( 290, 140 )
    )
    di:SetBackgroundColour( wx.wxColour( 255, 255, 255 ) )

    --// categoryname text
    local filepicker_file = "filepicker_file"
    filepicker_file = wx.wxTextCtrl( di, id_filepicker_file, "", wx.wxPoint( 25, 10 ), wx.wxSize( 230, 20 ), wx.wxTE_PROCESS_ENTER + wx.wxSUNKEN_BORDER )
    filepicker_file:SetBackgroundColour( wx.wxColour( 200, 200, 200 ) )
    filepicker_file:Connect( wx.wxID_ANY, wx.wxEVT_ENTER_WINDOW, function( event ) sb:SetStatusText( "Set freshstuff '*.dat' file to import", 0 ) end )
    filepicker_file:Connect( wx.wxID_ANY, wx.wxEVT_LEAVE_WINDOW, function( event ) sb:SetStatusText( "", 0 ) end )

    local filepicker = "filepicker"
    filepicker = wx.wxFilePickerCtrl( di, id_filepicker, "", "Choose a '*.dat' file to import:", "*.dat", wx.wxPoint( 105, 40 ), wx.wxSize( 80, 22 ), wx.wxFLP_FILE_MUST_EXIST )

    local dialog_category_add_button = wx.wxButton( di, id_button_add_category, "Import", wx.wxPoint( 85, 70 ), wx.wxSize( 60, 20 ) )
    dialog_category_add_button:Disable()
    local dialog_category_cancel_button = wx.wxButton( di, id_button_cancel_category, "Cancel", wx.wxPoint( 145, 70 ), wx.wxSize( 60, 20 ) )
    dialog_category_cancel_button:Connect( id_button_cancel_category, wx.wxEVT_COMMAND_BUTTON_CLICKED,  function( event ) di:Destroy() end )

    --// filepicker_file + filepicker events
    local dialog_category_validate_event = function( file )
        file = file or filepicker_file:GetValue()
        categories_fresh, categories_err = util.loadtable( file )
        local valid = type( categories_fresh ) == "table"
        if valid then
            for id, name in pairs( categories_fresh ) do
                if type( name ) ~= "string" or name == "" or name ~= id then
                    valid = false
                    sb:SetStatusText( "It's not a valid freshstuff file: '" .. file .. "'", 0 )
                end
            end
        end
        if valid then
            sb:SetStatusText( "It's a valid freshstuff file: '" .. file .. "'", 0 )
        end
        dialog_category_add_button:Enable( valid )
        return valid,  file
    end
    filepicker_file:Connect( id_filepicker_file , wx.wxEVT_COMMAND_TEXT_UPDATED, 
        function( event )
            local valid, file = dialog_category_validate_event()
            if valid then
                filepicker:SetPath( file )
            end
        end
    )
    filepicker:Connect( id_filepicker, wx.wxEVT_COMMAND_FILEPICKER_CHANGED,
        function( event )
            local valid, file = dialog_category_validate_event( filepicker:GetPath() )
            filepicker_file:SetValue( file:gsub( "\\", "/" ) )
        end
    )
    dialog_category_validate_event()

    --// add + cancel button event
    dialog_category_add_button:Connect( id_button_add_category, wx.wxEVT_COMMAND_BUTTON_CLICKED,
        function( event )
            local valid, file = dialog_category_validate_event( filepicker_file:GetValue() )
            if not valid then
                log_broadcast(
                    log_window,
                    {
                        "Manual Categories Import",
                        "Error: Parsed file " .. file .. " is not a valid freshstuff table!"
                    }
                )
                return
            end

            categories_fresh, categories_err = util.loadtable( file )
            local affected = { }
            for id, name in pairs( categories_fresh ) do
                if table.hasValue( tables[ "categories" ], name, "categoryname" ) == false then
                    table.insert( tables[ "categories" ], { categoryname = name } )
                    table.insert( affected, "Added: New Category #" .. #tables[ "categories" ] .. ": '" .. name .. "'" )
                end
            end
            if #affected > 0 then
                save_categories_values( log_window )
                rule_listview_fill( rules_listview )
                category_listview_fill( categories_listview )
                treebook:Destroy()
                make_treebook_page()
                table.insert( affected, 1, "Manual Categories Import" )
                table.insert( affected, 2, "Import data from: '" .. file .. "'" )
                table.insert( affected,    "Saved data to: '" .. files[ "tbl" ][ "categories" ] .. "'" )
                log_broadcast( log_window, affected )
            else
                log_broadcast(
                    log_window,
                    {
                        "Manual Categories Import",
                        "Error: No Category to add!"
                    }
                )
            end
            sb:SetStatusText( "", 0 )
            di:Destroy()
        end
    )
    local result = di:ShowModal()
end

--// export table entries to categories.tbl
local exp_category = function( categories_listview )
    local di = wx.wxDialog(
        frame,
        id_dialog_add_category,
        "Export categories to a 'freshstuff.tbl' file",
        wx.wxDefaultPosition,
        wx.wxSize( 290, 140 )
    )
    di:SetBackgroundColour( wx.wxColour( 255, 255, 255 ) )

    --// categoryname text
    local filepicker_file = "filepicker_file"
    filepicker_file = wx.wxTextCtrl( di, id_filepicker_file, "", wx.wxPoint( 25, 10 ), wx.wxSize( 230, 20 ), wx.wxTE_PROCESS_ENTER + wx.wxSUNKEN_BORDER )
    filepicker_file:SetBackgroundColour( wx.wxColour( 200, 200, 200 ) )
    filepicker_file:SetValue( lfs.currentdir():gsub( "\\", "/" ) .. "/" .. files[ "tbl" ][ "freshstuff" ] )
    filepicker_file:Connect( wx.wxID_ANY, wx.wxEVT_ENTER_WINDOW, function( event ) sb:SetStatusText( "Set freshstuff '*.dat' file to export", 0 ) end )
    filepicker_file:Connect( wx.wxID_ANY, wx.wxEVT_LEAVE_WINDOW, function( event ) sb:SetStatusText( "", 0 ) end )

    local filepicker = "filepicker"
    filepicker = wx.wxFilePickerCtrl( di, id_filepicker, "", "Choose a '*.dat' file to export:", "*.dat", wx.wxPoint( 105, 40 ), wx.wxSize( 80, 22 ), wx.wxFLP_SAVE )
    local dialog_category_add_button = wx.wxButton( di, id_button_add_category, "Export", wx.wxPoint( 85, 70 ), wx.wxSize( 60, 20 ) )
    dialog_category_add_button:Disable()
    local dialog_category_cancel_button = wx.wxButton( di, id_button_cancel_category, "Cancel", wx.wxPoint( 145, 70 ), wx.wxSize( 60, 20 ) )
    dialog_category_cancel_button:Connect( id_button_cancel_category, wx.wxEVT_COMMAND_BUTTON_CLICKED,  function( event ) di:Destroy() end )

    --// filepicker_file + filepicker events
    local dialog_category_validate_event = function( file )
        file = file or filepicker_file:GetValue()
        local valid = true
        dialog_category_add_button:Enable( valid )
        return valid,  file
    end
    filepicker_file:Connect( id_filepicker_file , wx.wxEVT_COMMAND_TEXT_UPDATED, 
        function( event )
            local valid, file = dialog_category_validate_event()
            if valid then
                filepicker:SetPath( file )
            end
        end
    )
    filepicker:Connect( id_filepicker, wx.wxEVT_COMMAND_FILEPICKER_CHANGED,
        function( event )
            local valid, file = dialog_category_validate_event( filepicker:GetPath() )
            filepicker_file:SetValue( file:gsub( "\\", "/" ) )
        end
    )
    dialog_category_validate_event()

    --// add + cancel button event
    dialog_category_add_button:Connect( id_button_add_category, wx.wxEVT_COMMAND_BUTTON_CLICKED,
        function( event )
            local valid, file = dialog_category_validate_event( filepicker_file:GetValue() )
            if not valid then
                log_broadcast(
                    log_window,
                    {
                        "Export Categories",
                        "Error: Parsed file " .. file .. " is not a valid freshstuff table!"
                    }
                )
                return
            end

            local exp = { }
            for k, v in pairs( table.getCategories() ) do
                exp[ v[ 3 ] ] = v[ 3 ]
            end
            util.savetable( exp, "", file )
            
            log_broadcast(
                log_window,
                {
                    "Export Categories",
                    "Saved data to: '" .. file .. "'"
                }
            )
            di:Destroy()
        end
    )
    local result = di:ShowModal()
end

--// wxListCtrl
categories_listview = wx.wxListView( tab_5, id_categories_listview, wx.wxPoint( 5, 5 ), wx.wxSize( 778, 330 ), wx.wxLC_REPORT + wx.wxLC_SINGLE_SEL + wx.wxLC_HRULES + wx.wxLC_VRULES )

category_add_button = wx.wxButton( tab_5, id_category_add, "Add", wx.wxPoint( 277, 338 ), wx.wxSize( 60, 20 ) )
category_add_button:Connect( wx.wxID_ANY, wx.wxEVT_ENTER_WINDOW, function( event ) sb:SetStatusText( "Add a new Freshstuff category", 0 ) end )
category_add_button:Connect( wx.wxID_ANY, wx.wxEVT_LEAVE_WINDOW, function( event ) sb:SetStatusText( "", 0 ) end )
category_add_button:Connect( id_category_add, wx.wxEVT_COMMAND_BUTTON_CLICKED,
    function( event )
        add_category( categories_listview )
    end
)

--// Button - Delete category
category_del_button = wx.wxButton( tab_5, id_category_del, "Delete", wx.wxPoint( 337, 338 ), wx.wxSize( 60, 20 ) )
category_del_button:Connect( wx.wxID_ANY, wx.wxEVT_ENTER_WINDOW, function( event ) sb:SetStatusText( "Delete an existing category", 0 ) end )
category_del_button:Connect( wx.wxID_ANY, wx.wxEVT_LEAVE_WINDOW, function( event ) sb:SetStatusText( "", 0 ) end )
category_del_button:Connect( id_category_del, wx.wxEVT_COMMAND_BUTTON_CLICKED,
    function( event )
        del_category( categories_listview )
    end
)

--// Button - Import freshstuff categories
category_imp_button = wx.wxButton( tab_5, id_category_imp, "Import", wx.wxPoint( 397, 338 ), wx.wxSize( 60, 20 ) )
category_imp_button:Connect( wx.wxID_ANY, wx.wxEVT_ENTER_WINDOW, function( event ) sb:SetStatusText( "Import categories from 'freshstuff.tbl' file", 0 ) end )
category_imp_button:Connect( wx.wxID_ANY, wx.wxEVT_LEAVE_WINDOW, function( event ) sb:SetStatusText( "", 0 ) end )
category_imp_button:Connect( id_category_imp, wx.wxEVT_COMMAND_BUTTON_CLICKED,
    function( event )
        imp_category( categories_listview )
    end
)

--// Button - Export freshstuff categories
category_exp_button = wx.wxButton( tab_5, id_category_exp, "Export", wx.wxPoint( 457, 338 ), wx.wxSize( 60, 20 ) )
category_exp_button:Connect( wx.wxID_ANY, wx.wxEVT_ENTER_WINDOW, function( event ) sb:SetStatusText( "Export categories to 'freshstuff.tbl' file", 0 ) end )
category_exp_button:Connect( wx.wxID_ANY, wx.wxEVT_LEAVE_WINDOW, function( event ) sb:SetStatusText( "", 0 ) end )
category_exp_button:Connect( id_category_exp, wx.wxEVT_COMMAND_BUTTON_CLICKED,
    function( event )
        exp_category( categories_listview )
    end
)

--// helper wxListView
category_listview_create = function( listCtrl )
    categories_arr, categories_key = table.getCategories()
    listCtrl:InsertColumn( 0, categories_key[ 1 ], wx.wxLIST_FORMAT_RIGHT, -1 )
    listCtrl:InsertColumn( 1, categories_key[ 2 ], wx.wxLIST_FORMAT_RIGHT, -1 )
    listCtrl:InsertColumn( 2, categories_key[ 3 ], wx.wxLIST_FORMAT_LEFT, -1 )

    listCtrl:SetColumnWidth( 0, wx.wxLIST_AUTOSIZE_USEHEADER )
    listCtrl:SetColumnWidth( 1, wx.wxLIST_AUTOSIZE_USEHEADER )
    listCtrl:SetColumnWidth( 2, wx.wxLIST_AUTOSIZE_USEHEADER )
    
    category_listview_fill( categories_listview, categories_arr )
end
category_listitem_add = function( listCtrl, colTable )
    local lc_item = listCtrl:GetItemCount()
    lc_item = listCtrl:InsertItem( lc_item, tostring( colTable[ 1 ] ) )
    listCtrl:SetItem( lc_item, 1, tostring( colTable[ 2 ] ) )
    listCtrl:SetItem( lc_item, 2, tostring( colTable[ 3 ] ) )
    return lc_item
end
category_listview_fill = function( listCtrl, colTable )
    category_del_button:Disable()
    listCtrl:DeleteAllItems()
    for k, v in pairs( colTable or table.getCategories() ) do
        category_listitem_add( listCtrl, { v[ 1 ], v[ 2 ], v[ 3 ] } )
    end
    listCtrl:SetColumnWidth( 2, wx.wxLIST_AUTOSIZE_USEHEADER )
end

categories_listview:Connect( id_categories_listview, wx.wxEVT_COMMAND_LIST_ITEM_SELECTED,
    function( event )
        local nr, cnt, name = parse_categories_listview_selection( categories_listview )
        if cnt == "" then
            category_del_button:Enable( true )
        end
    end
)
categories_listview:Connect( id_categories_listview, wx.wxEVT_COMMAND_LIST_ITEM_DESELECTED,
    function( event )
        category_del_button:Disable()
    end
)
categories_listview:Connect( id_categories_listview, wx.wxEVT_COMMAND_LIST_COL_BEGIN_DRAG,
    function( event )
        event:Veto()
    end
)

category_listview_create( categories_listview )

-------------------------------------------------------------------------------------------------------------------------------------
--// Tab 6 //------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------

--// logfile window
local logfile_window = wx.wxTextCtrl(
    tab_6,
    wx.wxID_ANY,
    "",
    wx.wxPoint( 5, 5 ),
    wx.wxSize( 778, 260 ),
    wx.wxTE_READONLY + wx.wxTE_MULTILINE + wx.wxTE_RICH + wx.wxSUNKEN_BORDER + wx.wxHSCROLL
)
logfile_window:SetBackgroundColour( wx.wxColour( 255, 255, 255 ) )
logfile_window:SetFont( log_font )

--// check if file exists, if not then create new one
local check_file = function( file )
    local path = wx.wxGetCwd() .. "\\"
    local mode, err = lfs.attributes( path .. file, "mode" )
    if mode ~= "file" then
        local f, err = io.open( file, "w" )
        assert( f, "Fail: " .. tostring( err ) )
        f:close()
        return false
    else
        return true
    end
end

--// file handler
local log_handler_last
local log_handler = function( file, parent, mode, button, count )
    local path = wx.wxGetCwd() .. "\\"
    local str
    if mode == "read" then
        if check_file( file ) then
            button:Disable()
            log_broadcast( log_window, "Reading text from: '" .. file .. "'" )

            parent:LoadFile( path .. file )
            if parent:GetValue() == "" then
                str = "Logfile is Empty"
                parent:WriteText( "\n\n\n\n\n\n\n\n\n" .. repeats( " ", ( 110 - str:len() ) / 2 ) .. str )
            else
                if ( count == "rows" or count == "both" ) then parent:AppendText( "\n\nAmount of releases: " .. parent:GetNumberOfLines() - 1 ) end
                if ( count == "size" or count == "both" ) then parent:AppendText( "\n\nSize of logfile: " .. util.formatbytes( wx.wxFileSize( path .. file ) or 0 ) ) end
            end
            local al = parent:GetNumberOfLines()
            parent:ScrollLines( al + 1 )
            button:Enable( true )
        else
            parent:Clear()
            str = "Error while reading text from: '" .. file .. "', file not found, created new one."
            parent:WriteText( "\n\n\n\n\n\n\n\n\n" .. repeats( " ", ( 110 - str:len() ) / 2 ) .. str )
            log_broadcast( log_window, "Info: Error while reading text from: '" .. file .. "', file not found, created new one." )
        end
    end
    if mode == "clean" then
        if check_file( file ) then
            local f = io.open( file, "w" )
            f:close()
            parent:Clear()
            str = "Cleaning file: '" .. file .. "'"
            parent:WriteText( "\n\n\n\n\n\n\n\n\n" .. repeats( " ", ( 110 - str:len() ) / 2 ) .. str )
            log_broadcast( log_window, "Cleaning file: '" .. file .. "'" )
        else
            parent:Clear()
            str = "Error while cleaning text from: '" .. file .. "', file not found, created new one."
            parent:WriteText( "\n\n\n\n\n\n\n\n\n" ..repeats( " ", ( 110 - str:len() ) / 2 ) .. str )
            log_broadcast( log_window, "Info: Error while cleaning text from: '" .. file .. "', file not found, created new one." )
        end
    end
    log_handler_last = { [ "file" ] = file, [ "path" ] = path, [ "time" ] = lfs.attributes( path .. file ).modification } 
end

--// border - logfile.txt
control = wx.wxStaticBox( tab_6, wx.wxID_ANY, "logfile.txt", wx.wxPoint( 132, 278 ), wx.wxSize( 161, 40 ) )

--// button - logfile load
local button_load_logfile = wx.wxButton( tab_6, id_button_load_logfile, "Load", wx.wxPoint( 140, 294 ), wx.wxSize( 70, 20 ) )
button_load_logfile:Connect( wx.wxID_ANY, wx.wxEVT_ENTER_WINDOW, function( event ) sb:SetStatusText( "Load 'logfile.txt'", 0 ) end )
button_load_logfile:Connect( wx.wxID_ANY, wx.wxEVT_LEAVE_WINDOW, function( event ) sb:SetStatusText( "", 0 ) end )
button_load_logfile:Connect( id_button_load_logfile, wx.wxEVT_COMMAND_BUTTON_CLICKED,
function( event )
    log_handler( files[ "log" ][ "logfile" ], logfile_window, "read", button_load_logfile, "size" )
    set_logfilesize( control_logsize_log_sensor, control_logsize_ann_sensor, control_logsize_exc_sensor )
end )

--// button - logfile clear
local button_clear_logfile = wx.wxButton( tab_6, id_button_clear_logfile, "Clear", wx.wxPoint( 215, 294 ), wx.wxSize( 70, 20 ) )
button_clear_logfile:Connect( wx.wxID_ANY, wx.wxEVT_ENTER_WINDOW, function( event ) sb:SetStatusText( "Clear 'logfile.txt'", 0 ) end )
button_clear_logfile:Connect( wx.wxID_ANY, wx.wxEVT_LEAVE_WINDOW, function( event ) sb:SetStatusText( "", 0 ) end )
button_clear_logfile:Connect( id_button_clear_logfile, wx.wxEVT_COMMAND_BUTTON_CLICKED,
function( event )
    log_handler( files[ "log" ][ "logfile" ], logfile_window, "clean", button_clear_logfile )
    set_logfilesize( control_logsize_log_sensor, control_logsize_ann_sensor, control_logsize_exc_sensor )
end )

--// border - logfile size - logfile.txt
control = wx.wxStaticBox( tab_6, wx.wxID_ANY, "Filesize", wx.wxPoint( 132, 321 ), wx.wxSize( 161, 37 ) )

--// gauge - logfile.txt
control_logsize_log_sensor = wx.wxGauge( tab_6, wx.wxID_ANY, defaults[ "logfilesizemax" ], wx.wxPoint( 140, 337 ), wx.wxSize( 145, 16 ), wx.wxGA_HORIZONTAL )
control_logsize_log_sensor:SetRange( tables[ "cfg" ][ "logfilesize" ] )

--// border - announced.txt
control = wx.wxStaticBox( tab_6, wx.wxID_ANY, "announced.txt", wx.wxPoint( 312, 278 ), wx.wxSize( 161, 40 ) )

--// button - announced load
local button_load_announced = wx.wxButton( tab_6, id_button_load_announced, "Load", wx.wxPoint( 320, 294 ), wx.wxSize( 70, 20 ) )
button_load_announced:Connect( wx.wxID_ANY, wx.wxEVT_ENTER_WINDOW, function( event ) sb:SetStatusText( "Load 'announced.txt'", 0 ) end )
button_load_announced:Connect( wx.wxID_ANY, wx.wxEVT_LEAVE_WINDOW, function( event ) sb:SetStatusText( "", 0 ) end )
button_load_announced:Connect( id_button_load_announced, wx.wxEVT_COMMAND_BUTTON_CLICKED,
function( event )
    log_handler( files[ "log" ][ "announced" ], logfile_window, "read", button_load_announced, "both" )
    set_logfilesize( control_logsize_log_sensor, control_logsize_ann_sensor, control_logsize_exc_sensor )
end )

--// button - announced clear
local button_clear_announced = wx.wxButton( tab_6, id_button_clear_announced, "Clear", wx.wxPoint( 395, 294 ), wx.wxSize( 70, 20 ) )
button_clear_announced:Connect( wx.wxID_ANY, wx.wxEVT_ENTER_WINDOW, function( event ) sb:SetStatusText( "Clear 'announced.txt'", 0 ) end )
button_clear_announced:Connect( wx.wxID_ANY, wx.wxEVT_LEAVE_WINDOW, function( event ) sb:SetStatusText( "", 0 ) end )
button_clear_announced:Connect( id_button_clear_announced, wx.wxEVT_COMMAND_BUTTON_CLICKED,
function( event )
    log_handler( files[ "log" ][ "announced" ], logfile_window, "clean", button_clear_announced )
    set_logfilesize( control_logsize_log_sensor, control_logsize_ann_sensor, control_logsize_exc_sensor )
end )

--// border - logfile size - announced.txt
control = wx.wxStaticBox( tab_6, wx.wxID_ANY, "Filesize", wx.wxPoint( 312, 321 ), wx.wxSize( 161, 37 ) )

--// gauge - announced.txt
control_logsize_ann_sensor = wx.wxGauge( tab_6, wx.wxID_ANY, defaults[ "logfilesizemax" ], wx.wxPoint( 320, 337 ), wx.wxSize( 145, 16 ), wx.wxGA_HORIZONTAL )
control_logsize_ann_sensor:SetRange( tables[ "cfg" ][ "logfilesize" ] )

--// border - exception.txt
control = wx.wxStaticBox( tab_6, wx.wxID_ANY, "exception.txt", wx.wxPoint( 492, 278 ), wx.wxSize( 161, 40 ) )

--// button - exception load
local button_load_exception = wx.wxButton( tab_6, id_button_load_exception, "Load", wx.wxPoint( 500, 294 ), wx.wxSize( 70, 20 ) )
button_load_exception:Connect( wx.wxID_ANY, wx.wxEVT_ENTER_WINDOW, function( event ) sb:SetStatusText( "Load 'exception.txt'", 0 ) end )
button_load_exception:Connect( wx.wxID_ANY, wx.wxEVT_LEAVE_WINDOW, function( event ) sb:SetStatusText( "", 0 ) end )
button_load_exception:Connect( id_button_load_exception, wx.wxEVT_COMMAND_BUTTON_CLICKED,
function( event )
    log_handler( files[ "log" ][ "exception" ], logfile_window, "read", button_load_exception, "size" )
    set_logfilesize( control_logsize_log_sensor, control_logsize_ann_sensor, control_logsize_exc_sensor )
end )

--// button - exception clean
local button_clear_exception = wx.wxButton( tab_6, id_button_clear_exception, "Clear", wx.wxPoint( 575, 294 ), wx.wxSize( 70, 20 ) )
button_clear_exception:Connect( wx.wxID_ANY, wx.wxEVT_ENTER_WINDOW, function( event ) sb:SetStatusText( "Clear 'exception.txt'", 0 ) end )
button_clear_exception:Connect( wx.wxID_ANY, wx.wxEVT_LEAVE_WINDOW, function( event ) sb:SetStatusText( "", 0 ) end )
button_clear_exception:Connect( id_button_clear_exception, wx.wxEVT_COMMAND_BUTTON_CLICKED,
function( event )
    log_handler( files[ "log" ][ "exception" ], logfile_window, "clean", button_clear_exception )
    set_logfilesize( control_logsize_log_sensor, control_logsize_ann_sensor, control_logsize_exc_sensor )
end )

--// border - logfile size - exception.txt
control = wx.wxStaticBox( tab_6, wx.wxID_ANY, "Filesize", wx.wxPoint( 492, 321 ), wx.wxSize( 161, 37 ) )

--// gauge - exception.txt
control_logsize_exc_sensor = wx.wxGauge( tab_6, wx.wxID_ANY, defaults[ "logfilesizemax" ], wx.wxPoint( 500, 337 ), wx.wxSize( 145, 16 ), wx.wxGA_HORIZONTAL )
control_logsize_exc_sensor:SetRange( tables[ "cfg" ][ "logfilesize" ] )

--// timer to refresh the filesize gauge on tab 6
timer = wx.wxTimer( panel )
panel:Connect( wx.wxEVT_TIMER, function( event )
    set_logfilesize( control_logsize_log_sensor, control_logsize_ann_sensor, control_logsize_exc_sensor )
    --// todo: known issue with result of lsf.attributes( file ).modification
    --// if type( log_handler_last ) == "table" and lfs.attributes( log_handler_last[ "path" ] .. log_handler_last[ "file" ] ).modification > log_handler_last[ "time" ] then
    if type( log_handler_last ) == "table" then
        log_handler( log_handler_last[ "file" ], logfile_window, "read", button_load_logfile, "size" )
    end
end )
local start_timer = function()
    timer:Start( refresh_timer )
    log_broadcast( log_window, "Started timer: calc logfiles size, every " .. refresh_timer .. " ms" )
end
local stop_timer = function()
    timer:Stop()
    log_broadcast( log_window, "Stopped timer: calc logfiles size" )
end

-------------------------------------------------------------------------------------------------------------------------------------
--// MAIN //-------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------

local proc
local start_client = wx.wxButton()
local stop_client = wx.wxButton()

local start_process = function()
    local cmd = wx.wxGetCwd()  .. "\\" .. files[ "res" ][ "client_app" ]

    ---------------------------------------------------------------------------------------------------------------------------------

    proc = wx.wxProcess()
    proc:Redirect()
    proc:Detach()
    proc:Connect( wx.wxEVT_END_PROCESS,
        function( event )
            proc = nil
            pid = 0
        end
    )

    pid = wx.wxExecute( cmd, wx.wxEXEC_ASYNC + wx.wxEXEC_MAKE_GROUP_LEADER, proc )

    ---------------------------------------------------------------------------------------------------------------------------------

    log_broadcast( log_window, "Announcer started. (process id: " .. pid .. ")", "WHITE" )
    log_broadcast( log_window, "Try to connect to hub...", "GREEN" )

    wx.wxMilliSleep( 3000 )

    ---------------------------------------------------------------------------------------------------------------------------------

    local run = true

    if get_status( files[ "core" ][ "status" ], "hubconnect" ):find( "Fail" ) then
        log_broadcast( log_window, get_status( files[ "core" ][ "status" ], "hubconnect" ), "RED" )
        run = false
        kill_process( pid, log_window )
    elseif get_status( files[ "core" ][ "status" ], "hubconnect" ) == "" then
        local hubaddr = trim( control_hubaddress:GetValue() )
        local hubport = trim( control_hubport:GetValue() )
        log_broadcast( log_window, "Fail: failed to connect to hub: 'adcs://" .. hubaddr .. ":" .. hubport .. "'", "RED" )
        kill_process( pid, log_window )
        run = false
    else
        log_broadcast( log_window, get_status( files[ "core" ][ "status" ], "hubconnect" ), "GREEN" )
    end
    if run then
        if get_status( files[ "core" ][ "status" ], "hubhandshake" ):find( "Fail" ) or get_status( files[ "core" ][ "status" ], "hubhandshake" ) == "" then
            log_broadcast( log_window, get_status( files[ "core" ][ "status" ], "hubhandshake" ), "RED" )
            kill_process( pid, log_window )
            run = false
        else
            log_broadcast( log_window, get_status( files[ "core" ][ "status" ], "hubhandshake" ), "GREEN" )
            wx.wxMilliSleep( 100 )
        end
    end

    if run then
        if get_status( files[ "core" ][ "status" ], "hubkeyp" ):find( "Fail" ) or get_status( files[ "core" ][ "status" ], "hubkeyp" ) == "" then
            log_broadcast( log_window, get_status( files[ "core" ][ "status" ], "hubkeyp" ), "RED" )
            run = false
        else
            log_broadcast( log_window, get_status( files[ "core" ][ "status" ], "hubkeyp" ), "GREEN" )
            log_broadcast( log_window, "Sending support..." , "GREEN" )
            wx.wxMilliSleep( 100 )
        end
    end

    if run then
        if get_status( files[ "core" ][ "status" ], "support" ):find( "Fail" ) or get_status( files[ "core" ][ "status" ], "support" ) == "" then
            log_broadcast( log_window, get_status( files[ "core" ][ "status" ], "support" ), "RED" )
            run = false
        else
            log_broadcast( log_window, get_status( files[ "core" ][ "status" ], "support" ), "GREEN" )
            wx.wxMilliSleep( 100 )
        end
    end

    if run then
        if get_status( files[ "core" ][ "status" ], "hubsupport" ):find( "Fail" ) or get_status( files[ "core" ][ "status" ], "hubsupport" ) == "" then
            log_broadcast( log_window, get_status( files[ "core" ][ "status" ], "hubsupport" ), "RED" )
            run = false
        else
            log_broadcast( log_window, get_status( files[ "core" ][ "status" ], "hubsupport" ), "GREEN" )
            wx.wxMilliSleep( 100 )
        end
    end

    if run then
        if get_status( files[ "core" ][ "status" ], "hubosnr" ):find( "Fail" ) or get_status( files[ "core" ][ "status" ], "hubosnr" ) == "" then
            log_broadcast( log_window, get_status( files[ "core" ][ "status" ], "hubosnr" ), "RED" )
            run = false
        else
            log_broadcast( log_window, get_status( files[ "core" ][ "status" ], "hubosnr" ), "GREEN" )
            wx.wxMilliSleep( 100 )
        end
    end

    if run then
        if get_status( files[ "core" ][ "status" ], "hubsid" ):find( "Fail" ) or get_status( files[ "core" ][ "status" ], "hubsid" ) == "" then
            log_broadcast( log_window, get_status( files[ "core" ][ "status" ], "hubsid" ), "RED" )
            log_broadcast( log_window, "No SID provided, closing...", "RED" )
            run = false
        else
            log_broadcast( log_window, get_status( files[ "core" ][ "status" ], "hubsid" ), "GREEN" )
            log_broadcast( log_window, "Waiting for hub INF...", "GREEN" )
            wx.wxMilliSleep( 100 )
        end
    end

    if run then
        if get_status( files[ "core" ][ "status" ], "hubinf" ):find( "Fail" ) or get_status( files[ "core" ][ "status" ], "hubinf" ) == "" then
            log_broadcast( log_window, get_status( files[ "core" ][ "status" ], "hubinf" ), "RED" )
            log_broadcast( log_window, "No INF provided, closing...", "RED" )
            run = false
        else
            log_broadcast( log_window, get_status( files[ "core" ][ "status" ], "hubinf" ), "GREEN" )
            wx.wxMilliSleep( 100 )
        end
    end

    if run then
        if get_status( files[ "core" ][ "status" ], "owninf" ):find( "Fail" ) or get_status( files[ "core" ][ "status" ], "owninf" ) == "" then
            log_broadcast( log_window, get_status( files[ "core" ][ "status" ], "owninf" ), "RED" )
            run = false
        else
            log_broadcast( log_window, get_status( files[ "core" ][ "status" ], "owninf" ), "GREEN" )
            wx.wxMilliSleep( 100 )
        end
    end

    if run then
        if get_status( files[ "core" ][ "status" ], "passwd" ):find( "Fail" ) or get_status( files[ "core" ][ "status" ], "passwd" ) == "" then
            log_broadcast( log_window, get_status( files[ "core" ][ "status" ], "passwd" ), "RED" )
            log_broadcast( log_window, "No password request, closing...", "RED" )
            run = false
        else
            log_broadcast( log_window, get_status( files[ "core" ][ "status" ], "passwd" ), "GREEN" )
            wx.wxMilliSleep( 100 )
        end
    end

    if run then
        if get_status( files[ "core" ][ "status" ], "hubsalt" ):find( "Fail" ) or get_status( files[ "core" ][ "status" ], "hubsalt" ) == "" then
            log_broadcast( log_window, get_status( files[ "core" ][ "status" ], "hubsalt" ), "RED" )
            run = false
        else
            log_broadcast( log_window, get_status( files[ "core" ][ "status" ], "hubsalt" ), "GREEN" )
            wx.wxMilliSleep( 100 )
        end
    end

    if run then
        if get_status( files[ "core" ][ "status" ], "hublogin" ):find( "Fail" ) or get_status( files[ "core" ][ "status" ], "hublogin" ) == "" then
            log_broadcast( log_window, get_status( files[ "core" ][ "status" ], "hublogin" ), "RED" )
        else
            stop_client:Enable( true )
            log_broadcast( log_window, "Login successful.", "GREEN" )
            log_broadcast( log_window, "Cipher: " .. get_status( files[ "core" ][ "status" ], "cipher" ), "WHITE" )
            frame:SetStatusText( "CONNECTED", 0 )
        end
    end

    if not run then
        stop_timer()
        stop_client:Disable()
        unprotect_hub_values( log_window, notebook, button_clear_logfile, button_clear_announced, button_clear_exception )

        pid = 0
        kill_process( pid, log_window )
        start_client:Enable( true )
    end

end

-------------------------------------------------------------------------------------------------------------------------------------

--// disable save button(s) (tab 1 + tab 2 + tab 3)
disable_save_buttons = function( page )
    if not page or page == "hub" then
        save_hub:Disable()
        need_save.hub = false
    end
    if not page or page == "cfg" then
        save_cfg:Disable()
        need_save.cfg = false
    end
    if not page or page == "rules" then
        save_rules:Disable()
        need_save.rules = false
        need_save.rules_categoryname = false
    end
end

--// save changes (tab 1 + tab 2 + tab 3)
save_changes = function( log_window, page )
    local msg = "Save to file"
    if not page then
        msg = "Save to files"
        log_broadcast_header( log_window, msg )
        save_hub_values( log_window, control_hubname, control_hubaddress, control_hubport, control_nickname, control_password, control_keyprint )
        save_sslparams_values( log_window, control_tls )
        save_cfg_values( log_window, control_bot_desc, control_bot_share, control_bot_slots, control_announceinterval, control_sleeptime, control_sockettimeout, control_logfilesize, checkbox_trayicon )
        save_rules_values( log_window )
        log_broadcast_footer( log_window, msg )
    end
    if page == "hub" then
        msg = "Save to files"
        log_broadcast_header( log_window, msg )
        save_hub_values( log_window, control_hubname, control_hubaddress, control_hubport, control_nickname, control_password, control_keyprint )
        save_sslparams_values( log_window, control_tls )
        log_broadcast_footer( log_window, msg )
    end
    if page == "cfg" then
        log_broadcast_header( log_window, msg )
        save_cfg_values( log_window, control_bot_desc, control_bot_share, control_bot_slots, control_announceinterval, control_sleeptime, control_sockettimeout, control_logfilesize, checkbox_trayicon )
        log_broadcast_footer( log_window, msg )
    end
    if page == "rules" then
        log_broadcast_header( log_window, msg )
        save_rules_values( log_window )
        log_broadcast_footer( log_window, msg )
    end
    disable_save_buttons( page )
end

--// undo changes (tab 1 + tab 2 + tab 3)
undo_changes = function( log_window, page )
    local msg = "Load from file"
    if not page then
        msg = "Load from files"
        log_broadcast_header( log_window, msg )
        set_hub_values( log_window, control_hubname, control_hubaddress, control_hubport, control_nickname, control_password, control_keyprint )
        set_sslparams_value( log_window, control_tls )
        set_cfg_values( log_window, control_bot_desc, control_bot_share, control_bot_slots, control_announceinterval, control_sleeptime, control_sockettimeout, control_logfilesize, checkbox_trayicon )
        make_treebook_page( log_window )
        log_broadcast_footer( log_window, msg )
    end
    if page == "hub" then
        msg = "Load from files"
        log_broadcast_header( log_window, msg )
        set_hub_values( log_window, control_hubname, control_hubaddress, control_hubport, control_nickname, control_password, control_keyprint )
        set_sslparams_value( log_window, control_tls )
        log_broadcast_footer( log_window, msg )
    end
    if page == "cfg" then
        log_broadcast_header( log_window, msg )
        set_cfg_values( log_window, control_bot_desc, control_bot_share, control_bot_slots, control_announceinterval, control_sleeptime, control_sockettimeout, control_logfilesize, checkbox_trayicon )
        log_broadcast_footer( log_window, msg )
    end
    if page == "rules" then
        log_broadcast_header( log_window, msg )
        make_treebook_page()
        log_broadcast_footer( log_window, msg )
    end
    disable_save_buttons( page )
    set_logfilesize( control_logsize_log_sensor, control_logsize_ann_sensor, control_logsize_exc_sensor )
    disable_save_buttons( page )
end

--// connect button
start_client = wx.wxButton( panel, id_start_client, "CONNECT", wx.wxPoint( 300, 1 ), wx.wxSize( 85, 28 ) )
start_client:SetBackgroundColour( wx.wxColour( 65,65,65 ) )
start_client:SetForegroundColour( wx.wxColour( 0,237,0 ) )
start_client:Connect( id_start_client, wx.wxEVT_COMMAND_BUTTON_CLICKED,
    function( event )
        if validate.cert( true ) then
            return
        end
        if not validate.connect( true ) then
            log_broadcast_header( log_window, "Connect to Hub: " .. control_hubname:GetValue() )
            start_client:Disable()
            protect_hub_values( log_window, notebook, button_clear_logfile, button_clear_announced, button_clear_exception )
            start_timer()
            start_process()
            log_broadcast_footer( log_window, "Connect to Hub: " .. control_hubname:GetValue() )
        end
    end
)

--// disconnect button
stop_client = wx.wxButton( panel, id_stop_client, "DISCONNECT", wx.wxPoint( 406, 1 ), wx.wxSize( 85, 28 ) )
stop_client:SetBackgroundColour( wx.wxColour( 65,65,65 ) )
stop_client:SetForegroundColour( wx.wxColour( 255,0,0 ) )
stop_client:Disable()
stop_client:Connect( id_stop_client, wx.wxEVT_COMMAND_BUTTON_CLICKED,
    function( event )
        log_broadcast_header( log_window, "Disconnect from Hub: " .. control_hubname:GetValue() )
        stop_client:Disable()
        unprotect_hub_values( log_window, notebook, button_clear_logfile, button_clear_announced, button_clear_exception )
        stop_timer()
        kill_process( pid, log_window )
        start_client:Enable( true )
        log_broadcast_footer( log_window, "Disconnect from Hub: " .. control_hubname:GetValue() )
    end
)

-------------------------------------------------------------------------------------------------------------------------------------
--// MAIN LOOP //--------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------

--// start functions on start
log_broadcast_header( log_window, "Init" )
import_categories_tbl()
undo_changes( log_window )
log_broadcast( log_window, app_name .. " " .. _VERSION .. " ready.", "ORANGE" )
validate.cert( false )
log_broadcast_header( log_window, "Init" )

--// main function
local main = function()
    local taskbar = add_taskbar( frame, checkbox_trayicon )

    --// event - destroy window
    frame:Connect( wx.wxID_ANY, wx.wxEVT_DESTROY,
        function( event )
            reset_status( files[ "core" ][ "status" ] )
            if ( pid > 0 ) then
                local exists = wx.wxProcess.Exists( pid )
                if exists then
                    local ret = wx.wxProcess.Kill( pid, wx.wxSIGKILL, wx.wxKILL_CHILDREN )
                end
                pid = 0
            end
        end
    )

    --// event - close window
    frame:Connect( wx.wxID_ANY, wx.wxEVT_CLOSE_WINDOW, HandleAppExit )

    --// event - menu - exit
    frame:Connect( wx.wxID_EXIT, wx.wxEVT_COMMAND_MENU_SELECTED,
        function( event )
            frame:Close( true )
        end
    )

    --// event - menu - about
    frame:Connect( wx.wxID_ABOUT, wx.wxEVT_COMMAND_MENU_SELECTED,
        function( event )
            show_about_window( frame )
        end
    )

    --// event - notepad page change
    frame:Connect( wx.wxID_ANY, wx.wxEVT_COMMAND_NOTEBOOK_PAGE_CHANGED, HandleEvents )

    --// start frame
    frame:Show( true )
end

main()
wx.wxGetApp():MainLoop()

end --> if integrity_check() then ....