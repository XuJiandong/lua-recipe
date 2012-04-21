

local cl = {}

-- from LuaRocks 
--- Extract flags from an arguments list.
-- Given string arguments, extract flag arguments into a flags set.
-- For example, given "foo", "--tux=beep", "--bla", "bar", "--baz",
-- it would return the following:
-- {["bla"] = true, ["tux"] = "beep", ["baz"] = true}, "foo", "bar".
function cl.parse_flags(...)
   local args = {...}
   local argc = select("#", ...)
   local flags = {}
   for i = argc, 1, -1 do
      local flag = args[i]:match("^%-%-(.*)")
      if flag then
         local var,val = flag:match("([a-z_%-]*)=(.*)")
         if val then
            flags[var] = val
         else
            flags[flag] = true
         end
         table.remove(args, i)
      end
   end
   return flags, unpack(args)
end


function cl.test()
    local flags, o1, o2 = cl.parse_flags("foo", "--tux=beep", "--bla", "bar", "--baz")
    assert(o1 == "foo")
    assert(o2 == "bar")
    assert(flags["tux"] == "beep")
    assert(flags["bla"] == true)
    assert(flags["baz"] == true)
    print("command line test passed")
end

return cl
