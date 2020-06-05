local Value  = {}
Value.__index = Value
local c = string.char
local types = {
    string  = c(0x0),
    lookup  = "",
    boolean = c(0x2),
    table   = c(0x3),
    number  = c(0x4)
}
function Value:__tostring()
    local t = self.type
    return types[t]..tostring(self.value)
end
function Value:new(name,value)
    local c = {}
    setmetatable(c,self)
    c.type = type(value)
    c.value = value
    if c.type=="string" and c.value:sub(1,1)=="\1" then
        c.type = "lookup"
    end
    c.name = name
    return c
end
function Value:set(value)
    self.type = type(value)
    self.value = value
end
function Value:get()
    return self.value
end
return Value