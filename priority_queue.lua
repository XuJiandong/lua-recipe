
-- from http://lua-users.org/files/wiki_insecure/users/rici/pq.lua
-- with changes
-- ---------------------------------------------------------------
-- package pq
-- ---------------------------------------------------------------
-- 
-- Each object in the queue has a "priority"; a priority function needs to be
-- provided when the heap is first created. The object at queue[1] (the "top"
-- of the queue) is guaranteed to have the "lowest" priority. The priority
-- is implicit in the definition of a comparison function.
--
-- Objects can change their priority but they must inform the queue by using
-- the up, down or put methods; otherwise the queue will lose consistency.
-- Up is towards the top; it should be called if the object has "decreased"
-- its priority.
--
-- The comparison function (the argument "lt" to the constructor) returns true
-- if its first argument is "higher priority" than its second argument. This
-- will work equally well with a less-than-or-equal function, if that is what
-- you have available, but it is necessary that all objects be comparable with
-- each other. (It could have equally well have been called gt, but the reason
-- for choosing lt may be clearer from the examples.)
-- 
-- You cannot put a number in a priority queue. You should probably use a heap
-- for that. I don't guarantee that false will work, either. Normally elements
-- in a priority queue are complex objects. Unlike a heap, a priority queue
-- can only have one instance of any object.
--
-- The getn function will return the number of elements in the queue. setn is
-- not supported. It is not guaranteed that elements are in any particular
-- order, except that the first element is the lowest. You can iterate over
-- queue elements with table.foreachi, or with queue.each (the latter does not
-- give you indices, which are not of much use anyway, but is probably slower.)
--
-- You can query if an object is in the queue with table lookup, but you must
-- not assign the value of any heap key. It is safe, and probably no slower,
-- to use the functional interface and forget the fact that the queue
-- is implemented as a table.

-- Constructors
--   p = pq.new(lt)
--     Creates a new empty queue with the given comparator.
--   fn = pq.factory(lt)
--     Creates a function which will create a new queue with the given
--     comparator; the function expects a table as an argument and
--     uses values from the table as initial heap elements. (It does not
--     reuse the table.)
-- Reconstructors:
--   pq.reheap(p[, lt])
--     Rebuilds the queue, optionally with a new priority function.
--     This will not necessarily make a heap consistent, but it will
--     work if the queue has not been seriously damaged.
--   pq.rebuild(p[, lt])
--     makes the queue consistent. If the second argument is provided,
--     replaces the queue's comparator function. If the queue has been seriously
--     damaged, this may cause elements to be deleted from the queue, but the
--     result will be consistent.
--   pq or nil, error = heap.checkconsistency(p)
--     returns the queue if it is consistent;
--     otherwise returns nil, and error information
-- Metadata Accessors:
--   lt = pq.lt(p)
--     Returns the queue's priority comparator function.
--   object = pq.top(p)
--     Returns the top of the heap; equivalent to h[1]
--   n = pq.getn(p)
--     Returns the number of elements in the queue. This is equivalent to
--     table.getn()
--   bool = pq.contains(p, object)
--     Returns nil if the queue contains the object: otherwise a true value
--     Equivalent to h[object]. No significance should be placed on the
--     return value other than its non-nilness.
-- Heap operations:
--   object = pq.pop(p)
--     Removes and returns the object at the top of the queue, or nil if the
--     queue was empty.
--   object = pq.remove(p, obj)
--     Removes obj from the queue and returns it; if it was not in the heap,
--     returns nil
--   pq.put(p, object)
--     Adds the object to the queue if it is not present; repositions it if
--     it is. Note: put is essentially defined as
--       pq.up(p, object) or pq.down(object)
--     You can do that yourself if you prefer.
--   object = pq.replace(p, object)
--     if the new object is already in the queue, repositions it according to
--     its priority and returns nil. If the object is not in the queue, adds it,
--     and removes and returns the top (which may be the object itself). This
--     is not the same as put followed by pop, unless the object was not
--     previously in the queue.
--     This is guaranteed to maintain the queue at the same size.
--   pq.limitput(p, n, object)
--     Repositions the object if it is present; adds it if it is not and
--     there are less than n objects in the queue; otherwise returns
--     pq.replace(p, object). This is guaranteed to maintain the queue at
--     no more than n elements, and will never shrink the queue; it is
--     intended for applications like LRU caches.
--   bool = pq.up(p, object)
--     Repositions the object upwards (towards the top) of the queue. If the
--     object's priority has actually increased, the object will not move
--     and the queue will be inconsistent. If the object is not in the queue,
--     it is added (and positioned correctly). Returns true if the queue was
--     changed.
--   bool = pq.down(p, object)
--     Repositions the object downwards in the queue. If the object's priority
--     has actually decreased, the object will not move and the queue will be
--     inconsistent. If the object is not in the queue, adds it and positions
--     it correctly. Returns true if the queue was changed.
--     
-- Iterators:
--   <nexter, p, nil> = pq.each(p)
--     iterator to non-destructively run through all queue elements in an
--     unspecified order.
--   <pq.pop, p, nil> = pq.unstack(p)
--     convenience iterator to run through all elements, popping them as
--     it proceeds.
--   val = pq.foreach(p, fn)
--     iteration function; pops each element and calls fn; if that
--     returns a non-nil value, that is returned and the iteration
--     terminates.
--   
-- Usage hints:
--   1. Use pq.up() or pq.down() if you know in which direction the priority of 
--      the object has changed. Do not use them if you don't.
--   2. pq.replace is probably better than pq.put followed by pq.pop. 
--   3. Avoid calling pq.rebuild unless you really really have to. If you
--      want to bulk add elements to the heap with table.insert, or to
--      convert a table into a priority queue, you can use pq.reheap (with the
--      caveat that the table must not have any non-integer keys).
--   4. You can extract elements from the queue in order with:
--        for obj in pq.pop, p do end
--      pq.each does not do this; it returns the elements without removing
--      them, in an unspecified order (except that top comes first).
--      pq.unstack(p) is a convenience function which returns pq.pop, p

