file = io.open("test.dms","rb")
content = file:read("*a")
line_num = 0
CMD = {}
CMD.__index = CMD
function CMD:new(ln,cmd,args)
    local c = {}
    setmetatable(c,self)
    c.line_num = ln
    c.command = cmd
    c.args = args
end
function CMD:process()
    
end
function string:trim()
    return (self:gsub("^%s*(.-)%s*$", "%1"))
end
local choice
for line in content:gmatch("(.-)\n") do
    line_num = line_num + 1
    line = line:trim()
    line = line:gsub("")
    if line=="" then goto continue end
    ::back::
    if line:match("^%[[_:,%w%(%)]+%]") then
        print(line_num,"BLOCK_START",line)
    elseif line:match("choice%s+\".+\"%s*:") then
        print(line_num,"CHOICE_BLOCK",line)
        choice = true
    elseif line:match("::([_:,%w%(%)]+)::") then
        print(line_num,"LABEL_BLOCK",line)
    elseif choice then
        choice = false
        if line:match("\".*\"%s*[_:,%w%(%)]+%(.*%)") then
            print(line_num,"CHOICE_OPTION",line)
            choice = true
        else
            goto back
        end
    else
        print(line_num,line)
    end
    ::continue::
end