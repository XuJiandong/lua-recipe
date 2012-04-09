

module ("lua_recipe_fuzzy_find", package.seeall)

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

-- return a set of strings which are fuzzy matched with "s"
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
        if table.concat(r) == s then 
            table.insert(result, v) 
        end
        if #r > bestMatched.count and must then
            bestMatched.s = v
        end
    end
    -- at least one string matched
    if #result == 0 and must then
        table.insert(result, bestMatched.s)
    end
    return result
end

function ff.test()
    local set = {"aaabbbccc", "acb", "aaabbbcccccccc", "abc"}
    local r = ff.find("abc", set, true)
    for i, v in ipairs(r) do
        print(v)
    end
end

return ff


