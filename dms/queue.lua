local Queue = {}
Queue.__index = Queue
function Queue:__call()
    local function next()
        return self:dequeue()
    end
    return next
end
function Queue:__tostring()
    return table.concat(self.queue, ", ")
end
function Queue:new()
    local c = {}
    setmetatable(c,self)
    c.queue = {}
    return c
end
function Queue:enqueue(data)
    table.insert(self.queue,data)
end
function Queue:peek(data)
    return self.queue[1]
end
function Queue:dequeue(data)
    return table.remove(self.queue,1)
end
return Queue