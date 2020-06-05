package.path="?.lua;?/init.lua;?.lua;?/?/init.lua;"..package.path
require("dms.utils")
--require("dms.parser")
parser = {}


print(parser:logicChop([[if (func(123)!=name[1] or true == "Bob") and foodCount >= 10.34]]))
-- function parser:parseLogic(expr)
-- 	expr = expr:gsub("")
-- end
-- print(parser:parseLogic([[if (name=="Ryan" or name == "Bob") and foodCount >= 10]]))
