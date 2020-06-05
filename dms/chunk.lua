local cmd = require("dms.cmd")
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
    return c
end
function Chunk:addVariable(value)
    self.varaiables[value.name] = value.value
end
function Chunk:addCmd(cmd)
    cmd.chunk = self
    table.insert(self.cmds,cmd)
end
function Chunk:count()
    return #self.cmds
end
return Chunk