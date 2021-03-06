#!/usr/bin/env lua

local d = require("deque")
d.test()

local ff = require("fuzzy_find")
ff.test()

local cl = require("command_line")
cl.test()

local hook = require("hook")
hook.test()

local heap = require("heap")
heap.test()

local priority_queue = require("priority_queue")
priority_queue.test()

local memoize = require("memoize")
memoize.test()

local popen = require("popen")
popen.test()

local st = require("serialize_table")
st.test()

local xml = require("xml")
xml.test()

local string_util = require("string_util")
string_util.test()

local base64 = require("base64")
base64.test()

