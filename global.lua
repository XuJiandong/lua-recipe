-- from http://lua-users.org/lists/lua-l/2006-05/msg00306.html
-- find undefined global vars
-- typical usage: luac -p -l *.lua | lua global.lua

local S = {}
local G = {}
local F

while true do
    local s = io.read()
    if s == nil then break end
    local ok, _, f = string.find(s,"^[mf].-<(.-):[%d,]+>")
    if ok then F = f end
    -- parse string like following:
    --  3   [4] GETGLOBAL   2 -2    ; wrongWord
    local ok, _, l, op, g = string.find(s,"%[%-?(%d*)%]%s*([GS])ETGLOBAL.-;%s+(.*)$")
    if ok then
        if op == "S" then 
            S[g] = true 
        else 
            G[g] = F.. ":" .. l 
        end
    end
end

local r, msg = loadfile("./user_defined_global.lua")
local U = {}
if r then
    U = r()
end

for k, v in pairs(G) do
    if not S[k] and not _G[k] and not U[k] then
        print(k, " may be undefined in ", v)
    end
end

