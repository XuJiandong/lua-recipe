
local pkg = {}

function pkg.split(str, del, plain)
    local r = {}
    local oldS, oldE = 0, 0
    while true do
        local s, e = string.find(str, del, oldE+1, plain)
        if not s then
            table.insert(r, str:sub(oldE+1, -1))
            break
        end
        table.insert(r, str:sub(oldE+1, s-1))
        oldS, oldE = s, e
    end
    return r
end


function pkg.test()
    local s = "hello,world"
    local r = pkg.split(s, ",", false)
    assert(r[1] == "hello" and r[2] == "world")

    s = "hello,,world,,42"
    r = pkg.split(s, ",,", true)
    assert(r[1] == "hello" and r[2] == "world" and r[3] == "42")

    s = "hello@@@world###42"
    r = pkg.split(s, "[^a-z0-9]+")
    assert(r[1] == "hello" and r[2] == "world" and r[3] == "42")

    print("string util passed")
end

return pkg

