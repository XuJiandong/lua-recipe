local pkg = {}

-- modified from http://stackoverflow.com/questions/6075262/lua-table-tostringtablename-and-table-fromstringstringtable-functions
-- TODO: string concating is inefficient in lua
function pkg.serializeTable(val, name, skipnewlines, depth)
    skipnewlines = skipnewlines or false
    depth = depth or 0
    local tmp = string.rep(" ", depth)
    if name then 
        if type(name) == "string" then
            tmp = string.format("%s[%q] = ", tmp, name)
        elseif type(name) == "number" then
            tmp = string.format("%s[%d] = ", tmp, name)
        else
            assert("not implemented")
        end
    end
    if type(val) == "table" then
        tmp = tmp .. "{" .. (not skipnewlines and "\n" or "")
        for k, v in pairs(val) do
            tmp =  tmp .. pkg.serializeTable(v, k, skipnewlines, depth + 1) .. "," .. (not skipnewlines and "\n" or "")
        end
        tmp = tmp .. string.rep(" ", depth) .. "}"
    elseif type(val) == "number" then
        tmp = tmp .. tostring(val)
    elseif type(val) == "string" then
        tmp = tmp .. string.format("%q", val)
    elseif type(val) == "boolean" then
        tmp = tmp .. tostring(val)
    else
        tmp = tmp .. "\"[inserializeable datatype:" .. type(val) .. "]\""
    end

    return tmp
end

function pkg.test()
    local t = {
        "first",
        "second",
        check = true,
        ["value"] = 100,
        ["value2"] = 1000,
        test = {
            inner = 1001,
            inner2 = "hello,world",
        }
    }
    local s = pkg.serializeTable(t)
    local o = assert(loadstring("return " .. s))()
    assert(o[1] == t[1])
    assert(o[2] == t[2])
    assert(o.check == t.check)
    assert(o.test.inner == t.test.inner)
    print("Serialize table is passed")
end

return pkg
