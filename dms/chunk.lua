local Stack = require("dms.stack")
local Queue = require("dms.queue")
local Chunk = {}
Chunk.__index = Chunk
function Chunk:__tostring()
    local str = self.chunkname..":"..self.chunktype.."\n"
    local s = ""
    for i,v in pairs(self.cmds) do
        str = str .. tostring(v).."\n"
    end
    return str
end
function Chunk:new(cname,ctype,filename)
    local c = {}
    setmetatable(c,self)
    c.chunkname = cname
    c.chunktype = ctype
    c.filename = filename
    c.variables = {}
    c.pos = 0
    c.cmds = {}
    c.control = Stack:new()
    c.lastCMD = nil
    c.alerts = {}
    return c
end
function Chunk:addVariable(value)
    self.varaiables[value.name] = value.value
end
function Chunk:addCmd(cmd)
    --print(">",cmd)
    if self.control:count()==0 then
        cmd.chunk = self
        table.insert(self.cmds,cmd)
    else
        if cmd.line[2] < self.lastCMD.line[2] then
            self:doPop()
            self:addCmd(cmd)
            return
        end
        cmd.chunk = self
        table.insert(self.cmds,cmd)
    end
    self.lastCMD = cmd
end
function Chunk:count()
    return #self.cmds
end
function Chunk:finished()
    self:doPop()
end
function Chunk:doPop(amt)
    if amt then
        for i=1,amt do
            self.control:pop()()
        end
    else
        local scope = self.control:pop()
        --while scope do
        if scope then
            scope()
            scope = self.control:pop()
        end
        --end
    end
end
function Chunk:setScope(func)
    self.first = true
    self.control:push(func)
end
return Chunk