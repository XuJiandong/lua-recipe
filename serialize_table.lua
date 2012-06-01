local pkg = {}

function pkg.serializeTable0(val, name, depth)
    depth = depth or 0
    local res = {}
    if name then 
        if type(name) == "string" then
            table.insert(res,  string.rep(" ", depth) .. string.format("[%q]=", name))
        elseif type(name) == "number" then
            table.insert(res, string.rep(" ", depth) .. string.format("[%d]=", name))
        else
            assert("not implemented")
        end
    end
    if type(val) == "table" then
        table.insert(res, "{\n")
        for k, v in pairs(val) do
            local tmp =  pkg.serializeTable0(v, k, depth + 1)
            for _, v in ipairs(tmp) do
                table.insert(res, v)
            end
            table.insert(res, ",\n")
        end
        table.insert(res, string.rep(" ", depth) .. "}")
    elseif type(val) == "number" or type(val) == "boolean" then
        table.insert(res, tostring(val))
    elseif type(val) == "string" then
        table.insert(res, string.format("%q", val)) 
    else
        assert("not implmented")
    end

    return res
end

-- it's faster to push string into table then concat them 
function pkg.serializeTable(t)
    local s = pkg.serializeTable0(t)
    return table.concat(s, "")
end

function pkg.test()
    local t = {
        "first",
        "second",
        check = true,
        ["value"] = 100,
        ["value2"] = 1000,
        ["value3"] = 1000.1,
        test = {
            "first inner",
            "second innder",
            inner = 1001,
            inner2 = "hello,world",
        }
    }
    local s = pkg.serializeTable(t)
    local o = assert(loadstring("return " .. s))()
    assert(o[1] == t[1])
    assert(o[2] == t[2])
    assert(o.value3 == t.value3)
    assert(o.check == t.check)
    assert(o.test.inner == t.test.inner)
    assert(o.test[1] == t.test[1])
    print("Serialize table is passed")
end

return pkg
