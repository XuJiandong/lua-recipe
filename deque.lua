#!/usr/bin/env lua

module("lua_recipe_deque", package.seeall)

-- objects can only be pushed/popped on two ends
-- implemented by 2 tables (stacks)
-- lua array is fater and use less space than normal table.
-- see 
-- www.lua.org/doc/jucs05.pdf
-- 4. Table
local deque = {}

function deque.new()
    local d = {}
    d.stack1 = {}
    d.stack2 = {}
    return d
end

function deque.clear(d)
   d.stack1 = {} 
   d.stack2 = {}
end

-- move n/2 objects from "from" to empty "to" stack 
function deque.balance(to, from)
    assert(#to == 0)
    if #from == 0 then return end
    local n = #from
    -- make sure number of objects to be moved is greater 
    -- than to be kept (at most 1)
    local kept = math.modf(n/2, 1)
    local moved = n - kept
    for i = moved, 1, -1 do
        table.insert(to, from[i])
    end
    -- move [moved+1, n] to [1, kept]
    for i = moved+1, n do
        from[i-moved] = from[i]
    end
    -- clear[kept+1, n] to nil
    for i = kept+1, n do
        from[i] = nil
    end
end

function deque.push1(d, obj)
    table.insert(d.stack1, obj)
end

function deque.pop1(d)
    if #d.stack1 == 0 then
        deque.balance(d.stack1, d.stack2)
    end
    return table.remove(d.stack1)
end

function deque.push2(d, obj)
    table.insert(d.stack2, obj)
end

function deque.pop2(d)
    if #d.stack2 == 0 then
        deque.balance(d.stack2, d.stack1)
    end
    return table.remove(d.stack2)
end

function deque.size(d)
    return #d.stack1+#d.stack2
end


function deque.test()
    local d = deque.new()
    deque.push1(d, 1)
    assert(deque.pop2(d) == 1)

    deque.push1(d, 1)
    assert(deque.pop1(d) == 1)
    
    deque.push1(d, 1)
    deque.push1(d, 2)
    assert(deque.pop2(d) == 1)
    assert(deque.pop2(d) == 2)
    
    deque.push1(d, 1)
    deque.push1(d, 2)
    assert(deque.pop1(d) == 2)
    assert(deque.pop1(d) == 1)
    assert(deque.size(d) == 0)

    assert(deque.pop1(d) == nil)
    assert(deque.pop2(d) == nil)
    print("Deque test passed")
end

return deque
