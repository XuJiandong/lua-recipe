-- use io.popen to get output from linux/unix command
-- then parse them.
-- it may also support windows but needs different command lines.
-- quite useful for small standalone tools.
local pkg = {}

-- return file names set under path
-- it's possible to use "*", "?", which "ls" support
function pkg.getFiles(path)
    local result = {}
    local output = io.popen("ls " .. path .. " | cat")
    for line in output:lines() do
        table.insert(result, line)
    end
    output:close()
    return result
end


function pkg.test()
    local function fileExists(f, files)
        for i, v in ipairs(files) do
            if f == v then return true end
        end
        return false 
    end

    local files = pkg.getFiles("/usr/bin")
    assert(fileExists("yes", files))
    assert(fileExists("id", files))
    assert(fileExists("top", files))
    print("Popen test passed")
end

return pkg