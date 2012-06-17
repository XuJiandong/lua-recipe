
local pkg = {}
-- a simple xml parser from http://lua-users.org/wiki/LuaXml
local function parseargs(s)
    local arg = {}
    string.gsub(s, "(%w+)=([\"'])(.-)%2", function (w, _, a)
        arg[w] = a
    end)
    return arg
end

function pkg.collect(s)
    local stack = {}
    local top = {}
    table.insert(stack, top)
    local ni,c,label,xarg, empty
    local i, j = 1, 1
    while true do
        ni,j,c,label,xarg, empty = string.find(s, "<(%/?)([%w:]+)(.-)(%/?)>", i)
        if not ni then break end
        local text = string.sub(s, i, ni-1)
        if not string.find(text, "^%s*$") then
            table.insert(top, text)
        end
        if empty == "/" then  -- empty element tag
            table.insert(top, {label=label, xarg=parseargs(xarg), empty=1})
        elseif c == "" then   -- start tag
            top = {label=label, xarg=parseargs(xarg)}
            table.insert(stack, top)   -- new level
        else  -- end tag
            local toclose = table.remove(stack)  -- remove top
            top = stack[#stack]
            if #stack < 1 then
                error("nothing to close with "..label)
            end
            if toclose.label ~= label then
                error("trying to close "..toclose.label.." with "..label)
            end
            table.insert(top, toclose)
        end
        i = j + 1
    end
    local text = string.sub(s, i)
    if not string.find(text, "^%s*$") then
        table.insert(stack[#stack], text)
    end
    if #stack > 1 then
        error("unclosed "..stack[#stack].label)
    end
    return stack[1]
end

function pkg.test()
    local x = pkg.collect[[
    <methodCall kind="xuxu">
    <methodName>examples.getStateName</methodName>
    <params>
    <param>
    <value><i4>41</i4></value>
    </param>
    </params>
    </methodCall>
    ]]
    local function getLabel(x)
        local label, content
        for k,v in pairs(x) do
            if type(k) == "string" and k == "label" then
                assert(type(v) == "string")
                label = v
            end
            if type(k) == "number" and type(v) == "string" then 
                content = v
            end
        end
        return label, content
    end
    local function searchLabel(x, label)
        local l, c = getLabel(x)
        if l == label then 
            return c 
        end
        for i, v in ipairs(x) do
            if type(v) == "table" then
                local c = searchLabel(v, label)
                if c then return c end
            end
        end
        return nil
    end

    local c = searchLabel(x, "i4")
    assert(c == "41")
    c = searchLabel(x, "methodName")
    assert(c == "examples.getStateName")
    c = searchLabel(x, "value")
    assert(c == nil)
    c = searchLabel(x, "not exist")
    assert(c == nil)
    print("xml test passed")
end

return pkg

