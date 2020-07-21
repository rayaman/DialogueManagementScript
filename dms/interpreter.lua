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
function Interpreter:dump(filename)
    local filedat = ""
    local entry = self.parser.entry
    if entry then
        filedat = "ENTR "..entry.."\n"
    end
    local flags = self.parser.flags
    for i,v in pairs(flags) do
        filedat = filedat.."FLAG "..i..":"..tostring(v).."\n"
    end
    for i,v in pairs(self.chunks) do
        filedat = filedat..tostring(v) .. "\n"
    end
    if filename then
        file = io.open("dump.dat","wb")
        file:write(filedat)
        file:flush()
    end
    return filedat
end
function Interpreter:interprete()
    
end
return Interpreter