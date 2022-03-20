--[[

    - written by blastbeat, 20141008
        - rewritten by pulsar for Luadch Announcer Client

]]--

package.path = package.path .. ";"
    .. "././core/?.lua;"
    .. "././lib/?/?.lua;"
    .. "././lib/luasocket/lua/?.lua;"
    .. "././lib/luasec/lua/?.lua;"
    .. "././lib/jit/?.lua;"

package.cpath = package.cpath .. ";"
    .. "././lib/?/?" .. ".dll" .. ";"
    .. "././lib/luasocket/?/?" .. ".dll" .. ";"
    .. "././lib/luasec/?/?" .. ".dll" .. ";"
    .. "././lib/lfs/?" .. ".dll" .. ";"

local lfs = require( "lfs" )
local util = require( CORE_PATH .. "util" )

local cfg_tbl = util.loadtable( CFG_PATH .. "cfg.lua" )
local maxlogsize = cfg_tbl[ "logfilesize" ] or 2097152

local logfile, content
local releasefile, releases

--// check if logfile reaches the maximum allowable size and if then clear it
local check_filesize = function( file )
    local logsize = lfs.attributes( file ).size or 0
    if logsize > maxlogsize then
        local f = io.open( file, "w+" ); f:close()
        if file:find( "logfile" ) then content = "" end
        if file:find( "announced" ) then releases = {} end
        return true
    end
    return false
end

local logfile, err = io.open( LOG_PATH .. "logfile.txt", "a+" )
assert( logfile, "Fail: " .. tostring( err ) )
local content = logfile:read( "*a" )

local releasefile, err = io.open( LOG_PATH .. "announced.txt", "a+" )
assert( releasefile, "Fail: " .. tostring( err ) )
local releases = { }
for line in releasefile:lines() do releases[ line ] = true end

log = { }

log.getreleases = function()
    return releases
end

log.release = function( buf )
    local cleared = false
    local timestamp = "[ " .. os.date( "%Y-%m-%d / %H:%M:%S" ) .. "] "
    if check_filesize( LOG_PATH .. "announced.txt" ) then cleared = true end
    releases[ buf ] = true
    releasefile:write( buf .. "\n" )
    releasefile:flush()
    if cleared then
        logfile:write( timestamp .. "cleared 'announced.txt' because of max logfile size: " .. util.formatbytes( maxlogsize ) .. "\n" )
        logfile:flush()
    end
end

log.event = function( buf )
    local cleared = false
    local timestamp = "[ " .. os.date( "%Y-%m-%d / %H:%M:%S" ) .. " ] "
    if check_filesize( LOG_PATH .. "logfile.txt" ) then cleared = true end
    buf = timestamp .. buf
    logfile:write( buf .. "\n" )
    logfile:flush()
    content = content .. buf
    if cleared then
        logfile:write( timestamp .. "cleared 'logfile.txt' because of max logfile size: " .. util.formatbytes( maxlogsize ) .. "\n" )
        logfile:flush()
    end
end

function log.find( buf )
    return content:find( buf, 1, true )
end