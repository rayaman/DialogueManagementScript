package.path = "./?/init.lua;"..package.path
local pm = require("parseManager")
state = pm:load("test.dms")
print(state:dump())
state:think()