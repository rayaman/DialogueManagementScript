package.path="?.lua;?/init.lua;?.lua;?/?/init.lua;"..package.path
local Interpreter = require("dms.interpreter")
local i = Interpreter:new("test.dms")
print(i:dump())