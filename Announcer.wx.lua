--[[

    Luadch Announcer Client

        Author:         pulsar
        License:        GNU GPLv2
        Environment:    wxLua-2.8.12.3-Lua-5.1.5-MSW-Unicode

        v0.4 [2015-06-05]
            
            - improve cipher suites
                - required if luadch is using a cert with ECDSA
            - add checkbox "minimize to tray" to tab_2
                - minimize to tray is optional now
        
        v0.3 [2015-05-13]

            - typo fix
            - cleaning some parts of code
            - improved some log messages
            - fix problem with wxDirPickerCtrl
            - add trayicon
                - possibility to minimize app to tray

        v0.2 [2015-05-11]

            - added: "core/status.lua"
            - changes: "core/net.lua"
            - changes: "core/announce.lua"
            - changes: "core/log.lua"
            - changes: "cfg/rules.lua"
            - fix promblems with childprocess
            - fix problems with announce refresh
            - new log messages
            - possibility to set a rule name
            - smooth auto-scroll in log window
            - auto jump to the end of the logfile window after reading
            - password text will be echoed as asterisks
            - fix possible race conditions
                - disable clean bottons on connect (Logfiles tab)
                - disable tab_2 on connect
                - disable tab_3 on connect
                - disable tab_3 on connect
            - changes on wxDirPickerCtrl
                - added "make new folder button" to dir picker window
            - show amount of releases in logfile window
            - fix problem on press close, childprocess now closing too
            - optimize log output
            - renamed: "icon.dll" to "res1.dll"
            - add save button on tab_1
            - add file: "res2.dll" (tab icons)
            - set max length for all text controls

        v0.1 [2015-05-01]

            - based on announcer_bot_v0.02 by blastbeat
            - starting announcer_bot as asynchronous child process "client.dll"
            - exclude sslparams table from "cfg/cfg.lua" to "cfg/sslparams.lua"
            - changes: "core/init.lua"
                - add "dofile "cfg/sslparams.lua"" to initialize the new sslparams file
            - added: "core/util.lua"
                - table: serialize, load, save
            - add new app icons as ".dll" ressource file
            - rewrite "cfg/rules.lua"
            - rewrite "core/announce.lua"
            - rewrite "core/net.lua"

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

local wx = require( "wx" )
local util = require( "core/util" )
local lfs = require( "lfs" )

local control
local pid = 0
local util_loadtable = util.loadtable
local util_savetable = util.savetable

-------------------------------------------------------------------------------------------------------------------------------------
--// BASIC CONST //------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------

local app_name                 = "Luadch Announcer Client"
local app_version              = "v0.4"
local app_copyright            = "Copyright © by pulsar"
local app_license              = "License: GPLv2"

local app_width                = 800
local app_height               = 687

local notebook_width           = 795
local notebook_height          = 289

local log_width                = 795
local log_height               = 322

local file_cfg                 = "cfg/cfg.lua"
local file_hub                 = "cfg/hub.lua"
local file_rules               = "cfg/rules.lua"
local file_sslparams           = "cfg/sslparams.lua"
local file_status              = "core/status.lua"
local file_icon                = "res1.dll"
local file_icon_2              = "res2.dll"
local file_client_app          = "client.dll"
local file_logfile             = "log/logfile.txt"
local file_announced           = "log/announced.txt"
local file_exception           = "exception.txt"

local menu_title               = "Menu"
local menu_exit                = "Exit"
local menu_about               = "About"

-------------------------------------------------------------------------------------------------------------------------------------
--// IDS //--------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------

id_start_client                = 10
id_stop_client                 = 15
id_control_tls                 = 20
id_save_hub_cfg                = 22
id_save_cfg                    = 25

id_treebook                    = 40

id_activate                    = 200
id_rulename                    = 300
id_daydirscheme                = 400
id_zeroday                     = 500
id_command                     = 600
id_category                    = 700
id_dirpicker_path              = 800
id_dirpicker                   = 900

id_blacklist_button            = 1000
id_blacklist_textctrl          = 1100
id_blacklist_add_button        = 1200
id_blacklist_listbox           = 1300
id_blacklist_del_button        = 1400

id_whitelist_button            = 1500
id_whitelist_textctrl          = 1600
id_whitelist_add_button        = 1700
id_whitelist_listbox           = 1800
id_whitelist_del_button        = 1900

id_dirpicker_path              = 2000
id_dirpicker                   = 2100

id_save_button                 = 2200

id_rules_listbox               = 3000
id_rule_add                    = 3010
id_rule_del                    = 3020
id_dialog_add_rule             = 3030
id_textctrl_add_rule           = 3040
id_button_add_rule             = 3045

id_button_load_logfile         = 3050
id_button_clear_logfile        = 3060
id_button_load_announced       = 3070
id_button_clear_announced      = 3080
id_button_load_exception       = 3090
id_button_clear_exception      = 3100

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
--// DIFFERENT FUNCS //--------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------

--// about window
local show_about_window = function( frame )
    local di = wx.wxDialog(

        frame,
        wx.wxID_ANY,
        "About",
        wx.wxDefaultPosition,
        wx.wxSize( 320, 270 ),
        wx.wxSTAY_ON_TOP + wx.wxRESIZE_BORDER --wx.wxTHICK_FRAME --wx.wxCAPTION-- + wx.wxFRAME_TOOL_WINDOW
    )
    di:SetBackgroundColour( wx.wxColour( 255, 255, 255 ) )
    di:SetMinSize( wx.wxSize( 320, 270 ) )
    di:SetMaxSize( wx.wxSize( 320, 270 ) )

    -------------------------------------------------------------------------------------------------------------------------

    local icon = wx.wxIcon( file_icon, 3, 32, 32 )
    local logo = wx.wxBitmap()
    logo:CopyFromIcon( icon )
    local X, Y = logo:GetWidth(), logo:GetHeight()

    local control = wx.wxStaticBitmap( di, wx.wxID_ANY, wx.wxBitmap( logo ), wx.wxPoint( 120, 10 ), wx.wxSize( X, Y ) )
    control:Centre( wx.wxHORIZONTAL )

    -------------------------------------------------------------------------------------------------------------------------

    control = wx.wxStaticText(

        di,
        wx.wxID_ANY,
        app_name .. " " .. app_version,
        wx.wxPoint( 27, 45 )
    )
    control:SetFont( about_bold )
    control:Centre( wx.wxHORIZONTAL )

    control = wx.wxStaticText(

        di,
        wx.wxID_ANY,
        app_copyright,
        wx.wxPoint( 25, 65 )
    )
    control:SetFont( about_normal_2 )
    control:Centre( wx.wxHORIZONTAL )

    control = wx.wxStaticText(

        di,
        wx.wxID_ANY,
        app_license,
        wx.wxPoint( 25, 80 )
    )
    control:SetFont( about_normal_2 )
    control:Centre( wx.wxHORIZONTAL )

    -------------------------------------------------------------------------------------------------------------------------

    local panel = wx.wxPanel( di, wx.wxID_ANY, wx.wxPoint( 0, 115 ), wx.wxSize( 275, 90 ) )
    panel:SetBackgroundColour( wx.wxColour( 225, 225, 225 ) )
    panel:Centre( wx.wxHORIZONTAL )

    control = wx.wxStaticText(

        di,
        wx.wxID_ANY,
        "Greets fly out to:\n\nblastbeat, Sopor, Peccator, Demonlord\nand all the others for testing the client.\nThanks.",
        wx.wxPoint( 10, 125 )
    )
    control:SetFont( about_normal_1 )
    control:SetBackgroundColour( wx.wxColour( 225, 225, 225 ) )
    control:Centre( wx.wxHORIZONTAL )

    -------------------------------------------------------------------------------------------------------------------------

    local button_ok = wx.wxButton( di, wx.wxID_ANY, "CLOSE", wx.wxPoint( 100, 221 ), wx.wxSize( 70, 20 ) )
    button_ok:SetBackgroundColour( wx.wxColour( 255, 255, 255 ) )
    button_ok:Connect( wx.wxID_ANY, wx.wxEVT_COMMAND_BUTTON_CLICKED,
        function( event )
            di:Destroy()
        end
    )
    button_ok:Centre( wx.wxHORIZONTAL )

    -------------------------------------------------------------------------------------------------------------------------
    local result = di:ShowModal()
end

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
local protect_hub_values = function( log_window, control_hubname, control_hubaddress, control_hubport, control_nickname, control_password, control_keyprint, control_tls,
                                     control_bot_desc, control_bot_share, control_bot_slots, control_announceinterval, control_sleeptime, control_sockettimeout, checkbox_trayicon,
                                     button_clear_logfile, button_clear_announced, button_clear_exception, rule_add_button, rule_del_button, rules_listbox, treebook )

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
    button_clear_logfile:Disable()
    button_clear_announced:Disable()
    button_clear_exception:Disable()
    rule_add_button:Disable()
    rule_del_button:Disable()
    rules_listbox:Disable()
    --// tab_4
    treebook:Disable()

    log_broadcast( log_window, "Lock 'Tab 1' controls while connecting to the hub", "CYAN" )
    log_broadcast( log_window, "Lock 'Tab 2' controls while connecting to the hub", "CYAN" )
    log_broadcast( log_window, "Lock 'Tab 3' controls while connecting to the hub", "CYAN" )
    log_broadcast( log_window, "Lock 'Tab 4' controls while connecting to the hub", "CYAN" )
end

--// unprotect hub values "cfg/cfg.lua"
local unprotect_hub_values = function( log_window, control_hubname, control_hubaddress, control_hubport, control_nickname, control_password, control_keyprint, control_tls,
                                       control_bot_desc, control_bot_share, control_bot_slots, control_announceinterval, control_sleeptime, control_sockettimeout, checkbox_trayicon,
                                       button_clear_logfile, button_clear_announced, button_clear_exception, rule_add_button, rule_del_button, rules_listbox, treebook )

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
    button_clear_logfile:Enable( true )
    button_clear_announced:Enable( true )
    button_clear_exception:Enable( true )
    rule_add_button:Enable( true )
    rule_del_button:Enable( true )
    rules_listbox:Enable( true )
    --// tab_4
    treebook:Enable( true )

    log_broadcast( log_window, "Unlock 'Tab 1' controls", "CYAN" )
    log_broadcast( log_window, "Unlock 'Tab 2' controls", "CYAN" )
    log_broadcast( log_window, "Unlock 'Tab 3' controls", "CYAN" )
    log_broadcast( log_window, "Unlock 'Tab 4' controls", "CYAN" )
end

--// set values from "cfg/cfg.lua"
local set_cfg_values = function( log_window, control_bot_desc, control_bot_share, control_bot_slots, control_announceinterval, control_sleeptime, control_sockettimeout, checkbox_trayicon )
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
end

--// save values to "cfg/cfg.lua"
local save_cfg_values = function( log_window, control_bot_desc, control_bot_share, control_bot_slots, control_announceinterval, control_sleeptime, control_sockettimeout, checkbox_trayicon )
    local cfg_tbl = util_loadtable( file_cfg )

    local botdesc = trim( control_bot_desc:GetValue() ) or ""
    local botshare = tonumber( trim( control_bot_share:GetValue() ) )
    local botslots = tonumber( trim( control_bot_slots:GetValue() ) )
    local announceinterval = tonumber( trim( control_announceinterval:GetValue() ) )
    local sleeptime = tonumber( trim( control_sleeptime:GetValue() ) )
    local sockettimeout = tonumber( trim( control_sockettimeout:GetValue() ) )
    local trayicon = checkbox_trayicon:GetValue()

    cfg_tbl[ "botdesc" ] = botdesc
    cfg_tbl[ "botshare" ] = botshare
    cfg_tbl[ "botslots" ] = botslots
    cfg_tbl[ "announceinterval" ] = announceinterval
    cfg_tbl[ "sleeptime" ] = sleeptime
    cfg_tbl[ "sockettimeout" ] = sockettimeout
    cfg_tbl[ "trayicon" ] = trayicon

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
        --ciphers = "ECDHE-ECDSA-AES256-SHA:ECDHE-RSA-AES256-SHA:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES128-SHA",
        ciphers = "ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA:ECDHE-RSA-AES256-SHA:AES256-GCM-SHA384:AES256-SHA256:AES256-SHA:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES128-SHA:DHE-RSA-AES128-SHA:AES128-GCM-SHA256:AES128-SHA256:AES128-SHA",
    }

    local tls12_tbl = {
        mode = "client",
        key = "certs/serverkey.pem",
        certificate = "certs/servercert.pem",
        protocol = "tlsv1_2",
        --ciphers = "ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA256",
        ciphers = "ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA:ECDHE-RSA-AES256-SHA:AES256-GCM-SHA384:AES256-SHA256:AES256-SHA:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES128-SHA:DHE-RSA-AES128-SHA:AES128-GCM-SHA256:AES128-SHA256:AES128-SHA",
    }

    if mode == 0 then
        util_savetable( tls1_tbl, "sslparams", file_sslparams )
        log_broadcast( log_window, "Saved TLSv1 data to: '" .. file_sslparams .. "'", "CYAN" )
    else
        util_savetable( tls12_tbl, "sslparams", file_sslparams )
        log_broadcast( log_window, "Saved TLSv1.2 data to: '" .. file_sslparams .. "'", "CYAN" )
    end
end

--// get status from status.lua
local get_status = function( file, key )
    local tbl = util_loadtable( file )
    local value = tbl[ key ]
    return value
end

--// reset status entrys from status.lua
local reset_status = function( file )
    local tbl = {

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
    if ( pid > 0 ) then
        local exists = wx.wxProcess.Exists( pid )
        if exists then
            local ret = wx.wxProcess.Kill( pid, wx.wxSIGKILL, wx.wxKILL_CHILDREN )
            if ( ret ~= wx.wxKILL_OK ) then
                log_broadcast( log_window, "Unable to kill process: " .. pid .. "  |  code: " .. tostring( ret ), "RED" )
                log_broadcast( log_window, app_name .. " " .. app_version .. " ready.", "ORANGE" )
            else
                log_broadcast( log_window, "Announcer stopped. (Killed process: " .. pid .. ")", "WHITE" )
                log_broadcast( log_window, app_name .. " " .. app_version .. " ready.", "ORANGE" )
            end
        end
        pid = 0
    end
    reset_status( file_status )
end

--// add taskbar (systemtrray)
local taskbar = nil
local add_taskbar = function( frame, checkbox_trayicon )
    if checkbox_trayicon:IsChecked() then
        taskbar = wx.wxTaskBarIcon()
        local icon = wx.wxIcon( file_icon, 3, 16, 16 )
        taskbar:SetIcon( icon, app_name .. " " .. app_version )

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
            end
        )
        frame:Connect( wx.wxEVT_ICONIZE,
            function( event )
                local show = not frame:IsIconized()
                frame:Show( show )
                if show then
                    frame:Raise()
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
                        frame:Raise()
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
local tab_5_ico = wx.wxIcon( file_icon_2 .. ";4", wx.wxBITMAP_TYPE_ICO, 16, 16 )

local tab_1_bmp = wx.wxBitmap(); tab_1_bmp:CopyFromIcon( tab_1_ico )
local tab_2_bmp = wx.wxBitmap(); tab_2_bmp:CopyFromIcon( tab_2_ico )
local tab_3_bmp = wx.wxBitmap(); tab_3_bmp:CopyFromIcon( tab_3_ico )
local tab_4_bmp = wx.wxBitmap(); tab_4_bmp:CopyFromIcon( tab_4_ico )
local tab_5_bmp = wx.wxBitmap(); tab_5_bmp:CopyFromIcon( tab_5_ico )

local notebook_image_list = wx.wxImageList( 16, 16 )

local tab_1_img = notebook_image_list:Add( wx.wxBitmap( tab_1_bmp ) )
local tab_2_img = notebook_image_list:Add( wx.wxBitmap( tab_2_bmp ) )
local tab_3_img = notebook_image_list:Add( wx.wxBitmap( tab_3_bmp ) )
local tab_4_img = notebook_image_list:Add( wx.wxBitmap( tab_4_bmp ) )
local tab_5_img = notebook_image_list:Add( wx.wxBitmap( tab_5_bmp ) )

-------------------------------------------------------------------------------------------------------------------------------------
--// FRAME //------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------

local frame = wx.wxFrame(

    wx.NULL,
    wx.wxID_ANY,
    app_name .. " " .. app_version,
    wx.wxPoint( 0, 0 ),
    wx.wxSize( app_width, app_height ),
    wx.wxMINIMIZE_BOX + wx.wxSYSTEM_MENU + wx.wxCAPTION + wx.wxCLOSE_BOX + wx.wxCLIP_CHILDREN -- + wx.wxFRAME_TOOL_WINDOW
)
frame:Centre( wx.wxBOTH )
frame:SetMenuBar( menu_bar )
frame:SetIcons( icons )

local panel = wx.wxPanel( frame, wx.wxID_ANY, wx.wxPoint( 0, 0 ), wx.wxSize( app_width, app_height ) )
panel:SetBackgroundColour( wx.wxColour( 225, 225, 225 ) )

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

notebook:AddPage( tab_1, "Hub Account" )
notebook:AddPage( tab_2, "Announcer Config" )
notebook:AddPage( tab_3, "Announcer Rules" )
notebook:AddPage( tab_4, "Add/Remove Rules" )
notebook:AddPage( tab_5, "Logfiles" )

notebook:SetImageList( notebook_image_list )

notebook:SetPageImage( 0, tab_1_img )
notebook:SetPageImage( 1, tab_2_img )
notebook:SetPageImage( 2, tab_3_img )
notebook:SetPageImage( 3, tab_4_img )
notebook:SetPageImage( 4, tab_5_img )

-------------------------------------------------------------------------------------------------------------------------------------
--// LOG WINDOW //-------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------

local log_window = wx.wxTextCtrl( panel, wx.wxID_ANY, "", wx.wxPoint( 0, 318 ), wx.wxSize( log_width, log_height ),
                                  wx.wxTE_READONLY + wx.wxTE_MULTILINE + wx.wxTE_RICH + wx.wxSUNKEN_BORDER + wx.wxHSCROLL )

log_window:SetBackgroundColour( wx.wxColour( 0, 0, 0 ) )
log_window:SetFont( log_font )

log_broadcast( log_window, app_name .. " " .. app_version .. " ready.", "ORANGE" )

-------------------------------------------------------------------------------------------------------------------------------------
--// Tab 1 //------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------

control = wx.wxStaticBox( tab_1, wx.wxID_ANY, "Hubname", wx.wxPoint( 5, 5 ), wx.wxSize( 630, 43 ) )
local control_hubname = wx.wxTextCtrl( tab_1, wx.wxID_ANY, "", wx.wxPoint( 20, 21 ), wx.wxSize( 600, 20 ),  wx.wxSUNKEN_BORDER )
control_hubname:SetBackgroundColour( wx.wxColour( 255, 255, 255 ) )
control_hubname:SetMaxLength( 70 )

control = wx.wxStaticBox( tab_1, wx.wxID_ANY, "Hubaddress (without adcs://)", wx.wxPoint( 5, 55 ), wx.wxSize( 630, 43 ) )
local control_hubaddress = wx.wxTextCtrl( tab_1, wx.wxID_ANY, "", wx.wxPoint( 20, 71 ), wx.wxSize( 600, 20 ),  wx.wxSUNKEN_BORDER )
control_hubaddress:SetBackgroundColour( wx.wxColour( 255, 255, 255 ) )
control_hubaddress:SetMaxLength( 70 )

control = wx.wxStaticBox( tab_1, wx.wxID_ANY, "Port", wx.wxPoint( 650, 55 ), wx.wxSize( 130, 43 ) )
local control_hubport = wx.wxTextCtrl( tab_1, wx.wxID_ANY, "", wx.wxPoint( 665, 71 ), wx.wxSize( 100, 20 ),  wx.wxSUNKEN_BORDER )
control_hubport:SetBackgroundColour( wx.wxColour( 255, 255, 255 ) )
control_hubport:SetMaxLength( 5 )

control = wx.wxStaticBox( tab_1, wx.wxID_ANY, "Nickname", wx.wxPoint( 5, 105 ), wx.wxSize( 630, 43 ) )
local control_nickname = wx.wxTextCtrl( tab_1, wx.wxID_ANY, "", wx.wxPoint( 20, 121 ), wx.wxSize( 600, 20 ),  wx.wxSUNKEN_BORDER )
control_nickname:SetBackgroundColour( wx.wxColour( 255, 255, 255 ) )
control_nickname:SetMaxLength( 70 )

control = wx.wxStaticBox( tab_1, wx.wxID_ANY, "Password", wx.wxPoint( 5, 155 ), wx.wxSize( 630, 43 ) )
local control_password = wx.wxTextCtrl( tab_1, wx.wxID_ANY, "", wx.wxPoint( 20, 171 ), wx.wxSize( 600, 20 ),  wx.wxSUNKEN_BORDER + wx.wxTE_PASSWORD )
control_password:SetBackgroundColour( wx.wxColour( 255, 255, 255 ) )
control_password:SetMaxLength( 70 )

control = wx.wxStaticBox( tab_1, wx.wxID_ANY, "Hub Keyprint (required!)", wx.wxPoint( 5, 205 ), wx.wxSize( 630, 43 ) )
local control_keyprint = wx.wxTextCtrl( tab_1, wx.wxID_ANY, "", wx.wxPoint( 20, 221 ), wx.wxSize( 600, 20 ),  wx.wxSUNKEN_BORDER )
control_keyprint:SetBackgroundColour( wx.wxColour( 255, 255, 255 ) )
control_keyprint:SetMaxLength( 75 )

local control_tls = wx.wxRadioBox( tab_1, id_control_tls, "TLS Mode", wx.wxPoint( 650, 110 ), wx.wxSize( 83, 60 ), { "TLSv1", "TLSv1.2" }, 1, wx.wxSUNKEN_BORDER )

local save_hub_cfg = wx.wxButton( tab_1, id_save_hub_cfg, "Save", wx.wxPoint( 670, 205 ), wx.wxSize( 83, 25 ) )
save_hub_cfg:SetBackgroundColour( wx.wxColour( 200, 200, 200 ) )
save_hub_cfg:Connect( id_save_hub_cfg, wx.wxEVT_COMMAND_BUTTON_CLICKED,
    function( event )
        save_hub_cfg:Disable()
        save_hub_values( log_window, control_hubname, control_hubaddress, control_hubport, control_nickname, control_password, control_keyprint )
        save_sslparams_values( log_window, control_tls )
    end
)

--// events
control_hubname:Connect( wx.wxID_ANY, wx.wxEVT_COMMAND_TEXT_UPDATED, function( event ) save_hub_cfg:Enable( true ) end )

control_hubaddress:Connect( wx.wxID_ANY, wx.wxEVT_COMMAND_TEXT_UPDATED, function( event ) save_hub_cfg:Enable( true ) end )
control_hubaddress:Connect( wx.wxID_ANY, wx.wxEVT_KILL_FOCUS, function( event ) check_for_whitespaces_textctrl( frame, control_hubaddress ) end )

control_hubport:Connect( wx.wxID_ANY, wx.wxEVT_COMMAND_TEXT_UPDATED, function( event ) save_hub_cfg:Enable( true ) end )
control_hubport:Connect( wx.wxID_ANY, wx.wxEVT_KILL_FOCUS, function( event ) check_for_whitespaces_textctrl( frame, control_hubport ) end )

control_nickname:Connect( wx.wxID_ANY, wx.wxEVT_COMMAND_TEXT_UPDATED, function( event ) save_hub_cfg:Enable( true ) end )
control_nickname:Connect( wx.wxID_ANY, wx.wxEVT_KILL_FOCUS, function( event ) check_for_whitespaces_textctrl( frame, control_nickname ) end )

control_password:Connect( wx.wxID_ANY, wx.wxEVT_COMMAND_TEXT_UPDATED, function( event ) save_hub_cfg:Enable( true ) end )
control_password:Connect( wx.wxID_ANY, wx.wxEVT_KILL_FOCUS, function( event ) check_for_whitespaces_textctrl( frame, control_password ) end )

control_keyprint:Connect( wx.wxID_ANY, wx.wxEVT_COMMAND_TEXT_UPDATED, function( event ) save_hub_cfg:Enable( true ) end )
control_keyprint:Connect( wx.wxID_ANY, wx.wxEVT_KILL_FOCUS, function( event ) check_for_whitespaces_textctrl( frame, control_keyprint ) end )

control_tls:Connect( wx.wxID_ANY, wx.wxEVT_COMMAND_RADIOBOX_SELECTED, function( event ) save_hub_cfg:Enable( true ) end )

-------------------------------------------------------------------------------------------------------------------------------------
--// Tab 2 //------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------

control = wx.wxStaticBox( tab_2, wx.wxID_ANY, "Bot description", wx.wxPoint( 5, 5 ), wx.wxSize( 380, 43 ) )
local control_bot_desc = wx.wxTextCtrl( tab_2, wx.wxID_ANY, "", wx.wxPoint( 20, 21 ), wx.wxSize( 350, 20 ),  wx.wxSUNKEN_BORDER ) -- + wx.wxTE_CENTRE + wx.wxTE_READONLY )
control_bot_desc:SetBackgroundColour( wx.wxColour( 255, 255, 255 ) )
control_bot_desc:SetMaxLength( 40 )

control = wx.wxStaticBox( tab_2, wx.wxID_ANY, "Bot share (in MBytes, to bypass hub min share rules)", wx.wxPoint( 400, 5 ), wx.wxSize( 380, 43 ) )
local control_bot_share = wx.wxTextCtrl( tab_2, wx.wxID_ANY, "", wx.wxPoint( 415, 21 ), wx.wxSize( 350, 20 ),  wx.wxSUNKEN_BORDER ) -- + wx.wxTE_CENTRE + wx.wxTE_READONLY )
control_bot_share:SetBackgroundColour( wx.wxColour( 255, 255, 255 ) )
control_bot_share:SetMaxLength( 40 )

