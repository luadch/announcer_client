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
local rules_listbox
local categories_listbox

--// table lookups
local util_loadtable = util.loadtable
local util_savetable = util.savetable
local util_formatbytes = util.formatbytes
local lfs_a = lfs.attributes

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

local file_cfg         = CFG_PATH ..  "cfg.lua"
local file_hub         = CFG_PATH ..  "hub.lua"
local file_rules       = CFG_PATH ..  "rules.lua"
local file_categories  = CFG_PATH ..  "categories.lua"
local file_sslparams   = CFG_PATH ..  "sslparams.lua"
local file_status      = CORE_PATH .. "status.lua"
local file_icon        = RES_PATH ..  "res1.dll"
local file_icon_2      = RES_PATH ..  "res2.dll"
local file_client_app  = RES_PATH ..  "client.dll"
local file_png_gpl     = RES_PATH ..  "png/GPLv3_160x80.png"
local file_png_applogo = RES_PATH ..  "png/applogo_96x96.png"
local file_logfile     = LOG_PATH ..  "logfile.txt"
local file_announced   = LOG_PATH ..  "announced.txt"
local file_exception   = LOG_PATH ..  "exception.txt"

local menu_title       = "Menu"
local menu_exit        = "Exit"
local menu_about       = "About"

--// cache tables
local hub_tbl        = util_loadtable( file_hub )
local cfg_tbl        = util_loadtable( file_cfg )
local rules_tbl      = util_loadtable( file_rules )
local sslparams_tbl  = util_loadtable( file_sslparams )
local categories_tbl = util_loadtable( file_categories )

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
id_dirpicker_path              = new_id()
id_dirpicker                   = new_id()

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

id_helper_dialog               = new_id()
id_helper_dialog_btn           = new_id()

id_rules_listbox               = new_id()
id_rule_add                    = new_id()
id_rule_del                    = new_id()
id_rule_clone                  = new_id()
id_dialog_add_rule             = new_id()
id_textctrl_add_rule           = new_id()
id_button_add_rule             = new_id()
id_button_cancel_rule          = new_id()

id_categories_listbox          = new_id()
id_category_add                = new_id()
id_category_del                = new_id()
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
local check_for_whitespaces_textctrl, parse_address_input, parse_listbox_selection
local disable_save_buttons, save_changes, undo_changes

-------------------------------------------------------------------------------------------------------------------------------------
--// EVENT HANDLER //----------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------

local save_hub, save_cfg, save_rules

local HandleEvents = function( event ) local name = event:GetEventObject():DynamicCast( "wxWindow" ):GetName() end
local HandleChangeTab1 = function( event ) HandleEvents( event ) save_hub:Enable( true ) need_save.hub = true end
local HandleChangeTab2 = function( event ) HandleEvents( event ) save_cfg:Enable( true ) need_save.cfg = true end
local HandleChangeTab3 = function( event ) HandleEvents( event ) save_rules:Enable( true ) need_save.rules = true end

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
icons:AddIcon( wx.wxIcon( file_icon, 3, 16, 16 ) )
icons:AddIcon( wx.wxIcon( file_icon, 3, 32, 32 ) )

--// icons for menubar
local mb_bmp_about_16x16 = wx.wxArtProvider.GetBitmap( wx.wxART_INFORMATION, wx.wxART_TOOLBAR )
local mb_bmp_exit_16x16  = wx.wxArtProvider.GetBitmap( wx.wxART_QUIT,        wx.wxART_TOOLBAR )

--// icons for taskbar
local tb_bmp_about_16x16 = wx.wxArtProvider.GetBitmap( wx.wxART_INFORMATION, wx.wxART_TOOLBAR )
local tb_bmp_exit_16x16  = wx.wxArtProvider.GetBitmap( wx.wxART_QUIT,        wx.wxART_TOOLBAR )

--// icons for tabs
local tab_1_ico = wx.wxIcon( file_icon_2 .. ";0", wx.wxBITMAP_TYPE_ICO, 16, 16 )
local tab_2_ico = wx.wxIcon( file_icon_2 .. ";1", wx.wxBITMAP_TYPE_ICO, 16, 16 )
local tab_3_ico = wx.wxIcon( file_icon_2 .. ";2", wx.wxBITMAP_TYPE_ICO, 16, 16 )
local tab_4_ico = wx.wxIcon( file_icon_2 .. ";3", wx.wxBITMAP_TYPE_ICO, 16, 16 )
local tab_5_ico = wx.wxIcon( file_icon_2 .. ";3", wx.wxBITMAP_TYPE_ICO, 16, 16 )
local tab_6_ico = wx.wxIcon( file_icon_2 .. ";4", wx.wxBITMAP_TYPE_ICO, 16, 16 )

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
local log_broadcast = function( control, msg, color )
    local timestamp = "[" .. os.date( "%Y-%m-%d/%H:%M:%S" ) .. "] "
    local before, after
    local log_color = function( l, m, c )
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
    if control and msg and ( color == "WHITE" ) then log_color( control, msg, wx.wxWHITE ) end
    if control and msg and ( color == "GREEN" ) then log_color( control, msg, wx.wxGREEN ) end
    if control and msg and ( color == "RED" ) then log_color( control, msg, wx.wxRED ) end
    if control and msg and ( color == "CYAN" ) then log_color( control, msg, wx.wxCYAN ) end
    if control and msg and ( color == "ORANGE" ) then log_color( control, msg, wx.wxColour( 254, 96, 1 ) ) end
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
        --wx.wxSTAY_ON_TOP + wx.wxRESIZE_BORDER
        wx.wxSTAY_ON_TOP + wx.wxDEFAULT_DIALOG_STYLE - wx.wxCLOSE_BOX - wx.wxMAXIMIZE_BOX - wx.wxMINIMIZE_BOX
    )
    di:SetBackgroundColour( wx.wxColour( 255, 255, 255 ) )
    di:SetMinSize( wx.wxSize( 320, 505 ) )
    di:SetMaxSize( wx.wxSize( 320, 505 ) )

    --// app logo
    local bmp_applogo = wx.wxBitmap():ConvertToImage()
    bmp_applogo:LoadFile( file_png_applogo )
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
    gpl_logo:LoadFile( file_png_gpl )
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
        if skip then
            local result = dialog.info( "Error: Whitespaces not allowed." )
        else
            local result = dialog.info( "Error: Whitespaces not allowed.\n\nRemoved whitespaces: " .. n, "Tab 3: " )
            control:SetValue( new )
        end
    end
end

--// parse input from address field and splitt the informations if possible
local parse_address_input = function( parent, control, control2, control3 )
    local addy, port, keyp
    local abcd = control:GetValue()
    --local _, _, found = string.find( abcd, "adcs://" )
    --// cut protokoll
    local bcd, n1 = string.gsub( abcd, "adcs://", "" )
    if n1 ~= 0 then abcd = bcd else bcd = abcd end
    addy = bcd
    --// cut port
    local bd, n2 = string.gsub( bcd, ":%d+", "" )
    if n2 ~= 0 then addy = bd end
    --// cut keyp
    local b, n3 = string.gsub( addy, "/%?kp=SHA256/%w+", "" )
    if n3 ~= 0 then addy = b end
    --// get port
    local _, _, c = string.find( bcd, ":(%d+)" )
    if c then port = c else port = nil end
    --// get keyp
    local _, _, d = string.find( bcd, "/%?kp=SHA256/(%w+)" )
    if d then keyp = d else keyp = nil end
    --// set values

    local dialog_title dialog_msg = "Mapped values by 'hubaddress':\n\n", false
    if n1 ~= 0 then
        dialog_msg = dialog_msg .. "Note: removed unneeded 'adcs://'." .. "\n"
    end
    control:SetValue( addy )
    if port then
        dialog_msg = dialog_msg ..  "Found port: " .. port .. "\n"
        control2:SetValue( port )
    end
    if keyp then
        dialog_msg = dialog_msg .. "Found keyprint: " .. keyp .. "\n"
        control3:SetValue( keyp )
    end
    if dialog_msg ~= "" then
        dialog.msg( dialog_title, dialog_msg )
    end
end

--// parse listbox selection and return id + name
parse_listbox_selection = function( control )
    local str = control:GetStringSelection()
    local n1, n2 = string.find( str, "#(%d+)" )
    local n3, n4 = string.find( str, ":%s(.*)" )
    return string.sub( str, n1 + 1, n2 ), string.sub( str, n3 + 2, n4 )
end

--// set values from "cfg/hub.lua"
local set_hub_values = function( log_window, control_hubname, control_hubaddress, control_hubport, control_nickname, control_password, control_keyprint )

    local hubname = hub_tbl[ "name" ] or "Luadch Testhub"
    local hubaddr = hub_tbl[ "addr" ] or "your.dynaddy.org"
    local hubport = hub_tbl[ "port" ] or 5001
    local hubnick = hub_tbl[ "nick" ] or "Announcer"
    local hubpass = hub_tbl[ "pass" ] or "test"
    local hubkeyp = hub_tbl[ "keyp" ] or "unknown"

    control_hubname:SetValue( hubname )
    control_hubaddress:SetValue( hubaddr )
    control_hubport:SetValue( hubport )
    control_nickname:SetValue( hubnick )
    control_password:SetValue( hubpass )
    control_keyprint:SetValue( hubkeyp )

    log_broadcast( log_window, "Import data from: '" .. file_hub .. "'", "CYAN" )
end

--// save values to "cfg/hub.lua"
local save_hub_values = function( log_window, control_hubname, control_hubaddress, control_hubport, control_nickname, control_password, control_keyprint )

    local hubname = trim( control_hubname:GetValue() )
    local hubaddr = trim( control_hubaddress:GetValue() )
    local hubport = trim( control_hubport:GetValue() )
    local hubnick = trim( control_nickname:GetValue() )
    local hubpass = trim( control_password:GetValue() )
    local hubkeyp = trim( control_keyprint:GetValue() )

    hub_tbl[ "name" ] = hubname
    hub_tbl[ "addr" ] = hubaddr
    hub_tbl[ "port" ] = hubport
    hub_tbl[ "nick" ] = hubnick
    hub_tbl[ "pass" ] = hubpass
    hub_tbl[ "keyp" ] = hubkeyp

    util_savetable( hub_tbl, "hub", file_hub )
    log_broadcast( log_window, "Saved data to: '" .. file_hub .. "'", "CYAN" )
end

--// protect hub values "cfg/cfg.lua"
local protect_hub_values = function( log_window, control_hubname, control_hubaddress, control_hubport, control_nickname,
                                     control_password, control_keyprint, control_tls, control_bot_desc, control_bot_share,
                                     control_bot_slots, control_announceinterval, control_sleeptime, control_sockettimeout, control_logfilesize,
                                     checkbox_trayicon, button_clear_logfile, button_clear_announced, button_clear_exception,
                                     rule_add_button, rule_del_button, rule_clone_button, rules_listbox, treebook, category_add_button,
                                     category_del_button, categories_listbox )

    --// tab_1
    control_hubname:Disable()
    control_hubaddress:Disable()
    control_hubport:Disable()
    control_nickname:Disable()
    control_password:Disable()
    control_keyprint:Disable()
    control_tls:Disable()
    --// tab_2
    control_bot_desc:Disable()
    control_bot_share:Disable()
    control_bot_slots:Disable()
    control_announceinterval:Disable()
    control_sleeptime:Disable()
    control_sockettimeout:Disable()
    control_logfilesize:Disable()
    checkbox_trayicon:Disable()
    --// tab_3
    treebook:Disable()
    --// tab_4
    rule_add_button:Disable()
    rule_del_button:Disable()
    rule_clone_button:Disable()
    rules_listbox:Disable()
    --// tab_5
    category_add_button:Disable()
    category_del_button:Disable()
    categories_listbox:Disable()
    --// tab_6
    button_clear_logfile:Disable()
    button_clear_announced:Disable()
    button_clear_exception:Disable()

    log_broadcast( log_window, "Lock 'Tab 1' controls while connecting to the hub", "CYAN" )
    log_broadcast( log_window, "Lock 'Tab 2' controls while connecting to the hub", "CYAN" )
    log_broadcast( log_window, "Lock 'Tab 3' controls while connecting to the hub", "CYAN" )
    log_broadcast( log_window, "Lock 'Tab 4' controls while connecting to the hub", "CYAN" )
    log_broadcast( log_window, "Lock 'Tab 5' controls while connecting to the hub", "CYAN" )
    log_broadcast( log_window, "Lock 'Tab 6' controls while connecting to the hub", "CYAN" )
end

--// unprotect hub values "cfg/cfg.lua"
local unprotect_hub_values = function( log_window, control_hubname, control_hubaddress, control_hubport, control_nickname,
                                       control_password, control_keyprint, control_tls, control_bot_desc, control_bot_share,
                                       control_bot_slots, control_announceinterval, control_sleeptime, control_sockettimeout, control_logfilesize,
                                       checkbox_trayicon, button_clear_logfile, button_clear_announced, button_clear_exception,
                                       rule_add_button, rule_del_button, rule_clone_button, rules_listbox, treebook, category_add_button,
                                       category_del_button, categories_listbox )

    --// tab_1
    control_hubname:Enable( true )
    control_hubaddress:Enable( true )
    control_hubport:Enable( true )
    control_nickname:Enable( true )
    control_password:Enable( true )
    control_keyprint:Enable( true )
    control_tls:Enable( true )
    --// tab_2
    control_bot_desc:Enable( true )
    control_bot_share:Enable( true )
    control_bot_slots:Enable( true )
    control_announceinterval:Enable( true )
    control_sleeptime:Enable( true )
    control_sockettimeout:Enable( true )
    control_logfilesize:Enable( true )
    checkbox_trayicon:Enable( true )
    --// tab_3
    treebook:Enable( true )
    --// tab_4
    rule_add_button:Enable( true )
    rule_del_button:Enable( true )
    rule_clone_button:Enable( true )
    rules_listbox:Enable( true )
    --// tab_5
    category_add_button:Enable( true )
    category_del_button:Enable( true )
    categories_listbox:Enable( true )
    --// tab_6
    button_clear_logfile:Enable( true )
    button_clear_announced:Enable( true )
    button_clear_exception:Enable( true )

    log_broadcast( log_window, "Unlock 'Tab 1' controls", "CYAN" )
    log_broadcast( log_window, "Unlock 'Tab 2' controls", "CYAN" )
    log_broadcast( log_window, "Unlock 'Tab 3' controls", "CYAN" )
    log_broadcast( log_window, "Unlock 'Tab 4' controls", "CYAN" )
    log_broadcast( log_window, "Unlock 'Tab 5' controls", "CYAN" )
    log_broadcast( log_window, "Unlock 'Tab 6' controls", "CYAN" )
