package.path="?.lua;?/init.lua;?.lua;?/?/init.lua;"..package.path
local parser = require("dms.parser")
local p = parser:new("test.dms")
p:parse()