control = wx.wxStaticBox( tab_2, wx.wxID_ANY, "Bot slots (to bypass hub min slots rules)", wx.wxPoint( 5, 55 ), wx.wxSize( 380, 43 ) )
local control_bot_slots = wx.wxTextCtrl( tab_2, wx.wxID_ANY, "", wx.wxPoint( 20, 71 ), wx.wxSize( 350, 20 ),  wx.wxSUNKEN_BORDER ) -- + wx.wxTE_CENTRE + wx.wxTE_READONLY )
control_bot_slots:SetBackgroundColour( wx.wxColour( 255, 255, 255 ) )
control_bot_slots:SetMaxLength( 2 )

control = wx.wxStaticBox( tab_2, wx.wxID_ANY, "Announce interval (seconds)", wx.wxPoint( 400, 55 ), wx.wxSize( 380, 43 ) )
local control_announceinterval = wx.wxTextCtrl( tab_2, wx.wxID_ANY, "", wx.wxPoint( 415, 71 ), wx.wxSize( 350, 20 ),  wx.wxSUNKEN_BORDER ) -- + wx.wxTE_CENTRE + wx.wxTE_READONLY )
control_announceinterval:SetBackgroundColour( wx.wxColour( 255, 255, 255 ) )
control_announceinterval:SetMaxLength( 6 )

