local Stack = {}
Stack.__index = Stack
function Stack.__tostring(self)
    return table.concat(self.stack, ", ")
end
function Stack:new(n)
    local c = {}
    setmetatable(c,self)
    c.max = n or math.huge
    c.stack = {}
    return c
end
function Stack:push(n)
    table.insert(self.stack,n)
end
function Stack:pop()
    return table.remove(self.stack,#self.stack)
end
function Stack:peek(n)
    return self.stack[#self.stack - (n or 0)]
end
function Stack:count()
    return #self.stack
end
return Stack