-- weak-keyed table to stash comparators into.
local comps = setmetatable({}, {__mode = "k"})

local pkg = {}
local table = table or package.table
local math = math or package.math
local getn = function (t) return #t end -- changed in lua5.1
local setn = function (t) end -- removed in lua5.1
local floor = math.floor

-- Constructors
function pkg.new(lt)
    local self = {}
    comps[self] = assert(lt, "Heap requires a comparator function ")
    return self
end

function pkg.factory(lt)
    return function (tab)
        local self = pkg.new(lt)
        table.foreachi(tab, function (i, v) table.insert(self, v) end)
        pkg.reheap(self)
        return self
    end
end
-- Accessors
pkg.getn = getn

function pkg.lt(h) return comps[h] end

function pkg.top(h)
    if not comps[h] then error "Not a heap"
    else return h[1]
    end
end

function pkg.contains(h, obj)
    if not comps[h] then error "Not a heap"
    else return type(obj) ~= "number" and h[obj]
    end
end

-- Motion. upi is faster and handles the case where i is nil.
local function upi(h, lt, obj, i)
    local handled
    if not i then 
        i = getn(h) + 1
        h[i], h[obj] = obj, i
        setn(h, i)
        handled = true
    end
    local j = floor(i/2)
    local hj = h[j]
    if j == 0 or lt(hj, obj) then return handled end
    repeat 
        h[hj], h[i] = i, hj
        i, j = j, floor(j/2)
        hj = h[j]
    until j == 0 or lt(hj, obj)
    h[obj], h[i] = i, obj
    return true
end

local function downi(h, lt, obj, i)
    local n = getn(h)
    local j = i * 2
    if j > n then return end
    local hj = h[j]
    if j < n then
        local j1 = j + 1
        local hj1 = h[j1]
        if lt(hj1, hj) then j, hj = j1, hj1 end
    end
    if lt(obj, hj) then return end
    repeat
        h[hj], h[i] = i, hj
        i, j = j, j * 2
        if j > n then break end
        hj = h[j]
        if j < n then
            local j1 = j + 1
            local hj1 = h[j1]
            if lt(hj1, hj) then j, hj = j1, hj1 end
        end
    until lt(obj, hj)
    h[obj], h[i] = i, obj
    return true
end

function pkg.up(h, obj)
    local lt = comps[h] or error "Not a heap"
    -- TODO: undefined i
    return upi(h, lt, obj, i)
end

function pkg.down(h, obj)
    local lt = comps[h] or error "Not a heap"
    local i = h[obj]
    if i then return downi(h, lt, obj, i)
    else return upi(h, lt, obj, i)
    end
end

function pkg.put(h, obj)
    local lt = comps[h] or error "Not a heap"
    local i = h[obj]
    local _ = upi(h, lt, obj, i) or downi(h, lt, obj, i)
end

function pkg.pop(h)
    local lt = comps[h] or error "Not a heap"
    local rv = h[1]
    if rv then
        local n = getn(h)
        if n == 1 then
            h[1], h[rv] = nil
            setn(h, 0)
        else
            local hn = h[n]
            h[1], h[hn], h[n], h[rv] = hn, 1
            setn(h, n - 1)
            downi(h, lt, hn, 1)
        end
    end
    return rv
end