control = wx.wxStaticBox( tab_2, wx.wxID_ANY, "Sleeptime after connect (seconds)", wx.wxPoint( 5, 105 ), wx.wxSize( 380, 43 ) )
local control_sleeptime = wx.wxTextCtrl( tab_2, wx.wxID_ANY, "", wx.wxPoint( 20, 121 ), wx.wxSize( 350, 20 ),  wx.wxSUNKEN_BORDER ) -- + wx.wxTE_CENTRE + wx.wxTE_READONLY )
control_sleeptime:SetBackgroundColour( wx.wxColour( 255, 255, 255 ) )
control_sleeptime:SetMaxLength( 6 )

control = wx.wxStaticBox( tab_2, wx.wxID_ANY, "Socket Timeout (seconds)", wx.wxPoint( 400, 105 ), wx.wxSize( 380, 43 ) )
local control_sockettimeout = wx.wxTextCtrl( tab_2, wx.wxID_ANY, "", wx.wxPoint( 415, 121 ), wx.wxSize( 350, 20 ),  wx.wxSUNKEN_BORDER ) -- + wx.wxTE_CENTRE + wx.wxTE_READONLY )
control_sockettimeout:SetBackgroundColour( wx.wxColour( 255, 255, 255 ) )
control_sockettimeout:SetMaxLength( 3 )

