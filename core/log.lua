--[[

    - written by blastbeat, 20141008
        - rewritten by pulsar for Luadch Announcer Client
        
]]--



local logfile, err = io.open( LOG_PATH .. "logfile.txt", "a+" )
assert( logfile, "Fail: " .. tostring( err ) )
local content = logfile:read( "*a" )
--logfile:close()

local releasefile, err = io.open( LOG_PATH .. "announced.txt", "a+" )
assert( releasefile, "Fail: " .. tostring( err ) )
local releases = { }
for line in releasefile:lines() do releases[ line ] = true end
--releasefile:close()

log = { }

log.getreleases = function()
    --releasefile, err = io.open( LOG_PATH .. "announced.txt", "r" )
    --assert( releasefile, "Fail: " .. tostring( err ) )
    --releases = { }
    --for line in releasefile:lines() do releases[ line ] = true end
    --releasefile:close()
    return releases
end

log.release = function( buf )
    --releasefile, err = io.open( LOG_PATH .. "announced.txt", "a+" )
    --assert( releasefile, "Fail: " .. tostring( err ) )
    --for line in releasefile:lines() do releases[ line ] = true end
    releases[ buf ] = true
    releasefile:write( buf .. "\n" )
    releasefile:flush()
    --releasefile:close()
end

log.event = function( buf )
    --logfile, err = io.open( LOG_PATH .. "logfile.txt", "a+" )
    --assert( logfile, "Fail: " .. tostring( err ) )
    buf = "[" .. os.date( "%Y-%m-%d/%H:%M:%S" ) .. "] " .. buf
    logfile:write( buf .. "\n" )
    logfile:flush()
    --logfile:close()
    content = content .. buf
end

function log.find( buf )
  return content:find( buf, 1, true )
end