function pkg.remove(h, obj)
    local lt = comps[h] or error "Not a heap"
    local i, n = h[obj], getn(h)
    if not i then return nil end
    setn(h, n - 1)
    if i == n then
        h[i], h[obj] = nil
    else
        local hn = h[n]
        h[i], h[hn], h[n], h[obj] = hn, i
        downi(h, lt, hn, i)
    end
    return obj
end

function pkg.replace(h, obj)
    local lt = comps[h] or error "Not a heap"
    local i = h[obj]
    local rv
    if i then
        local _ = upi(h, lt, obj, i) or downi(h, lt, obj, i)
    else
        rv = h[1]
        if not rv or lt(obj, rv) then return obj end
        h[1], h[rv], h[obj] = obj, nil, 1
        downi(h, lt, obj, 1)
    end
    return rv
end

function pkg.checkconsistency(h)
    local lt = comps[h]
    if not lt then return nil, "Not a heap" end
    local n = getn(h)
    local objs = {}
    -- check that all indexes exist and are consistent
    for i = 1, n do
        local hi = h[i]
        if not hi then
            return nil, "Heap inconsistent", "nil index", i
        elseif h[hi] ~= i then
            return nil, "Heap inconsistent", "backlink incorrect", i
        elseif objs[hi] then
            return nil, "Heap inconsistent", "repeated object", i
        else
            objs[i], objs[hi] = i, hi
        end
    end
    -- check that there are no stray objects
    for k, v in h do
        if not objs[k] then
            return nil, "Heap inconsistent", "stray object", k, v
        end
    end
    -- Now actually check the heap condition
    for i = 1, (n - 1) / 2 do
        if not lt(h[i], h[2 * i]) then
            return nil, "Heap inconsistent", "failed heap condition", i, 2 * i
        elseif not lt(h[i], h[2 * i + 1]) then
            return nil, "Heap inconsistent", "failed heap condition", i, 2 * i
        end
    end
    -- the gettable will return nil if n is odd :)
    if h[n / 2] and not lt(h[n / 2], h[n]) then
        return nil, "Heap inconsistent", "failed heap condition", n / 2, n
    end
    -- that's all the tests I can think of :)
    return true
end

-- Reconstructors
-- (Not the optimal algorithm; should be like heap.reheap, which
-- is linear time)
function pkg.reheap(h, lt)
    if lt then comps[h] = lt
    else lt = comps[h]
        if not lt then
            error "Not a heap and no comparator specified"
        end
    end
    for i = 2, getn(h) do
        local hi = h[i]
        h[hi] = i
        upi(h, lt, hi, i)
    end
    return h
end

function pkg.rebuild(h, lt)
    if lt then comps[h] = lt
    else lt = comps[h]
        if not lt then
            error "Not a heap and no comparator specified"
        end
    end
    -- just get rid of anything extraneous. This is not so easy in Lua
    local valid = {}
    -- first we'll find the reasonably valid objects, and remember
    -- all their indices
    local j = 1
    for i = 1, getn(h) do
        local hi = h[i]
        if hi and type(hi) ~= "number" then
            h[j], valid[j], valid[hi], j = hi, true, true, j + 1

        end
    end
    -- Now, we'll look for anything we didn't yet find
    for k, v in h do
        if not valid[k] then valid[k] = false end
    end
    -- Now, every key in the table is in valid, and the false ones are
    -- redundant, so we can delete them
    for k, v in valid do
        if not v then h[k] = nil end
    end
    -- Reset the element count
    setn(h, j - 1)
    -- At which point it is good enough to reheap
    return pkg.reheap(h)
end

-- iterators

function pkg.each(h)
    local i, n = 1, getn(h)
    local function nexter(h)
        if i <= n then
            i = i + 1
            return h[n]
        end
    end
    return nexter, h, nil
end

function pkg.unstack(h)
    return pkg.pop, h, nil
end

function pkg.foreach(h, fn)
    for obj in pkg.pop, h do
        local val = fn(obj)
        if val then return val end
    end
end

function pkg.limitput(h, n, obj)
    if h[obj] or getn(h) < n then pkg.put(h, obj)
    else return pkg.replace(h, obj)
    end
end

function pkg.test()
    local function compare(a, b)
        return a.pri < b.pri
    end
    local function gen(n)
        local r = {}
        r.pri = n
        return r
    end
    local pq = pkg.new(compare)
    pkg.put(pq, gen(10))
    pkg.put(pq, gen(9))
    assert(pkg.top(pq).pri == 9)
    pkg.put(pq, gen(8))
    assert(pkg.top(pq).pri == 8)
    pkg.pop(pq)
    assert(pkg.top(pq).pri == 9)
    print("Priotity queue passed")
end

return pkg