local checkbox_trayicon = wx.wxCheckBox( tab_2, wx.wxID_ANY, "Minimize to tray", wx.wxPoint( 335, 165 ), wx.wxDefaultSize )


--// save button
local save_cfg = wx.wxButton()
save_cfg = wx.wxButton( tab_2, id_save_cfg, "Save", wx.wxPoint( 352, 200 ), wx.wxSize( 83, 25 ) )
save_cfg:SetBackgroundColour( wx.wxColour( 200, 200, 200 ) )
save_cfg:Connect( id_save_cfg, wx.wxEVT_COMMAND_BUTTON_CLICKED,
    function( event )
        save_cfg_values( log_window, control_bot_desc, control_bot_share, control_bot_slots, control_announceinterval, control_sleeptime, control_sockettimeout, checkbox_trayicon )
        save_cfg:Disable()
    end
)


--// events
control_bot_desc:Connect( wx.wxID_ANY, wx.wxEVT_COMMAND_TEXT_UPDATED, function( event ) save_cfg:Enable( true ) end )

control_bot_share:Connect( wx.wxID_ANY, wx.wxEVT_COMMAND_TEXT_UPDATED, function( event ) save_cfg:Enable( true ) end )
control_bot_share:Connect( wx.wxID_ANY, wx.wxEVT_KILL_FOCUS, function( event ) check_for_whitespaces_textctrl( frame, control_bot_share ) end )

control_bot_slots:Connect( wx.wxID_ANY, wx.wxEVT_COMMAND_TEXT_UPDATED, function( event ) save_cfg:Enable( true ) end )
control_bot_slots:Connect( wx.wxID_ANY, wx.wxEVT_KILL_FOCUS, function( event ) check_for_whitespaces_textctrl( frame, control_bot_slots ) end )

control_announceinterval:Connect( wx.wxID_ANY, wx.wxEVT_COMMAND_TEXT_UPDATED, function( event ) save_cfg:Enable( true ) end )
control_announceinterval:Connect( wx.wxID_ANY, wx.wxEVT_KILL_FOCUS, function( event ) check_for_whitespaces_textctrl( frame, control_announceinterval ) end )

