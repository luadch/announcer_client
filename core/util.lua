--[[

    util.lua written by blastbeat
    
    based on "luadch/core/util.lua"

]]--

local sortserialize
local savearray
local savetable
local loadtable
local formatbytes

local string_format = string.format
 
sortserialize = function( tbl, name, file, tab, r )
    tab = tab or ""
    local temp = { }
    for key, k in pairs( tbl ) do
        --if type( key ) == "string" or "number" then
            table.insert( temp, key )
        --end
    end
    table.sort( temp )
    local str = tab .. name
    if r then
        file:write( str .. " {\n\n" )
    else
        file:write( str .. " = {\n\n" )
    end
    for k, key in ipairs( temp ) do
        if ( type( tbl[ key ] ) ~= "function" ) then
            local skey = ( type( key ) == "string" ) and string.format( "[ %q ]", key ) or string.format( "[ %d ]", key )
            if type( tbl[ key ] ) == "table" then
                sortserialize( tbl[ key ], skey, file, tab .. "    " )
                file:write( ",\n" )
            else
                local svalue = ( type( tbl[ key ] ) == "string" ) and string.format( "%q", tbl[ key ] ) or tostring( tbl[ key ] )
                file:write( tab .. "    " .. skey .. " = " .. svalue )
                file:write( ",\n" )
            end
        end
    end
    file:write( "\n" )
    file:write( tab .. "}" )
end
 
savetable = function( tbl, name, path )
    local file, err = io.open( path, "w+" )
    if file then
        if name == "return" then
            sortserialize( tbl, name, file, "", true )
        else
            sortserialize( tbl, name, file, "" )
            file:write( "\n\nreturn " .. name )
        end
        file:close( )
        return true
    else
        return false, err
    end
end
 
loadtable = function( path )
    local file, err = io.open( path, "r" )
    if not file then
        return nil, err
    end
    local content = file:read "*a"
    file:close( )
    local chunk, err = loadstring( content )
    if chunk then
        local ret = chunk( )
        if ret and type( ret ) == "table" then
            return ret
        else
            return nil, "invalid table"
        end
    end
    return nil, err
end
 
savearray = function( array, path )
    array = array or { }
    local file, err = io.open( path, "w+" )
    if not file then
        return false, err
    end
    local iterate, savetbl
    iterate = function( tbl )
        local tmp = { }
        for key, value in pairs( tbl ) do
            tmp[ #tmp + 1 ] = tostring( key )
        end
        table.sort( tmp )
        for i, key in ipairs( tmp ) do
            key = tonumber( key ) or key
            if type( tbl[ key ] ) == "table" then
                file:write( ( ( type( key ) ~= "number" ) and tostring( key ) .. " = " ) or " " )
                savetbl( tbl[ key ] )
            else
                file:write( ( ( type( key ) ~= "number" and tostring( key ) .. " = " ) or "" ) .. ( ( type( tbl[ key ] ) == "string" ) and string.format( "%q", tbl[ key ] ) or tostring( tbl[ key ] ) ) .. ", " )
            end
        end
    end
    savetbl = function( tbl )
        local tmp = { }
        for key, value in pairs( tbl ) do
            tmp[ #tmp + 1 ] = tostring( key )
        end
        table.sort( tmp )
        file:write( "{ " )
        iterate( tbl )
        file:write( "}, " )
    end
    file:write( "return {\n\n" )
    for i, tbl in ipairs( array ) do
        if type( tbl ) == "table" then
            file:write( "    { " )
            iterate( tbl )
            file:write( "},\n" )
        else
            file:write( "    " .. string.format( "%q", tostring( tbl ) ) .. ",\n" )
        end
    end
    file:write( "\n}" )
    file:close( )
    return true
end

formatbytes = function( bytes )
    local err
    local bytes = tonumber( bytes )

    --if ( not bytes ) or ( not type( bytes ) == "number" ) or ( bytes < 0 ) or ( bytes == 1 / 0 ) then
    if not bytes then
        err = "util.lua: error: number expected, got nil"
        return nil, err
    end
    if not type( bytes ) == "number" then
        err = "util.lua: error: number expected, got " .. type( bytes )
        return nil, err
    end
    if ( bytes < 0 ) or ( bytes == 1 / 0 ) then
        err = "util.lua: error: parameter not valid"
        return nil, err
    end
    if bytes == 0 then return "0 B" end
    local i, units = 1, { "B", "KB", "MB", "GB", "TB", "PB", "EB", "YB" }
    while bytes >= 1024 do
        bytes = bytes / 1024
        i = i + 1
    end
    
    if units[ i ] == "B" then
        return string_format( "%.0f", bytes ) .. " " .. ( units[ i ] or "?" )
    else
        return string_format( "%.2f", bytes ) .. " " .. ( units[ i ] or "?" )
    end
end

return {
 
    savetable = savetable,
    loadtable = loadtable,
    savearray = savearray,
    formatbytes = formatbytes,
 
}