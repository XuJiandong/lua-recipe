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

function pkg.exist(f)
    -- also redirect stderr to stdout
    local cmd = "ls " .. f .. " 2>&1"
    local output = io.popen(cmd, "r")
    for line in output:lines() do
        if string.find(line, "cannot access") then
            return false
        end
    end
    return true
end

function pkg.loadFileBz2(file)
    local output = io.popen("bzip2 -d -c -k " .. file)
    local all = output:read("*a")
    return loadstring(all)
end

function pkg.loadFileGzip(file)
    local output = io.popen("zcat " .. file)
    local all = output:read("*a")
    return loadstring(all)
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
    assert(pkg.exist("/usr/bin"))

    local a = pkg.loadFileBz2("./test/popen.lua.bz2")
    local aa =  assert(a)()
    assert(aa.loadFileBz2)
    local b = pkg.loadFileGzip("./test/popen.lua.gz")
    local bb = assert(b)()
    assert(bb.loadFileGzip)

    print("Popen test passed")
end

return pkg
