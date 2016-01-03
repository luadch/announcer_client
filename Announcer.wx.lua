--[[

    Luadch Announcer Client

        Author:         pulsar
        Members:        jrock
        License:        GNU GPLv3
        Environment:    wxLua-2.8.12.3-Lua-5.1.5-MSW-Unicode

        v0.8 [2015-]

            NEW Project member: jrock

            - update: "docs/LICENSE"  / by pulsar
                - changed from "GPLv2" to "GPLv3"

            - added: "lib/ressources/png/GPLv3_160x80.png"  / by pulsar
            - added: "lib/ressources/png/applogo_96x96.png"  / by pulsar
            - added: "cfg/categories.lua"  / by jrock

            - update: "Announcer.wx.lua"  / by pulsar
                - fixed small issue with blacklist/whitelist dialog window  / thx Sopor
                    - disable announcer window in background till popup is open
                - changed about window
                    - added new license
                    - added jrock as new project member
                - removed unneeded commented code parts
                - added optional parameter "both" for log_handler() function
                - recompiled "client.dll"
                - tab 3:
                    - renamed controlname of "checkbox_checkage"
                        - using "LOG_PATH" for "exception.txt"
                    - changed message dialog on "checkbox_alibicheck"
                - tab 4:
                    - add "Cancel" button to add rule message dialog
                - tab 5:
                    - add "Cancel" button to add categories message dialog

            - update: "Announcer.wx.lua" / by jrock
                - tab 3:
                    - changed "textctrl_category" input field into a "choicectrl_category" selection
                    - changed "choicectrl_category" to sort categories by name
                    - fixed "textctrl_command" and "textctrl_alibinick" to avoid whitespaces in fields after restart
                    - added "textctrl_checkage" to enable/disable "spinctrl_maxage"
                    - removed "choicectrl_maxage" to select max-age of release to be announced
                    - added "spinctrl_maxage" to input max-age in days of release to be announced
                    - fixed "del_folder()" function on whitelist/blacklist window if no TAG was selected
                    - changed "checkbox_alibicheck" to avoid wxMessageDialog to show up every time
                - tab 4:
                    - changed "del_rule()" function
                        - fix bug who delete btn caused a fatal error if no rule was selected
                    - changed "add_rule()" function
                        - check if rule name already exists
                        - fix bug where add_rule overwrites last rule on list
                    - added "rule_clone_button" button
                    - disable clone rule buttons while connected to hub as expected
                - tab 5 / tab 6:
                    - moved existing "tab_5" to "tab_6"
                - tab 5:
                    - added new tab for "categories" on tab position 5
                    - added "categories_listbox" element
                    - changed "categories_listbox" to sort categories by name
                    - added "import_categories_tbl()" function
                        - import categories from "cfg/rules.lua" to "cfg/categories.lua"
                    - added "add_category()" function
                        - check if category name contain whitespaces
                        - check if category name already exists
                    - added "del_category()" function
                        - check if category name is selected on a rule
                - tab 6:
                    - show filesize of log + error file

            - global:
                - added "inTable(table, value, field)" function to search in table
                    - table: table to search in
                    - value: value to search for
                    - field: optional field for multidimensional tables
                - added "spairs(table , order, field)" function to order a table
                    - table: table to search in
                    - order: asc | desc | custom funtion
                    - field: optional field for multidimensional tables
                - added "table.copy(tablename)" function to clone a table
                    - tablename: table to clone
                - added "check_for_whitespaces()" function to "core/announce.lua"

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
local rules_tbl
local pid = 0
local need_save = false
local need_save_rules = false
local rules_listbox

--// table lookups
local util_loadtable = util.loadtable
local util_savetable = util.savetable
local util_formatbytes = util.formatbytes

-------------------------------------------------------------------------------------------------------------------------------------
--// BASIC CONST //------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------

local app_name         = "Luadch Announcer Client"
local app_copyright    = "Copyright © by pulsar"
local app_license      = "License: GPLv3"

local app_width        = 800
local app_height       = 687

local notebook_width   = 795
local notebook_height  = 389

local log_width        = 795
local log_height       = 222

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
--local file_exception   =              "exception.txt"

local menu_title       = "Menu"
local menu_exit        = "Exit"
local menu_about       = "About"

-------------------------------------------------------------------------------------------------------------------------------------
--// IDS //--------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------

local id_counter = wx.wxID_HIGHEST + 1
local new_id = function()
    id_counter = id_counter + 1
    return id_counter
end

id_start_client                = new_id()
id_stop_client                 = new_id()
id_control_tls                 = new_id()
id_save_hub_cfg                = new_id()
id_save_cfg                    = new_id()

id_treebook                    = new_id()

id_activate                    = new_id()
id_rulename                    = new_id()
id_daydirscheme                = new_id()
id_zeroday                     = new_id()
id_maxage                      = new_id()

id_checkdirs                   = new_id()
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

id_save_button                 = new_id()

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
--// EVENT HANDLER //----------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------

local HandleEvents = function( event ) local name = event:GetEventObject():DynamicCast( "wxWindow" ):GetName() end

-------------------------------------------------------------------------------------------------------------------------------------
--// FONTS //------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------

local log_font = wx.wxFont( 8, wx.wxMODERN, wx.wxNORMAL, wx.wxNORMAL, false, "Lucida Console" )
local default_font = wx.wxFont( 8, wx.wxMODERN, wx.wxNORMAL, wx.wxNORMAL, false, "Verdana" )
local about_normal_1 = wx.wxFont( 9, wx.wxMODERN, wx.wxNORMAL, wx.wxNORMAL, false, "Verdana" )
local about_normal_2 = wx.wxFont( 10, wx.wxMODERN, wx.wxNORMAL, wx.wxNORMAL, false, "Verdana" )
local about_bold = wx.wxFont( 10, wx.wxMODERN, wx.wxNORMAL, wx.wxFONTWEIGHT_BOLD, false, "Verdana" )

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
local check_for_whitespaces_textctrl = function( parent, control )
    local s = control:GetValue()
    local new, n = string.gsub( s, " ", "" )
    if n ~= 0 then
        --// send dialog msg
        local di = wx.wxMessageDialog( parent, "Error: Whitespaces not allowed.\n\nRemoved whitespaces: " .. n, "INFO", wx.wxOK )
        local result = di:ShowModal()
        di:Destroy()
        control:SetValue( new )
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
    if n1 ~= 0 then
        local di = wx.wxMessageDialog( parent, 'Note: removed unneeded "adcs://".', "INFO", wx.wxOK )
        local result = di:ShowModal()
        di:Destroy()
    end
    control:SetValue( addy )
    if port then
        local di = wx.wxMessageDialog( parent, 'Found port: ' .. port, "INFO", wx.wxOK )
        local result = di:ShowModal()
        di:Destroy()
        control2:SetValue( port )
    end
    if keyp then
        local di = wx.wxMessageDialog( parent, 'Found keyprint:\n\n' .. keyp, "INFO", wx.wxOK )
        local result = di:ShowModal()
        di:Destroy()
        control3:SetValue( keyp )
    end
end

--// set values from "cfg/hub.lua"
local set_hub_values = function( log_window, control_hubname, control_hubaddress, control_hubport, control_nickname, control_password, control_keyprint )
    local hub_tbl = util_loadtable( file_hub )

    local hubname = hub_tbl[ "name" ] or "unknown"
    local hubaddr = hub_tbl[ "addr" ] or "unknown"
    local hubport = hub_tbl[ "port" ] or "unknown"
    local hubnick = hub_tbl[ "nick" ] or "unknown"
    local hubpass = hub_tbl[ "pass" ] or "unknown"
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
    local hub_tbl = util_loadtable( file_hub )

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
                                     control_bot_slots, control_announceinterval, control_sleeptime, control_sockettimeout,
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
    control_tls:Enable( false )
    --// tab_2
    control_bot_desc:Disable()
    control_bot_share:Disable()
    control_bot_slots:Disable()
    control_announceinterval:Disable()
    control_sleeptime:Disable()
    control_sockettimeout:Disable()
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
end

--// unprotect hub values "cfg/cfg.lua"
local unprotect_hub_values = function( log_window, control_hubname, control_hubaddress, control_hubport, control_nickname,
                                       control_password, control_keyprint, control_tls, control_bot_desc, control_bot_share,
                                       control_bot_slots, control_announceinterval, control_sleeptime, control_sockettimeout,
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
end

--// set values from "cfg/cfg.lua"
local set_cfg_values = function( log_window, control_bot_desc, control_bot_share, control_bot_slots, control_announceinterval,
                                 control_sleeptime, control_sockettimeout, checkbox_trayicon )

    local cfg_tbl = util_loadtable( file_cfg )

    local botdesc = cfg_tbl[ "botdesc" ] or "unknown"
    local botshare = cfg_tbl[ "botshare" ] or "unknown"
    local botslots = cfg_tbl[ "botslots" ] or "unknown"
    local announceinterval = cfg_tbl[ "announceinterval" ] or "unknown"
    local sleeptime = cfg_tbl[ "sleeptime" ] or "unknown"
    local sockettimeout = cfg_tbl[ "sockettimeout" ] or "unknown"
    local trayicon = cfg_tbl[ "trayicon" ] or false

    control_bot_desc:SetValue( botdesc )
    control_bot_share:SetValue( tostring( botshare ) )
    control_bot_slots:SetValue( tostring( botslots ) )
    control_announceinterval:SetValue( tostring( announceinterval ) )
    control_sleeptime:SetValue( tostring( sleeptime ) )
    control_sockettimeout:SetValue( tostring( sockettimeout ) )
    if cfg_tbl[ "trayicon" ] == true then checkbox_trayicon:SetValue( true ) else checkbox_trayicon:SetValue( false ) end

    log_broadcast( log_window, "Import data from: '" .. file_cfg .. "'", "CYAN" )
    need_save = false
end

--// save freshstuff version value to "cfg/cfg.lua"
local save_cfg_freshstuff_value = function()
    local cfg_tbl = util_loadtable( file_cfg )
    cfg_tbl[ "freshstuff_version" ] = true

    util_savetable( cfg_tbl, "cfg", file_cfg )
    log_broadcast( log_window, "Saved data to: '" .. file_cfg .. "'", "CYAN" )
end

--// save values to "cfg/cfg.lua"
local save_cfg_values = function( log_window, control_bot_desc, control_bot_share, control_bot_slots, control_announceinterval,
                                  control_sleeptime, control_sockettimeout, checkbox_trayicon )

    local cfg_tbl = util_loadtable( file_cfg )

    local botdesc = trim( control_bot_desc:GetValue() ) or ""
    local botshare = tonumber( trim( control_bot_share:GetValue() ) )
    local botslots = tonumber( trim( control_bot_slots:GetValue() ) )
    local announceinterval = tonumber( trim( control_announceinterval:GetValue() ) )
    local sleeptime = tonumber( trim( control_sleeptime:GetValue() ) )
    local sockettimeout = tonumber( trim( control_sockettimeout:GetValue() ) )
    local trayicon = checkbox_trayicon:GetValue()
    local freshstuff_version = cfg_tbl[ "freshstuff_version" ] or false

    cfg_tbl[ "botdesc" ] = botdesc
    cfg_tbl[ "botshare" ] = botshare
    cfg_tbl[ "botslots" ] = botslots
    cfg_tbl[ "announceinterval" ] = announceinterval
    cfg_tbl[ "sleeptime" ] = sleeptime
    cfg_tbl[ "sockettimeout" ] = sockettimeout
    cfg_tbl[ "trayicon" ] = trayicon
    cfg_tbl[ "freshstuff_version" ] = freshstuff_version

    util_savetable( cfg_tbl, "cfg", file_cfg )
    log_broadcast( log_window, "Saved data to: '" .. file_cfg .. "'", "CYAN" )
end

--// set values from "cfg/sslparams.lua"
local set_sslparams_value = function( log_window, control )
    local sslparams_tbl = util_loadtable( file_sslparams )
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
    local sslparams_tbl = util_loadtable( file_sslparams )
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
    local rules_arr = {}
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
    local categories_arr = {}
    for k,v in spairs(categories_tbl, 'asc', 'categoryname') do
       categories_arr[ #categories_arr+1 ] = "Category #" .. #categories_arr+1 .. ": " .. v['categoryname']
    end

    return categories_arr
end

--// get ordered categories table entrys as array
local list_categories_tbl = function()
    local categories_arr = {}
    for k,v in spairs(categories_tbl, 'asc', 'categoryname') do
       categories_arr[ #categories_arr+1 ] = v['categoryname']
    end

    return categories_arr
end

--// helper to check if value exists on table
function inTable(tbl, item, field)
    if(type(field) == 'string') then
        for key, value in pairs(tbl) do
            if value[field] == item then return true end
        end
    else
        for key, value in pairs(tbl) do
            if value == item then return key end
        end
    end
    return false
end

--// helper to clone a table
function table.copy(t)
  local u = { }
  for k, v in pairs(t) do u[k] = v end
  return setmetatable(u, getmetatable(t))
end

--// helper to order list by field
function spairs(tbl, order, field)
    local keys = {}
    for k in pairs(tbl) do keys[#keys+1] = k end

    if order then
        if('function' == type(order)) then
            table.sort( keys, function(a,b) return order(tbl, a, b) end )
        else
            if('asc' == order) then
                if('string' == type(field)) then
                    table.sort( keys, function(a, b) return string.lower(tbl[b][field]) > string.lower(tbl[a][field]) end )
                else
                    table.sort( keys, function(a, b) return string.lower(tbl[b]) > string.lower(tbl[a]) end )
                end
            end
            if('desc' == order) then
                if('string' == type(field)) then
                    table.sort( keys, function(a, b) return string.lower(tbl[b][field]) < string.lower(tbl[a][field]) end )
                else
                    table.sort( keys, function(a, b) return string.lower(tbl[b]) < string.lower(tbl[a]) end )
                end
            end
        end
    else
        table.sort(keys)
    end

    local i = 0
    return function()
        i = i + 1
        if keys[i] then
            return keys[i], tbl[keys[i]]
        end
    end
end

--// add taskbar (systemtrray)
local taskbar = nil
local add_taskbar = function( frame, checkbox_trayicon )
    if checkbox_trayicon:IsChecked() then
        taskbar = wx.wxTaskBarIcon()
        local icon = wx.wxIcon( file_icon, 3, 16, 16 )
        taskbar:SetIcon( icon, app_name .. " " .. _VERSION )

        local menu = wx.wxMenu()
        menu:Append( wx.wxID_ABOUT, menu_about )
        menu:Append( wx.wxID_EXIT, menu_exit )

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

-------------------------------------------------------------------------------------------------------------------------------------
--// MENUBAR //----------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------

local menu = wx.wxMenu()
menu:Append( wx.wxID_ABOUT, menu_about )
menu:Append( wx.wxID_EXIT, menu_exit )

local menu_bar = wx.wxMenuBar()
menu_bar:Append( menu, menu_title )

-------------------------------------------------------------------------------------------------------------------------------------
--// ICONS //------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------

--// icons for app titlebar and taskbar
local icons = wx.wxIconBundle()
icons:AddIcon( wx.wxIcon( file_icon, 3, 16, 16 ) )
icons:AddIcon( wx.wxIcon( file_icon, 3, 32, 32 ) )

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
--// FRAME //------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------

local frame = wx.wxFrame(

    wx.NULL,
    wx.wxID_ANY,
    app_name .. " " .. _VERSION,
    wx.wxPoint( 0, 0 ),
    wx.wxSize( app_width, app_height ),
    wx.wxMINIMIZE_BOX + wx.wxSYSTEM_MENU + wx.wxCAPTION + wx.wxCLOSE_BOX + wx.wxCLIP_CHILDREN -- + wx.wxFRAME_TOOL_WINDOW
)
frame:Centre( wx.wxBOTH )
frame:SetMenuBar( menu_bar )
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

-------------------------------------------------------------------------------------------------------------------------------------
--// LOG WINDOW //-------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------

local log_window = wx.wxTextCtrl( panel, wx.wxID_ANY, "", wx.wxPoint( 0, 418 ), wx.wxSize( log_width, log_height ),
                                  wx.wxTE_READONLY + wx.wxTE_MULTILINE + wx.wxTE_RICH + wx.wxSUNKEN_BORDER + wx.wxHSCROLL )

log_window:SetBackgroundColour( wx.wxColour( 0, 0, 0 ) )
log_window:SetFont( log_font )

-------------------------------------------------------------------------------------------------------------------------------------
--// Tab 1 //------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------

--// hubname
control = wx.wxStaticBox( tab_1, wx.wxID_ANY, "Hubname", wx.wxPoint( 5, 5 ), wx.wxSize( 775, 43 ) )
local control_hubname = wx.wxTextCtrl( tab_1, wx.wxID_ANY, "", wx.wxPoint( 20, 21 ), wx.wxSize( 745, 20 ),  wx.wxSUNKEN_BORDER )
control_hubname:SetBackgroundColour( wx.wxColour( 255, 255, 255 ) )
control_hubname:SetMaxLength( 70 )

--// hubaddress
control = wx.wxStaticBox( tab_1, wx.wxID_ANY, "Hubaddress (without adcs://)", wx.wxPoint( 5, 55 ), wx.wxSize( 692, 43 ) )
local control_hubaddress = wx.wxTextCtrl( tab_1, wx.wxID_ANY, "", wx.wxPoint( 20, 71 ), wx.wxSize( 662, 20 ),  wx.wxSUNKEN_BORDER )
control_hubaddress:SetBackgroundColour( wx.wxColour( 255, 255, 255 ) )
control_hubaddress:SetMaxLength( 170 )

--// port
control = wx.wxStaticBox( tab_1, wx.wxID_ANY, "Port", wx.wxPoint( 698, 55 ), wx.wxSize( 82, 43 ) )
local control_hubport = wx.wxTextCtrl( tab_1, wx.wxID_ANY, "", wx.wxPoint( 713, 71 ), wx.wxSize( 52, 20 ),  wx.wxSUNKEN_BORDER )
control_hubport:SetBackgroundColour( wx.wxColour( 255, 255, 255 ) )
control_hubport:SetMaxLength( 5 )

--// nickname
control = wx.wxStaticBox( tab_1, wx.wxID_ANY, "Nickname", wx.wxPoint( 5, 105 ), wx.wxSize( 775, 43 ) )
local control_nickname = wx.wxTextCtrl( tab_1, wx.wxID_ANY, "", wx.wxPoint( 20, 121 ), wx.wxSize( 745, 20 ),  wx.wxSUNKEN_BORDER )
control_nickname:SetBackgroundColour( wx.wxColour( 255, 255, 255 ) )
control_nickname:SetMaxLength( 70 )

--// password
control = wx.wxStaticBox( tab_1, wx.wxID_ANY, "Password", wx.wxPoint( 5, 155 ), wx.wxSize( 775, 43 ) )
local control_password = wx.wxTextCtrl( tab_1, wx.wxID_ANY, "", wx.wxPoint( 20, 171 ), wx.wxSize( 745, 20 ),  wx.wxSUNKEN_BORDER + wx.wxTE_PASSWORD )
control_password:SetBackgroundColour( wx.wxColour( 255, 255, 255 ) )
control_password:SetMaxLength( 70 )

--// keyprint
control = wx.wxStaticBox( tab_1, wx.wxID_ANY, "Hub Keyprint (optional)", wx.wxPoint( 5, 205 ), wx.wxSize( 775, 43 ) )
local control_keyprint = wx.wxTextCtrl( tab_1, wx.wxID_ANY, "", wx.wxPoint( 20, 221 ), wx.wxSize( 745, 20 ),  wx.wxSUNKEN_BORDER )
control_keyprint:SetBackgroundColour( wx.wxColour( 255, 255, 255 ) )
control_keyprint:SetMaxLength( 80 )

--//  tsl mode
local control_tls = wx.wxRadioBox( tab_1, id_control_tls, "TLS Mode", wx.wxPoint( 352, 260 ), wx.wxSize( 83, 60 ), { "TLSv1", "TLSv1.2" }, 1, wx.wxSUNKEN_BORDER )

--// button save
local save_hub_cfg = wx.wxButton( tab_1, id_save_hub_cfg, "Save", wx.wxPoint( 352, 332 ), wx.wxSize( 83, 25 ) )
save_hub_cfg:SetBackgroundColour( wx.wxColour( 200, 200, 200 ) )
save_hub_cfg:Connect( id_save_hub_cfg, wx.wxEVT_COMMAND_BUTTON_CLICKED,
    function( event )
        save_hub_cfg:Disable()
        save_hub_values( log_window, control_hubname, control_hubaddress, control_hubport, control_nickname, control_password, control_keyprint )
        save_sslparams_values( log_window, control_tls )
        need_save = false
    end
)

--// event - hubname
control_hubname:Connect( wx.wxID_ANY, wx.wxEVT_COMMAND_TEXT_UPDATED, function( event ) save_hub_cfg:Enable( true ) need_save = true addy_change = true end )

--// event - hubaddress
control_hubaddress:Connect( wx.wxID_ANY, wx.wxEVT_COMMAND_TEXT_UPDATED, function( event ) save_hub_cfg:Enable( true ) need_save = true end )
control_hubaddress:Connect( wx.wxID_ANY, wx.wxEVT_KILL_FOCUS,
    function( event )
        check_for_whitespaces_textctrl( frame, control_hubaddress )
        parse_address_input( frame, control_hubaddress, control_hubport, control_keyprint )
    end
)

--// event - port
control_hubport:Connect( wx.wxID_ANY, wx.wxEVT_COMMAND_TEXT_UPDATED, function( event ) save_hub_cfg:Enable( true ) need_save = true end )
control_hubport:Connect( wx.wxID_ANY, wx.wxEVT_KILL_FOCUS, function( event ) check_for_whitespaces_textctrl( frame, control_hubport ) end )

--// event - nickname
control_nickname:Connect( wx.wxID_ANY, wx.wxEVT_COMMAND_TEXT_UPDATED, function( event ) save_hub_cfg:Enable( true ) need_save = true end )
control_nickname:Connect( wx.wxID_ANY, wx.wxEVT_KILL_FOCUS, function( event ) check_for_whitespaces_textctrl( frame, control_nickname ) end )

--// event - password
control_password:Connect( wx.wxID_ANY, wx.wxEVT_COMMAND_TEXT_UPDATED, function( event ) save_hub_cfg:Enable( true ) need_save = true end )
control_password:Connect( wx.wxID_ANY, wx.wxEVT_KILL_FOCUS, function( event ) check_for_whitespaces_textctrl( frame, control_password ) end )

--// event - keyprint
control_keyprint:Connect( wx.wxID_ANY, wx.wxEVT_COMMAND_TEXT_UPDATED, function( event ) save_hub_cfg:Enable( true ) need_save = true end )
control_keyprint:Connect( wx.wxID_ANY, wx.wxEVT_KILL_FOCUS, function( event ) check_for_whitespaces_textctrl( frame, control_keyprint ) end )

--// event - tls mode
control_tls:Connect( wx.wxID_ANY, wx.wxEVT_COMMAND_RADIOBOX_SELECTED, function( event ) save_hub_cfg:Enable( true ) need_save = true end )

-------------------------------------------------------------------------------------------------------------------------------------
--// Tab 2 //------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------

--// bot description
control = wx.wxStaticBox( tab_2, wx.wxID_ANY, "Bot description", wx.wxPoint( 5, 5 ), wx.wxSize( 380, 43 ) )
local control_bot_desc = wx.wxTextCtrl( tab_2, wx.wxID_ANY, "", wx.wxPoint( 20, 21 ), wx.wxSize( 350, 20 ),  wx.wxSUNKEN_BORDER )
control_bot_desc:SetBackgroundColour( wx.wxColour( 255, 255, 255 ) )
control_bot_desc:SetMaxLength( 40 )

--//  bot slots
control = wx.wxStaticBox( tab_2, wx.wxID_ANY, "Bot slots (to bypass hub min slots rules)", wx.wxPoint( 5, 55 ), wx.wxSize( 380, 43 ) )
local control_bot_slots = wx.wxTextCtrl( tab_2, wx.wxID_ANY, "", wx.wxPoint( 20, 71 ), wx.wxSize( 350, 20 ),  wx.wxSUNKEN_BORDER )
control_bot_slots:SetBackgroundColour( wx.wxColour( 255, 255, 255 ) )
control_bot_slots:SetMaxLength( 2 )

--//  bot share
control = wx.wxStaticBox( tab_2, wx.wxID_ANY, "Bot share (in MBytes, to bypass hub min share rules)", wx.wxPoint( 5, 105 ), wx.wxSize( 380, 43 ) )
local control_bot_share = wx.wxTextCtrl( tab_2, wx.wxID_ANY, "", wx.wxPoint( 20, 121 ), wx.wxSize( 350, 20 ),  wx.wxSUNKEN_BORDER )
control_bot_share:SetBackgroundColour( wx.wxColour( 255, 255, 255 ) )
control_bot_share:SetMaxLength( 40 )

--// sleeptime
control = wx.wxStaticBox( tab_2, wx.wxID_ANY, "Sleeptime after connect (seconds)", wx.wxPoint( 400, 5 ), wx.wxSize( 380, 43 ) )
local control_sleeptime = wx.wxTextCtrl( tab_2, wx.wxID_ANY, "", wx.wxPoint( 415, 21 ), wx.wxSize( 350, 20 ),  wx.wxSUNKEN_BORDER )
control_sleeptime:SetBackgroundColour( wx.wxColour( 255, 255, 255 ) )
control_sleeptime:SetMaxLength( 6 )

--//  announce interval
control = wx.wxStaticBox( tab_2, wx.wxID_ANY, "Announce interval (seconds)", wx.wxPoint( 400, 55 ), wx.wxSize( 380, 43 ) )
local control_announceinterval = wx.wxTextCtrl( tab_2, wx.wxID_ANY, "", wx.wxPoint( 415, 71 ), wx.wxSize( 350, 20 ),  wx.wxSUNKEN_BORDER )
control_announceinterval:SetBackgroundColour( wx.wxColour( 255, 255, 255 ) )
control_announceinterval:SetMaxLength( 6 )

--// timeout
control = wx.wxStaticBox( tab_2, wx.wxID_ANY, "Socket Timeout (seconds)", wx.wxPoint( 400, 105 ), wx.wxSize( 380, 43 ) )
local control_sockettimeout = wx.wxTextCtrl( tab_2, wx.wxID_ANY, "", wx.wxPoint( 415, 121 ), wx.wxSize( 350, 20 ),  wx.wxSUNKEN_BORDER )
control_sockettimeout:SetBackgroundColour( wx.wxColour( 255, 255, 255 ) )
control_sockettimeout:SetMaxLength( 3 )

--// minimize to tray
local checkbox_trayicon = wx.wxCheckBox( tab_2, wx.wxID_ANY, "Minimize to tray", wx.wxPoint( 335, 165 ), wx.wxDefaultSize )

--// save button
local save_cfg = wx.wxButton()
save_cfg = wx.wxButton( tab_2, id_save_cfg, "Save", wx.wxPoint( 352, 190 ), wx.wxSize( 83, 25 ) )
save_cfg:SetBackgroundColour( wx.wxColour( 200, 200, 200 ) )
save_cfg:Connect( id_save_cfg, wx.wxEVT_COMMAND_BUTTON_CLICKED,
    function( event )
        save_cfg_values( log_window, control_bot_desc, control_bot_share, control_bot_slots, control_announceinterval, control_sleeptime, control_sockettimeout, checkbox_trayicon )
        save_cfg:Disable()
        need_save = false
    end
)

--// events - bot description
control_bot_desc:Connect( wx.wxID_ANY, wx.wxEVT_COMMAND_TEXT_UPDATED, function( event ) save_cfg:Enable( true ) need_save = true end )

--// events - bot share
control_bot_share:Connect( wx.wxID_ANY, wx.wxEVT_COMMAND_TEXT_UPDATED, function( event ) save_cfg:Enable( true ) need_save = true end )
control_bot_share:Connect( wx.wxID_ANY, wx.wxEVT_KILL_FOCUS, function( event ) check_for_whitespaces_textctrl( frame, control_bot_share ) end )

--// events - bot slots
control_bot_slots:Connect( wx.wxID_ANY, wx.wxEVT_COMMAND_TEXT_UPDATED, function( event ) save_cfg:Enable( true ) need_save = true end )
control_bot_slots:Connect( wx.wxID_ANY, wx.wxEVT_KILL_FOCUS, function( event ) check_for_whitespaces_textctrl( frame, control_bot_slots ) end )

--// events - announce interval
control_announceinterval:Connect( wx.wxID_ANY, wx.wxEVT_COMMAND_TEXT_UPDATED, function( event ) save_cfg:Enable( true ) need_save = true end )
control_announceinterval:Connect( wx.wxID_ANY, wx.wxEVT_KILL_FOCUS, function( event ) check_for_whitespaces_textctrl( frame, control_announceinterval ) end )

--// events - sleeptime
control_sleeptime:Connect( wx.wxID_ANY, wx.wxEVT_COMMAND_TEXT_UPDATED, function( event ) save_cfg:Enable( true ) need_save = true end )
control_sleeptime:Connect( wx.wxID_ANY, wx.wxEVT_KILL_FOCUS, function( event ) check_for_whitespaces_textctrl( frame, control_sleeptime ) end )

--// events - timeout
control_sockettimeout:Connect( wx.wxID_ANY, wx.wxEVT_COMMAND_TEXT_UPDATED, function( event ) save_cfg:Enable( true ) need_save = true end )
control_sockettimeout:Connect( wx.wxID_ANY, wx.wxEVT_KILL_FOCUS, function( event ) check_for_whitespaces_textctrl( frame, control_sockettimeout ) end )

--// events - minimize to tray
checkbox_trayicon:Connect( wx.wxID_ANY, wx.wxEVT_COMMAND_CHECKBOX_CLICKED,
    function( event )
        save_cfg:Enable( true )
        add_taskbar( frame, checkbox_trayicon )
        need_save = true
    end
)

-------------------------------------------------------------------------------------------------------------------------------------
--// Tab 3 //------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------

--// add new table entrys on app start (to prevent errors on update)
local check_new_rule_entrys = function()
    rules_tbl = util_loadtable( file_rules )
    local add_new = false
    for k, v in ipairs( rules_tbl ) do
        if type( v[ "checkdirs" ] ) == "nil" then v[ "checkdirs" ] = true add_new = true end
        if type( v[ "checkfiles" ] ) == "nil" then v[ "checkfiles" ] = false add_new = true end
        if type( v[ "alibinick" ] ) == "nil" then v[ "alibinick" ] = "DUMP" add_new = true end
        if type( v[ "alibicheck" ] ) == "nil" then v[ "alibicheck" ] = false add_new = true end
        if type( v[ "checkage" ] ) == "nil" then v[ "checkage" ] = false add_new = true end
        if type( v[ "maxage" ] ) == "nil" then v[ "maxage" ] = 0 add_new = true end
    end
    if add_new then
        save_rules_values( log_window )
    end
end
check_new_rule_entrys()

--// save button
local save_button = "save_button"
save_button = wx.wxButton()
save_button = wx.wxButton( tab_3, id_save_button, "Save", wx.wxPoint( 15, 330 ), wx.wxSize( 83, 25 ) )
save_button:SetBackgroundColour( wx.wxColour( 200, 200, 200 ) )
save_button:Connect( id_save_button, wx.wxEVT_COMMAND_BUTTON_CLICKED,
    function( event )
        save_button:Disable()
        save_hub_cfg:Disable()
        save_cfg:Disable()
        save_cfg_values( log_window, control_bot_desc, control_bot_share, control_bot_slots, control_announceinterval, control_sleeptime, control_sockettimeout, checkbox_trayicon )
        save_hub_values( log_window, control_hubname, control_hubaddress, control_hubport, control_nickname, control_password, control_keyprint )
        save_sslparams_values( log_window, control_tls )
        save_rules_values( log_window )
        need_save = false
        need_save_rules = false
        refresh_rulenames( rules_listbox )
    end
)
save_button:Disable()

--// treebook
local treebook, set_rules_values
local make_treebook_page = function( parent )
    treebook = wx.wxTreebook( parent,
                              wx.wxID_ANY,
                              wx.wxPoint( 0, 0 ),
                              wx.wxSize( 795, 320 ), -- 795, 335
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

            if rules_tbl[ k ].active == true then
                treebook:AddPage( panel, "" .. i .. ": " .. rules_tbl[ k ].rulename .. " (on)", first_page, i - 1 )
            else
                treebook:AddPage( panel, "" .. i .. ": " .. rules_tbl[ k ].rulename .. " (off)", first_page, i - 1 )
            end

            first_page = false

            --// activate
            local checkbox_activate = "checkbox_activate_" .. str
            checkbox_activate = wx.wxCheckBox( panel, id_activate + i, "Activate", wx.wxPoint( 5, 15 ), wx.wxDefaultSize )
            checkbox_activate:SetForegroundColour( wx.wxRED )
            if rules_tbl[ k ].active == true then
                checkbox_activate:SetValue( true )
                checkbox_activate:SetForegroundColour( wx.wxColour( 0, 128, 0 ) )
            else
                checkbox_activate:SetValue( false )
            end

            --// rulename
            local textctrl_rulename = "textctrl_rulename_" .. str
            textctrl_rulename = wx.wxTextCtrl( panel, id_rulename + i, "", wx.wxPoint( 80, 11 ), wx.wxSize( 180, 20 ),  wx.wxSUNKEN_BORDER + wx.wxTE_CENTRE ) -- + wx.wxTE_READONLY )
            textctrl_rulename:SetBackgroundColour( wx.wxColour( 255, 255, 255 ) )
            textctrl_rulename:SetMaxLength( 25 )
            textctrl_rulename:SetValue( rules_tbl[ k ].rulename )

            --// announcing path
            control = wx.wxStaticBox( panel, wx.wxID_ANY, "Announcing path", wx.wxPoint( 5, 40 ), wx.wxSize( 460, 43 ) )
            local dirpicker_path = "dirpicker_path_" .. str
            dirpicker_path = wx.wxTextCtrl( panel, id_dirpicker_path + i, "", wx.wxPoint( 20, 55 ), wx.wxSize( 350, 20 ), wx.wxTE_PROCESS_ENTER + wx.wxSUNKEN_BORDER )
            dirpicker_path:SetValue( rules_tbl[ k ].path )

            --// announcing path dirpicker
            local dirpicker = "dirpicker_" .. str
            dirpicker = wx.wxDirPickerCtrl(
                panel,
                id_dirpicker + i,
                wx.wxGetCwd(),
                "Choose announcing folder:",
                wx.wxPoint( 378, 55 ),
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

            --// alibi nick border
            control = wx.wxStaticBox( panel, wx.wxID_ANY, "", wx.wxPoint( 5, 141 ), wx.wxSize( 240, 67 ) )

            --// alibi nick
            local textctrl_alibinick = "textctrl_alibinick_" .. str
            textctrl_alibinick = wx.wxTextCtrl( panel, id_alibinick + i, "", wx.wxPoint( 20, 181 ), wx.wxSize( 210, 20 ),  wx.wxSUNKEN_BORDER )
            textctrl_alibinick:SetBackgroundColour( wx.wxColour( 255, 255, 255 ) )
            textctrl_alibinick:SetMaxLength( 30 )
            textctrl_alibinick:SetValue( rules_tbl[ k ].alibinick )

            --// alibi nick checkbox
            local checkbox_alibicheck = "checkbox_alibicheck_" .. str
            checkbox_alibicheck = wx.wxCheckBox( panel, id_alibicheck + i, "Use alternative nick", wx.wxPoint( 17, 158 ), wx.wxDefaultSize )
            if rules_tbl[ k ].alibicheck == true then
                checkbox_alibicheck:SetValue( true )
            else
                checkbox_alibicheck:SetValue( false )
                textctrl_alibinick:Enable( false )
            end

            --// category border
            control = wx.wxStaticBox( panel, wx.wxID_ANY, "Category", wx.wxPoint( 5, 216 ), wx.wxSize( 240, 43 ) )

            --// category choice
            local choicectrl_category = "choice_category_" .. str
            choicectrl_category = wx.wxChoice( panel, id_category + i, wx.wxPoint( 20, 232 ), wx.wxSize( 210, 20 ), list_categories_tbl() )
            choicectrl_category:Select( choicectrl_category:FindString( rules_tbl[ k ].category ) )

            -------------------------------------------------------------------------------------------------------------------------
            --// blacklist | whitelist border
            control = wx.wxStaticBox( panel, wx.wxID_ANY, "", wx.wxPoint( 260, 256 ), wx.wxSize( 205, 43 ) )

            --// Button - Blacklist
            local blacklist_button = "blacklist_button_" .. str
            blacklist_button = wx.wxButton( panel, id_blacklist_button + i, "Blacklist", wx.wxPoint( 270, 271 ), wx.wxSize( 90, 20 ) )
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
                            local s = blacklist_textctrl:GetValue()
                            local new, n = string.gsub( s, " ", "" )
                            if n ~= 0 then
                                --// send dialog msg
                                local mdi = wx.wxMessageDialog( frame, "Error: Whitespaces not allowed.\n\nRemoved whitespaces: " .. n, "INFO", wx.wxOK )
                                local result = mdi:ShowModal()
                                mdi:Destroy()
                                blacklist_textctrl:SetValue( new )
                            end
                        end
                    )

                    --// get blacklist table entrys as array
                    local sorted_skip_tbl = function()
                        local skip_lst = {}
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
                            local di = wx.wxMessageDialog( frame, "Error: please enter a name for the TAG", "INFO", wx.wxOK )
                            local result = di:ShowModal()
                            di:Destroy()
                        else
                            rules_tbl[ k ].blacklist[ folder ] = true
                            blacklist_textctrl:SetValue( "" )
                            blacklist_listbox:Set( sorted_skip_tbl() )
                            blacklist_listbox:SetSelection( 0 )
                            local di = wx.wxMessageDialog( frame, "The following TAG was added to table: " .. folder, "INFO", wx.wxOK )
                            local result = di:ShowModal()
                            di:Destroy()
                            log_broadcast( log_window, "The following TAG was added to Blacklist table: " .. folder, "CYAN" )
                        end
                    end

                    --// remove table entry from blacklist
                    local del_folder = function( blacklist_textctrl, blacklist_listbox )
                        if blacklist_listbox:GetSelection() == -1 then
                            local di = wx.wxMessageDialog( frame, "Error: No TAG selected", "INFO", wx.wxOK )
                            local result = di:ShowModal()
                            di:Destroy()
                            return
                        end
                        local folder = blacklist_listbox:GetString( blacklist_listbox:GetSelection() )
                        if folder then rules_tbl[ k ].blacklist[ folder ] = nil end
                        blacklist_textctrl:SetValue( "" )
                        blacklist_listbox:Set( sorted_skip_tbl() )
                        blacklist_listbox:SetSelection( 0 )
                        local di = wx.wxMessageDialog( frame, "The following TAG was removed from table: " .. folder, "INFO", wx.wxOK )
                        local result = di:ShowModal()
                        di:Destroy()
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
                            save_button:Enable( true )
                            need_save_rules = true
                        end
                    )

                    --// Button - Delete Folder
                    local blacklist_del_button = "blacklist_del_button_" .. str
                    blacklist_del_button = wx.wxButton( di, id_blacklist_del_button + i, "delete", wx.wxPoint( 20, 298 ), wx.wxSize( 169, 18 ) )
                    blacklist_del_button:Connect( id_blacklist_del_button + i, wx.wxEVT_COMMAND_BUTTON_CLICKED,
                        function( event )
                            del_folder( blacklist_textctrl, blacklist_listbox )
                            save_button:Enable( true )
                            need_save_rules = true
                        end
                    )

                    di:ShowModal()
                end
            )

            -------------------------------------------------------------------------------------------------------------------------
            --// Button - Whitelist
            local whitelist_button = "whitelist_button_" .. str
            whitelist_button = wx.wxButton( panel, id_whitelist_button + i, "Whitelist", wx.wxPoint( 365, 271 ), wx.wxSize( 90, 20 ) )
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
                    whitelist_textctrl:Connect( id_whitelist_textctrl + i, wx.wxEVT_KILL_FOCUS, --> check spaces
                        function( event )
                            local s = whitelist_textctrl:GetValue()
                            local new, n = string.gsub( s, " ", "" )
                            if n ~= 0 then
                                --// send dialog msg
                                local mdi = wx.wxMessageDialog( frame, "Error: Whitespaces not allowed.\n\nRemoved whitespaces: " .. n, "INFO", wx.wxOK )
                                local result = mdi:ShowModal()
                                mdi:Destroy()
                                whitelist_textctrl:SetValue( new )
                            end
                        end
                    )

                    --// get whitelist table entrys as array
                    local sorted_skip_tbl = function()
                        local skip_lst = {}
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
                            local di = wx.wxMessageDialog( frame, "Error: please enter a name for the TAG", "INFO", wx.wxOK )
                            local result = di:ShowModal()
                            di:Destroy()
                        else
                            rules_tbl[ k ].whitelist[ folder ] = true
                            whitelist_textctrl:SetValue( "" )
                            whitelist_listbox:Set( sorted_skip_tbl() )
                            whitelist_listbox:SetSelection( 0 )
                            local di = wx.wxMessageDialog( frame, "The following TAG was added to table: " .. folder, "INFO", wx.wxOK )
                            local result = di:ShowModal()
                            di:Destroy()
                            log_broadcast( log_window, "The following TAG was added to Whitelist table: " .. folder, "CYAN" )
                        end
                    end

                    --// remove table entry from whitelist
                    local del_folder = function( whitelist_textctrl, whitelist_listbox )
                        if whitelist_listbox:GetSelection() == -1 then
                            local di = wx.wxMessageDialog( frame, "Error: No TAG selected", "INFO", wx.wxOK )
                            local result = di:ShowModal()
                            di:Destroy()
                            return
                        end
                        local folder = whitelist_listbox:GetString( whitelist_listbox:GetSelection() )
                        if folder then rules_tbl[ k ].whitelist[ folder ] = nil end
                        whitelist_textctrl:SetValue( "" )
                        whitelist_listbox:Set( sorted_skip_tbl() )
                        whitelist_listbox:SetSelection( 0 )
                        local di = wx.wxMessageDialog( frame, "The following TAG was removed from table: " .. folder, "INFO", wx.wxOK )
                        local result = di:ShowModal()
                        di:Destroy()
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
                            save_button:Enable( true )
                            need_save_rules = true
                        end
                    )

                    --// Button - Delete Folder
                    local whitelist_del_button = "whitelist_del_button_" .. str
                    whitelist_del_button = wx.wxButton( di, id_whitelist_del_button + i, "delete", wx.wxPoint( 20, 298 ), wx.wxSize( 169, 18 ) )
                    whitelist_del_button:Connect( id_whitelist_del_button + i, wx.wxEVT_COMMAND_BUTTON_CLICKED,
                        function( event )
                            del_folder( whitelist_textctrl, whitelist_listbox )
                            save_button:Enable( true )
                            need_save_rules = true
                        end
                    )

                    di:ShowModal()
                end
            )

            -------------------------------------------------------------------------------------------------------------------------
            --// different checkboxes border
            control = wx.wxStaticBox( panel, wx.wxID_ANY, "", wx.wxPoint( 260, 91 ), wx.wxSize( 205, 157 ) )

            --// daydir scheme
            local checkbox_daydirscheme = "checkbox_daydirscheme_" .. str
            checkbox_daydirscheme = wx.wxCheckBox( panel, id_daydirscheme + i, "Use daydir scheme (mmdd)", wx.wxPoint( 270, 108 ), wx.wxDefaultSize )
            if rules_tbl[ k ].daydirscheme == true then checkbox_daydirscheme:SetValue( true ) else checkbox_daydirscheme:SetValue( false ) end

            --// daydir current day
            local checkbox_zeroday = "checkbox_zeroday_" .. str
            checkbox_zeroday = wx.wxCheckBox( panel, id_zeroday + i, "Check only current daydir", wx.wxPoint( 280, 131 ), wx.wxDefaultSize )
            if rules_tbl[ k ].zeroday == true then checkbox_zeroday:SetValue( true ) else checkbox_zeroday:SetValue( false ) end
            if rules_tbl[ k ].daydirscheme == true then checkbox_zeroday:Enable( true ) else checkbox_zeroday:Enable( false ) end

            --// check dirs
            local checkbox_checkdirs = "checkbox_checkdirs_" .. str
            checkbox_checkdirs = wx.wxCheckBox( panel, id_checkdirs + i, "Announce Directories", wx.wxPoint( 270, 158 ), wx.wxDefaultSize )
            if rules_tbl[ k ].checkdirs == true then checkbox_checkdirs:SetValue( true ) else checkbox_checkdirs:SetValue( false ) end

            --// check files
            local checkbox_checkfiles = "checkbox_checkfiles_" .. str
            checkbox_checkfiles = wx.wxCheckBox( panel, id_checkfiles + i, "Announce Files", wx.wxPoint( 270, 178 ), wx.wxDefaultSize )
            if rules_tbl[ k ].checkfiles == true then checkbox_checkfiles:SetValue( true ) else checkbox_checkfiles:SetValue( false ) end

            --// check age
            local checkbox_checkage = "checkbox_checkage_" .. str
            checkbox_checkage = wx.wxCheckBox( panel, id_checkage + i, "Max age of dirs/files (days)", wx.wxPoint( 270, 198 ), wx.wxDefaultSize )
            if rules_tbl[ k ].checkage == true then
                checkbox_checkage:SetValue( true )
            else
                checkbox_checkage:SetValue( false )
            end

            --// maxage spin
            local spinctrl_maxage = "spin_maxage_" .. str
            spinctrl_maxage = wx.wxSpinCtrl( panel, id_maxage + i, "", wx.wxPoint( 280, 218 ), wx.wxSize( 100, 20 ) )
            spinctrl_maxage:SetRange( 0, 999 )
            spinctrl_maxage:SetValue( rules_tbl[ k ].maxage )
            spinctrl_maxage:Enable( rules_tbl[ k ].checkage )

            --// events - rulename
            textctrl_rulename:Connect( id_rulename + i, wx.wxEVT_COMMAND_TEXT_UPDATED,
                function( event )
                    local id = treebook:GetSelection()
                    if rules_tbl[ id + 1 ].active == true then
                        treebook:SetPageText( id, "" .. id + 1 .. ": " .. rules_tbl[ id + 1 ].rulename .. " (on)" )
                    else
                        treebook:SetPageText( id, "" .. id + 1 .. ": " .. rules_tbl[ id + 1 ].rulename .. " (off)" )
                    end
                    save_button:Enable( true )
                    need_save_rules = true
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
                    save_button:Enable( true )
                    need_save_rules = true
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
                        local cfg_tbl = util_loadtable( file_cfg )
                        if cfg_tbl["freshstuff_version"] == true then
                            result = wx.wxID_YES
                        else
                            local di = wx.wxMessageDialog(

                                frame,
                                "Warning: Needs ptx_freshstuff_v0.7 or higher" ..
                                "\n\nThis warning appears only once if you accept." ..
                                "\n\nContinue?",
                                "INFO",
                                wx.wxYES_NO + wx.wxICON_QUESTION + wx.wxCENTRE
                            )
                            result = di:ShowModal()
                            di:Destroy()
                        end
                        if result == wx.wxID_YES then
                            if cfg_tbl["freshstuff_version"] == false then
                                save_cfg_freshstuff_value()
                            end
                            textctrl_alibinick:Enable( true )
                            textctrl_command:SetValue( "+announcerel" )
                            rules_tbl[ k ].alibicheck = true
                            rules_tbl[ k ].command = "+announcerel"
                            save_button:Enable( true )
                            need_save_rules = true
                        else
                            checkbox_alibicheck:SetValue( false )
                        end
                    else
                        textctrl_alibinick:Enable( false )
                        textctrl_command:SetValue( "+addrel" )
                        rules_tbl[ k ].alibicheck = false
                        rules_tbl[ k ].command = "+addrel"
                        save_button:Enable( true )
                        need_save_rules = true
                    end
                end
            )

            textctrl_alibinick:Connect( id_alibinick + i, wx.wxEVT_COMMAND_TEXT_UPDATED,
                function( event )
                    save_button:Enable( true )
                    need_save_rules = true
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
                    save_button:Enable( true )
                    need_save_rules = true
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
                    if rules_tbl[ id + 1 ].active == true then
                        treebook:SetPageText( id, "" .. id + 1 .. ": " .. rules_tbl[ id + 1 ].rulename .. " (on)" )
                    else
                        treebook:SetPageText( id, "" .. id + 1 .. ": " .. rules_tbl[ id + 1 ].rulename .. " (off)" )
                    end
                    save_button:Enable( true )
                    need_save_rules = true
                end
            )

            --// events - daydir
            checkbox_daydirscheme:Connect( id_daydirscheme + i, wx.wxEVT_COMMAND_CHECKBOX_CLICKED,
                function( event )
                    if checkbox_daydirscheme:IsChecked() then
                        checkbox_zeroday:Enable( true )
                        rules_tbl[ k ].daydirscheme = true
                    else
                        checkbox_zeroday:Enable( false )
                        rules_tbl[ k ].daydirscheme = false
                    end
                    save_button:Enable( true )
                    need_save_rules = true
                end
            )

            checkbox_zeroday:Connect( id_zeroday + i, wx.wxEVT_COMMAND_CHECKBOX_CLICKED,
                function( event )
                    if checkbox_zeroday:IsChecked() then
                        rules_tbl[ k ].zeroday = true
                    else
                        rules_tbl[ k ].zeroday = false
                    end
                    save_button:Enable( true )
                    need_save_rules = true
                end
            )

            --// events - check dirs
            checkbox_checkdirs:Connect( id_checkdirs + i, wx.wxEVT_COMMAND_CHECKBOX_CLICKED,
                function( event )
                    if checkbox_checkdirs:IsChecked() then
                        rules_tbl[ k ].checkdirs = true
                    else
                        rules_tbl[ k ].checkdirs = false
                    end
                    if checkbox_checkfiles:IsChecked() then
                        rules_tbl[ k ].checkfiles = true
                    else
                        rules_tbl[ k ].checkfiles = false
                    end
                    save_button:Enable( true )
                    need_save_rules = true
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
                    if checkbox_checkdirs:IsChecked() then
                        rules_tbl[ k ].checkdirs = true
                    else
                        rules_tbl[ k ].checkdirs = false
                    end
                    save_button:Enable( true )
                    need_save_rules = true
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
                        spinctrl_maxage:Enable( false )
                    end
                    save_button:Enable( true )
                    need_save_rules = true
                end
            )

            --// events - maxage spin
            spinctrl_maxage:Connect( id_maxage + i, wx.wxEVT_COMMAND_TEXT_UPDATED,
                function( event )
                    rules_tbl[ k ].maxage = spinctrl_maxage:GetValue()
                    save_button:Enable( true )
                    need_save_rules = true
                end
            )

            --// events - dirpicker
            dirpicker_path:Connect( id_dirpicker_path + i, wx.wxEVT_COMMAND_TEXT_UPDATED,
                function( event )
                    save_button:Enable( true )
                    need_save_rules = true
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
                    save_button:Enable( true )
                    need_save_rules = true
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
            [ "category" ] = "<your_freshstuff_category>",
            [ "command" ] = "+addrel",
            [ "daydirscheme" ] = false,
            [ "path" ] = "C:/your/path/to/announce",
            [ "rulename" ] = "<your_rule_name>",
            [ "whitelist" ] = { },
            [ "zeroday" ] = false,
            [ "checkdirs" ] = true,
            [ "checkfiles" ] = false,
            [ "checkage" ] = false,
            [ "maxage" ] = 0,

        }
    end

    local di = wx.wxDialog(

        frame,
        id_dialog_add_rule,
        "Enter rule name",
        wx.wxDefaultPosition,
        wx.wxSize( 290, 90 ) --,wx.wxFRAME_TOOL_WINDOW
    )
    di:SetBackgroundColour( wx.wxColour( 255, 255, 255 ) )

    local dialog_rule_add_textctrl = wx.wxTextCtrl( di, id_textctrl_add_rule, "", wx.wxPoint( 25, 10 ), wx.wxSize( 230, 20 ),  wx.wxSUNKEN_BORDER + wx.wxTE_CENTRE ) -- + wx.wxTE_READONLY )
    dialog_rule_add_textctrl:SetBackgroundColour( wx.wxColour( 200, 200, 200 ) )
    dialog_rule_add_textctrl:SetMaxLength( 25 )

    local dialog_rule_add_button = wx.wxButton( di, id_button_add_rule, "OK", wx.wxPoint( 75, 36 ), wx.wxSize( 60, 20 ) )
    dialog_rule_add_button:Connect( id_button_add_rule, wx.wxEVT_COMMAND_BUTTON_CLICKED,
        function( event )
            local value = trim( dialog_rule_add_textctrl:GetValue() ) or ""
            for k, v in ipairs( rules_tbl ) do
                if v[ "rulename" ] == value then
                    local di = wx.wxMessageDialog( frame, "Error: Rule name already taken", "INFO", wx.wxOK )
                    local result = di:ShowModal()
                    di:Destroy()
                    return --// function return to avoid multiple rules with same name
                end
            end
            table.insert( rules_tbl, t )
            rules_tbl[ #rules_tbl ].rulename = value
            rules_listbox:Set( sorted_rules_tbl() )
            save_rules_values( log_window )
            log_broadcast( log_window, "Added new Rule '#" .. #rules_tbl .. ": " .. rules_tbl[ #rules_tbl ].rulename .. "'", "CYAN" )
            treebook:Destroy()
            make_treebook_page( tab_3 )
            di:Destroy()
        end
    )
    local dialog_rule_cancel_button = wx.wxButton( di, id_button_cancel_rule, "Cancel", wx.wxPoint( 145, 36 ), wx.wxSize( 60, 20 ) )
    dialog_rule_cancel_button:Connect( id_button_cancel_rule, wx.wxEVT_COMMAND_BUTTON_CLICKED,
        function( event )
            di:Destroy()
        end
    )
    local result = di:ShowModal()
end

--// remove table entry from rules
local del_rule = function( rules_listbox, treebook )
    local selection = rules_listbox:GetSelection()
    if selection == -1 then
        local di = wx.wxMessageDialog( frame, "Error: No rule selected", "INFO", wx.wxOK )
        local result = di:ShowModal()
        di:Destroy()
    else
        local str = rules_listbox:GetStringSelection()
        local n1, n2 = string.find( str, "#(%d+)" )
        local n3, n4 = string.find( str, ":%s(.*)" )
        local nr = string.sub( str, n1 + 1, n2 )
        local rule = string.sub( str, n3 + 2, n4 )

        for k, v in ipairs( rules_tbl ) do
            if v[ "rulename" ] == rule then
                table.remove( rules_tbl, k )
                log_broadcast( log_window, "Deleted: Rule #" .. nr .. ": " .. rule .. " | Rules list was renumbered!", "CYAN" )
                save_rules_values( log_window )
                rules_listbox:Set( sorted_rules_tbl() )
                treebook:Destroy()
            end
        end
    end
end

--// clone table entry from rules
local clone_rule = function( rules_listbox, treebook )
    local selection = rules_listbox:GetSelection()
    if selection == -1 then
        local di = wx.wxMessageDialog( frame, "Error: No rule selected", "INFO", wx.wxOK )
        local result = di:ShowModal()
        di:Destroy()
    else
        local str = rules_listbox:GetStringSelection()
        local n1, n2 = string.find( str, "#(%d+)" )
        local n3, n4 = string.find( str, ":%s(.*)" )
        local nr = string.sub( str, n1 + 1, n2 )
        local rule = string.sub( str, n3 + 2, n4 )

        for k, v in ipairs( rules_tbl ) do
            if v[ "rulename" ] == rule then
                local t = table.copy(v)
                add_rule( rules_listbox, treebook, t )
            end
        end
    end
end

--// wxListBox
rules_listbox = wx.wxListBox(

    tab_4,
    id_rules_listbox,
    wx.wxPoint( 235, 5 ),
    wx.wxSize( 320, 330 ),
    sorted_rules_tbl(),
    wx.wxLB_SINGLE + wx.wxLB_HSCROLL + wx.wxSUNKEN_BORDER --  + wx.wxLB_SORT
)

--// Button - Add Rule
local rule_add_button = wx.wxButton( tab_4, id_rule_add, "Add", wx.wxPoint( 305, 338 ), wx.wxSize( 60, 20 ) )
rule_add_button:Connect( id_rule_add, wx.wxEVT_COMMAND_BUTTON_CLICKED,
    function( event )
        add_rule( rules_listbox, treebook )
    end
)

--// Button - Delete Rule
local rule_del_button = wx.wxButton( tab_4, id_rule_del, "Delete", wx.wxPoint( 365, 338 ), wx.wxSize( 60, 20 ) )
rule_del_button:Connect( id_rule_del, wx.wxEVT_COMMAND_BUTTON_CLICKED,
    function( event )
        del_rule( rules_listbox, treebook )
    end
)

--// Button - Clone Rule
local rule_clone_button = wx.wxButton( tab_4, id_rule_clone, "Clone", wx.wxPoint( 425, 338 ), wx.wxSize( 60, 20 ) )
rule_clone_button:Connect( id_rule_clone, wx.wxEVT_COMMAND_BUTTON_CLICKED,
    function( event )
        clone_rule( rules_listbox, treebook )
    end
)

-------------------------------------------------------------------------------------------------------------------------------------
--// Tab 5 //------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------

--// load categories form table
categories_tbl = util_loadtable( file_categories )

--// import categories from "cfg/rules.lua" to "cfg/categories.lua"
local import_categories_tbl
import_categories_tbl = function()
    if(type(categories_tbl) == "nil") then
        categories_tbl = { }
    end
    log_broadcast( log_window, "Import new categories from: '" .. file_rules .. "'", "CYAN" )
    for k, v in spairs( rules_tbl, 'asc', 'category' ) do
        if(inTable(categories_tbl, rules_tbl[ k ].category, 'categoryname') == false) then
            categories_tbl[ #categories_tbl+1 ] = { categoryname = rules_tbl[ k ].category }
            log_broadcast( log_window, "Added new Category '#" .. #categories_tbl .. ": " .. rules_tbl[ k ].category .. "'", "CYAN" )
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
    local t = {

        [ "categoryname" ] = "<your_Category_name>",

    }

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
    dialog_category_add_button:Connect( id_button_add_category, wx.wxEVT_COMMAND_BUTTON_CLICKED,
        function( event )
            -- check for whitespaces in rulename
            check_for_whitespaces_textctrl( frame, dialog_category_add_textctrl )
            local value = trim( dialog_category_add_textctrl:GetValue() ) or ""
            for k, v in ipairs( categories_tbl ) do
                if v[ "categoryname" ] == value then
                    local di = wx.wxMessageDialog( frame, "Error: Category name already taken", "INFO", wx.wxOK )
                    local result = di:ShowModal()
                    di:Destroy()
                    return --// function return to avoid multiple categories with same name
                end
            end
            table.insert( categories_tbl, t )
            categories_tbl[ #categories_tbl ].categoryname = value
            categories_listbox:Set( sorted_categories_tbl() )
            log_broadcast( log_window, "Added new Category '#" .. #categories_tbl .. ": " .. categories_tbl[ #categories_tbl ].categoryname .. "'", "CYAN" )
            save_categories_values( log_window )
            treebook:Destroy()
            make_treebook_page( tab_3 )
            di:Destroy()
        end
    )
    local dialog_category_cancel_button = wx.wxButton( di, id_button_cancel_category, "Cancel", wx.wxPoint( 145, 36 ), wx.wxSize( 60, 20 ) )
    dialog_category_cancel_button:Connect( id_button_cancel_category, wx.wxEVT_COMMAND_BUTTON_CLICKED,
        function( event )
            di:Destroy()
        end
    )
    local result = di:ShowModal()
end

--// remove table entry from categories
local del_category = function( categories_listbox )
    local selection = categories_listbox:GetSelection()

    if selection == -1 then
        local di = wx.wxMessageDialog( frame, "Error: No category selected", "INFO", wx.wxOK )
        local result = di:ShowModal()
        di:Destroy()
    else
        local str = categories_listbox:GetStringSelection()
        local n1, n2 = string.find( str, "#(%d+)" )
        local n3, n4 = string.find( str, ":%s(.*)" )
        local nr = string.sub( str, n1 + 1, n2 )
        local category = string.sub( str, n3 + 2, n4 )

        for k, v in ipairs( categories_tbl ) do
            if v[ "categoryname" ] == category then
                for rk, rv in ipairs( rules_tbl ) do
                    if rv[ "category" ] == category then
                        local di = wx.wxMessageDialog( frame, "Error: Selected category is in use", "INFO", wx.wxOK )
                        local result = di:ShowModal()
                        di:Destroy()
                        return --// function return to avoid removal of used category
                    end
                end
                table.remove( categories_tbl, k )
                log_broadcast( log_window, "Deleted: Category #" .. nr .. ": " .. category .. " | Category list was renumbered!", "CYAN" )
                save_categories_values( log_window )
                categories_listbox:Set( sorted_categories_tbl() )
                treebook:Destroy()
                make_treebook_page( tab_3 )
            end
        end
    end
end

--// wxListBox
categories_listbox = wx.wxListBox(

    tab_5,
    id_categories_listbox,
    wx.wxPoint( 235, 5 ),
    wx.wxSize( 320, 330 ),
    sorted_categories_tbl(),
    wx.wxLB_SINGLE + wx.wxLB_HSCROLL + wx.wxSUNKEN_BORDER --  + wx.wxLB_SORT
)

--// Button - Add category
local category_add_button = wx.wxButton( tab_5, id_category_add, "Add", wx.wxPoint( 335, 338 ), wx.wxSize( 60, 20 ) )
category_add_button:Connect( id_category_add, wx.wxEVT_COMMAND_BUTTON_CLICKED,
    function( event )
        add_category( categories_listbox )
    end
)

--// Button - Delete category
local category_del_button = wx.wxButton( tab_5, id_category_del, "Delete", wx.wxPoint( 395, 338 ), wx.wxSize( 60, 20 ) )
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
    wx.wxSize( 778, 310 ),
    wx.wxTE_READONLY + wx.wxTE_MULTILINE + wx.wxTE_RICH + wx.wxSUNKEN_BORDER + wx.wxHSCROLL
)
logfile_window:SetBackgroundColour( wx.wxColour( 255, 255, 255 ) )
logfile_window:SetFont( log_font )

--// check if file exists, if not then create new one
local check_file = function( file )
    local path = wx.wxGetCwd()
    local mode, err = lfs.attributes( path .. "\\" .. file, "mode" )
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
control = wx.wxStaticBox( tab_6, wx.wxID_ANY, "logfile.txt", wx.wxPoint( 132, 318 ), wx.wxSize( 161, 40 ) )

--// button - logfile load
local button_load_logfile = wx.wxButton( tab_6, id_button_load_logfile, "Load", wx.wxPoint( 140, 334 ), wx.wxSize( 70, 20 ) )
button_load_logfile:Connect( id_button_load_logfile, wx.wxEVT_COMMAND_BUTTON_CLICKED,
    function( event )
        log_handler( file_logfile, logfile_window, "read", button_load_logfile, "size" )
    end
)

--// button - logfile clean
local button_clear_logfile = wx.wxButton( tab_6, id_button_clear_logfile, "Clean", wx.wxPoint( 215, 334 ), wx.wxSize( 70, 20 ) )
button_clear_logfile:Connect( id_button_clear_logfile, wx.wxEVT_COMMAND_BUTTON_CLICKED,
    function( event )
        log_handler( file_logfile, logfile_window, "clean", button_clear_logfile )
    end
)

--// border - announced.txt
control = wx.wxStaticBox( tab_6, wx.wxID_ANY, "announced.txt", wx.wxPoint( 312, 318 ), wx.wxSize( 161, 40 ) )

--// button - announced load
local button_load_announced = wx.wxButton( tab_6, id_button_load_announced, "Load", wx.wxPoint( 320, 334 ), wx.wxSize( 70, 20 ) )
button_load_announced:Connect( id_button_load_announced, wx.wxEVT_COMMAND_BUTTON_CLICKED,
    function( event )
        log_handler( file_announced, logfile_window, "read", button_load_announced, "both" )
    end
)

--// button - announced clean
local button_clear_announced = wx.wxButton( tab_6, id_button_clear_announced, "Clean", wx.wxPoint( 395, 334 ), wx.wxSize( 70, 20 ) )
button_clear_announced:Connect( id_button_clear_announced, wx.wxEVT_COMMAND_BUTTON_CLICKED,
    function( event )
        log_handler( file_announced, logfile_window, "clean", button_clear_announced )
    end
)

--// border - exception.txt
control = wx.wxStaticBox( tab_6, wx.wxID_ANY, "exception.txt", wx.wxPoint( 492, 318 ), wx.wxSize( 161, 40 ) )

--// button - exception load
local button_load_exception = wx.wxButton( tab_6, id_button_load_exception, "Load", wx.wxPoint( 500, 334 ), wx.wxSize( 70, 20 ) )
button_load_exception:Connect( id_button_load_exception, wx.wxEVT_COMMAND_BUTTON_CLICKED,
    function( event )
        log_handler( file_exception, logfile_window, "read", button_load_exception, "size" )
    end
)

--// button - exception clean
local button_clear_exception = wx.wxButton( tab_6, id_button_clear_exception, "Clean", wx.wxPoint( 575, 334 ), wx.wxSize( 70, 20 ) )
button_clear_exception:Connect( id_button_clear_exception, wx.wxEVT_COMMAND_BUTTON_CLICKED,
    function( event )
        log_handler( file_exception, logfile_window, "clean", button_clear_exception )
    end
)

-------------------------------------------------------------------------------------------------------------------------------------
--// Panel //------------------------------------------------------------------------------------------------------------------------
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
        end
    else
        start_client:Enable( true )
        stop_client:Disable()
        unprotect_hub_values( log_window, control_hubname, control_hubaddress, control_hubport, control_nickname, control_password, control_keyprint, control_tls,
                              control_bot_desc, control_bot_share, control_bot_slots, control_announceinterval, control_sleeptime, control_sockettimeout, checkbox_trayicon,
                              button_clear_logfile, button_clear_announced, button_clear_exception, rule_add_button, rule_del_button, rule_clone_button, rules_listbox, treebook, category_add_button, category_del_button, categories_listbox )

        pid = 0
        kill_process( pid, log_window )
    end

end

-------------------------------------------------------------------------------------------------------------------------------------

--// disable all save buttons
local disable_save_buttons = function()
    save_hub_cfg:Disable()
    save_cfg:Disable()
    save_button:Disable()
end

--// save changes
local save_changes = function()
    save_cfg_values( log_window, control_bot_desc, control_bot_share, control_bot_slots, control_announceinterval, control_sleeptime, control_sockettimeout, checkbox_trayicon )
    save_hub_values( log_window, control_hubname, control_hubaddress, control_hubport, control_nickname, control_password, control_keyprint )
    save_sslparams_values( log_window, control_tls )
    save_rules_values( log_window )
    disable_save_buttons()
end

--// undo changes (tab 1 + tab 2)
local undo_changes = function()
    set_hub_values( log_window, control_hubname, control_hubaddress, control_hubport, control_nickname, control_password, control_keyprint )
    set_cfg_values( log_window, control_bot_desc, control_bot_share, control_bot_slots, control_announceinterval, control_sleeptime, control_sockettimeout, checkbox_trayicon )
    set_sslparams_value( log_window, control_tls )
    disable_save_buttons()
end

--// connect button
start_client = wx.wxButton( panel, id_start_client, "CONNECT", wx.wxPoint( 300, 1 ), wx.wxSize( 85, 28 ) )
start_client:SetBackgroundColour( wx.wxColour( 65,65,65 ) )
start_client:SetForegroundColour( wx.wxColour( 0,237,0 ) )
start_client:Connect( id_start_client, wx.wxEVT_COMMAND_BUTTON_CLICKED,
    function( event )
        local ready = true
        if need_save_rules then
            local di = wx.wxMessageDialog( frame, "Please save your changes first before connect!", "INFO", wx.wxOK + wx.wxCENTRE )
            local result = di:ShowModal()
            di:Destroy()
            ready = false
        end
        if ready then
            if need_save then
                need_save = false
                local di = wx.wxMessageDialog( frame, "Save changes?", "INFO", wx.wxYES_NO + wx.wxICON_QUESTION + wx.wxCENTRE )
                local result = di:ShowModal()
                di:Destroy()
                if result == wx.wxID_YES then
                    save_changes()
                else
                    undo_changes()
                end
            end
            start_client:Disable()
            stop_client:Enable( true )
            protect_hub_values( log_window, control_hubname, control_hubaddress, control_hubport, control_nickname, control_password, control_keyprint, control_tls,
                                control_bot_desc, control_bot_share, control_bot_slots, control_announceinterval, control_sleeptime, control_sockettimeout, checkbox_trayicon,
                                button_clear_logfile, button_clear_announced, button_clear_exception, rule_add_button, rule_del_button, rule_clone_button, rules_listbox, treebook, category_add_button, category_del_button, categories_listbox )

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
                              control_bot_desc, control_bot_share, control_bot_slots, control_announceinterval, control_sleeptime, control_sockettimeout, checkbox_trayicon,
                              button_clear_logfile, button_clear_announced, button_clear_exception, rule_add_button, rule_del_button, rule_clone_button, rules_listbox, treebook, category_add_button, category_del_button, categories_listbox )

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
            --// send dialog msg
            local di = wx.wxMessageDialog( frame, "Really quit?", "INFO", wx.wxYES_NO + wx.wxICON_QUESTION + wx.wxCENTRE )
            local result = di:ShowModal()
            di:Destroy()
            if result == wx.wxID_YES then
                if need_save or need_save_rules then
                    need_save = false
                    need_save_rules = false
                    --// send dialog msg
                    local di = wx.wxMessageDialog( frame, "Save changes?", "INFO", wx.wxYES_NO + wx.wxICON_QUESTION + wx.wxCENTRE )
                    local result = di:ShowModal()
                    di:Destroy()
                    if result == wx.wxID_YES then
                        save_changes()
                    else
                        --undo_changes()
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