control_sleeptime:Connect( wx.wxID_ANY, wx.wxEVT_COMMAND_TEXT_UPDATED, function( event ) save_cfg:Enable( true ) end )
control_sleeptime:Connect( wx.wxID_ANY, wx.wxEVT_KILL_FOCUS, function( event ) check_for_whitespaces_textctrl( frame, control_sleeptime ) end )

control_sockettimeout:Connect( wx.wxID_ANY, wx.wxEVT_COMMAND_TEXT_UPDATED, function( event ) save_cfg:Enable( true ) end )
control_sockettimeout:Connect( wx.wxID_ANY, wx.wxEVT_KILL_FOCUS, function( event ) check_for_whitespaces_textctrl( frame, control_sockettimeout ) end )

checkbox_trayicon:Connect( wx.wxID_ANY, wx.wxEVT_COMMAND_CHECKBOX_CLICKED,
    function( event )
        save_cfg:Enable( true )
        add_taskbar( frame, checkbox_trayicon )
    end
)

-------------------------------------------------------------------------------------------------------------------------------------
--// Tab 3 //------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------

local treebook

local make_treebook_page = function( parent )
    treebook = wx.wxTreebook( parent, wx.wxID_ANY, wx.wxPoint( 0, 0 ), wx.wxSize( 795, 263 ) )

    notebook:SetImageList( notebook_image_list )
    notebook:SetPageImage( 0, tab_1_img )
    notebook:SetPageImage( 1, tab_2_img )
    notebook:SetPageImage( 2, tab_3_img )
    notebook:SetPageImage( 3, tab_4_img )
    notebook:SetPageImage( 4, tab_5_img )

    local rules_tbl = util_loadtable( file_rules )
    local first_page = true
    local i = 1

    for k, v in ipairs( rules_tbl ) do
        local str = tostring( i )

        local panel = "panel_" .. str
        panel = wx.wxPanel( treebook, wx.wxID_ANY )
        panel:SetBackgroundColour( wx.wxColour( 225, 225, 225 ) )

        local sizer = wx.wxBoxSizer( wx.wxVERTICAL )
        sizer:SetMinSize( 795, 263 )
        panel:SetSizer( sizer )

        treebook:AddPage( panel, "#" .. i .. ": " .. rules_tbl[ k ].rulename, first_page, i - 1 )
        first_page = false

        -----------------------------------------------------------------------------------------------------------------------------

        local checkbox_activate = "checkbox_activate_" .. str
        checkbox_activate = wx.wxCheckBox( panel, id_activate + i, "Activate", wx.wxPoint( 5, 20 ), wx.wxDefaultSize )
        checkbox_activate:SetForegroundColour( wx.wxRED )
        if rules_tbl[ k ].active == true then checkbox_activate:SetValue( true ) else checkbox_activate:SetValue( false ) end

        -----------------------------------------------------------------------------------------------------------------------------

        local textctrl_rulename = "textctrl_rulename_" .. str
        textctrl_rulename = wx.wxTextCtrl( panel, id_rulename + i, "", wx.wxPoint( 80, 16 ), wx.wxSize( 230, 20 ),  wx.wxSUNKEN_BORDER + wx.wxTE_CENTRE ) -- + wx.wxTE_READONLY )
        textctrl_rulename:SetBackgroundColour( wx.wxColour( 255, 255, 255 ) )
        textctrl_rulename:SetMaxLength( 30 )
        textctrl_rulename:SetForegroundColour( wx.wxRED )
        textctrl_rulename:SetValue( rules_tbl[ k ].rulename )

        -----------------------------------------------------------------------------------------------------------------------------

        control = wx.wxStaticBox( panel, wx.wxID_ANY, "Hub command", wx.wxPoint( 5, 63 ), wx.wxSize( 260, 43 ) )
        local textctrl_command = "textctrl_command_" .. str
        textctrl_command = wx.wxTextCtrl( panel, id_command + i, "", wx.wxPoint( 20, 79 ), wx.wxSize( 230, 20 ),  wx.wxSUNKEN_BORDER ) -- + wx.wxTE_CENTRE + wx.wxTE_READONLY )
        textctrl_command:SetBackgroundColour( wx.wxColour( 255, 255, 255 ) )
        textctrl_command:SetMaxLength( 30 )
        textctrl_command:SetValue( rules_tbl[ k ].command )

        -----------------------------------------------------------------------------------------------------------------------------

        control = wx.wxStaticBox( panel, wx.wxID_ANY, "Category", wx.wxPoint( 282, 63 ), wx.wxSize( 260, 43 ) )
        local textctrl_category = "textctrl_category_" .. str
        textctrl_category = wx.wxTextCtrl( panel, id_category + i, "", wx.wxPoint( 297, 79 ), wx.wxSize( 230, 20 ),  wx.wxSUNKEN_BORDER ) -- + wx.wxTE_CENTRE + wx.wxTE_READONLY )
        textctrl_category:SetBackgroundColour( wx.wxColour( 255, 255, 255 ) )
        textctrl_category:SetMaxLength( 30 )
        textctrl_category:SetValue( rules_tbl[ k ].category )

        -----------------------------------------------------------------------------------------------------------------------------

        control = wx.wxStaticBox( panel, wx.wxID_ANY, "", wx.wxPoint( 5, 113 ), wx.wxSize( 205, 56 ) )

        local checkbox_daydirscheme = "checkbox_daydirscheme_" .. str
        checkbox_daydirscheme = wx.wxCheckBox( panel, id_daydirscheme + i, "Use daydir scheme (mmdd)", wx.wxPoint( 15, 128 ), wx.wxDefaultSize )
        if rules_tbl[ k ].daydirscheme == true then checkbox_daydirscheme:SetValue( true ) else checkbox_daydirscheme:SetValue( false ) end

        local checkbox_zeroday = "checkbox_zeroday_" .. str
        checkbox_zeroday = wx.wxCheckBox( panel, id_zeroday + i, "Check only current daydir", wx.wxPoint( 25, 148 ), wx.wxDefaultSize )
        if rules_tbl[ k ].zeroday == true then checkbox_zeroday:SetValue( true ) else checkbox_zeroday:SetValue( false ) end
        if rules_tbl[ k ].daydirscheme == true then checkbox_zeroday:Enable( true ) else checkbox_zeroday:Enable( false ) end

        -----------------------------------------------------------------------------------------------------------------------------

        control = wx.wxStaticBox( panel, wx.wxID_ANY, "Announcing path", wx.wxPoint( 5, 175 ), wx.wxSize( 537, 43 ) )
        local dirpicker_path = "dirpicker_path_" .. str
        dirpicker_path = wx.wxTextCtrl( panel, id_dirpicker_path + i, "", wx.wxPoint( 20, 190 ), wx.wxSize( 430, 20 ), wx.wxTE_PROCESS_ENTER + wx.wxSUNKEN_BORDER )
        dirpicker_path:SetValue( rules_tbl[ k ].path )

        local dirpicker = "dirpicker_" .. str
        dirpicker = wx.wxDirPickerCtrl(
            panel,
            id_dirpicker + i,
            wx.wxGetCwd(),
            "Choose announcing folder:",
            wx.wxPoint( 458, 190 ),
            wx.wxSize( 80, 22 ),
            --wx.wxDIRP_DEFAULT_STYLE + wx.wxDIRP_DIR_MUST_EXIST - wx.wxDIRP_USE_TEXTCTRL
            wx.wxDIRP_DIR_MUST_EXIST
        )

        -----------------------------------------------------------------------------------------------------------------------------

        --// save button
        local save_button = "save_button_" .. str
        save_button = wx.wxButton()
        save_button = wx.wxButton( panel, id_save_button + i, "Save", wx.wxPoint( 230, 230 ), wx.wxSize( 83, 25 ) )
        save_button:SetBackgroundColour( wx.wxColour( 200, 200, 200 ) )
        save_button:Connect( id_save_button + i, wx.wxEVT_COMMAND_BUTTON_CLICKED,
            function( event )
                util_savetable( rules_tbl, "rules", file_rules )
                save_button:Disable()
                log_broadcast( log_window, "Saved data to: '" .. file_rules .. "'", "CYAN" )
                local id = treebook:GetSelection()
                treebook:SetPageText( id, "#" .. id + 1 .. ": " .. rules_tbl[ id + 1 ].rulename )
            end
        )
        save_button:Disable()

        -----------------------------------------------------------------------------------------------------------------------------

        --// Button - Blacklist
        local blacklist_button = "blacklist_button_" .. str
        blacklist_button = wx.wxButton( panel, id_blacklist_button + i, "Blacklist", wx.wxPoint( 230, 120 ), wx.wxSize( 120, 23 ) )
        blacklist_button:Connect( id_blacklist_button + i, wx.wxEVT_COMMAND_BUTTON_CLICKED,
            function( event )
                --// send dialog msg
                local di = "di_" .. str
                di = wx.wxDialog( frame, wx.wxID_ANY, "Blacklist", wx.wxDefaultPosition, wx.wxSize( 215, 365 ) )
                di:SetBackgroundColour( wx.wxColour( 255, 255, 255 ) )

                control = wx.wxStaticBox( di, wx.wxID_ANY, "Forbidden TAG's", wx.wxPoint( 5, 5 ), wx.wxSize( 200, 325 ) )
                control = wx.wxStaticText( di, wx.wxID_ANY, "Add Term:", wx.wxPoint( 20, 25 ) )

                --// wxTextCtrl
                local blacklist_textctrl = "blacklist_textctrl_" .. str
                blacklist_textctrl = wx.wxTextCtrl( di, id_blacklist_textctrl + i, "", wx.wxPoint( 20, 38 ), wx.wxSize( 170, 20 ), wx.wxTE_PROCESS_ENTER )
                blacklist_textctrl:SetBackgroundColour( wx.wxColour( 200, 200, 200 ) )
                blacklist_textctrl:Connect( id_blacklist_textctrl + i, wx.wxEVT_KILL_FOCUS, --> check spaces
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

                ---------------------------------------------------------------------------------------------------------------------

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
                        blacklist_listbox:Clear()
                        blacklist_listbox:Append( sorted_skip_tbl() )
                        blacklist_listbox:SetSelection( 0 )
                        local di = wx.wxMessageDialog( frame, "The following TAG was added to table: " .. folder, "INFO", wx.wxOK )
                        local result = di:ShowModal()
                        di:Destroy()
                        log_broadcast( log_window, "The following TAG was added to Blacklist table: " .. folder, "CYAN" )
                    end
                end

                --// remove table entry from blacklist
                local del_folder = function( blacklist_textctrl, blacklist_listbox )
                    local folder = blacklist_listbox:GetString( blacklist_listbox:GetSelection() )
                    if folder then rules_tbl[ k ].blacklist[ folder ] = nil end
                    blacklist_textctrl:SetValue( "" )
                    blacklist_listbox:Clear()
                    blacklist_listbox:Append( sorted_skip_tbl() )
                    blacklist_listbox:SetSelection( 0 )
                    local di = wx.wxMessageDialog( frame, "The following TAG was removed from table: " .. folder, "INFO", wx.wxOK )
                    local result = di:ShowModal()
                    di:Destroy()
                    log_broadcast( log_window, "The following TAG was removed from Blacklist table: " .. folder, "CYAN" )
                end

                ---------------------------------------------------------------------------------------------------------------------

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

                ---------------------------------------------------------------------------------------------------------------------

                --// Button - Add Folder
                local blacklist_add_button = "blacklist_add_button_" .. str
                blacklist_add_button = wx.wxButton( di, id_blacklist_add_button + i, "add", wx.wxPoint( 20, 60 ), wx.wxSize( 169, 18 ) )
                blacklist_add_button:Connect( id_blacklist_add_button + i, wx.wxEVT_COMMAND_BUTTON_CLICKED,
                    function( event )
                        add_folder( blacklist_textctrl, blacklist_listbox )
                        save_button:Enable( true )
                    end
                )

                --// Button - Delete Folder
                local blacklist_del_button = "blacklist_del_button_" .. str
                blacklist_del_button = wx.wxButton( di, id_blacklist_del_button + i, "delete", wx.wxPoint( 20, 298 ), wx.wxSize( 169, 18 ) )
                blacklist_del_button:Connect( id_blacklist_del_button + i, wx.wxEVT_COMMAND_BUTTON_CLICKED,
                    function( event )
                        del_folder( blacklist_textctrl, blacklist_listbox )
                        save_button:Enable( true )
                    end
                )

                di:ShowModal()
            end
        )

        -----------------------------------------------------------------------------------------------------------------------------

        --// Button - Whitelist
        local whitelist_button = "whitelist_button_" .. str
        whitelist_button = wx.wxButton( panel, id_whitelist_button + i, "Whitelist", wx.wxPoint( 230, 145 ), wx.wxSize( 120, 23 ) )
        whitelist_button:Connect( id_whitelist_button + i, wx.wxEVT_COMMAND_BUTTON_CLICKED,
            function( event )
                --// send dialog msg
                local di = "di_" .. str
                di = wx.wxDialog( frame, wx.wxID_ANY, "Whitelist", wx.wxDefaultPosition, wx.wxSize( 215, 365 ) )
                di:SetBackgroundColour( wx.wxColour( 255, 255, 255 ) )

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

                ---------------------------------------------------------------------------------------------------------------------

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
                        whitelist_listbox:Clear()
                        whitelist_listbox:Append( sorted_skip_tbl() )
                        whitelist_listbox:SetSelection( 0 )
                        local di = wx.wxMessageDialog( frame, "The following TAG was added to table: " .. folder, "INFO", wx.wxOK )
                        local result = di:ShowModal()
                        di:Destroy()
                        log_broadcast( log_window, "The following TAG was added to Whitelist table: " .. folder, "CYAN" )
                    end
                end

                --// remove table entry from whitelist
                local del_folder = function( whitelist_textctrl, whitelist_listbox )
                    local folder = whitelist_listbox:GetString( whitelist_listbox:GetSelection() )
                    if folder then rules_tbl[ k ].whitelist[ folder ] = nil end
                    whitelist_textctrl:SetValue( "" )
                    whitelist_listbox:Clear()
                    whitelist_listbox:Append( sorted_skip_tbl() )
                    whitelist_listbox:SetSelection( 0 )
                    local di = wx.wxMessageDialog( frame, "The following TAG was removed from table: " .. folder, "INFO", wx.wxOK )
                    local result = di:ShowModal()
                    di:Destroy()
                    log_broadcast( log_window, "The following TAG was removed from Whitelist table: " .. folder, "CYAN" )
                end

                ---------------------------------------------------------------------------------------------------------------------

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

                ---------------------------------------------------------------------------------------------------------------------

                --// Button - Add Folder
                local whitelist_add_button = "whitelist_add_button_" .. str
                whitelist_add_button = wx.wxButton( di, id_whitelist_add_button + i, "add", wx.wxPoint( 20, 60 ), wx.wxSize( 169, 18 ) )
                whitelist_add_button:Connect( id_whitelist_add_button + i, wx.wxEVT_COMMAND_BUTTON_CLICKED,
                    function( event )
                        add_folder( whitelist_textctrl, whitelist_listbox )
                        save_button:Enable( true )
                    end
                )

                --// Button - Delete Folder
                local whitelist_del_button = "whitelist_del_button_" .. str
                whitelist_del_button = wx.wxButton( di, id_whitelist_del_button + i, "delete", wx.wxPoint( 20, 298 ), wx.wxSize( 169, 18 ) )
                whitelist_del_button:Connect( id_whitelist_del_button + i, wx.wxEVT_COMMAND_BUTTON_CLICKED,
                    function( event )
                        del_folder( whitelist_textctrl, whitelist_listbox )
                        save_button:Enable( true )
                    end
                )

                di:ShowModal()
            end
        )

        -----------------------------------------------------------------------------------------------------------------------------

        --// events
        textctrl_rulename:Connect( id_rulename + i, wx.wxEVT_COMMAND_TEXT_UPDATED,
            function( event )
                save_button:Enable( true )
            end
        )

        textctrl_rulename:Connect( id_rulename + i, wx.wxEVT_KILL_FOCUS,
            function( event )
                local value = trim( textctrl_rulename:GetValue() )
                rules_tbl[ k ].rulename = value
            end
        )

        textctrl_command:Connect( id_command + i, wx.wxEVT_COMMAND_TEXT_UPDATED,
            function( event )
                save_button:Enable( true )
            end
        )

        textctrl_command:Connect( id_command + i, wx.wxEVT_KILL_FOCUS,
            function( event )
                local value = textctrl_command:GetValue()
                check_for_whitespaces_textctrl( frame, textctrl_command )
                rules_tbl[ k ].command = value
            end
        )

        textctrl_category:Connect( id_category + i, wx.wxEVT_COMMAND_TEXT_UPDATED,
            function( event )
                save_button:Enable( true )
            end
        )

        textctrl_category:Connect( id_category + i, wx.wxEVT_KILL_FOCUS,
            function( event )
                local value = textctrl_category:GetValue()
                check_for_whitespaces_textctrl( frame, textctrl_category )
                rules_tbl[ k ].category = value
            end
        )

        checkbox_activate:Connect( id_activate + i, wx.wxEVT_COMMAND_CHECKBOX_CLICKED,
            function( event )
                if checkbox_activate:IsChecked() then
                    rules_tbl[ k ].active = true
                else
                    rules_tbl[ k ].active = false
                end
                save_button:Enable( true )
            end
        )

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
            end
        )

        dirpicker_path:Connect( id_dirpicker_path + i, wx.wxEVT_COMMAND_TEXT_UPDATED,
            function( event )
                save_button:Enable( true )
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
            end
        )

        i = i + 1
    end
