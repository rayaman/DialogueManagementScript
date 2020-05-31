local CMD = {}
CMD.__index = CMD
CMD.tostring = function(self) return self.command end
function CMD:__tostring()
    return self.command .. " " .. self:tostring() 
end 
function CMD:new(line,cmd,args)
    local c = {}
    setmetatable(c,self)
    c.line = line
    c.command = cmd
    c.args = args
    return c
end
return CMD