end

--// set values from "cfg/cfg.lua"
local set_cfg_values = function( log_window, control_bot_desc, control_bot_share, control_bot_slots, control_announceinterval,
                                 control_sleeptime, control_sockettimeout, control_logfilesize, checkbox_trayicon )

    local botdesc = cfg_tbl[ "botdesc" ] or "Luadch Announcer Client"
    local botshare = cfg_tbl[ "botshare" ] or 0
    local botslots = cfg_tbl[ "botslots" ] or 0
    local announceinterval = cfg_tbl[ "announceinterval" ] or 300
    local sleeptime = cfg_tbl[ "sleeptime" ] or 10
    local sockettimeout = cfg_tbl[ "sockettimeout" ] or 60
    local logfilesize = cfg_tbl[ "logfilesize" ] or 2097152
    local trayicon = cfg_tbl[ "trayicon" ] or false

    control_bot_desc:SetValue( botdesc )
    control_bot_share:SetValue( tostring( botshare ) )
    control_bot_slots:SetValue( tostring( botslots ) )
    control_announceinterval:SetValue( tostring( announceinterval ) )
    control_sleeptime:SetValue( tostring( sleeptime ) )
    control_sockettimeout:SetValue( tostring( sockettimeout ) )
    control_logfilesize:SetValue( tostring( logfilesize ) )
    if cfg_tbl[ "trayicon" ] == true then checkbox_trayicon:SetValue( true ) else checkbox_trayicon:SetValue( false ) end

    log_broadcast( log_window, "Import data from: '" .. file_cfg .. "'", "CYAN" )
    need_save.cfg = false
end

--// save freshstuff version value to "cfg/cfg.lua"
local save_cfg_freshstuff_value = function()
    cfg_tbl[ "freshstuff_version" ] = true
    util_savetable( cfg_tbl, "cfg", file_cfg )
    log_broadcast( log_window, "Saved data to: '" .. file_cfg .. "'", "CYAN" )
end

--// save values to "cfg/cfg.lua"
local save_cfg_values = function( log_window, control_bot_desc, control_bot_share, control_bot_slots, control_announceinterval,
                                  control_sleeptime, control_sockettimeout, control_logfilesize, checkbox_trayicon )

    local botdesc = trim( control_bot_desc:GetValue() ) or ""
    local botshare = tonumber( trim( control_bot_share:GetValue() ) )
    local botslots = tonumber( trim( control_bot_slots:GetValue() ) )
    local announceinterval = tonumber( trim( control_announceinterval:GetValue() ) )
    local sleeptime = tonumber( trim( control_sleeptime:GetValue() ) )
    local sockettimeout = tonumber( trim( control_sockettimeout:GetValue() ) )
    local logfilesize = tonumber( trim( control_logfilesize:GetValue() ) )
    local trayicon = checkbox_trayicon:GetValue()
    local freshstuff_version = cfg_tbl[ "freshstuff_version" ] or false

    cfg_tbl[ "botdesc" ] = botdesc
    cfg_tbl[ "botshare" ] = botshare
    cfg_tbl[ "botslots" ] = botslots
    cfg_tbl[ "announceinterval" ] = announceinterval
    cfg_tbl[ "sleeptime" ] = sleeptime
    cfg_tbl[ "sockettimeout" ] = sockettimeout
    cfg_tbl[ "trayicon" ] = trayicon
    cfg_tbl[ "logfilesize" ] = logfilesize
    cfg_tbl[ "freshstuff_version" ] = freshstuff_version

    util_savetable( cfg_tbl, "cfg", file_cfg )
    log_broadcast( log_window, "Saved data to: '" .. file_cfg .. "'", "CYAN" )
end

--// set values from "cfg/sslparams.lua"
local set_sslparams_value = function( log_window, control )
    local protocol = sslparams_tbl.protocol
    if protocol == "tlsv1" then
        control:SetSelection( 0 )
    else
        control:SetSelection( 1 )
    end
    log_broadcast( log_window, "Import data from: '" .. file_sslparams .. "'", "CYAN" )
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
        util_savetable( tls1_tbl, "sslparams", file_sslparams )
        log_broadcast( log_window, "Saved TLSv1 data to: '" .. file_sslparams .. "'", "CYAN" )
    else
        util_savetable( tls12_tbl, "sslparams", file_sslparams )
        log_broadcast( log_window, "Saved TLSv1.2 data to: '" .. file_sslparams .. "'", "CYAN" )
    end
end

--// save values to "cfg/cfg.lua"
local save_config_values = function( log_window )
    util_savetable( cfg_tbl, "cfg", file_cfg )
    log_broadcast( log_window, "Saved data to: '" .. file_cfg .. "'", "CYAN" )
end

--// save values to "cfg/rules.lua"
local save_rules_values = function( log_window )
    util_savetable( rules_tbl, "rules", file_rules )
    log_broadcast( log_window, "Saved data to: '" .. file_rules .. "'", "CYAN" )
end

--// save values to "cfg/categories.lua"
local save_categories_values = function( log_window )
    util_savetable( categories_tbl, "categories", file_categories )
    log_broadcast( log_window, "Saved data to: '" .. file_categories .. "'", "CYAN" )
end

--// get status from status.lua
local get_status = function( file, key )
    local tbl, err = util_loadtable( file )
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
    util_savetable( tbl, "status", file )
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
    reset_status( file_status )
end

--// get rules table entrys as array
local sorted_rules_tbl = function()
    local rules_arr = { }
    for k, v in ipairs( rules_tbl ) do
        rules_arr[ k ] = "Rule #" .. k .. ": " .. rules_tbl[ k ].rulename
    end
    return rules_arr
end

--// change rulename value from a rule
local refresh_rulenames = function( control )
    control:Set( sorted_rules_tbl() )
end

