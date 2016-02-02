--[[

    - originally written by blastbeat, 20141008
        - rewritten by pulsar for Luadch Announcer Client

]]--


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

local directory_has_nfo = function( path )
    local lfs_a = lfs.attributes
    for file in lfs.dir(path) do
        if file ~= "." and file ~= ".." then
            local f = path .. "/" .. file
            local mode, err = lfs_a( f, "mode" )
            local ext = string.match( file, ".-[^\\/]-%.?([^%.\\/]*)$" )
            if mode == "file" and ext == "nfo" then
                return true
            end
        end
    end
    return false
end

local directory_has_valid_sfv = function( path )
    local lfs_a = lfs.attributes
    for file in lfs.dir(path) do
        if file ~= "." and file ~= ".." then
            local f = path .. "/" .. file
            local mode, err = lfs_a( f, "mode" )
            local ext = string.match( file, ".-[^\\/]-%.?([^%.\\/]*)$" )
            if type( err ) == "nil" and mode == "file" and ext == "sfv" then
                for line in io.lines(f) do
                    if string.len( line ) > 0 and not ( string.gsub( line, 1, 1 ) == ";" ) then
                        local sfv_filename, sfv_checksum = line:match("([^,]+) ([^,]+)")
                        if type( sfv_filename ) == "string" then
                            local sfv_mode, sfv_err = lfs_a( path .. "/" .. tostring( sfv_filename ), "mode" )
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
    local lfs_a = lfs.attributes
    for release in lfs.dir( path ) do
        local f = path .. "/" .. release
        local mode, err = lfs_a( f ).mode
        if ( release ~= "." ) and ( release ~= "..") and ( not announce.blocked[ release ] ) and ( not alreadysent[ release ] ) then
            if match( release, cfg.blacklist )
            or ( not match( release, cfg.whitelist, true ) )
            or ( cfg.checkspaces == true and check_for_whitespaces( release ) )
            or ( cfg.checkage == true and cfg.maxage > 0 and age_in_days( lfs_a( f ).modification ) >= cfg.maxage )
            or ( cfg.checkdirs and cfg.checkdirsnfo and not directory_has_nfo( f ) )
            or ( cfg.checkdirs and cfg.checkdirssfv and not directory_has_valid_sfv( f ) ) then
                --log.event( "Release '" .. release .. "' blocked." )
                count = count + 1
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
                                if n and ( 0101 <= n ) and ( 1231 >= n ) then  -- rough estimate; 1199 is still allowed, though
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