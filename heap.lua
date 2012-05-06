--
-- from http://lua-users.org/files/wiki_insecure/users/rici/heap.lua
-- with changes for getn and setn (changed in lua5.1)
--
-- Heaps or Priority Queues have been around for a long time, but are
-- surprisingly infrequently used, even though the implementation is
-- straightforward. This implementation is based on Robert Sedgwick's
-- Algorithms in C++ (some of the details are slightly different), but
-- I believe the original idea (as with so many) comes from Donald Knuth.
--
-- I distinguish heaps from priority queues based on the mutability of the
-- objects. This package implements heaps: vectors of simple immutable objects.
-- The vector is semi-ordered: the first element is always the smallest,
-- and there are put and pop operations which work in O(log n) time,
-- where n is the size of the heap.
-- 
-- Technically, these heaps are relaxed binary tree; it has the property
-- that the children of each node are larger than the node, but does
-- not require the left child to be smaller than the right child.
-- Heaps use a clever trick to simulate a tree without the storage
-- and time overhead of maintaining pointers: the children of node i
-- are nodes 2i and 2i+1.
--
-- There are other more sophisticated algorithms which have even better
-- performance for large heaps, but this one is particularly suitable for Lua.
--
-- Heaps are useful when:
--   - you want to always have fast reference to the smallest object
--     in a vector.
--   - you want to sort a vector but you probably are only going to
--     use the first few elements.
-- There is a sorting algorithm based on building heaps, but quicksort
-- is usually faster -- see Sedgwick for more details.
--
-- If you need random access to a sorted vector which accepts insertion and
-- deletion, you probably want a b-tree, not a heap. 
--
-- In some applications, the objects in a vector can change their comparison
-- value over the course of time. A good example of this is a cache in which
-- each object maintains its last reference time; other examples include
-- backtracking search trees where the search heuristic is refined during the
-- course of investigation; or vectors of mutable objects. A priority queue is
-- a heap whose elements "know" where they are in the queue. The "change"
-- operation is also O(log n).
--
-- This implementation takes advantage of Lua's table implementation to
-- keep the location information in the queue itself. (Many implementations
-- require the object to remember its own position.) Putting the
-- information in the priority heap is more robust and does not require
-- changing the implementation of the queued object.
--
-- The priority queue implementation has a richer set of methods; these
-- are described below. 
-- 
-- ------------
-- package heap
-- ------------
-- Constructors:
--   h = heap.new(lt)
--     lt is a comparison function; if not provided, < will be used.
--   fn = heap.factory(lt)
--     Returns a constructor which creates a heap from the values in a
--     table, using the provided lt method (or <). The table is not reused.
-- Metadata accessors:
--   lt = heap.lt(h)
--     Returns the comparison function for the given heap.
--   n = heap.getn(h)
--     This is simply table.getn; it returns the number of objects in
--     the heap. Do not use setn on a heap.
-- Heap operations:
--   heap.put(h, obj)
--     Puts obj into the heap. There may be several instances of the
--     same object in the heap; no check is made for this.
--   obj = heap.pop(h)
--     Removes and returns the smallest object from the heap; if the
--     heap is empty returns nil
--   obj = heap.replace(h, obj)
--     This is technically equivalent to
--       heap.put(h, obj); return heap.pop(h)
--     That is, it returns the obj if it is smallest than the top
--     element of the heap (or the heap is empty); otherwise, it
--     puts obj into the heap and removes and returns the top.
--     It is, therefore, guaranteed to not change the size of
--     the heap. It is usually faster than the combination of put
--     and pop.
-- Iterators:
--   <triple> = heap.first(h, k)
--     Allows iteration over the first k elements of the heap. (These
--     are removed by this operation.)
--   val = heap.foreach(h, fn)
--     Calls fn with each element of the heap in turn (popping it off
--     the heap); if the fn returns a true value, returns it.
-- Reconstructors:
--   heap.reheap(h[, lt])
--     (re)builds the heap, optionally using a different comparison
--     function. This can also be used to convert a table to a heap.
--   h or nil, error = heap.checkconsistency(h)
--     returns the heap if it is consistent; otherwise returns
--     an error message.

-- weak-keyed table to stash comparators into.
local comps = setmetatable({}, {__mode = "k"})
local pkg = {}
local table = table or package.table
local math = math or package.math
local setn = function (t) end -- removed in lua 5.1
local getn = function (t) return #t end 
local floor = math.floor

local function lessthan(a, b) return a < b end
local function greaterthan(a, b) return a > b end
-- Accessors

pkg.getn = getn

function pkg.lt(h) return comps[h] end

function pkg.top(h)
    if not comps[h] then error "Not a heap"
    else return h[1]
    end
end

local function upi(h, lt, obj, i)
    local j = floor(i/2)
    local hj = h[j]
    while j > 0 and lt(obj, hj) do
        h[i] = hj
        i, j = j, floor(j/2)
        hj = h[j]
    end
    h[i] = obj
