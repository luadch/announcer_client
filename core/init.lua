--[[

    - written by blastbeat, 20141008

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

dofile "core/const.lua"
dofile "cfg/cfg.lua"
dofile "cfg/sslparams.lua"
dofile "cfg/hub.lua"
dofile "core/log.lua"
dofile "core/adc.lua"
dofile "core/announce.lua"
dofile "cfg/rules.lua"
dofile "core/net.lua"