--[[

    - written by blastbeat, 20141008
        - rewritten by pulsar for Luadch Announcer Client

]]--


local ssl = require "ssl"
local socket = require "socket"
local basexx = require "basexx"
local util = require "core/util"

local status_file = "core/status.lua"
local util_loadtable = util.loadtable
local util_savetable = util.savetable

local sslctx, err = ssl.newcontext( sslparams )
assert( sslctx, "Fail: " .. tostring( err ) )

local bottag = "Announcer\\s" .. adclib.escape( _VERSION )
--local bottag = "Announcer\\s" .. app_version

local set_status = function( file, key, value )
    local is_writable, err = assert( io.open( file, "a+" ) )
    repeat
        if is_writable then
            --if file then file:close() end
            local tbl = util_loadtable( file )
            tbl[ key ] = value
            util_savetable( tbl, "status", file )
            is_writable = false
        end
    until not is_writable
end

local run = true
net = { }

net.loop = function( )
    local client, err = socket.tcp( )
    local bshare = cfg.botshare * 1024 * 1024
    assert( client, "Fail: " .. tostring( err ) )
    log.event( "Try to connect to hub '" .. hub.name .. "' via " .. hub.nick .. "@" .. hub.addr .. ":" .. hub.port .. " with timeout " .. cfg.sockettimeout .. " seconds..." )
    client:settimeout( cfg.sockettimeout )
    repeat
        local succ, err = client:connect( hub.addr, hub.port )
        run = true
        if err then
            log.event( "Fail: " .. tostring( err ) )
            log.event( "Try to reconnect in " .. tonumber( cfg.sleeptime ) or 10 .. " seconds..." )
            --set_status( status_file, "hubconnect", "Fail: " .. tostring( err ) .. "  |  Try to reconnect in " .. tonumber( cfg.sleeptime ) or 10 .. " seconds..." )
            set_status( status_file, "hubconnect", "Fail: " .. tostring( err ) )
            socket.sleep( tonumber( cfg.sleeptime ) or 10 )
            run = false
        end
    until succ
    log.event( "Connected. Try a SSL handshake..." )
    if run then set_status( status_file, "hubconnect", "Connected. Try a SSL handshake..." ) end
    local client, err = ssl.wrap( client, sslctx )
    assert( client, "Fail: " .. tostring( err ) )
    client:settimeout( cfg.sockettimeout )
    local succ, err = client:dohandshake( )
    if err then
        log.event( "Fail: " .. tostring( err ) )
        set_status( status_file, "hubhandshake", "Fail: " .. tostring( err ) )
        run = false
        return false
    end
    local cert = client:getpeercertificate( )
    log.event( "Generate keyprint..." )
    if run then set_status( status_file, "hubhandshake", "Generate keyprint..." ) end
    local fingerprint = basexx.to_base32( basexx.from_hex( cert:digest( "sha256" ) ) ):gsub( "=", "" )
    if hub.keyp ~= "" then
        if fingerprint ~= hub.keyp then
            log.event( "Fail: Keyprint mismatch" )
            set_status( status_file, "hubkeyp", "Fail: Keyprint mismatch" )
            run = false
            client:close( )
            return true
        else
            log.event( "Connection with Keyprint verification..." )
            set_status( status_file, "hubkeyp", "Connection with Keyprint verification..." )
        end
    else
        log.event( "Connection without Keyprint verification..." )
        set_status( status_file, "hubkeyp", "Connection without Keyprint verification..." )
    end
    log.event( "Connection established. Try now to login..." )
    if run then set_status( status_file, "hubkeyp", "Connection established. Try now to login..." ) end
    log.event( "Sending support..." )
    local succ, err = client:send( "HSUP ADBASE ADTIGR ADOSNR ADKEYP ADADCS ADADC0\n" )
    if err then
        log.event( "Fail: " .. tostring( err ) )
        set_status( status_file, "support", "Fail: " .. tostring( err ) )
        run = false
        return false
    end
    log.event( "Waiting for hub support..." )
    if run then set_status( status_file, "support", "Waiting for hub support..." ) end
    local buf, err = client:receive( "*l" )
    if err then
        log.event( "Fail: " .. tostring( err ) )
        set_status( status_file, "hubsupport", "Fail: " .. tostring( err ) )
        run = false
        return false
    end
    log.event( "Check for OSNR support..." )
    if run then set_status( status_file, "hubsupport", "Check for OSNR support..." ) end
    if not buf:find( "ADOSNR" ) then
        log.event( "Fail: No OSNR support, closing..." )
        set_status( status_file, "hubosnr", "Fail: No OSNR support, closing..." )
        run = false
        client:close( )
        return true
    end
    log.event( "Hub has OSNR support, waiting for SID..." )
    if run then set_status( status_file, "hubosnr", "Hub has OSNR support, waiting for SID..." ) end
    local buf, err = client:receive( "*l" )
    if err then
        log.event( "Fail: " .. tostring( err ) )
        set_status( status_file, "hubsid", "Fail: " .. tostring( err ) )
        return false
    end
    local sid
    if buf:find( "ISID" ) then
        sid = buf:sub( 6, 9 )
        log.event( "Provided SID: " .. sid )
        if run then set_status( status_file, "hubsid", "Provided SID: " .. sid ) end
    else
        log.event( "No SID provided, closing..." )
        client:close( )
        run = false
        return true
    end
    log.event( "Waiting for hub INF..." )
    local buf, err = client:receive( "*l" )
    if err then
        log.event( "Fail: " .. tostring( err ) )
        set_status( status_file, "hubinf", "Fail: " .. tostring( err ) )
        run = false
        return false
    end
    if not buf:find( "IINF" ) then
        log.event( "No INF provided, closing..." )
        client:close( )
        run = false
        return true
    else
        log.event( "Hub INF provided, try to send own INF..." )
        if run then set_status( status_file, "hubinf", "Hub INF provided, try to send own INF..." ) end
        local succ, err = client:send( "BINF " ..
                                        sid ..
                                        " NI" .. adclib.escape( tostring( hub.nick ) ) ..
                                        " DE" .. adclib.escape( tostring( cfg.botdesc ) ) ..
                                        " PD" .. id.pid ..
                                        " ID" .. id.cid ..
                                        " VE" .. bottag ..
                                        " SS" .. bshare ..
                                        " SL" .. cfg.botslots ..
                                        " HN" .. tonumber( "0" ) ..
                                        " HR" .. tonumber( "0" ) ..
                                        " HO" .. tonumber( "0" ) ..
                                        " I4" .. "0.0.0.0" ..
                                        " AW" .. tonumber( "2" ) ..
                                        " SU" .. "OSNR,ADC0,ADCS,TCP4,UDP4" ..
                                        "\n" )

        if err then
            log.event( "Fail: " .. tostring( err ) )
            set_status( status_file, "owninf", "Fail: " .. tostring( err ) )
            run = false
            return false
        end
    end
    log.event( "Own INF sended, waiting for password request..." )
    if run then set_status( status_file, "owninf", "Own INF sended, waiting for password request..." ) end
    local buf, err = client:receive( "*l" )
    if err then
        log.event( "Fail: " .. tostring( err ) )
        set_status( status_file, "passwd", "Fail: " .. tostring( err ) )
        run = false
        return false
    end
    local salt
    if not buf:find( "GPA" ) then
        log.event( "No password request, closing..." )
        set_status( status_file, "passwd", "Fail: No password request, closing..." )
        client:close( )
        run = false
        return true
    else
        salt = buf:sub( 6, -1 ):match( "^([A-Z2-7]+)" )
    end
    log.event( "Salt provided, try to send password..." )
    if run then set_status( status_file, "passwd", "Salt provided, try to send password..." ) end
    local pas = adclib.hashpas( hub.pass, salt )
    local succ, err = client:send( "HPAS " .. pas .. "\n" )
    if err then
        log.event( "Fail: " .. tostring( err ) )
        set_status( status_file, "hubsalt", "Fail: " .. tostring( err ) )
        client:close( )
        run = false
        return false
    end
    log.event( "Waiting for login..." )
    if run then set_status( status_file, "hubsalt", "Waiting for login..." ) end
    local buf, err = client:receive( "*l" )
    if err then
        log.event( "Fail: " .. tostring( err ) )
        --set_status( status_file, "hublogin", "Fail: " .. tostring( err ) )
        return false
    end
    if not buf:find( "BINF" ) then
        log.event( "Login failed. Last hub message: " .. buf )
        set_status( status_file, "hublogin", "Fail: Login failed. Last hub message: " .. buf )
        client:close( )
        run = false
        return true
    end
    local hubcount = "HR1"
    if buf:find( "CT8" ) then
        hubcount = "HO1"
    end
    local succ, err = client:send( "BINF " .. sid .. " " .. hubcount .. "\n" )
    if err then
        log.event( "Fail: " .. tostring( err ) )
        client:close( )
        return false
    end
    log.event( "Login complete." )
    if run then set_status( status_file, "hublogin", "Login complete." ) end
    log.event( "Waiting " .. ( tonumber( cfg.sleeptime ) or 10 ) .. " seconds before starting the announcer..." )
    socket.sleep( tonumber( cfg.sleeptime ) or 10 )
    while true do
        local found = announce.update( )
        local c = 0
        log.event( "Start announcing..." )
        for release, cfg in pairs( found ) do
            local command = cfg.command
            local category = cfg.category
            if ( type( category ) ~= "string" ) or ( type( command ) ~= "string" ) then
                log.event( "Your rules.lua is broken. No valid category/command given for release '" .. release .. "' given." )
            else
                command = command .. " " .. category .. " " .. release
                command = adclib.escape( command )
                local succ, err = client:send( "BMSG " .. sid .. " " .. command .. "\n" )
                if err then
                    log.event( "Fail: " .. tostring( err ) )
                    return false
                else
                    log.release( release )
                    --log.event( "Announced '" .. release .. "'.")
                    c = c + 1
                end
            end
        end
        log.event( "...finished. Announced " .. c .. " new releases." )
        socket.sleep( tonumber( cfg.announceinterval ) or 5 * 60 )
        local succ, err = client:send( "BINF " .. sid .. " VE" .. bottag .. "\n" ) -- send some keeping alive ping
        if err then log.event( "Fail: " .. tostring( err ) ) return false end
    end
end

log.event( "Starting bot..." )
repeat
until net.loop( )
log.event( "Bot terminated." )
os.exit( )