end

local function downi(h, lt, obj, i, n)
    local j = i * 2
    while j <= n do
        local hj = h[j]
        if j < n then
            local hj1 = h[j + 1]
            if lt(hj1, hj) then
                j = j + 1
                hj = hj1
            end
        end
        if lt(obj, hj) then break end
        h[i] = hj
        i = j
        j = j * 2
    end
    h[i] = obj
end

function pkg.put(h, obj)
    local lt = comps[h] or error "Not a heap"
    local n = getn(h) + 1
    setn(h, n)
    return upi(h, lt, obj, n)
end

function pkg.pop(h)
    local lt = comps[h] or error "Not a heap"
    local rv = h[1]
    if rv then
        local n = getn(h)
        if n > 1 then
            local hn = h[n]
            h[1] = hn 
            h[n] = nil
            n = n - 1
            setn(h, n)
            downi(h, lt, hn, 1, n)
        else
            h[1] = nil
            setn(h, 0)
        end
    end
    return rv
end

function pkg.replace(h, obj)
    local lt = comps[h] or error "Not a heap"
    local rv = h[1]
    if not rv or lt(obj, rv) then return obj end
    h[1] = obj
    downi(h, lt, obj, 1, getn(h))
    return rv
end

function pkg.limitput(h, n, obj)
    if getn(h) < n then pkg.put(h, obj)
    else return pkg.replace(h, obj)
    end
end

-- Constructors

function pkg.new(lt)
    local self = {}
    setn(self, 0)
    comps[self] = lt or lessthan
    return self
end

function pkg.factory(lt)
    return function (tab)
        local self = pkg.new(lt)
        local n = 0
        table.foreachi(tab, function(i, v) 
            upi(self, lt, v, i)
            n = i
        end)
        -- TODO: h is undefined
        setn(h, n)
        return self
    end
end

-- Reconstructor. This is linear time

function pkg.reheap(h, lt)
    lt = lt or comps[h] or lessthan
    comps[h] = lt
    local n = getn(h)
    setn(h, n)
    for i = floor(n / 2), 1, -1 do
        downi(h, lt, h[i], i, n)
    end
    return h
end

-- Fully sort the heap.
function pkg.sort(h)
    lt = comps[h] or error "Not a heap"
    for n = getn(h), 2, -1 do
        local obj = h[n]
        h[n] = h[1]
        downi(h, lt, obj, 1, n - 1)
    end
    return h
end

-- works on any t; just a combination of the above two functions
-- NOTE 1: sorts backwards... The comparator needs to be documented.
-- NOTE 2: a version which actually used > instead of gt would
--         probably be a lot faster. But this is surprisingly ok
function pkg.heapsort(t, gt)
    lt = lt or greaterthan
    local n = getn(t)
    for i = floor(n / 2), 1, -1 do
        downi(t, lt, t[i], i, n)
    end
    while n > 1 do
        local obj = t[n]
        t[n] = t[1]
        n = n - 1
        downi(t, lt, obj, 1, n)
    end
    return t
end

function pkg.checkconsistency(h)
    local lt = comps[h]
    if not lt then return nil, "Not a heap" end
    local n = getn(h)
    -- check for nils
    for i = 1, n do
        if not h[i] then
            return nil, "Heap inconsistent", "nil element"
        end
    end
    -- could check for stray elements here, but that won't impede
    -- heap operations so we don't
    -- check even children with their parents
    for i = 2, n, 2 do
        if not lt(h[i / 2], h[i]) then
            return nil, "Heap inconsistent", "failed heap condition", i / 2, i
        end
    end
    -- check odd children with their parents
    for i = 2, n - 1, 2 do
        if not lt(h[i / 2], h[i + 1]) then
            return nil, "Heap inconsistent", "failed heap condition", i / 2, i + 1
        end
    end
    return true
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

function pkg.test()
    local h = pkg.new()
    pkg.put(h, 10)
    pkg.put(h, 6)
    pkg.put(h, 8)
    pkg.put(h, 4)
    pkg.put(h, 2)
    assert(pkg.pop(h) == 2)
    assert(pkg.pop(h) == 4)
    assert(pkg.pop(h) == 6)
    assert(pkg.pop(h) == 8)
    assert(pkg.pop(h) == 10)

    pkg.put(h, 10)
    pkg.put(h, 6)
    pkg.put(h, 8)
    pkg.put(h, 4)
    pkg.put(h, 2)
    pkg.reheap(h, function (a, b) return a > b end)
    assert(pkg.pop(h) == 10)
    assert(pkg.pop(h) == 8)
    assert(pkg.pop(h) == 6)
    assert(pkg.pop(h) == 4)
    assert(pkg.pop(h) == 2)

    print("Heap passed")
end

return pkg


