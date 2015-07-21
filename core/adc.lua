--[[

    - written by blastbeat, 20141008

]]--

local adclib = require "adclib"

adc = { }

adc.createid = function( )
    local str = os.date( ) .. os.clock( ) .. os.time( )
    local salt = "GHKZUGFTDFLIHLHGKGVKHGGH545FGFKH43754KHFKHKHGKDDSWSGDJKGUK6758"
    local pid = adclib.hashpas( salt .. str, str .. salt )
    return pid, adclib.hash( pid )
end

local idfile = loadfile( CFG_PATH .. "id.lua" )
if idfile then
  idfile( )
else
  local idfile, err = io.open( CFG_PATH .. "id.lua", "a+" )
  assert( idfile, "Fail: " .. tostring( err ) )
  local pid, cid = adc.createid( ) 
  idfile:write( "id = { }\nid.pid = '" .. pid .. "'\nid.cid = '" .. cid .. "'\n" )
  idfile:flush( )
  idfile:close( ) 
  id = { pid = pid, cid = cid }
end 