--// get categories table entrys as array
local sorted_categories_tbl = function()
    local categories_arr = { }
    for k,v in spairs( categories_tbl, "asc", "categoryname" ) do
        categories_arr[ #categories_arr+1 ] = "Category #" .. #categories_arr+1 .. ": " .. v[ "categoryname" ]
    end
    return categories_arr
end

--// get ordered categories table entrys as array
local list_categories_tbl = function()
    local categories_arr = { }
    for k,v in spairs( categories_tbl, "asc", "categoryname" ) do
        categories_arr[ #categories_arr+1 ] = v[ "categoryname" ]
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

--// helper to check if key exists on table
function table.hasKey( tbl, item, field, id )
    if type( field ) == "string" then
        for key, value in pairs( tbl ) do
            if value[ field ][ item ] and key ~= id then return true end
        end
    else
        for key, value in pairs( tbl ) do
            if value[ item ] and key ~= id then return true end
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
function table.copy( tbl )
  local u = { }
  for key, value in pairs( tbl ) do u[ key ] = value end
  return setmetatable( u, getmetatable( tbl ) )
end

--// helper to order list by field
function spairs(tbl, order, field)
    local keys = { }
    for k in pairs( tbl ) do keys[ #keys+1 ] = k end
    if order then
        if type( order ) == "function" then
            table.sort( keys, function( a, b ) return order( tbl, a, b ) end )
        else
            if order == "asc" then
                if type( field ) == "string" then
                    table.sort( keys, function( a, b ) return string.lower( tbl[b][field] ) > string.lower( tbl[a][field] ) end )
                else
                    table.sort( keys, function( a, b ) return string.lower( tbl[b] ) > string.lower( tbl[a] ) end )
                end
            end
            if order == "desc" then
                if  type( field ) == "string" then
                    table.sort( keys, function( a, b ) return string.lower( tbl[b][field] ) < string.lower( tbl[a][field] ) end )
                else
                    table.sort( keys, function( a, b ) return string.lower( tbl[b] ) < string.lower( tbl[a] ) end )
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
    local path = wx.wxGetCwd()
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
        mode, err = lfs_a( path .. "\\" .. k, "mode" )
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
            wx.wxTE_READONLY + wx.wxTE_MULTILINE + wx.wxTE_RICH + wx.wxSUNKEN_BORDER + wx.wxHSCROLL-- + wx.wxTE_CENTRE
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
        local icon = wx.wxIcon( file_icon, 3, 16, 16 )
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
        menu:Connect( wx.wxID_EXIT, wx.wxEVT_COMMAND_MENU_SELECTED,
            function( event )
                frame:Destroy()
                taskbar:delete()
            end
        )
        taskbar:Connect( wx.wxEVT_TASKBAR_RIGHT_DOWN,
            function( event )
                taskbar:PopupMenu( menu )
            end
        )
        taskbar:Connect( wx.wxEVT_TASKBAR_LEFT_DOWN,
            function( event )
                frame:Iconize( not frame:IsIconized() )
                -- new
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
        frame:Connect( wx.wxEVT_CLOSE_WINDOW,
            function( event )
                frame:Iconize( true )
                return false
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
            frame:Connect( wx.wxEVT_CLOSE_WINDOW,
                function( event )
                    frame:Iconize( false )
                    frame:Destroy()
                    return false
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
    --size = util_formatbytes( wx.wxFileSize( file ) )
    local size_log = 0
    local size_log_success, size_log_error = lfs.attributes( file_logfile, "mode" )
    if size_log_success then
          size_log = wx.wxFileSize( file_logfile )
    end
    local size_ann = 0
    local size_ann_success, size_ann_error = lfs.attributes( file_announced, "mode" )
    if size_ann_success then
          size_ann = wx.wxFileSize( file_announced )
    end
    local size_exc = 0
    local size_exc_success, size_exc_error = lfs.attributes( file_exception, "mode" )
    if size_exc_success then
          size_exc = wx.wxFileSize( file_exception )
    end
    return size_log, size_ann, size_exc
end

--// set file size gauge values on tab 6
local set_logfilesize = function( control1, control2, control3 )
    control1:SetValue( select( 1, get_logfilesize() ) )
    control2:SetValue( select( 2, get_logfilesize() ) )
    control3:SetValue( select( 3, get_logfilesize() ) )
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
    wx.wxMINIMIZE_BOX + wx.wxSYSTEM_MENU + wx.wxCAPTION + wx.wxCLOSE_BOX + wx.wxCLIP_CHILDREN -- + wx.wxFRAME_TOOL_WINDOW
)
frame:Centre( wx.wxBOTH )
frame:SetIcons( icons )

local panel = wx.wxPanel( frame, wx.wxID_ANY, wx.wxPoint( 0, 0 ), wx.wxSize( app_width, app_height ) )
panel:SetBackgroundColour( wx.wxColour( 240, 240, 240 ) )

local notebook = wx.wxNotebook( panel, wx.wxID_ANY, wx.wxPoint( 0, 30 ), wx.wxSize( notebook_width, notebook_height ) ) --,wx.wxNB_NOPAGETHEME )
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

-------------------------------------------------------------------------------------------------------------------------------------
--// LOG WINDOW //-------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------

local log_window = wx.wxTextCtrl( panel, wx.wxID_ANY, "", wx.wxPoint( 0, 418 ), wx.wxSize( log_width, log_height ),
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
        wx.wxSize( 250, 300 ),
        wx.wxSTAY_ON_TOP + wx.wxDEFAULT_DIALOG_STYLE - wx.wxCLOSE_BOX - wx.wxMAXIMIZE_BOX - wx.wxMINIMIZE_BOX
    )
    di:SetBackgroundColour( wx.wxColour( 255, 255, 255 ) )
    di:Centre( wx.wxBOTH )

    control = wx.wxStaticText( di, wx.wxID_ANY, title, wx.wxPoint( 20, 10 ) )

    dialog.textctrl = wx.wxTextCtrl(
        di,
        wx.wxID_ANY,
        "",
        wx.wxPoint( 20, 50 ),
        wx.wxSize( 200, 180 ),
        wx.wxTE_READONLY + wx.wxTE_MULTILINE + wx.wxTE_RICH + wx.wxSUNKEN_BORDER + wx.wxHSCROLL-- + wx.wxTE_CENTRE
    )
    dialog.textctrl:SetBackgroundColour( wx.wxColour( 245, 245, 245 ) )
    dialog.textctrl:SetForegroundColour( wx.wxBLACK )
    dialog.textctrl:Centre( wx.wxHORIZONTAL )
    dialog.textctrl:AppendText( text )

    dialog.button = wx.wxButton( di, id_helper_dialog_btn, "OK", wx.wxPoint( 75, 242 ), wx.wxSize( 60, 20 ) )
    dialog.button:Centre( wx.wxHORIZONTAL )
    dialog.button:Connect( id_helper_dialog_btn, wx.wxEVT_COMMAND_BUTTON_CLICKED, function( event ) di:Destroy() end )
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
    local ssl_mode, ssl_err = lfs_a( sslparams_tbl["certificate"], "mode" )
    local check_failed = type( ssl_err ) == "string" or ssl_mode == "nil"
    if check_failed then
        log_broadcast( log_window, "Fail: failed to load ssl certificate file", "RED" )
        if dialog_show then
            local dialog_info = "Please generate your certificate files before connect!\nHowto instructions: docs/README.txt"
            dialog.info( dialog_info )
        end
        return check_failed
    end
end

--// validate hub: Tab 1
validate.hub = function( dialog_show )
    if not need_save.hub and dialog_show then
        local dialog_info = "Please save your changes before continue!"
        dialog.info( dialog_info, "Tab 1: " .. notebook:GetPageText( 0 ) )
    end
    return need_save.hub
end

--// validate cfg: Tab 2
validate.cfg = function( dialog_show )
    if not need_save.cfg and dialog_show then
        local dialog_info = "Please save your changes before continue!"
        dialog.info( dialog_info, "Tab 1: " .. notebook:GetPageText( 1 ) )
    end
    return need_save.cfg
end

--// validate helper empty name: Tab 3
validate.empty_name = function( dialog_show )
    local check_failed, dialog_msg = false, ""
    for k, v in ipairs( rules_tbl ) do
        if v[ "rulename" ] == "" then
            dialog_msg = dialog_msg .. "Rule #" .. k .. ": " .. v[ "rulename" ] .. "\n"
            check_failed = true
        end
    end
    if check_failed and dialog_show then
        local dialog_title = "There is no rule name set for the following\nrules:"
        dialog.msg( dialog_title, dialog_msg, "Tab 3: " .. notebook:GetPageText( 2 ) )
    end
    return check_failed
end

--// validate helper empty category: Tab 3
validate.empty_cat = function( dialog_show )
    local check_failed, dialog_msg = false, ""
    for k, v in ipairs( rules_tbl ) do
        if v[ "category" ] == "" then
            dialog_msg = dialog_msg .. "Rule #" .. k .. ": " .. v[ "rulename" ] .. "\n"
            check_failed = true
        end
    end
    if check_failed and dialog_show then
        local dialog_title = "There is no category set for the following\nrules:"
        dialog.msg( dialog_title, dialog_msg, "Tab 3: " .. notebook:GetPageText( 2 ) )
    end
    return check_failed
end

--// validate helper multiple rule: Tab 3
validate.unique_name = function( dialog_show )
    local check_failed, dialog_msg = false, ""
    for k, v in ipairs( rules_tbl ) do
        if table.hasValue( rules_tbl, v[ "rulename" ], "rulename", k ) then
            dialog_msg = dialog_msg .. "Rule #" .. k .. ": " .. v[ "rulename" ] .. "\n"
            check_failed = true
        end
    end
    if check_failed and dialog_show then
        local dialog_title = "There is no unique name set for the following\nrules:"
        dialog.msg( dialog_title, dialog_msg, "Tab 3: " .. notebook:GetPageText( 2 ) )
    end
    return check_failed
end

--// validate rules: Tab 3
validate.rules = function( dialog_show, dialog_name )
    local empty_name, empty_cat, unique_name = validate.empty_name( false ), validate.empty_cat( false ), validate.unique_name( false )
    local check_failed = empty_name or empty_cat or unique_name
    local dialog_info = ""
    if dialog_show then
        if check_failed then
            dialog_info = "Please solve the following issues your changes before continue!\n"
            if need_save.rules then
                dialog_info = dialog_info .. "- Warn: Unsaved changes\n"
            end
            if empty_name then
                dialog_info = dialog_info .. "- Error: Rule(s) without a name!\n"
            end
            if empty_cat then
                dialog_info = dialog_info .. "- Error: Rule(s) without a category!\n"
            end
            if unique_name then
                dialog_info = dialog_info .. "- Error: Rule(s) name are not unique!\n"
            end
            dialog.info( dialog_info, dialog_name or "Tab 3: " .. notebook:GetPageText( 2 ) )
        else
            if need_save.rules then
                local dialog_info = "Please save your changes before continue!"
                dialog.info( dialog_info, dialog_name or "Tab 3: " .. notebook:GetPageText( 2 ) )
            end
        end
    end
    return check_failed or need_save.rules
end

--// validate changes: Tab 1 + Tab 2 + Tab 3
validate.changes = function( dialog_show )
    local check_failed, dialog_msg = false, ""
    if dialog_show then
        if validate.hub( false ) then
            dialog_msg = dialog_msg .. "Tab 1: " .. notebook:GetPageText( 0 ) .. "\n- Warn: Unsaved changes\n\n"
            check_failed = true
        end
        if validate.cfg( false ) then
            dialog_msg = dialog_msg .. "Tab 2: " .. notebook:GetPageText( 1 ) .. "\n- Warn: Unsaved changes\n\n"
            check_failed = true
        end
        if validate.rules( false ) then
            dialog_msg = dialog_msg .. "Tab 3: " .. notebook:GetPageText( 2 ) .. "\n"
            if need_save.rules then
                dialog_msg = dialog_msg .. "- Warn: Unsaved changes\n"
            end
            if validate.empty_name( false) then
                dialog_msg = dialog_msg .. "- Error: Rule(s) without a name!\n"
            end
            if validate.empty_cat( false) then
                dialog_msg = dialog_msg .. "- Error: Rule(s) without a category!\n"
            end
            if validate.unique_name( false) then
                dialog_msg = dialog_msg .. "- Error: Rule(s) name are not unique!\n"
            end
            check_failed = true
        end
        if check_failed and dialog_show then
            local dialog_title = "Please save your changes on the following\nTabs:"
            dialog.msg( dialog_title, dialog_msg )
        end

    end
    return check_failed
end

-------------------------------------------------------------------------------------------------------------------------------------
--// Tab 1 //------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------

--// hubname
control = wx.wxStaticBox( tab_1, wx.wxID_ANY, "Hubname", wx.wxPoint( 5, 5 ), wx.wxSize( 775, 43 ) )
local control_hubname = wx.wxTextCtrl( tab_1, wx.wxID_ANY, "", wx.wxPoint( 20, 21 ), wx.wxSize( 745, 20 ),  wx.wxSUNKEN_BORDER )
control_hubname:SetBackgroundColour( wx.wxColour( 255, 255, 255 ) )
control_hubname:SetMaxLength( 70 )
control_hubname:Connect( wx.wxID_ANY, wx.wxEVT_ENTER_WINDOW, function( event ) sb:SetStatusText( "Enter your Hubname", 0 ) end )
control_hubname:Connect( wx.wxID_ANY, wx.wxEVT_LEAVE_WINDOW, function( event ) sb:SetStatusText( "", 0 ) end )

--// hubaddress
control = wx.wxStaticBox( tab_1, wx.wxID_ANY, "Hubaddress", wx.wxPoint( 5, 55 ), wx.wxSize( 692, 43 ) )
local control_hubaddress = wx.wxTextCtrl( tab_1, wx.wxID_ANY, "", wx.wxPoint( 20, 71 ), wx.wxSize( 662, 20 ),  wx.wxSUNKEN_BORDER )
control_hubaddress:SetBackgroundColour( wx.wxColour( 255, 255, 255 ) )
control_hubaddress:SetMaxLength( 170 )
control_hubaddress:Connect( wx.wxID_ANY, wx.wxEVT_ENTER_WINDOW, function( event ) sb:SetStatusText( "Enter your Hubaddress, you can use the complete address with adcs://addy:port/keyprint the informations will be auto-split", 0 ) end )
control_hubaddress:Connect( wx.wxID_ANY, wx.wxEVT_LEAVE_WINDOW, function( event ) sb:SetStatusText( "", 0 ) end )

--// port
control = wx.wxStaticBox( tab_1, wx.wxID_ANY, "Port", wx.wxPoint( 698, 55 ), wx.wxSize( 82, 43 ) )
local control_hubport = wx.wxTextCtrl( tab_1, wx.wxID_ANY, "", wx.wxPoint( 713, 71 ), wx.wxSize( 52, 20 ),  wx.wxSUNKEN_BORDER )
control_hubport:SetBackgroundColour( wx.wxColour( 255, 255, 255 ) )
control_hubport:SetMaxLength( 5 )
control_hubport:Connect( wx.wxID_ANY, wx.wxEVT_ENTER_WINDOW, function( event ) sb:SetStatusText( "Enter your Hubport", 0 ) end )
control_hubport:Connect( wx.wxID_ANY, wx.wxEVT_LEAVE_WINDOW, function( event ) sb:SetStatusText( "", 0 ) end )

--// nickname
control = wx.wxStaticBox( tab_1, wx.wxID_ANY, "Nickname", wx.wxPoint( 5, 105 ), wx.wxSize( 775, 43 ) )
local control_nickname = wx.wxTextCtrl( tab_1, wx.wxID_ANY, "", wx.wxPoint( 20, 121 ), wx.wxSize( 745, 20 ),  wx.wxSUNKEN_BORDER )
control_nickname:SetBackgroundColour( wx.wxColour( 255, 255, 255 ) )
control_nickname:SetMaxLength( 70 )
control_nickname:Connect( wx.wxID_ANY, wx.wxEVT_ENTER_WINDOW, function( event ) sb:SetStatusText( "Enter your Nickname", 0 ) end )
control_nickname:Connect( wx.wxID_ANY, wx.wxEVT_LEAVE_WINDOW, function( event ) sb:SetStatusText( "", 0 ) end )

--// password
control = wx.wxStaticBox( tab_1, wx.wxID_ANY, "Password", wx.wxPoint( 5, 155 ), wx.wxSize( 775, 43 ) )
local control_password = wx.wxTextCtrl( tab_1, wx.wxID_ANY, "", wx.wxPoint( 20, 171 ), wx.wxSize( 745, 20 ),  wx.wxSUNKEN_BORDER + wx.wxTE_PASSWORD )
control_password:SetBackgroundColour( wx.wxColour( 255, 255, 255 ) )
control_password:SetMaxLength( 70 )
control_password:Connect( wx.wxID_ANY, wx.wxEVT_ENTER_WINDOW, function( event ) sb:SetStatusText( "Enter your Password", 0 ) end )
control_password:Connect( wx.wxID_ANY, wx.wxEVT_LEAVE_WINDOW, function( event ) sb:SetStatusText( "", 0 ) end )

--// keyprint
control = wx.wxStaticBox( tab_1, wx.wxID_ANY, "Hub Keyprint (optional)", wx.wxPoint( 5, 205 ), wx.wxSize( 775, 43 ) )
local control_keyprint = wx.wxTextCtrl( tab_1, wx.wxID_ANY, "", wx.wxPoint( 20, 221 ), wx.wxSize( 745, 20 ),  wx.wxSUNKEN_BORDER )
control_keyprint:SetBackgroundColour( wx.wxColour( 255, 255, 255 ) )
control_keyprint:SetMaxLength( 80 )
control_keyprint:Connect( wx.wxID_ANY, wx.wxEVT_ENTER_WINDOW, function( event ) sb:SetStatusText( "Enter your Hub Keyprint. (optional)", 0 ) end )
control_keyprint:Connect( wx.wxID_ANY, wx.wxEVT_LEAVE_WINDOW, function( event ) sb:SetStatusText( "", 0 ) end )

--//  tsl mode
local control_tls = wx.wxRadioBox( tab_1, id_control_tls, "TLS Mode", wx.wxPoint( 352, 260 ), wx.wxSize( 83, 60 ), { "TLSv1", "TLSv1.2" }, 1, wx.wxSUNKEN_BORDER )

--// button save
save_hub = wx.wxButton( tab_1, id_save_hub, "Save", wx.wxPoint( 352, 332 ), wx.wxSize( 83, 25 ) )
save_hub:SetBackgroundColour( wx.wxColour( 200, 200, 200 ) )
save_hub:Connect( id_save_hub, wx.wxEVT_COMMAND_BUTTON_CLICKED,
    function( event )
        save_changes( log_window, "hub" )
    end )

--// event - hubname
control_hubname:Connect( wx.wxID_ANY, wx.wxEVT_COMMAND_TEXT_UPDATED, HandleChangeTab1 )

--// event - hubaddress
control_hubaddress:Connect( wx.wxID_ANY, wx.wxEVT_COMMAND_TEXT_UPDATED, HandleChangeTab1 )
control_hubaddress:Connect( wx.wxID_ANY, wx.wxEVT_KILL_FOCUS,
    function( event )
        check_for_whitespaces_textctrl( frame, control_hubaddress )
        parse_address_input( frame, control_hubaddress, control_hubport, control_keyprint )
    end )

--// event - port
control_hubport:Connect( wx.wxID_ANY, wx.wxEVT_COMMAND_TEXT_UPDATED, HandleChangeTab1 )
control_hubport:Connect( wx.wxID_ANY, wx.wxEVT_KILL_FOCUS, function( event ) check_for_whitespaces_textctrl( frame, control_hubport ) end )

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
    if type( cfg_tbl[ "logfilesize" ] ) == "nil" then cfg_tbl[ "logfilesize" ] = 2097152 add_new = true end
    if type( cfg_tbl[ "freshstuff_version" ] ) == "nil" then cfg_tbl[ "freshstuff_version" ] = false add_new = true end
    if add_new then save_config_values( log_window ) end
end
check_new_cfg_entrys()

--// bot description
control = wx.wxStaticBox( tab_2, wx.wxID_ANY, "Bot description", wx.wxPoint( 5, 5 ), wx.wxSize( 380, 43 ) )
local control_bot_desc = wx.wxTextCtrl( tab_2, wx.wxID_ANY, "", wx.wxPoint( 20, 21 ), wx.wxSize( 350, 20 ),  wx.wxSUNKEN_BORDER )
control_bot_desc:SetBackgroundColour( wx.wxColour( 255, 255, 255 ) )
control_bot_desc:SetMaxLength( 40 )
control_bot_desc:Connect( wx.wxID_ANY, wx.wxEVT_ENTER_WINDOW, function( event ) sb:SetStatusText( "Enter a Bot Description (optional)", 0 ) end )
control_bot_desc:Connect( wx.wxID_ANY, wx.wxEVT_LEAVE_WINDOW, function( event ) sb:SetStatusText( "", 0 ) end )

--//  bot slots
control = wx.wxStaticBox( tab_2, wx.wxID_ANY, "Bot slots (to bypass hub min slots rules)", wx.wxPoint( 5, 55 ), wx.wxSize( 380, 43 ) )
local control_bot_slots = wx.wxTextCtrl( tab_2, wx.wxID_ANY, "", wx.wxPoint( 20, 71 ), wx.wxSize( 350, 20 ),  wx.wxSUNKEN_BORDER )
control_bot_slots:SetBackgroundColour( wx.wxColour( 255, 255, 255 ) )
control_bot_slots:SetMaxLength( 2 )
control_bot_slots:Connect( wx.wxID_ANY, wx.wxEVT_ENTER_WINDOW, function( event ) sb:SetStatusText( "Amount of Slots, to bypass hub min slots rules", 0 ) end )
control_bot_slots:Connect( wx.wxID_ANY, wx.wxEVT_LEAVE_WINDOW, function( event ) sb:SetStatusText( "", 0 ) end )

--//  bot share
control = wx.wxStaticBox( tab_2, wx.wxID_ANY, "Bot share (in MBytes, to bypass hub min share rules)", wx.wxPoint( 5, 105 ), wx.wxSize( 380, 43 ) )
local control_bot_share = wx.wxTextCtrl( tab_2, wx.wxID_ANY, "", wx.wxPoint( 20, 121 ), wx.wxSize( 350, 20 ),  wx.wxSUNKEN_BORDER )
control_bot_share:SetBackgroundColour( wx.wxColour( 255, 255, 255 ) )
control_bot_share:SetMaxLength( 40 )
control_bot_share:Connect( wx.wxID_ANY, wx.wxEVT_ENTER_WINDOW, function( event ) sb:SetStatusText( "Amount of Share (in MBytes), to bypass hub min share rules", 0 ) end )
control_bot_share:Connect( wx.wxID_ANY, wx.wxEVT_LEAVE_WINDOW, function( event ) sb:SetStatusText( "", 0 ) end )

--// sleeptime
control = wx.wxStaticBox( tab_2, wx.wxID_ANY, "Sleeptime after connect (seconds)", wx.wxPoint( 400, 5 ), wx.wxSize( 380, 43 ) )
local control_sleeptime = wx.wxTextCtrl( tab_2, wx.wxID_ANY, "", wx.wxPoint( 415, 21 ), wx.wxSize( 350, 20 ),  wx.wxSUNKEN_BORDER )
control_sleeptime:SetBackgroundColour( wx.wxColour( 255, 255, 255 ) )
control_sleeptime:SetMaxLength( 6 )
control_sleeptime:Connect( wx.wxID_ANY, wx.wxEVT_ENTER_WINDOW, function( event ) sb:SetStatusText( "Sleeptime after connect to the hub, before firt scan", 0 ) end )
control_sleeptime:Connect( wx.wxID_ANY, wx.wxEVT_LEAVE_WINDOW, function( event ) sb:SetStatusText( "", 0 ) end )

--//  announce interval
control = wx.wxStaticBox( tab_2, wx.wxID_ANY, "Announce interval (seconds)", wx.wxPoint( 400, 55 ), wx.wxSize( 380, 43 ) )
local control_announceinterval = wx.wxTextCtrl( tab_2, wx.wxID_ANY, "", wx.wxPoint( 415, 71 ), wx.wxSize( 350, 20 ),  wx.wxSUNKEN_BORDER )
control_announceinterval:SetBackgroundColour( wx.wxColour( 255, 255, 255 ) )
control_announceinterval:SetMaxLength( 6 )
control_announceinterval:Connect( wx.wxID_ANY, wx.wxEVT_ENTER_WINDOW, function( event ) sb:SetStatusText( "Announce interval in seconds", 0 ) end )
control_announceinterval:Connect( wx.wxID_ANY, wx.wxEVT_LEAVE_WINDOW, function( event ) sb:SetStatusText( "", 0 ) end )

--// timeout
control = wx.wxStaticBox( tab_2, wx.wxID_ANY, "Socket Timeout (seconds)", wx.wxPoint( 400, 105 ), wx.wxSize( 380, 43 ) )
local control_sockettimeout = wx.wxTextCtrl( tab_2, wx.wxID_ANY, "", wx.wxPoint( 415, 121 ), wx.wxSize( 350, 20 ),  wx.wxSUNKEN_BORDER )
control_sockettimeout:SetBackgroundColour( wx.wxColour( 255, 255, 255 ) )
control_sockettimeout:SetMaxLength( 3 )
control_sockettimeout:Connect( wx.wxID_ANY, wx.wxEVT_ENTER_WINDOW, function( event ) sb:SetStatusText( "Socket timeout, you shouldn't change this if you not know what you do", 0 ) end )
control_sockettimeout:Connect( wx.wxID_ANY, wx.wxEVT_LEAVE_WINDOW, function( event ) sb:SetStatusText( "", 0 ) end )

--// max logfile size
control = wx.wxStaticBox( tab_2, wx.wxID_ANY, "Max Logfile size (bytes)", wx.wxPoint( 320, 160 ), wx.wxSize( 150, 43 ) )
local control_logfilesize = wx.wxSpinCtrl( tab_2, wx.wxID_ANY, "", wx.wxPoint( 335, 176 ), wx.wxSize( 120, 20 ) ) --, wx.wxALIGN_CENTRE + wx.wxALIGN_CENTRE_HORIZONTAL + wx.wxTE_CENTRE )
control_logfilesize:Connect( wx.wxID_ANY, wx.wxEVT_ENTER_WINDOW, function( event ) sb:SetStatusText( "Set maximum size of logfiles, you should leave it as it is", 0 ) end )
control_logfilesize:Connect( wx.wxID_ANY, wx.wxEVT_LEAVE_WINDOW, function( event ) sb:SetStatusText( "", 0 ) end )
control_logfilesize:SetRange( 2097152, 6291456 )
control_logfilesize:SetValue( 2097152 )

--// minimize to tray
local checkbox_trayicon = wx.wxCheckBox( tab_2, wx.wxID_ANY, "Minimize to tray", wx.wxPoint( 335, 245 ), wx.wxDefaultSize )
checkbox_trayicon:Connect( wx.wxID_ANY, wx.wxEVT_ENTER_WINDOW, function( event ) sb:SetStatusText( "Minimize the App to systemtray", 0 ) end )
checkbox_trayicon:Connect( wx.wxID_ANY, wx.wxEVT_LEAVE_WINDOW, function( event ) sb:SetStatusText( "", 0 ) end )

--// save button
save_cfg = wx.wxButton( tab_2, id_save_cfg, "Save", wx.wxPoint( 352, 270 ), wx.wxSize( 83, 25 ) )
save_cfg:SetBackgroundColour( wx.wxColour( 200, 200, 200 ) )
save_cfg:Connect( id_save_cfg, wx.wxEVT_COMMAND_BUTTON_CLICKED,
    function( event )
        save_changes( log_window, "cfg" )
    end )

--// events - bot description
control_bot_desc:Connect( wx.wxID_ANY, wx.wxEVT_COMMAND_TEXT_UPDATED, HandleChangeTab2 )

--// events - bot share
control_bot_share:Connect( wx.wxID_ANY, wx.wxEVT_COMMAND_TEXT_UPDATED, HandleChangeTab2 )
control_bot_share:Connect( wx.wxID_ANY, wx.wxEVT_KILL_FOCUS, function( event ) check_for_whitespaces_textctrl( frame, control_bot_share ) end )

--// events - bot slots
control_bot_slots:Connect( wx.wxID_ANY, wx.wxEVT_COMMAND_TEXT_UPDATED, HandleChangeTab2 )
control_bot_slots:Connect( wx.wxID_ANY, wx.wxEVT_KILL_FOCUS, function( event ) check_for_whitespaces_textctrl( frame, control_bot_slots ) end )

--// events - announce interval
control_announceinterval:Connect( wx.wxID_ANY, wx.wxEVT_COMMAND_TEXT_UPDATED, HandleChangeTab2 )
control_announceinterval:Connect( wx.wxID_ANY, wx.wxEVT_KILL_FOCUS, function( event ) check_for_whitespaces_textctrl( frame, control_announceinterval ) end )

--// events - sleeptime
control_sleeptime:Connect( wx.wxID_ANY, wx.wxEVT_COMMAND_TEXT_UPDATED, HandleChangeTab2 )
control_sleeptime:Connect( wx.wxID_ANY, wx.wxEVT_KILL_FOCUS, function( event ) check_for_whitespaces_textctrl( frame, control_sleeptime ) end )

--// events - timeout
control_sockettimeout:Connect( wx.wxID_ANY, wx.wxEVT_COMMAND_TEXT_UPDATED, HandleChangeTab2 )
control_sockettimeout:Connect( wx.wxID_ANY, wx.wxEVT_KILL_FOCUS, function( event ) check_for_whitespaces_textctrl( frame, control_sockettimeout ) end )

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
    for k, v in ipairs( rules_tbl ) do
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
    if add_new then save_rules_values( log_window ) end
end
check_new_rule_entrys()

--// save button
save_rules = wx.wxButton( tab_3, id_save_rules, "Save", wx.wxPoint( 15, 330 ), wx.wxSize( 83, 25 ) )
save_rules:SetBackgroundColour( wx.wxColour( 200, 200, 200 ) )
save_rules:Connect( id_save_rules, wx.wxEVT_COMMAND_BUTTON_CLICKED,
    function( event )
        local empty_name, empty_cat, unique_name = validate.empty_name( true ), validate.empty_cat( true ), validate.unique_name( true )
        if not empty_name and not empty_cat and not unique_name then
            save_changes( log_window, "rules" )
            refresh_rulenames( rules_listbox )
        end
    end )
save_rules:Disable()

--// treebook
local treebook, set_rules_values
local make_treebook_page = function( parent )
    treebook = wx.wxTreebook(
        parent,
        wx.wxID_ANY,
        wx.wxPoint( 0, 0 ),
        wx.wxSize( 795, 320 ),
        wx.wxBK_LEFT -- wx.wxBK_TOP | wx.wxBK_BOTTOM | wx.wxBK_LEFT | wx.wxBK_RIGHT
    )

    notebook:SetImageList( notebook_image_list )
    notebook:SetPageImage( 0, tab_1_img )
    notebook:SetPageImage( 1, tab_2_img )
    notebook:SetPageImage( 2, tab_3_img )
    notebook:SetPageImage( 3, tab_4_img )
    notebook:SetPageImage( 4, tab_5_img )
    notebook:SetPageImage( 5, tab_6_img )

    local first_page = true
    local i = 1

    set_rules_values = function()
        for k, v in ipairs( rules_tbl ) do
            local str = tostring( i )

            local panel = "panel_" .. str
            panel = wx.wxPanel( treebook, wx.wxID_ANY )
            panel:SetBackgroundColour( wx.wxColour( 225, 225, 225 ) )

            local sizer = wx.wxBoxSizer( wx.wxVERTICAL )
            sizer:SetMinSize( 795, 235 )
            panel:SetSizer( sizer )
            sizer:SetSizeHints( panel )

            --// avoid to long rulename
            local rulename = rules_tbl[ k ].rulename
            if string.len(rulename) > 18 then
                rulename = string.sub(rulename, 1, 18) .. ".."
            end

            --// set short rulename
            if rules_tbl[ k ].active == true then
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
            if rules_tbl[ k ].active == true then
                checkbox_activate:SetValue( true )
                checkbox_activate:SetForegroundColour( wx.wxColour( 0, 128, 0 ) )
            else
                checkbox_activate:SetValue( false )
            end

            --// rulename
            local textctrl_rulename = "textctrl_rulename_" .. str
            textctrl_rulename = wx.wxTextCtrl( panel, id_rulename + i, "", wx.wxPoint( 80, 11 ), wx.wxSize( 350, 20 ), wx.wxSUNKEN_BORDER ) -- + wx.wxTE_CENTRE + wx.wxTE_READONLY )
            textctrl_rulename:SetBackgroundColour( wx.wxColour( 255, 255, 255 ) )
            textctrl_rulename:SetMaxLength( 25 )
            textctrl_rulename:SetValue( rules_tbl[ k ].rulename )
            textctrl_rulename:Connect( wx.wxID_ANY, wx.wxEVT_ENTER_WINDOW, function( event ) sb:SetStatusText( "Rulename, you can rename it if you like", 0 ) end )
            textctrl_rulename:Connect( wx.wxID_ANY, wx.wxEVT_LEAVE_WINDOW, function( event ) sb:SetStatusText( "", 0 ) end )

            --// announcing path
            control = wx.wxStaticBox( panel, wx.wxID_ANY, "Announcing path", wx.wxPoint( 5, 40 ), wx.wxSize( 520, 43 ) )
            local dirpicker_path = "dirpicker_path_" .. str
            dirpicker_path = wx.wxTextCtrl( panel, id_dirpicker_path + i, "", wx.wxPoint( 20, 55 ), wx.wxSize( 410, 20 ), wx.wxTE_PROCESS_ENTER + wx.wxSUNKEN_BORDER )
            dirpicker_path:SetValue( rules_tbl[ k ].path )
            dirpicker_path:Connect( wx.wxID_ANY, wx.wxEVT_ENTER_WINDOW, function( event ) sb:SetStatusText( "Set source path for files/directorys to announce", 0 ) end )
            dirpicker_path:Connect( wx.wxID_ANY, wx.wxEVT_LEAVE_WINDOW, function( event ) sb:SetStatusText( "", 0 ) end )

            --// announcing path dirpicker
            local dirpicker = "dirpicker_" .. str
            dirpicker = wx.wxDirPickerCtrl(
                panel,
                id_dirpicker + i,
                wx.wxGetCwd(),
                "Choose announcing folder:",
                wx.wxPoint( 438, 55 ),
                wx.wxSize( 80, 22 ),
                --wx.wxDIRP_DEFAULT_STYLE + wx.wxDIRP_DIR_MUST_EXIST - wx.wxDIRP_USE_TEXTCTRL
                wx.wxDIRP_DIR_MUST_EXIST
            )

            --// command
            control = wx.wxStaticBox( panel, wx.wxID_ANY, "Hub command", wx.wxPoint( 5, 91 ), wx.wxSize( 240, 43 ) )
            local textctrl_command = "textctrl_command_" .. str
            textctrl_command = wx.wxTextCtrl( panel, id_command + i, "", wx.wxPoint( 20, 107 ), wx.wxSize( 210, 20 ),  wx.wxSUNKEN_BORDER )
            textctrl_command:SetBackgroundColour( wx.wxColour( 255, 255, 255 ) )
            textctrl_command:SetMaxLength( 30 )
            textctrl_command:SetValue( rules_tbl[ k ].command )
            textctrl_command:Connect( wx.wxID_ANY, wx.wxEVT_ENTER_WINDOW, function( event ) sb:SetStatusText( "Freshstuff hubcommand, default: +addrel", 0 ) end )
            textctrl_command:Connect( wx.wxID_ANY, wx.wxEVT_LEAVE_WINDOW, function( event ) sb:SetStatusText( "", 0 ) end )

            --// alibi nick border
            control = wx.wxStaticBox( panel, wx.wxID_ANY, "Hub nickname", wx.wxPoint( 5, 141 ), wx.wxSize( 240, 67 ) )

            --// alibi nick
            local textctrl_alibinick = "textctrl_alibinick_" .. str
            textctrl_alibinick = wx.wxTextCtrl( panel, id_alibinick + i, "", wx.wxPoint( 20, 181 ), wx.wxSize( 210, 20 ),  wx.wxSUNKEN_BORDER )
            textctrl_alibinick:SetBackgroundColour( wx.wxColour( 255, 255, 255 ) )
            textctrl_alibinick:SetMaxLength( 30 )
            textctrl_alibinick:SetValue( rules_tbl[ k ].alibinick )
            textctrl_alibinick:Connect( wx.wxID_ANY, wx.wxEVT_ENTER_WINDOW, function( event ) sb:SetStatusText( "Alibi nick, you can announce releases with an other nickname, requires ptx_freshstuff_v0.7 or higher", 0 ) end )
            textctrl_alibinick:Connect( wx.wxID_ANY, wx.wxEVT_LEAVE_WINDOW, function( event ) sb:SetStatusText( "", 0 ) end )

            --// alibi nick checkbox
            local checkbox_alibicheck = "checkbox_alibicheck_" .. str
            checkbox_alibicheck = wx.wxCheckBox( panel, id_alibicheck + i, "Use alternative nick", wx.wxPoint( 20, 158 ), wx.wxDefaultSize )
            checkbox_alibicheck:Connect( wx.wxID_ANY, wx.wxEVT_ENTER_WINDOW, function( event ) sb:SetStatusText( "Alibi nick, you can announce releases with an other nickname, requires ptx_freshstuff_v0.7 or higher", 0 ) end )
            checkbox_alibicheck:Connect( wx.wxID_ANY, wx.wxEVT_LEAVE_WINDOW, function( event ) sb:SetStatusText( "", 0 ) end )
            if rules_tbl[ k ].alibicheck == true then
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
            choicectrl_category:Select( choicectrl_category:FindString( rules_tbl[ k ].category, true ) )
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
                    di = wx.wxDialog( frame, id_blacklist + i, "Blacklist", wx.wxDefaultPosition, wx.wxSize( 215, 365 ) ) --, wx.wxDEFAULT_DIALOG_STYLE + wx.wxSTAY_ON_TOP )
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
                        for k, v in pairs( rules_tbl[ k ].blacklist ) do
                            table.insert( skip_lst, i, k )
                            i = i + 1
                        end
                        table.sort( skip_lst )
                        return skip_lst
                    end

                    --// add new table entry to blacklist
                    local add_folder = function( blacklist_textctrl, blacklist_listbox )
                        local folder = blacklist_textctrl:GetValue()
                        if folder == "" then
                            local result = dialog.info(  "Error: please enter a name for the TAG" )
                        else
                            if table.hasKey( rules_tbl, folder, "blacklist" ) then
                                local result = dialog.info( "Error: TAG name '" .. folder .. "' already taken" )
                                return
                            end
                            rules_tbl[ k ].blacklist[ folder ] = true
                            blacklist_textctrl:SetValue( "" )
                            blacklist_listbox:Set( sorted_skip_tbl() )
                            blacklist_listbox:SetSelection( 0 )
                            local result = dialog.info( "The following TAG was added to table: " .. folder )
                            log_broadcast( log_window, "The following TAG was added to Blacklist table: " .. folder, "CYAN" )
                        end
                    end

                    --// remove table entry from blacklist
                    local del_folder = function( blacklist_textctrl, blacklist_listbox )
                        if blacklist_listbox:GetSelection() == -1 then
                            local result = dialog.info( "Error: No TAG selected" )
                            return
                        end
                        local folder = blacklist_listbox:GetString( blacklist_listbox:GetSelection() )
                        if folder then rules_tbl[ k ].blacklist[ folder ] = nil end
                        blacklist_textctrl:SetValue( "" )
                        blacklist_listbox:Set( sorted_skip_tbl() )
                        blacklist_listbox:SetSelection( 0 )
                        local result = dialog.info( "The following TAG was removed from table: " .. folder )
                        log_broadcast( log_window, "The following TAG was removed from Blacklist table: " .. folder, "CYAN" )
                    end

                    control = wx.wxStaticBox( di, wx.wxID_ANY, "", wx.wxPoint( 20, 78 ), wx.wxSize( 170, 215 ) )

                    --// wxListBox
                    local blacklist_listbox = "blacklist_listbox_" .. str
                    blacklist_listbox = wx.wxListBox(

                        di,
                        id_blacklist_listbox + i,
                        wx.wxPoint( 30, 93 ),
                        wx.wxSize( 150, 192 ),
                        sorted_skip_tbl(),
                        wx.wxLB_SINGLE + wx.wxLB_HSCROLL + wx.wxLB_SORT
                    )
                    blacklist_listbox:SetSelection( 0 )

                    --// Button - Add Folder
                    local blacklist_add_button = "blacklist_add_button_" .. str
                    blacklist_add_button = wx.wxButton( di, id_blacklist_add_button + i, "add", wx.wxPoint( 20, 60 ), wx.wxSize( 169, 18 ) )
                    blacklist_add_button:Connect( id_blacklist_add_button + i, wx.wxEVT_COMMAND_BUTTON_CLICKED,
                        function( event )
                            add_folder( blacklist_textctrl, blacklist_listbox )
                            HandleChangeTab3( event )
                        end
                    )

                    --// Button - Delete Folder
                    local blacklist_del_button = "blacklist_del_button_" .. str
                    blacklist_del_button = wx.wxButton( di, id_blacklist_del_button + i, "delete", wx.wxPoint( 20, 298 ), wx.wxSize( 169, 18 ) )
                    blacklist_del_button:Connect( id_blacklist_del_button + i, wx.wxEVT_COMMAND_BUTTON_CLICKED,
                        function( event )
                            del_folder( blacklist_textctrl, blacklist_listbox )
                            HandleChangeTab3( event )
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
                        for k, v in pairs( rules_tbl[ k ].whitelist ) do
                            table.insert( skip_lst, i, k )
                            i = i + 1
                        end
                        table.sort( skip_lst )
                        return skip_lst
                    end

                    --// add new table entry to whitelist
                    local add_folder = function( whitelist_textctrl, whitelist_listbox )
                        local folder = whitelist_textctrl:GetValue()
                        if folder == "" then
                            local result = dialog.info( "Error: please enter a name for the TAG" )
                        else
                            if table.hasKey( rules_tbl, folder, "whitelist" ) then
                                local result = dialog.info( "Error: TAG name '" .. folder .. "' already taken" )
                                return
                            end
                            rules_tbl[ k ].whitelist[ folder ] = true
                            whitelist_textctrl:SetValue( "" )
                            whitelist_listbox:Set( sorted_skip_tbl() )
                            whitelist_listbox:SetSelection( 0 )
                            local result = dialog.info( "The following TAG was added to table: " .. folder )
                            log_broadcast( log_window, "The following TAG was added to Whitelist table: " .. folder, "CYAN" )
                        end
                    end

                    --// remove table entry from whitelist
                    local del_folder = function( whitelist_textctrl, whitelist_listbox )
                        if whitelist_listbox:GetSelection() == -1 then
                            local result = dialog.info( "Error: No TAG selected" )
                            return
                        end
                        local folder = whitelist_listbox:GetString( whitelist_listbox:GetSelection() )
                        if folder then rules_tbl[ k ].whitelist[ folder ] = nil end
                        whitelist_textctrl:SetValue( "" )
                        whitelist_listbox:Set( sorted_skip_tbl() )
                        whitelist_listbox:SetSelection( 0 )
                        local result = dialog.info( "The following TAG was removed from table: " .. folder )
                        log_broadcast( log_window, "The following TAG was removed from Whitelist table: " .. folder, "CYAN" )
                    end

                    control = wx.wxStaticBox( di, wx.wxID_ANY, "", wx.wxPoint( 20, 78 ), wx.wxSize( 170, 215 ) )

                    --// wxListBox
                    local whitelist_listbox = "whitelist_listbox_" .. str
                    whitelist_listbox = wx.wxListBox(

                        di,
                        id_whitelist_listbox + i,
                        wx.wxPoint( 30, 93 ),
                        wx.wxSize( 150, 192 ),
                        sorted_skip_tbl(),
                        wx.wxLB_SINGLE + wx.wxLB_HSCROLL + wx.wxLB_SORT
                    )
                    whitelist_listbox:SetSelection( 0 )

                    --// Button - Add Folder
                    local whitelist_add_button = "whitelist_add_button_" .. str
                    whitelist_add_button = wx.wxButton( di, id_whitelist_add_button + i, "add", wx.wxPoint( 20, 60 ), wx.wxSize( 169, 18 ) )
                    whitelist_add_button:Connect( id_whitelist_add_button + i, wx.wxEVT_COMMAND_BUTTON_CLICKED,
                        function( event )
                            add_folder( whitelist_textctrl, whitelist_listbox )
                            HandleChangeTab3( event )
                        end
                    )

                    --// Button - Delete Folder
                    local whitelist_del_button = "whitelist_del_button_" .. str
                    whitelist_del_button = wx.wxButton( di, id_whitelist_del_button + i, "delete", wx.wxPoint( 20, 298 ), wx.wxSize( 169, 18 ) )
                    whitelist_del_button:Connect( id_whitelist_del_button + i, wx.wxEVT_COMMAND_BUTTON_CLICKED,
                        function( event )
                            del_folder( whitelist_textctrl, whitelist_listbox )
                            HandleChangeTab3( event )
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
            if rules_tbl[ k ].daydirscheme == true then checkbox_daydirscheme:SetValue( true ) else checkbox_daydirscheme:SetValue( false ) end

            --// daydir current day
            local checkbox_zeroday = "checkbox_zeroday_" .. str
            checkbox_zeroday = wx.wxCheckBox( panel, id_zeroday + i, "Check only current daydir", wx.wxPoint( 280, 128 ), wx.wxDefaultSize )
            checkbox_zeroday:Connect( wx.wxID_ANY, wx.wxEVT_ENTER_WINDOW, function( event ) sb:SetStatusText( "To announce only releases in daydirs from today", 0 ) end )
            checkbox_zeroday:Connect( wx.wxID_ANY, wx.wxEVT_LEAVE_WINDOW, function( event ) sb:SetStatusText( "", 0 ) end )
            if rules_tbl[ k ].zeroday == true then checkbox_zeroday:SetValue( true ) else checkbox_zeroday:SetValue( false ) end
            if rules_tbl[ k ].daydirscheme == true then checkbox_zeroday:Enable( true ) else checkbox_zeroday:Disable() end

            --// check dirs
            local checkbox_checkdirs = "checkbox_checkdirs_" .. str
            checkbox_checkdirs = wx.wxCheckBox( panel, id_checkdirs + i, "Announce Directories", wx.wxPoint( 270, 153 ), wx.wxDefaultSize )
            checkbox_checkdirs:Connect( wx.wxID_ANY, wx.wxEVT_ENTER_WINDOW, function( event ) sb:SetStatusText( "Announce directorys?", 0 ) end )
            checkbox_checkdirs:Connect( wx.wxID_ANY, wx.wxEVT_LEAVE_WINDOW, function( event ) sb:SetStatusText( "", 0 ) end )
            if rules_tbl[ k ].checkdirs == true then checkbox_checkdirs:SetValue( true ) else checkbox_checkdirs:SetValue( false ) end

            --// check dirs nfo
            local checkbox_checkdirsnfo = "checkbox_checkdirsnfo_" .. str
            checkbox_checkdirsnfo = wx.wxCheckBox( panel, id_checkdirsnfo + i, "Only if it contains a NFO file", wx.wxPoint( 280, 173 ), wx.wxDefaultSize )
            checkbox_checkdirsnfo:Connect( wx.wxID_ANY, wx.wxEVT_ENTER_WINDOW, function( event ) sb:SetStatusText( "To announce only releases containing a NFO File", 0 ) end )
            checkbox_checkdirsnfo:Connect( wx.wxID_ANY, wx.wxEVT_LEAVE_WINDOW, function( event ) sb:SetStatusText( "", 0 ) end )
            if rules_tbl[ k ].checkdirsnfo == true then checkbox_checkdirsnfo:SetValue( true ) else checkbox_checkdirsnfo:SetValue( false ) end
            if rules_tbl[ k ].checkdirs == true then checkbox_checkdirsnfo:Enable( true ) else checkbox_checkdirsnfo:Disable() end

            --// check dirs sfv
            local checkbox_checkdirssfv = "checkbox_checkdirssfv_" .. str
            checkbox_checkdirssfv = wx.wxCheckBox( panel, id_checkdirssfv + i, "Only if it contains a validated SFV file", wx.wxPoint( 280, 195 ), wx.wxDefaultSize )
            checkbox_checkdirssfv:Connect( wx.wxID_ANY, wx.wxEVT_ENTER_WINDOW, function( event ) sb:SetStatusText( "To announce only releases containing a validated SFV File", 0 ) end )
            checkbox_checkdirssfv:Connect( wx.wxID_ANY, wx.wxEVT_LEAVE_WINDOW, function( event ) sb:SetStatusText( "", 0 ) end )
            if rules_tbl[ k ].checkdirssfv == true then checkbox_checkdirssfv:SetValue( true ) else checkbox_checkdirssfv:SetValue( false ) end
            if rules_tbl[ k ].checkdirs == true then checkbox_checkdirssfv:Enable( true ) else checkbox_checkdirssfv:Disable() end

            --// check files
            local checkbox_checkfiles = "checkbox_checkfiles_" .. str
            checkbox_checkfiles = wx.wxCheckBox( panel, id_checkfiles + i, "Announce Files", wx.wxPoint( 270, 221 ), wx.wxDefaultSize )
            checkbox_checkfiles:Connect( wx.wxID_ANY, wx.wxEVT_ENTER_WINDOW, function( event ) sb:SetStatusText( "Announce files?", 0 ) end )
            checkbox_checkfiles:Connect( wx.wxID_ANY, wx.wxEVT_LEAVE_WINDOW, function( event ) sb:SetStatusText( "", 0 ) end )
            if rules_tbl[ k ].checkfiles == true then checkbox_checkfiles:SetValue( true ) else checkbox_checkfiles:SetValue( false ) end

            --// check whitespaces
            local checkbox_checkspaces = "checkbox_checkspaces_" .. str
            checkbox_checkspaces = wx.wxCheckBox( panel, id_checkspaces + i, "Disallow whitespaces", wx.wxPoint( 270, 241 ), wx.wxDefaultSize )
            checkbox_checkspaces:Connect( wx.wxID_ANY, wx.wxEVT_ENTER_WINDOW, function( event ) sb:SetStatusText( "Do not announce if the files/folders containing whitespaces", 0 ) end )
            checkbox_checkspaces:Connect( wx.wxID_ANY, wx.wxEVT_LEAVE_WINDOW, function( event ) sb:SetStatusText( "", 0 ) end )
            if rules_tbl[ k ].checkspaces == true then checkbox_checkspaces:SetValue( true ) else checkbox_checkspaces:SetValue( false ) end

            --// check age
            local checkbox_checkage = "checkbox_checkage_" .. str
            checkbox_checkage = wx.wxCheckBox( panel, id_checkage + i, "Max age of dirs/files (days)", wx.wxPoint( 270, 261 ), wx.wxDefaultSize )
            checkbox_checkage:Connect( wx.wxID_ANY, wx.wxEVT_ENTER_WINDOW, function( event ) sb:SetStatusText( "Set a maximum age in days for the files/folders to announce", 0 ) end )
            checkbox_checkage:Connect( wx.wxID_ANY, wx.wxEVT_LEAVE_WINDOW, function( event ) sb:SetStatusText( "", 0 ) end )
            if rules_tbl[ k ].checkage == true then
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
            spinctrl_maxage:SetValue( rules_tbl[ k ].maxage )
            spinctrl_maxage:Enable( rules_tbl[ k ].checkage )

            --// events - rulename
            textctrl_rulename:Connect( id_rulename + i, wx.wxEVT_COMMAND_TEXT_UPDATED,
                function( event )
                    local value = trim( textctrl_rulename:GetValue() )
                    rules_tbl[ k ].rulename = value
                    local id = treebook:GetSelection()

                    --// avoid to long rulename
                    local rulename = rules_tbl[ id + 1 ].rulename
                    if string.len(rulename) > 15 then
                        rulename = string.sub(rulename, 1, 15) .. ".."
                    end

                    if rules_tbl[ id + 1 ].active == true then
                        treebook:SetPageText( id, "" .. id + 1 .. ": " .. rulename .. " (on)" )
                    else
                        treebook:SetPageText( id, "" .. id + 1 .. ": " .. rulename .. " (off)" )
                    end
                    HandleChangeTab3( event )
                end
            )

            textctrl_rulename:Connect( id_rulename + i, wx.wxEVT_KILL_FOCUS,
                function( event )
                    local value = trim( textctrl_rulename:GetValue() )
                    rules_tbl[ k ].rulename = value
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
                    rules_tbl[ k ].command = value
                end
            )

            --// events - alibi nick
            checkbox_alibicheck:Connect( id_alibicheck + i, wx.wxEVT_COMMAND_CHECKBOX_CLICKED,
                function( event )
                    if checkbox_alibicheck:IsChecked() then
                        --// freshstuff version
                        local result
                        if cfg_tbl["freshstuff_version"] == true then
                            result = wx.wxID_YES
                        else
                            result = dialog.question( "Warning: Needs ptx_freshstuff_v0.7 or higher" ..
                                                         "\n\nThis warning appears only once if you accept." ..
                                                         "\n\nContinue?" )
                        end
                        if result == wx.wxID_YES then
                            if cfg_tbl["freshstuff_version"] == false then
                                save_cfg_freshstuff_value()
                            end
                            textctrl_alibinick:Enable( true )
                            textctrl_command:SetValue( "+announcerel" )
                            rules_tbl[ k ].alibicheck = true
                            rules_tbl[ k ].command = "+announcerel"
                            HandleChangeTab3( event )
                        else
                            checkbox_alibicheck:SetValue( false )
                        end
                    else
                        textctrl_alibinick:Disable()
                        textctrl_command:SetValue( "+addrel" )
                        rules_tbl[ k ].alibicheck = false
                        rules_tbl[ k ].command = "+addrel"
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
                    rules_tbl[ k ].alibinick = value
                end
            )

            --// events - category choice
            choicectrl_category:Connect( id_category + i, wx.wxEVT_COMMAND_CHOICE_SELECTED,
                function( event )
                    rules_tbl[ k ].category = choicectrl_category:GetStringSelection()
                    HandleChangeTab3( event )
                end
            )

            --// events - activate
            checkbox_activate:Connect( id_activate + i, wx.wxEVT_COMMAND_CHECKBOX_CLICKED,
                function( event )
                    if checkbox_activate:IsChecked() then
                        rules_tbl[ k ].active = true
                        checkbox_activate:SetForegroundColour( wx.wxColour( 0, 128, 0 ) )
                    else
                        rules_tbl[ k ].active = false
                        checkbox_activate:SetForegroundColour( wx.wxRED )
                    end
                    local id = treebook:GetSelection()

                    --// avoid to long rulename
                    local rulename = rules_tbl[ id + 1 ].rulename
                    if string.len(rulename) > 15 then
                        rulename = string.sub(rulename, 1, 15) .. ".."
                    end

                    if rules_tbl[ id + 1 ].active == true then
                        treebook:SetPageText( id, "" .. id + 1 .. ": " .. rulename .. " (on)" )
                    else
                        treebook:SetPageText( id, "" .. id + 1 .. ": " .. rulename .. " (off)" )
                    end
                    HandleChangeTab3( event )
                end
            )

            --// events - daydir
            checkbox_daydirscheme:Connect( id_daydirscheme + i, wx.wxEVT_COMMAND_CHECKBOX_CLICKED,
                function( event )
                    if checkbox_daydirscheme:IsChecked() then
                        checkbox_zeroday:Enable( true )
                        rules_tbl[ k ].daydirscheme = true
                    else
                        checkbox_zeroday:Disable()
                        rules_tbl[ k ].daydirscheme = false
                    end
                    HandleChangeTab3( event )
                end
            )

            checkbox_zeroday:Connect( id_zeroday + i, wx.wxEVT_COMMAND_CHECKBOX_CLICKED,
                function( event )
                    if checkbox_zeroday:IsChecked() then
                        rules_tbl[ k ].zeroday = true
                    else
                        rules_tbl[ k ].zeroday = false
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
                        rules_tbl[ k ].checkdirs = true
                    else
                        checkbox_checkdirsnfo:Disable()
                        checkbox_checkdirssfv:Disable()
                        rules_tbl[ k ].checkdirs = false
                    end
                    HandleChangeTab3( event )
                end
            )

            --// events - check dirs nfo
            checkbox_checkdirsnfo:Connect( id_checkdirsnfo + i, wx.wxEVT_COMMAND_CHECKBOX_CLICKED,
                function( event )
                    if checkbox_checkdirsnfo:IsChecked() then
                        rules_tbl[ k ].checkdirsnfo = true
                    else
                        rules_tbl[ k ].checkdirsnfo = false
                    end
                    HandleChangeTab3( event )
                end
            )

            --// events - check dirs sfv
            checkbox_checkdirssfv:Connect( id_checkdirssfv + i, wx.wxEVT_COMMAND_CHECKBOX_CLICKED,
                function( event )
                    if checkbox_checkdirssfv:IsChecked() then
                        rules_tbl[ k ].checkdirssfv = true
                    else
                        rules_tbl[ k ].checkdirssfv = false
                    end
                    HandleChangeTab3( event )
                end
            )

            --// events - check files
            checkbox_checkfiles:Connect( id_checkfiles + i, wx.wxEVT_COMMAND_CHECKBOX_CLICKED,
                function( event )
                    if checkbox_checkfiles:IsChecked() then
                        rules_tbl[ k ].checkfiles = true
                    else
                        rules_tbl[ k ].checkfiles = false
                    end
                    HandleChangeTab3( event )
                end
            )

            --// events - check age
            checkbox_checkage:Connect( id_checkage + i, wx.wxEVT_COMMAND_CHECKBOX_CLICKED,
                function( event )
                    if checkbox_checkage:IsChecked() then
                        rules_tbl[ k ].checkage = true
                        spinctrl_maxage:Enable( true )
                    else
                        rules_tbl[ k ].checkage = false
                        spinctrl_maxage:SetValue( 0 )
                        rules_tbl[ k ].maxage = 0
                        spinctrl_maxage:Disable()
                    end
                    HandleChangeTab3( event )
                end
            )

            --// events - maxage spin
            spinctrl_maxage:Connect( id_maxage + i, wx.wxEVT_COMMAND_TEXT_UPDATED,
                function( event )
                    rules_tbl[ k ].maxage = spinctrl_maxage:GetValue()
                    HandleChangeTab3( event )
                end
            )

            --// events - check spaces
            checkbox_checkspaces:Connect( id_checkspaces + i, wx.wxEVT_COMMAND_CHECKBOX_CLICKED,
                function( event )
                    if checkbox_checkspaces:IsChecked() then
                        rules_tbl[ k ].checkspaces = true
                    else
                        rules_tbl[ k ].checkspaces = false
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
                    rules_tbl[ k ].path = path
                end
            )

            dirpicker:Connect( id_dirpicker + i, wx.wxEVT_COMMAND_DIRPICKER_CHANGED,
                function( event )
                    local path = trim( dirpicker:GetPath():gsub( "\\", "/" ) )
                    dirpicker_path:SetValue( path )
                    log_broadcast( log_window, "Set announcing path to: '" .. path .. "'", "CYAN" )
                    rules_tbl[ k ].path = path
                    HandleChangeTab3( event )
                end
            )

            i = i + 1
        end
    end
    set_rules_values()
    log_broadcast( log_window, "Import data from: '" .. file_rules .. "'", "CYAN" )
end

-------------------------------------------------------------------------------------------------------------------------------------
--// Tab 4 //------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------

--// add new table entry to rules
local add_rule = function( rules_listbox, treebook, t )
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
        wx.wxSize( 290, 90 )
    )
    di:SetBackgroundColour( wx.wxColour( 255, 255, 255 ) )
    di:Centre( wx.wxBOTH )

    local dialog_rule_add_textctrl = wx.wxTextCtrl( di, id_textctrl_add_rule, "", wx.wxPoint( 25, 10 ), wx.wxSize( 230, 20 ),  wx.wxSUNKEN_BORDER + wx.wxTE_CENTRE ) -- + wx.wxTE_READONLY )
    dialog_rule_add_textctrl:SetBackgroundColour( wx.wxColour( 200, 200, 200 ) )
    dialog_rule_add_textctrl:SetMaxLength( 25 )

    local dialog_rule_add_button = wx.wxButton( di, id_button_add_rule, "OK", wx.wxPoint( 75, 36 ), wx.wxSize( 60, 20 ) )
    dialog_rule_add_button:Disable()
    dialog_rule_add_button:Connect( id_button_add_rule, wx.wxEVT_COMMAND_BUTTON_CLICKED,
        function( event )
            local value = trim( dialog_rule_add_textctrl:GetValue() ) or ""
            if value == "" then di:Destroy() end
            if table.hasValue( rules_tbl, value, "rulename" ) then
                local result = dialog.info( "Error: Rule name '" .. value .. "' already taken" )
            elseif need_save.rules or validate.empty_name( false ) or validate.unique_name( false ) then
                validate.rules( true, "Tab 4: " .. notebook:GetPageText( 3 ) )
            else
                t.rulename = value
                table.insert( rules_tbl, t )
                log_broadcast( log_window, "Added new Rule '#" .. #rules_tbl .. ": " .. rules_tbl[ #rules_tbl ].rulename .. "'", "CYAN" )
                save_changes( log_window, "rules" )
                rules_listbox:Set( sorted_rules_tbl() )
                treebook:Destroy()
                make_treebook_page( tab_3 )
                di:Destroy()
            end
        end
    )
    local dialog_rule_cancel_button = wx.wxButton( di, id_button_cancel_rule, "Cancel", wx.wxPoint( 145, 36 ), wx.wxSize( 60, 20 ) )
    dialog_rule_cancel_button:Connect( id_button_cancel_rule, wx.wxEVT_COMMAND_BUTTON_CLICKED, function( event ) di:Destroy() end
    )

    --// events - dialog_rule_add_textctrl
    dialog_rule_add_textctrl:Connect( id_textctrl_add_rule, wx.wxEVT_COMMAND_TEXT_UPDATED,
        function( event )
            local value = trim( dialog_rule_add_textctrl:GetValue() ) or ""
            local enabled = ( value ~= "" )
            dialog_rule_add_button:Enable( enabled )
        end
    )
    local result = di:ShowModal()
end

--// remove table entry from rules
local del_rule = function( rules_listbox, treebook )
    local selection = rules_listbox:GetSelection()
    if selection == -1 then
        local result = dialog.info( "Error: No rule selected" )
    elseif #rules_tbl == 1 then
        local result = dialog.info( "Error: The last rule can not be deleted." )
    elseif need_save.rules or validate.empty_name( false ) or validate.unique_name( false ) then
        validate.rules( true, "Tab 4: " .. notebook:GetPageText( 3 ) )
    else
        local nr, name = parse_listbox_selection( rules_listbox )
        local id = table.getKey( rules_tbl, name, "rulename" )
        table.remove( rules_tbl, id )
        log_broadcast( log_window, "Deleted: Rule #" .. nr .. ": " .. name .. " | Rules list was renumbered!", "CYAN" )
        save_changes( log_window, "rules" )
        rules_listbox:Set( sorted_rules_tbl() )
        treebook:Destroy()
        make_treebook_page( tab_3 )
    end
end

--// clone table entry from rules
local clone_rule = function( rules_listbox, treebook )
    local selection = rules_listbox:GetSelection()
    if selection == -1 then
        local result = dialog.info( "Error: No rule selected" )
    elseif need_save.rules or validate.empty_name( false ) or validate.unique_name( false ) then
        validate.rules( true, "Tab 4: " .. notebook:GetPageText( 3 ) )
    else
        local nr, name = parse_listbox_selection( rules_listbox )
        local id = table.getKey( rules_tbl, name, "rulename" )
        add_rule( rules_listbox, treebook, table.copy( rules_tbl[ id ] ) )
    end
end

--// wxListBox
rules_listbox = wx.wxListBox(
    tab_4,
    id_rules_listbox,
    wx.wxPoint( 135, 5 ),
    wx.wxSize( 520, 330 ),
    sorted_rules_tbl(),
    wx.wxLB_SINGLE + wx.wxLB_HSCROLL + wx.wxSUNKEN_BORDER --  + wx.wxLB_SORT
)

--// Button - Add Rule
local rule_add_button = wx.wxButton( tab_4, id_rule_add, "Add", wx.wxPoint( 305, 338 ), wx.wxSize( 60, 20 ) )
rule_add_button:Connect( wx.wxID_ANY, wx.wxEVT_ENTER_WINDOW, function( event ) sb:SetStatusText( "Add a new rule", 0 ) end )
rule_add_button:Connect( wx.wxID_ANY, wx.wxEVT_LEAVE_WINDOW, function( event ) sb:SetStatusText( "", 0 ) end )
rule_add_button:Connect( id_rule_add, wx.wxEVT_COMMAND_BUTTON_CLICKED,
    function( event )
        add_rule( rules_listbox, treebook )
    end
)

--// Button - Delete Rule
local rule_del_button = wx.wxButton( tab_4, id_rule_del, "Delete", wx.wxPoint( 365, 338 ), wx.wxSize( 60, 20 ) )
rule_del_button:Connect( wx.wxID_ANY, wx.wxEVT_ENTER_WINDOW, function( event ) sb:SetStatusText( "Delete an existing rule", 0 ) end )
rule_del_button:Connect( wx.wxID_ANY, wx.wxEVT_LEAVE_WINDOW, function( event ) sb:SetStatusText( "", 0 ) end )
rule_del_button:Connect( id_rule_del, wx.wxEVT_COMMAND_BUTTON_CLICKED,
    function( event )
        del_rule( rules_listbox, treebook )
    end
)

--// Button - Clone Rule
local rule_clone_button = wx.wxButton( tab_4, id_rule_clone, "Clone", wx.wxPoint( 425, 338 ), wx.wxSize( 60, 20 ) )
rule_clone_button:Connect( wx.wxID_ANY, wx.wxEVT_ENTER_WINDOW, function( event ) sb:SetStatusText( "Clone an existing rule with all settings", 0 ) end )
rule_clone_button:Connect( wx.wxID_ANY, wx.wxEVT_LEAVE_WINDOW, function( event ) sb:SetStatusText( "", 0 ) end )
rule_clone_button:Connect( id_rule_clone, wx.wxEVT_COMMAND_BUTTON_CLICKED,
    function( event )
        clone_rule( rules_listbox, treebook )
    end
)

-------------------------------------------------------------------------------------------------------------------------------------
--// Tab 5 //------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------

--// import categories from "cfg/rules.lua" to "cfg/categories.lua"
local import_categories_tbl = function()
    if type( categories_tbl ) == "nil" then
        categories_tbl = { }
    end
    log_broadcast( log_window, "Import new categories from: '" .. file_rules .. "'", "CYAN" )
    for k, v in spairs( rules_tbl, "asc", "category" ) do
        if table.hasValue( categories_tbl, rules_tbl[ k ].category, "categoryname" ) == false then
            if rules_tbl[ k ].category ~= "" then
                categories_tbl[ #categories_tbl+1 ] = { categoryname = rules_tbl[ k ].category }
                log_broadcast( log_window, "Added new Category '#" .. #categories_tbl .. ": " .. rules_tbl[ k ].category .. "'", "CYAN" )
            end
        end
    end
    save_categories_values( log_window )
end
import_categories_tbl()

--// set categories values
local set_categories_values
set_categories_values = function()
    log_broadcast( log_window, "Import data from: '" .. file_categories .. "'", "CYAN" )
end
set_categories_values()

--// add new table entry to categories
local add_category = function( categories_listbox )
    local di = wx.wxDialog(
        frame,
        id_dialog_add_category,
        "Enter category name",
        wx.wxDefaultPosition,
        wx.wxSize( 290, 90 ) --,wx.wxFRAME_TOOL_WINDOW
    )
    di:SetBackgroundColour( wx.wxColour( 255, 255, 255 ) )

    local dialog_category_add_textctrl = wx.wxTextCtrl( di, id_textctrl_add_category, "", wx.wxPoint( 25, 10 ), wx.wxSize( 230, 20 ),  wx.wxSUNKEN_BORDER + wx.wxTE_CENTRE ) -- + wx.wxTE_READONLY )
    dialog_category_add_textctrl:SetBackgroundColour( wx.wxColour( 200, 200, 200 ) )
    dialog_category_add_textctrl:SetMaxLength( 25 )

    local dialog_category_add_button = wx.wxButton( di, id_button_add_category, "OK", wx.wxPoint( 75, 36 ), wx.wxSize( 60, 20 ) )
    dialog_category_add_button:Disable()
    dialog_category_add_button:Connect( id_button_add_category, wx.wxEVT_COMMAND_BUTTON_CLICKED,
        function( event )
            check_for_whitespaces_textctrl( frame, dialog_category_add_textctrl )
            local value = trim( dialog_category_add_textctrl:GetValue() ) or ""
            if value == "" then di:Destroy() end
            if table.hasValue( categories_tbl, value, "categoryname" ) then
                local result = dialog.info( "Error: Category name '" .. value .. "' already taken" )
            else
                table.insert( categories_tbl, { } )
                categories_tbl[ #categories_tbl ].categoryname = value
                categories_listbox:Set( sorted_categories_tbl() )
                log_broadcast( log_window, "Added new Category '#" .. #categories_tbl .. ": " .. categories_tbl[ #categories_tbl ].categoryname .. "'", "CYAN" )
                save_categories_values( log_window )
                treebook:Destroy()
                make_treebook_page( tab_3 )
                di:Destroy()
            end
        end
    )
    local dialog_category_cancel_button = wx.wxButton( di, id_button_cancel_category, "Cancel", wx.wxPoint( 145, 36 ), wx.wxSize( 60, 20 ) )
    dialog_category_cancel_button:Connect( id_button_cancel_category, wx.wxEVT_COMMAND_BUTTON_CLICKED,
        function( event )
            di:Destroy()
        end
    )
    local result = di:ShowModal()

    --// events - dialog_category_add_textctrl
    dialog_category_add_textctrl:Connect( id_textctrl_add_category, wx.wxEVT_COMMAND_TEXT_UPDATED,
        function( event )
            local value = trim( dialog_category_add_textctrl:GetValue() ) or ""
            local enabled = ( value ~= "" )
            dialog_category_add_button:Enable( enabled )
        end
    )
end

--// remove table entry from categories
local del_category = function( categories_listbox )
    local selection = categories_listbox:GetSelection()
    if selection == -1 then
        local result = dialog.info( "Error: No category selected" )
    else
        local nr, name = parse_listbox_selection( categories_listbox )
        local category = categories_tbl[ selection ][ "categoryname" ]
        if table.hasValue( rules_tbl, category, "categoryname", selection ) then
            local result = dialog.info( "Error: Selected category '" .. category .. "' is in use" )
        else
            local nr, name = parse_listbox_selection( categories_listbox )
            local id = table.getKey( categories_tbl, name, "categoryname" )
            table.remove( categories_tbl, id )
            log_broadcast( log_window, "Deleted: Category #" .. nr .. ": " .. category .. " | Category list was renumbered!", "CYAN" )
            save_categories_values( log_window )
            categories_listbox:Set( sorted_categories_tbl() )
            treebook:Destroy()
            make_treebook_page( tab_3 )
        end
    end
end

--// wxListBox
categories_listbox = wx.wxListBox(
    tab_5,
    id_categories_listbox,
    wx.wxPoint( 135, 5 ),
    wx.wxSize( 520, 330 ),
    sorted_categories_tbl(),
    wx.wxLB_SINGLE + wx.wxLB_HSCROLL + wx.wxSUNKEN_BORDER --  + wx.wxLB_SORT
)

--// Button - Add category
local category_add_button = wx.wxButton( tab_5, id_category_add, "Add", wx.wxPoint( 335, 338 ), wx.wxSize( 60, 20 ) )
category_add_button:Connect( wx.wxID_ANY, wx.wxEVT_ENTER_WINDOW, function( event ) sb:SetStatusText( "Add a new Freshstuff category", 0 ) end )
category_add_button:Connect( wx.wxID_ANY, wx.wxEVT_LEAVE_WINDOW, function( event ) sb:SetStatusText( "", 0 ) end )
category_add_button:Connect( id_category_add, wx.wxEVT_COMMAND_BUTTON_CLICKED,
    function( event )
        add_category( categories_listbox )
    end
)

--// Button - Delete category
local category_del_button = wx.wxButton( tab_5, id_category_del, "Delete", wx.wxPoint( 395, 338 ), wx.wxSize( 60, 20 ) )
category_del_button:Connect( wx.wxID_ANY, wx.wxEVT_ENTER_WINDOW, function( event ) sb:SetStatusText( "Delete an existing category", 0 ) end )
category_del_button:Connect( wx.wxID_ANY, wx.wxEVT_LEAVE_WINDOW, function( event ) sb:SetStatusText( "", 0 ) end )
category_del_button:Connect( id_category_del, wx.wxEVT_COMMAND_BUTTON_CLICKED,
    function( event )
        del_category( categories_listbox )
    end
)

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
    local path = wx.wxGetCwd()
    local mode, err = lfs_a( path .. "\\" .. file, "mode" )
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
local log_handler = function( file, parent, mode, button, count )
    if mode == "read" then
        if check_file( file ) then
            parent:Clear()
            button:Disable()
            local path = wx.wxGetCwd() .. "\\"

            local logsize = 0
            if ( count == "size" or count == "both" ) then
                logsize = util_formatbytes( wx.wxFileSize( path .. file ) or 0 )
            end

            wx.wxCopyFile( path .. file, path .. LOG_PATH .."tmp_file.txt", true )
            local f = io.open( path .. LOG_PATH .. "tmp_file.txt", "r" )
            local content = f:read( "*a" )
            local i = 0
            if ( count == "rows" or count == "both" ) then
                for line in io.lines( path .. LOG_PATH .. "tmp_file.txt" ) do i = i + 1 end
                f:close()
            else
                f:close()
            end
            wx.wxRemoveFile( path .. LOG_PATH .. "tmp_file.txt" )
            log_broadcast( log_window, "Reading text from: '" .. file .. "'", "CYAN" )
            --wx.wxSleep( 1 )
            parent:Clear()
            if content == "" then
                parent:AppendText( "\n\n\n\n\n\n\n\n\n\t\t\t\t\t\t      Logfile is Empty" )
            else
                parent:AppendText( content )
                if ( count == "rows" or count == "both" ) then parent:AppendText( "\n\nAmount of releases: " .. i ) end
                if ( count == "size" or count == "both" ) then parent:AppendText( "\n\nSize of logfile: " .. logsize ) end
            end
            local al = parent:GetNumberOfLines()
            parent:ScrollLines( al + 1 )
            button:Enable( true )
        else
            parent:Clear()
            parent:WriteText( "\n\n\n\n\n\n\n\n\n\t     Error while reading text from: '" .. file .. "', file not found, created new one." )
            log_broadcast( log_window, "Error while reading text from: '" .. file .. "', file not found, created new one.", "CYAN" )
        end
    end
    if mode == "clean" then
        if check_file( file ) then
            local f = io.open( file, "w" )
            f:close()
            parent:Clear()
            parent:WriteText( "\n\n\n\n\n\n\n\n\n\t\t\t\t\t    Cleaning file: '" .. file .. "'" )
            log_broadcast( log_window, "Cleaning file: '" .. file .. "'", "CYAN" )
        else
            parent:Clear()
            parent:WriteText( "\n\n\n\n\n\n\n\n\n\t     Error while cleaning text from: '" .. file .. "', file not found, created new one." )
            log_broadcast( log_window, "Error while cleaning text from: '" .. file .. "', file not found, created new one.", "CYAN" )
        end
    end
end

--// border - logfile.txt
control = wx.wxStaticBox( tab_6, wx.wxID_ANY, "logfile.txt", wx.wxPoint( 132, 278 ), wx.wxSize( 161, 40 ) )

--// button - logfile load
local button_load_logfile = wx.wxButton( tab_6, id_button_load_logfile, "Load", wx.wxPoint( 140, 294 ), wx.wxSize( 70, 20 ) )
button_load_logfile:Connect( wx.wxID_ANY, wx.wxEVT_ENTER_WINDOW, function( event ) sb:SetStatusText( "Load 'logfile.txt'", 0 ) end )
button_load_logfile:Connect( wx.wxID_ANY, wx.wxEVT_LEAVE_WINDOW, function( event ) sb:SetStatusText( "", 0 ) end )
button_load_logfile:Connect( id_button_load_logfile, wx.wxEVT_COMMAND_BUTTON_CLICKED,
function( event )
    log_handler( file_logfile, logfile_window, "read", button_load_logfile, "size" )
end )

--// button - logfile clear
local button_clear_logfile = wx.wxButton( tab_6, id_button_clear_logfile, "Clear", wx.wxPoint( 215, 294 ), wx.wxSize( 70, 20 ) )
button_clear_logfile:Connect( wx.wxID_ANY, wx.wxEVT_ENTER_WINDOW, function( event ) sb:SetStatusText( "Clear 'logfile.txt'", 0 ) end )
button_clear_logfile:Connect( wx.wxID_ANY, wx.wxEVT_LEAVE_WINDOW, function( event ) sb:SetStatusText( "", 0 ) end )
button_clear_logfile:Connect( id_button_clear_logfile, wx.wxEVT_COMMAND_BUTTON_CLICKED,
function( event )
    log_handler( file_logfile, logfile_window, "clean", button_clear_logfile )
    set_logfilesize( control_logsize_log_sensor, control_logsize_ann_sensor, control_logsize_exc_sensor )
end )

--// border - logfile size - logfile.txt
control = wx.wxStaticBox( tab_6, wx.wxID_ANY, "Filesize", wx.wxPoint( 132, 321 ), wx.wxSize( 161, 37 ) )

--// gauge - logfile.txt
control_logsize_log_sensor = wx.wxGauge( tab_6, wx.wxID_ANY, 6291456, wx.wxPoint( 140, 337 ), wx.wxSize( 145, 16 ), wx.wxGA_HORIZONTAL )
control_logsize_log_sensor:SetRange( cfg_tbl[ "logfilesize" ] )
control_logsize_log_sensor:SetValue( select( 1, get_logfilesize() ) )


--// border - announced.txt
control = wx.wxStaticBox( tab_6, wx.wxID_ANY, "announced.txt", wx.wxPoint( 312, 278 ), wx.wxSize( 161, 40 ) )

--// button - announced load
local button_load_announced = wx.wxButton( tab_6, id_button_load_announced, "Load", wx.wxPoint( 320, 294 ), wx.wxSize( 70, 20 ) )
button_load_announced:Connect( wx.wxID_ANY, wx.wxEVT_ENTER_WINDOW, function( event ) sb:SetStatusText( "Load 'announced.txt'", 0 ) end )
button_load_announced:Connect( wx.wxID_ANY, wx.wxEVT_LEAVE_WINDOW, function( event ) sb:SetStatusText( "", 0 ) end )
button_load_announced:Connect( id_button_load_announced, wx.wxEVT_COMMAND_BUTTON_CLICKED,
function( event )
    log_handler( file_announced, logfile_window, "read", button_load_announced, "both" )
end )

--// button - announced clear
local button_clear_announced = wx.wxButton( tab_6, id_button_clear_announced, "Clear", wx.wxPoint( 395, 294 ), wx.wxSize( 70, 20 ) )
button_clear_announced:Connect( wx.wxID_ANY, wx.wxEVT_ENTER_WINDOW, function( event ) sb:SetStatusText( "Clear 'announced.txt'", 0 ) end )
button_clear_announced:Connect( wx.wxID_ANY, wx.wxEVT_LEAVE_WINDOW, function( event ) sb:SetStatusText( "", 0 ) end )
button_clear_announced:Connect( id_button_clear_announced, wx.wxEVT_COMMAND_BUTTON_CLICKED,
function( event )
    log_handler( file_announced, logfile_window, "clean", button_clear_announced )
    set_logfilesize( control_logsize_log_sensor, control_logsize_ann_sensor, control_logsize_exc_sensor )
end )

--// border - logfile size - announced.txt
control = wx.wxStaticBox( tab_6, wx.wxID_ANY, "Filesize", wx.wxPoint( 312, 321 ), wx.wxSize( 161, 37 ) )

--// gauge - announced.txt
control_logsize_ann_sensor = wx.wxGauge( tab_6, wx.wxID_ANY, 6291456, wx.wxPoint( 320, 337 ), wx.wxSize( 145, 16 ), wx.wxGA_HORIZONTAL )
control_logsize_ann_sensor:SetRange( cfg_tbl[ "logfilesize" ] )
control_logsize_ann_sensor:SetValue( select( 2, get_logfilesize() ) )


--// border - exception.txt
control = wx.wxStaticBox( tab_6, wx.wxID_ANY, "exception.txt", wx.wxPoint( 492, 278 ), wx.wxSize( 161, 40 ) )

--// button - exception load
local button_load_exception = wx.wxButton( tab_6, id_button_load_exception, "Load", wx.wxPoint( 500, 294 ), wx.wxSize( 70, 20 ) )
button_load_exception:Connect( wx.wxID_ANY, wx.wxEVT_ENTER_WINDOW, function( event ) sb:SetStatusText( "Load 'exception.txt'", 0 ) end )
button_load_exception:Connect( wx.wxID_ANY, wx.wxEVT_LEAVE_WINDOW, function( event ) sb:SetStatusText( "", 0 ) end )
button_load_exception:Connect( id_button_load_exception, wx.wxEVT_COMMAND_BUTTON_CLICKED,
function( event )
    log_handler( file_exception, logfile_window, "read", button_load_exception, "size" )
end )

--// button - exception clean
local button_clear_exception = wx.wxButton( tab_6, id_button_clear_exception, "Clear", wx.wxPoint( 575, 294 ), wx.wxSize( 70, 20 ) )
button_clear_exception:Connect( wx.wxID_ANY, wx.wxEVT_ENTER_WINDOW, function( event ) sb:SetStatusText( "Clear 'exception.txt'", 0 ) end )
button_clear_exception:Connect( wx.wxID_ANY, wx.wxEVT_LEAVE_WINDOW, function( event ) sb:SetStatusText( "", 0 ) end )
button_clear_exception:Connect( id_button_clear_exception, wx.wxEVT_COMMAND_BUTTON_CLICKED,
function( event )
    log_handler( file_exception, logfile_window, "clean", button_clear_exception )
    set_logfilesize( control_logsize_log_sensor, control_logsize_ann_sensor, control_logsize_exc_sensor )
end )

--// border - logfile size - exception.txt
control = wx.wxStaticBox( tab_6, wx.wxID_ANY, "Filesize", wx.wxPoint( 492, 321 ), wx.wxSize( 161, 37 ) )

--// gauge - exception.txt
control_logsize_exc_sensor = wx.wxGauge( tab_6, wx.wxID_ANY, 6291456, wx.wxPoint( 500, 337 ), wx.wxSize( 145, 16 ), wx.wxGA_HORIZONTAL )
control_logsize_exc_sensor:SetRange( cfg_tbl[ "logfilesize" ] )
control_logsize_exc_sensor:SetValue( select( 3, get_logfilesize() ) )

-------------------------------------------------------------------------------------------------------------------------------------
--// MAIN //-------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------

local proc
local start_client = wx.wxButton()
local stop_client = wx.wxButton()

local start_process = function()
    local cmd = wx.wxGetCwd()  .. "\\" .. file_client_app

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

    if get_status( file_status, "hubconnect" ):find( "Fail" ) then
        log_broadcast( log_window, get_status( file_status, "hubconnect" ), "RED" )
        run = false
        kill_process( pid, log_window )
    elseif get_status( file_status, "hubconnect" ) == "" then
        local hubaddr = trim( control_hubaddress:GetValue() )
        local hubport = trim( control_hubport:GetValue() )
        log_broadcast( log_window, "Fail: failed to connect to hub: 'adcs://" .. hubaddr .. ":" .. hubport .. "'", "RED" )
        kill_process( pid, log_window )
        run = false
    else
        log_broadcast( log_window, get_status( file_status, "hubconnect" ), "GREEN" )
    end
    if run then
        if get_status( file_status, "hubhandshake" ):find( "Fail" ) or get_status( file_status, "hubhandshake" ) == "" then
            log_broadcast( log_window, get_status( file_status, "hubhandshake" ), "RED" )
            kill_process( pid, log_window )
            run = false
        else
            log_broadcast( log_window, get_status( file_status, "hubhandshake" ), "GREEN" )
            wx.wxMilliSleep( 100 )
        end
    end

    if run then
        if get_status( file_status, "hubkeyp" ):find( "Fail" ) or get_status( file_status, "hubkeyp" ) == "" then
            log_broadcast( log_window, get_status( file_status, "hubkeyp" ), "RED" )
            run = false
        else
            log_broadcast( log_window, get_status( file_status, "hubkeyp" ), "GREEN" )
            log_broadcast( log_window, "Sending support..." , "GREEN" )
            wx.wxMilliSleep( 100 )
        end
    end

    if run then
        if get_status( file_status, "support" ):find( "Fail" ) or get_status( file_status, "support" ) == "" then
            log_broadcast( log_window, get_status( file_status, "support" ), "RED" )
            run = false
        else
            log_broadcast( log_window, get_status( file_status, "support" ), "GREEN" )
            wx.wxMilliSleep( 100 )
        end
    end

    if run then
        if get_status( file_status, "hubsupport" ):find( "Fail" ) or get_status( file_status, "hubsupport" ) == "" then
            log_broadcast( log_window, get_status( file_status, "hubsupport" ), "RED" )
            run = false
        else
            log_broadcast( log_window, get_status( file_status, "hubsupport" ), "GREEN" )
            wx.wxMilliSleep( 100 )
        end
    end

    if run then
        if get_status( file_status, "hubosnr" ):find( "Fail" ) or get_status( file_status, "hubosnr" ) == "" then
            log_broadcast( log_window, get_status( file_status, "hubosnr" ), "RED" )
            run = false
        else
            log_broadcast( log_window, get_status( file_status, "hubosnr" ), "GREEN" )
            wx.wxMilliSleep( 100 )
        end
    end

    if run then
        if get_status( file_status, "hubsid" ):find( "Fail" ) or get_status( file_status, "hubsid" ) == "" then
            log_broadcast( log_window, get_status( file_status, "hubsid" ), "RED" )
            log_broadcast( log_window, "No SID provided, closing...", "RED" )
            run = false
        else
            log_broadcast( log_window, get_status( file_status, "hubsid" ), "GREEN" )
            log_broadcast( log_window, "Waiting for hub INF...", "GREEN" )
            wx.wxMilliSleep( 100 )
        end
    end

    if run then
        if get_status( file_status, "hubinf" ):find( "Fail" ) or get_status( file_status, "hubinf" ) == "" then
            log_broadcast( log_window, get_status( file_status, "hubinf" ), "RED" )
            log_broadcast( log_window, "No INF provided, closing...", "RED" )
            run = false
        else
            log_broadcast( log_window, get_status( file_status, "hubinf" ), "GREEN" )
            wx.wxMilliSleep( 100 )
        end
    end

    if run then
        if get_status( file_status, "owninf" ):find( "Fail" ) or get_status( file_status, "owninf" ) == "" then
            log_broadcast( log_window, get_status( file_status, "owninf" ), "RED" )
            run = false
        else
            log_broadcast( log_window, get_status( file_status, "owninf" ), "GREEN" )
            wx.wxMilliSleep( 100 )
        end
    end

    if run then
        if get_status( file_status, "passwd" ):find( "Fail" ) or get_status( file_status, "passwd" ) == "" then
            log_broadcast( log_window, get_status( file_status, "passwd" ), "RED" )
            log_broadcast( log_window, "No password request, closing...", "RED" )
            run = false
        else
            log_broadcast( log_window, get_status( file_status, "passwd" ), "GREEN" )
            wx.wxMilliSleep( 100 )
        end
    end

    if run then
        if get_status( file_status, "hubsalt" ):find( "Fail" ) or get_status( file_status, "hubsalt" ) == "" then
            log_broadcast( log_window, get_status( file_status, "hubsalt" ), "RED" )
            run = false
        else
            log_broadcast( log_window, get_status( file_status, "hubsalt" ), "GREEN" )
            wx.wxMilliSleep( 100 )
        end
    end

    if run then
        if get_status( file_status, "hublogin" ):find( "Fail" ) or get_status( file_status, "hublogin" ) == "" then
            log_broadcast( log_window, get_status( file_status, "hublogin" ), "RED" )
        else
            log_broadcast( log_window, "Login successful.", "WHITE" )
            log_broadcast( log_window, "Cipher: " .. get_status( file_status, "cipher" ), "WHITE" )
            frame:SetStatusText( "CONNECTED", 0 )
        end
    else
        start_client:Enable( true )
        stop_client:Disable()
        unprotect_hub_values( log_window, control_hubname, control_hubaddress, control_hubport, control_nickname, control_password, control_keyprint, control_tls,
                              control_bot_desc, control_bot_share, control_bot_slots, control_announceinterval, control_sleeptime, control_sockettimeout, control_logfilesize, checkbox_trayicon,
                              button_clear_logfile, button_clear_announced, button_clear_exception, rule_add_button, rule_del_button, rule_clone_button, rules_listbox, treebook, category_add_button, category_del_button, categories_listbox )

        pid = 0
        kill_process( pid, log_window )
    end

end

-------------------------------------------------------------------------------------------------------------------------------------

--// timer to refresh the filesize gauge on tab 6
timer = wx.wxTimer( panel )
panel:Connect( wx.wxEVT_TIMER,
function( event )
    set_logfilesize( control_logsize_log_sensor, control_logsize_ann_sensor, control_logsize_exc_sensor )
end )
local start_timer = function()
    timer:Start( refresh_timer )
    log_broadcast( log_window, "Refresh timer to calc size of logfiles startet, interval: " .. refresh_timer .. " milliseconds", "CYAN" )
end
local stop_timer = function()
    timer:Stop()
    log_broadcast( log_window, "Refresh timer to calc size of logfiles stopped", "CYAN" )
end

--// disable save button(s) (tab 1 + tab 2 + tab 3)
disable_save_buttons = function( page )
    if not page or page == "hub" then
        save_hub:Disable()
        need_save.cfg = false
    end
    if not page or page == "cfg" then
        save_cfg:Disable()
        need_save.hub = false
    end
    if not page or page == "rules" then
        save_rules:Disable()
        need_save.rules = false
    end
end

--// save changes (tab 1 + tab 2 + tab 3)
save_changes = function( log_window, page )
    if not page or page == "hub" then
        save_hub_values( log_window, control_hubname, control_hubaddress, control_hubport, control_nickname, control_password, control_keyprint )
        save_sslparams_values( log_window, control_tls )
    end
    if not page or page == "cfg" then
        save_cfg_values( log_window, control_bot_desc, control_bot_share, control_bot_slots, control_announceinterval, control_sleeptime, control_sockettimeout, control_logfilesize, checkbox_trayicon )
    end
    if not page or page == "rules" then
        save_rules_values( log_window )
    end
    disable_save_buttons( page )
end

--// undo changes (tab 1 + tab 2 + tab 3)
undo_changes = function( log_window, page )
    if not page or page == "hub" then
        set_hub_values( log_window, control_hubname, control_hubaddress, control_hubport, control_nickname, control_password, control_keyprint )
        set_sslparams_value( log_window, control_tls )
    end
    if not page or page == "cfg" then
        set_cfg_values( log_window, control_bot_desc, control_bot_share, control_bot_slots, control_announceinterval, control_sleeptime, control_sockettimeout, control_logfilesize, checkbox_trayicon )
    end
    if not page or page == "rules" then
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
        if not validate.changes( true ) then
            start_client:Disable()
            stop_client:Enable( true )
            protect_hub_values( log_window, control_hubname, control_hubaddress, control_hubport, control_nickname, control_password, control_keyprint, control_tls,
                                control_bot_desc, control_bot_share, control_bot_slots, control_announceinterval, control_sleeptime, control_sockettimeout, control_logfilesize, checkbox_trayicon,
                                button_clear_logfile, button_clear_announced, button_clear_exception, rule_add_button, rule_del_button, rule_clone_button, rules_listbox, treebook, category_add_button, category_del_button, categories_listbox )
            start_timer()
            start_process()
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
        start_client:Enable( true )
        stop_client:Disable()
        unprotect_hub_values( log_window, control_hubname, control_hubaddress, control_hubport, control_nickname, control_password, control_keyprint, control_tls,
                              control_bot_desc, control_bot_share, control_bot_slots, control_announceinterval, control_sleeptime, control_sockettimeout, control_logfilesize, checkbox_trayicon,
                              button_clear_logfile, button_clear_announced, button_clear_exception, rule_add_button, rule_del_button, rule_clone_button, rules_listbox, treebook, category_add_button, category_del_button, categories_listbox )

        stop_timer()
        kill_process( pid, log_window )
    end
)

-------------------------------------------------------------------------------------------------------------------------------------
--// MAIN LOOP //--------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------

--// start functions on start
undo_changes()
make_treebook_page( tab_3 )
log_broadcast( log_window, app_name .. " " .. _VERSION .. " ready.", "ORANGE" )
validate.cert( false )

--// main function
local main = function()
    local taskbar = add_taskbar( frame, checkbox_trayicon )

    --// event - destroy window
    frame:Connect( wx.wxID_ANY, wx.wxEVT_DESTROY,
        function( event )
            reset_status( file_status )
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
    frame:Connect( wx.wxID_ANY, wx.wxEVT_CLOSE_WINDOW,
        function( event )
            local empty_name, empty_cat, unique_name = validate.empty_name( false ), validate.empty_cat( false ), validate.unique_name( false )
            if empty_name or empty_cat or unique_name then
                if validate.rules( true, "Tab 4: " .. notebook:GetPageText( 3 ) ) then
                    return
                end
            end
            local quit = dialog.question( "Really quit?" )
            if quit == wx.wxID_YES then
                if need_save.cfg or need_save.hub or need_save.rules then
                    local dialog_question = "Save changes?\n"
                    local save = dialog.question( dialog_question )
                    if save == wx.wxID_YES then
                        save_changes( log_window )
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
    )

    --// event - menu - exit
    frame:Connect( wx.wxID_EXIT, wx.wxEVT_COMMAND_MENU_SELECTED,
        function( event )
            frame:Close( true )
            --frame:Destroy()
            --if taskbar then taskbar:delete() end
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