local Parser = require("dms.parser")
local Interpreter= {}
Interpreter.__index = Interpreter
function Interpreter:new(file) 
    local c = {}
    setmetatable(c,self)
    if file then
        c.parser = Parser:new(file)
        c.chunks = c.parser:parse()
    else
        c.chunks = {}
    end
    return c
end
function Interpreter:compile(file)
    if not file then error("You must provide a file path to compile!") end
    self.chunks = Parser:new(file,self.chunks):parse()
end
function Interpreter:dump()
    local filedat = ""

    for i,v in pairs(self.chunks) do
        filedat = filedat..tostring(v) .. "\n"
    end
    return filedat
end
function Interpreter:interprete()
    --
end
return Interpreter