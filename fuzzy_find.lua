
local ff = {}

-- from https://github.com/rrthomas/lua-stdlib/blob/origin/src/lcs.lua
--- Longest Common Subsequence algorithm.
-- After pseudo-code in <a
-- href="http://www.ics.uci.edu/~eppstein/161/960229.html">lecture
-- notes</a> by <a href="mailto:eppstein@ics.uci.edu">David Eppstein</a>.


-- Find common subsequences.
-- @param a first sequence
-- @param b second sequence
-- @return list of common subsequences
-- @return the length of a
-- @return the length of b
local function commonSubseqs (a, b)
  local l, m, n = {}, #a, #b
  for i = m + 1, 1, -1 do
    l[i] = {}
    for j = n + 1, 1, -1 do
      if i > m or j > n then
        l[i][j] = 0
      elseif a[i] == b[j] then
        l[i][j] = 1 + l[i + 1][j + 1]
      else
        l[i][j] = math.max (l[i + 1][j], l[i][j + 1])
      end
    end
  end
  return l, m, n
end

--- Find the longest common subsequence of two sequences.
-- The sequence objects must have an <code>__append</code> metamethod.
-- This is provided by <code>string_ext</code> for strings, and by
-- <code>list</code> for lists.
-- @param a first sequence
-- @param b second sequence
-- @param s an empty sequence of the same type, to hold the result
-- @return the LCS of a and b
local function longestCommonSubseq (a, b, s)
  local l, m, n = commonSubseqs (a, b)
  local i, j = 1, 1
  -- local f = getmetatable (s).__append
  while i <= m and j <= n do
    if a[i] == b[j] then
      table.insert(s, a[i])
      i = i + 1
      j = j + 1
    elseif l[i + 1][j] >= l[i][j + 1] then
      i = i + 1
    else
      j = j + 1
    end
  end
  return s
end

-- return a set of sequences which are fuzzy matched with "s"
-- from "set"
-- if "must" is not nil, at least return one (best matched)
-- otherwise, it might return empty 
function ff.find(s, set, must)
    local result = {}
    local bestMatched = {}
    bestMatched.count = 0
    bestMatched.s     = nil 
    for i, v in ipairs(set) do
        local r = longestCommonSubseq(s, v, {})
        if ff.sequenceEqual(r,s) then 
            table.insert(result, v) 
        end
        if #r > bestMatched.count and must then
            bestMatched.s = v
        end
    end
    -- at least one sequence matched
    if #result == 0 and must then
        table.insert(result, bestMatched.s)
    end
    return result
end

function ff.stringToSequence(s)
    return {string.byte(s, 1, #s)}
end

function ff.sequenceToString(s)
    return string.char(unpack(s))
end

function ff.stringSetToSequenceSet(s)
    local set = {}
    for _, v in ipairs(s) do
        table.insert(set, ff.stringToSequence(v))
    end
    return set
end

function ff.sequenceSetToStringSet(s)
    local stringSet = {}
    for _, v in ipairs(s) do
        table.insert(stringSet, ff.sequenceToString(v))
    end
    return stringSet
end

function ff.sequenceEqual(a, b)
    if #a ~= #b then
        return false
    end
    for i = 1, #a do
        if a[i] ~= b[i] then return false end
    end
    return true
end

function ff.test()
    local set = ff.stringSetToSequenceSet{"aaabbbccc", "acb", "aaabbbcccccccc", "abc"}
    local s = ff.stringToSequence"abc"
    assert("abc" == ff.sequenceToString(s))
    local r = ff.find(s, set, false)
    local set = ff.sequenceSetToStringSet(r)
    assert(set[1] == "aaabbbccc")
    assert(set[2] == "aaabbbcccccccc")
    assert(set[3] == "abc")
    print("Fuzzy find test passed")
end

return ff

