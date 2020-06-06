package.path="?.lua;?/init.lua;?.lua;?/?/init.lua;"..package.path
local queue = require("dms.queue"):new()
queue:enqueue(1)
queue:enqueue(2)
queue:enqueue(3)
queue:enqueue(4)
for i in queue() do
    print(i)
end