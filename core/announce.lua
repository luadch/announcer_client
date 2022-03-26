--[[

    - originally written by blastbeat, 20141008
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

local alreadysent = log.getreleases( )

local match = function( buf, patternlist, white )
    buf = buf:lower()
    local count = 0
    for pattern, _ in pairs( patternlist ) do
        pattern = pattern:lower( )
        count = count + 1
        if buf:find( pattern, 1, true ) then return true end
    end
    if white and ( count == 0 ) then return true end
    return false
end

local age_in_days = function( filetime )
    return ( os.time() - filetime ) / 86400
end

local check_for_whitespaces = function( release )
    local t1, t2 = string.find( release, " " )
    if type( t1 ) == "nil" then
        return false
    else
        return true
    end
end

local check_number_between = function( num, mini, maxi )
    num = tonumber( num )
    return ( num >= mini and maxi >= num )
end

local directory_has_nfo = function( path )
    for file in lfs.dir(path) do
        if file ~= "." and file ~= ".." then
            local f = path .. "/" .. file
            local mode, err = lfs.attributes( f, "mode" )
            local ext = string.match( file, ".-[^\\/]-%.?([^%.\\/]*)$" )
            if mode == "file" and ext == "nfo" then
                return true
            end
        end
    end
    return false
end

local directory_has_valid_sfv = function( path )
    for file in lfs.dir(path) do
        if file ~= "." and file ~= ".." then
            local f = path .. "/" .. file
            local mode, err = lfs.attributes( f, "mode" )
            local ext = string.match( file, ".-[^\\/]-%.?([^%.\\/]*)$" )
            if type( err ) == "nil" and mode == "file" and ext == "sfv" then
                for line in io.lines(f) do
                    --if string.len( line ) > 0 and not ( string.gsub( line, 1, 1 ) == ";" ) then
                    if string.len( line ) > 0 and not ( string.find( line, ";" ) == 1 ) then
                        local sfv_filename, sfv_checksum = line:match("([^,]+) ([^,]+)")
                        if type( sfv_filename ) == "string" then
                            local sfv_mode, sfv_err = lfs.attributes( path .. "/" .. tostring( sfv_filename ), "mode" )
                            if type( sfv_err ) == "string" or sfv_mode == "nil" then
                                return false
                            end
                        end
                    end
                end
                return true
            end
        end
    end
    return false
end

local search = function( path, cfg, found )
    local count = 0
    for release in lfs.dir( path ) do
        local f = path .. "/" .. release
        local mode, err = lfs.attributes( f ).mode

        if ( release ~= "." ) and ( release ~= "..") and ( not announce.blocked[ release ] ) and ( not alreadysent[ release ] ) then
            --// blacklist check
            if match( release, cfg.blacklist ) then
                count = count + 1
                log.event( "Release: '" .. release .. "' blocked. | Reason: " .. "Blacklist" )
            --// whitelist check
            elseif ( not match( release, cfg.whitelist, true ) ) then
                count = count + 1
                log.event( "Release: '" .. release .. "' blocked. | Reason: " .. "Whitelist" )
            --// whitespaces check
            elseif ( cfg.checkspaces and check_for_whitespaces( release ) ) then
                count = count + 1
                log.event( "Release: '" .. release .. "' blocked. | Reason: " .. "Whitespaces" )
            --// max age check
            elseif ( cfg.checkage and cfg.maxage > 0 and age_in_days( lfs.attributes( f ).modification ) >= cfg.maxage ) then
                count = count + 1
                log.event( "Release: '" .. release .. "' blocked. | Reason: " .. "Max Age" )
            --// nfo check
            elseif ( cfg.checkdirs and cfg.checkdirsnfo and not directory_has_nfo( f ) ) then
                count = count + 1
                log.event( "Release: '" .. release .. "' blocked. | Reason: " .. "NFO Check: No NFO file found" )
            --// sfv check
            elseif ( cfg.checkdirs and cfg.checkdirssfv and not directory_has_valid_sfv( f ) ) then
                count = count + 1
                log.event( "Release: '" .. release .. "' blocked. | Reason: " .. "SFV Check" )
            else
                --found[ release ] = cfg
                if mode then
                    if mode == "directory" then
                        if cfg.checkdirs then
                            found[ release ] = cfg
                        end
                    end
                    if mode == "file" then
                        if cfg.checkfiles then
                            found[ release ] = cfg
                        end
                    end
                else
                    log.event( "Error: " .. err )
                end
            end
        end
    end
    log.event( "Releases blocked: " .. count )
end

announce = { }
announce.blocked = { }

announce.update = function( )
    local file, err = loadfile( CFG_PATH .. "rules.lua" )
    if not err then
        file( )
    else
        log.event( "Your rules.lua is broken: " .. err .. "; Using old configuration." )
    end
    local found = { }
    log.event( "Search directories for updates..." )
    for key, cfg in pairs( rules ) do
        if cfg.active then
            local path = cfg.path
            path = tostring( path )
            local mode, err = lfs.attributes( path, "mode" )
            if mode ~= "directory" then
                log.event( "Warning: directory '" .. path .. "' is not a directory or does not exist, skipping..." )
            elseif ( ( type( cfg.blacklist ) ~= "table" ) or type( cfg.whitelist ) ~= "table" ) then
                log.event( "Warning: config for '" .. path .. "' is broken, skipping..." )
            else
                log.event( "Searching in '" .. path .. "'..." )
                if cfg.daydirscheme then
                    if cfg.zeroday then
                        local today = path .. "/" .. os.date( "%m%d" )
                        local mode = lfs.attributes( today, "mode" )
                        if mode ~= "directory" then
                            log.event( "Warning: directory '" .. today .. "' seems not to exist, skipping..." )
                        else
                            search( today, cfg, found )
                        end
                    else
                        for dir in lfs.dir( path ) do
                            if ( dir ~= "." ) and ( dir ~= "..") then
                                local n = tonumber( dir )
                                local d, m = string.match( dir, "(%d%d)(%d%d)" )
                                if n and check_number_between( m, 1, 31 ) and check_number_between( d, 1, 12 ) then
                                    search( path .. "/" .. dir, cfg, found )
                                else
                                    log.event( "Warning: directory '" .. dir .. "' fits not in 4 digit day dir scheme, skipping..." )
                                end
                            end
                        end
                    end
                else
                    search( path, cfg, found )
                end
            end
        end
    end
    local c = 0
    for i, k in pairs( found ) do c = c + 1 end
    log.event( "...finished. Found " .. c .. " new releases." )
    return found
end