end

-------------------------------------------------------------------------------------------------------------------------------------
--// Tab 4 //------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------

--// get rules table entrys as array
local sorted_rules_tbl = function()
    local rules_tbl = util_loadtable( file_rules )
    local rules_arr = {}
    local i = 1
    for k, v in pairs( rules_tbl ) do
        table.insert( rules_arr, i, "Rule #" .. i .. ": " .. rules_tbl[ i ].rulename )
        i = i + 1
    end
    table.sort( rules_arr )
    return rules_arr
end

--// add new table entry to whitelist
local add_rule = function( rules_listbox, treebook )
    local rules_tbl = util_loadtable( file_rules )
    local t = {

        [ "active" ] = false,
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
    }

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
    dialog_rule_add_textctrl:SetMaxLength( 20 )

    local dialog_rule_add_button = wx.wxButton( di, id_button_add_rule, "OK", wx.wxPoint( 110, 36 ), wx.wxSize( 60, 20 ) )
    dialog_rule_add_button:Connect( id_button_add_rule, wx.wxEVT_COMMAND_BUTTON_CLICKED,
        function( event )
            local value = trim( dialog_rule_add_textctrl:GetValue() ) or ""
            table.insert( rules_tbl, t )
            rules_tbl[ #rules_tbl ].rulename = value
            util_savetable( rules_tbl, "rules", file_rules )
            rules_listbox:Clear()
            rules_listbox:Append( sorted_rules_tbl() )
            log_broadcast( log_window, "Added new Rule '#" .. #rules_tbl .. ": " .. rules_tbl[ #rules_tbl ].rulename .. "'", "CYAN" )
            log_broadcast( log_window, "Saved data to: '" .. file_rules .. "'", "CYAN" )
            treebook:Destroy()
            make_treebook_page( tab_3 )
            di:Destroy()
        end
    )
    local result = di:ShowModal()
end

--// remove table entry from whitelist
local del_rule = function( rules_listbox, treebook )
    local rules_tbl = util_loadtable( file_rules )
    local entry = rules_listbox:GetSelection()
    if entry == -1 then
        local di = wx.wxMessageDialog( frame, "Error: No rule selected", "INFO", wx.wxOK )
        local result = di:ShowModal()
        di:Destroy()
    else
        table.remove( rules_tbl, entry + 1 )
        util_savetable( rules_tbl, "rules", file_rules )
        rules_listbox:Clear()
        rules_listbox:Append( sorted_rules_tbl() )
        log_broadcast( log_window, "Rule '#" .. entry + 1 .. "' was deleted. Rules list was renumbered!", "CYAN" )
        log_broadcast( log_window, "Saved data to: '" .. file_rules .. "'", "CYAN" )
        treebook:Destroy()
        make_treebook_page( tab_3 )
    end
end

--// wxListBox
local rules_listbox = wx.wxListBox(

    tab_4,
    id_rules_listbox,
    wx.wxPoint( 285, 5 ),
    wx.wxSize( 220, 230 ),
    sorted_rules_tbl(),
    wx.wxLB_SINGLE + wx.wxLB_HSCROLL + wx.wxLB_SORT + wx.wxSUNKEN_BORDER
)

--// Button - Add Folder
local rule_add_button = wx.wxButton( tab_4, id_rule_add, "Add", wx.wxPoint( 335, 238 ), wx.wxSize( 60, 20 ) )
rule_add_button:Connect( id_rule_add, wx.wxEVT_COMMAND_BUTTON_CLICKED,
    function( event )
        add_rule( rules_listbox, treebook )
    end
)

--// Button - Delete Folder
local rule_del_button = wx.wxButton( tab_4, id_rule_del, "Delete", wx.wxPoint( 395, 238 ), wx.wxSize( 60, 20 ) )
rule_del_button:Connect( id_rule_del, wx.wxEVT_COMMAND_BUTTON_CLICKED,
    function( event )
        del_rule( rules_listbox, treebook )
    end
)

-------------------------------------------------------------------------------------------------------------------------------------
--// Tab 5 //------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------

local logfile_window = wx.wxTextCtrl(

    tab_5,
    wx.wxID_ANY,
    "",
    wx.wxPoint( 5, 5 ),
    wx.wxSize( 778, 210 ),
    wx.wxTE_READONLY + wx.wxTE_MULTILINE + wx.wxTE_RICH + wx.wxSUNKEN_BORDER + wx.wxHSCROLL
)
logfile_window:SetBackgroundColour( wx.wxColour( 255, 255, 255 ) )
logfile_window:SetFont( log_font )

-------------------------------------------------------------------------------------------------------------------------------------

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

local log_handler = function( file, parent, mode, button, count )
    if mode == "read" then
        if check_file( file ) then
            button:Disable()
            local path = wx.wxGetCwd() .. "\\"
            wx.wxCopyFile( path .. file, path .. "log/tmp_file.txt", true )
            local f = io.open( path .. "log/tmp_file.txt", "r" )
            local content = f:read( "*a" )
            local i = 0
            if count then
                for line in io.lines( path .. "log/tmp_file.txt" ) do i = i + 1 end
                f:close()
            else
                f:close()
            end
            wx.wxRemoveFile( path .. "log/tmp_file.txt" )
            log_broadcast( log_window, "Reading text from: '" .. file .. "'", "CYAN" )
            wx.wxSleep( 1 )
            parent:Clear()
            parent:AppendText( content )
            if count then parent:AppendText( "\nAmount of releases: " .. i ) end
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

-------------------------------------------------------------------------------------------------------------------------------------

control = wx.wxStaticBox( tab_5, wx.wxID_ANY, "logfile.txt", wx.wxPoint( 132, 218 ), wx.wxSize( 161, 40 ) )

--// wxButton - logfile load
local button_load_logfile = wx.wxButton( tab_5, id_button_load_logfile, "Load", wx.wxPoint( 140, 234 ), wx.wxSize( 70, 20 ) )
button_load_logfile:Connect( id_button_load_logfile, wx.wxEVT_COMMAND_BUTTON_CLICKED,
    function( event )
        log_handler( file_logfile, logfile_window, "read", button_load_logfile )
    end
)

--// wxButton - logfile clean
local button_clear_logfile = wx.wxButton( tab_5, id_button_clear_logfile, "Clean", wx.wxPoint( 215, 234 ), wx.wxSize( 70, 20 ) )
button_clear_logfile:Connect( id_button_clear_logfile, wx.wxEVT_COMMAND_BUTTON_CLICKED,
    function( event )
        log_handler( file_logfile, logfile_window, "clean", button_clear_logfile )
    end
)

-------------------------------------------------------------------------------------------------------------------------------------

control = wx.wxStaticBox( tab_5, wx.wxID_ANY, "announced.txt", wx.wxPoint( 312, 218 ), wx.wxSize( 161, 40 ) )

--// wxButton - announced load
local button_load_announced = wx.wxButton( tab_5, id_button_load_announced, "Load", wx.wxPoint( 320, 234 ), wx.wxSize( 70, 20 ) )
button_load_announced:Connect( id_button_load_announced, wx.wxEVT_COMMAND_BUTTON_CLICKED,
    function( event )
        log_handler( file_announced, logfile_window, "read", button_load_announced, true )
    end
)

--// wxButton - announced clean
local button_clear_announced = wx.wxButton( tab_5, id_button_clear_announced, "Clean", wx.wxPoint( 395, 234 ), wx.wxSize( 70, 20 ) )
button_clear_announced:Connect( id_button_clear_announced, wx.wxEVT_COMMAND_BUTTON_CLICKED,
    function( event )
        log_handler( file_announced, logfile_window, "clean", button_clear_announced )
    end
)

-------------------------------------------------------------------------------------------------------------------------------------

control = wx.wxStaticBox( tab_5, wx.wxID_ANY, "exception.txt", wx.wxPoint( 492, 218 ), wx.wxSize( 161, 40 ) )

--// wxButton - exception load
local button_load_exception = wx.wxButton( tab_5, id_button_load_exception, "Load", wx.wxPoint( 500, 234 ), wx.wxSize( 70, 20 ) )
button_load_exception:Connect( id_button_load_exception, wx.wxEVT_COMMAND_BUTTON_CLICKED,
    function( event )
        log_handler( file_exception, logfile_window, "read", button_load_exception )
    end
)

--// wxButton - exception clean
local button_clear_exception = wx.wxButton( tab_5, id_button_clear_exception, "Clean", wx.wxPoint( 575, 234 ), wx.wxSize( 70, 20 ) )
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

    wx.wxMilliSleep( 2000 )

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
        run = false
        kill_process( pid, log_window )
    else
        log_broadcast( log_window, get_status( file_status, "hubconnect" ), "GREEN" )
    end

    if run then
        if get_status( file_status, "hubhandshake" ):find( "Fail" ) or get_status( file_status, "hubhandshake" ) == "" then
            log_broadcast( log_window, get_status( file_status, "hubhandshake" ), "RED" )
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
        end
    else
        start_client:Enable( true )
        stop_client:Disable()
        unprotect_hub_values( log_window, control_hubname, control_hubaddress, control_hubport, control_nickname, control_password, control_keyprint, control_tls,
                              control_bot_desc, control_bot_share, control_bot_slots, control_announceinterval, control_sleeptime, control_sockettimeout, checkbox_trayicon,
                              button_clear_logfile, button_clear_announced, button_clear_exception, rule_add_button, rule_del_button, rules_listbox, treebook )

        pid = 0
        kill_process( pid, log_window )
    end

end

-------------------------------------------------------------------------------------------------------------------------------------

--// connect button
start_client = wx.wxButton( panel, id_start_client, "CONNECT", wx.wxPoint( 302, 2 ), wx.wxSize( 83, 25 ) )
start_client:SetBackgroundColour( wx.wxColour( 65,65,65 ) )
start_client:SetForegroundColour( wx.wxColour( 0,237,0 ) )
start_client:Connect( id_start_client, wx.wxEVT_COMMAND_BUTTON_CLICKED,
    function( event )
        start_client:Disable()
        stop_client:Enable( true )
        protect_hub_values( log_window, control_hubname, control_hubaddress, control_hubport, control_nickname, control_password, control_keyprint, control_tls,
                            control_bot_desc, control_bot_share, control_bot_slots, control_announceinterval, control_sleeptime, control_sockettimeout, checkbox_trayicon,
                            button_clear_logfile, button_clear_announced, button_clear_exception, rule_add_button, rule_del_button, rules_listbox, treebook )

        save_hub_values( log_window, control_hubname, control_hubaddress, control_hubport, control_nickname, control_password, control_keyprint )
        save_sslparams_values( log_window, control_tls )
        start_process()
    end
)

--// disconnect button
stop_client = wx.wxButton( panel, id_stop_client, "DISCONNECT", wx.wxPoint( 408, 2 ), wx.wxSize( 83, 25 ) )
stop_client:SetBackgroundColour( wx.wxColour( 65,65,65 ) )
stop_client:SetForegroundColour( wx.wxColour( 255,0,0 ) )
stop_client:Disable()
stop_client:Connect( id_stop_client, wx.wxEVT_COMMAND_BUTTON_CLICKED,
    function( event )
        start_client:Enable( true )
        stop_client:Disable()
        unprotect_hub_values( log_window, control_hubname, control_hubaddress, control_hubport, control_nickname, control_password, control_keyprint, control_tls,
                              control_bot_desc, control_bot_share, control_bot_slots, control_announceinterval, control_sleeptime, control_sockettimeout, checkbox_trayicon,
                              button_clear_logfile, button_clear_announced, button_clear_exception, rule_add_button, rule_del_button, rules_listbox, treebook )

        kill_process( pid, log_window )
    end
)

-------------------------------------------------------------------------------------------------------------------------------------
--// MAIN LOOP //--------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------

--// import values from files
set_hub_values( log_window, control_hubname, control_hubaddress, control_hubport, control_nickname, control_password, control_keyprint )
set_cfg_values( log_window, control_bot_desc, control_bot_share, control_bot_slots, control_announceinterval, control_sleeptime, control_sockettimeout, checkbox_trayicon )
set_sslparams_value( log_window, control_tls )
save_hub_cfg:Disable()
save_cfg:Disable()
make_treebook_page( tab_3 )

--// main function
local main = function()
    local taskbar = add_taskbar( frame, checkbox_trayicon )

    frame:Connect( wx.wxID_ANY, wx.wxEVT_DESTROY, --wx.wxEVT_CLOSE_WINDOW,
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

    frame:Connect( wx.wxID_EXIT, wx.wxEVT_COMMAND_MENU_SELECTED,
        function( event )
            --frame:Close( true )
            frame:Destroy()
            if taskbar then taskbar:delete() end
        end
    )

    frame:Connect( wx.wxID_ABOUT, wx.wxEVT_COMMAND_MENU_SELECTED,
        function( event )
            show_about_window( frame )
        end
    )

    frame:Connect( wx.wxID_ANY, wx.wxEVT_COMMAND_NOTEBOOK_PAGE_CHANGED, HandleEvents )

    frame:Show( true )
end

main()
wx.wxGetApp():MainLoop()