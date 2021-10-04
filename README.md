# Luadch Announcer Client
[![Latest-Release](https://img.shields.io/github/v/release/luadch/announcer_client?include_prereleases)](https://github.com/luadch/announcer_client/releases)
[![GitHub license](https://img.shields.io/badge/license-GPLv3.0-blueviolet.svg)](https://github.com/luadch/announcer_client/blob/master/LICENSE)
[![Website](https://img.shields.io/website?down_message=offline&up_message=online&url=https%3A%2F%2Fluadch.github.io)](https://luadch.github.io/)
[![Platform](https://img.shields.io/badge/Platform-Windows-orange.svg)](https://luadch.github.io/)

Win32 Release Announcer for Luadch (with GUI)


## First start:

1. goto "certs" folder
    * Use "make_cert.bat" to make a new certificate (required) Note: OpenSSL must be installed
    * Alternatively you can use the Luadch Certmanager if you don't want to install OpenSSL
        * Certmanager Link: https://github.com/luadch/certmanager/releases

2. Start "Announcer.exe" and make your configuration

3. Click the "Connect" button

Done!

## You already use the Announcer and you only want to update:

1. Copy the "certs" and the "cfg" folder from your old Announcer folder to the new Announcer folder, overwrite all existing files

Done!
	
## Compile a ".lua" (wxLua) to a ".exe":

1. First you need wxLua binarys: [wxLua-2.8.12.3-Lua-5.1.5-MSW-Unicode.zip](https://sourceforge.net/projects/wxlua/files/wxlua/2.8.12.3/wxLua-2.8.12.3-Lua-5.1.5-MSW-Unicode.zip/download "")
2. Copy the "Announcer.wx.lua" to the "wxLua/bin/" directory
3. Open command prompt (in this folder)

use this command:

    lua.exe ..\apps\wxluafreeze\wxluafreeze.lua wxluafreeze.exe "Announcer.wx.lua" "Announcer.exe"

*note: there are better ways to do this, but it's the easiest way. (i'am using Notepad++ with integrated Lua/wxLua interpreter and macro shortcuts for "run" and "compile")*