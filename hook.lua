


-- hook functions (in table or not)
-- can be a simple way to trace function
local hook = {}

function hook:init(outputFunc)
    self.outputFunction = outputFunc
    if not self.functionTable then
        self.functionTable = {}
    end
end

function hook:output(...)
    self.outputFunction(...)
end

function hook:hook(tbl, func, printTrace)
    local origFunc = rawget(tbl, func)
    if not origFunc then
        self:output("the function name is not in table: " .. func)
        return
    end

    local entry = self.functionTable[tbl]
    if not entry then
        entry = {}
        self.functionTable[tbl] = entry
    else
        if entry[func] then
            self:output("hooked already, abort : " .. func)
            return
        end
    end
    entry[func] = origFunc
    local newFunc = function (...)
        self:output("hooked: entering " .. func)
        if printTrace then
            self:output("Trace : " .. debug.traceback())
        end
        local arg = {origFunc(...)}
        self:output("hooked: leaving  " .. func)
        return unpack(arg)
    end
    self:output("hooked: " .. func)
    rawset(tbl, func, newFunc)
end

function hook:restore(tbl, func)
    local entry = self.functionTable[tbl]
    if not entry then
        self:output("can't find the table: " .. tostring(tbl))
        return
    end
    local origFunc = entry[func]
    if not origFunc then
        self:output("error, can't find function : " .. func)
        return
    end

    if not rawget(tbl, func) then
        self:output("the function is not in table: " .. func)
        return
    end
    rawset(tbl, func, origFunc)
    self.functionTable[tbl][func] = nil
end

function hook:restoreAll()
    for tbl, entry in pairs(self.functionTable) do
        for func, origFunc in pairs(entry) do
            rawset(tbl, func, origFunc)
        end
    end
    self.functionTable = {}
end

function hook.test()
    local result = {}
    local _print = function (...)
        table.insert(result, table.concat({...})) 
    end
    hook:init(_print)
    local funcName = "testFunction"
    rawset(_G, funcName, function ()
        _print(funcName .. "() called")
    end
    )
    _print("hooked")
    hook:hook(_G, funcName)
    -- check double hook
    hook:hook(_G, funcName)
    testFunction()
    hook:restore(_G, funcName)
    _print("restored")
    testFunction()

    _print("start testing on functions in table")
    local instance = {}
    function instance:testFunction(param1, param2)
        _print("instance:TestFunction()")
    end
    hook:hook(instance,"testFunction", true)
    instance:testFunction("first", "sencond")
    _print("restoreAll()")
    hook:restoreAll()
    instance:testFunction()
    -- print(table.concat(result, "\n"))
    assert(result[1] == "hooked")
    assert(result[2] == "hooked: testFunction")
    assert(result[3] == "hooked already, abort : testFunction")
    assert(result[4] == "hooked: entering testFunction")
    assert(result[5] == "testFunction() called")
    assert(result[6] == "hooked: leaving  testFunction")
    assert(result[7] == "restored")
    assert(result[8] == "testFunction() called")
    assert(result[9] == "start testing on functions in table")
    assert(result[10] == "hooked: testFunction")
    assert(result[11] == "hooked: entering testFunction")
    -- trace skipped, too long
    assert(result[13] == "instance:TestFunction()")
    assert(result[14] == "hooked: leaving  testFunction")
    assert(result[15] == "restoreAll()")
    assert(result[16] == "instance:TestFunction()")
    print("Hook test passed")
end

return hook

