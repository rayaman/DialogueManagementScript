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
Stack = {}
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

function string:trim()
    return (self:gsub("^%s*(.-)%s*$", "%1"))
end
function string.tabs(str)
    local c = 0
    for i in str:gmatch(".") do
        if i=="\t" then
            c=c+1
        else
            break
        end
    end
    return c
end
local choice
local group = 0
local lastgroup = 0
local groupStack = Stack:new({})
local lastpop
groupStack:push({})
function groupStack:append(t)
    local c = self:peek()
    val = pcall(function()
        table.insert(c,t)
    end)
    if not val then
        error("Inconsistant indentation!")
    end
end
local noblock = true
for line in content:gmatch("(.-)\n") do
    line_num = line_num + 1
    --line = line:trim()
    --line = line:gsub("")
    lastgroup = group
    group = line:tabs()
    if lastgroup>group then
        for i=1,lastgroup-group do
            local c = groupStack:pop()
            lastpop = c
            for i,v in pairs(c) do
                print(table.concat(v,", "))
            end
        end
    elseif lastgroup<group then
        groupStack:push({})
    end
    if line=="" then goto continue end
    ::back::
    if line:trim()=="" then
        goto continue
    elseif line:match("^%[[_:,%w%(%)]+%]") then
        groupStack:append{group,line_num,"<BLOCK_START>",line}
        noblock = false
    -- We gonna define header stuff
    elseif noblock and line:lower():match("enable%s(.+)") then
        groupStack:append{group,line_num,"<ENABLE>",line}
    elseif noblock and line:lower():match("disable%s(.+)") then
        groupStack:append{group,line_num,"<DISABLE>",line}
    elseif noblock and line:lower():match("loadfile%s(.+)") then
        groupStack:append{group,line_num,"<LOADFILE>",line}
    elseif noblock and line:lower():match("entry%s(.+)") then
        groupStack:append{group,line_num,"<ENTRY>",line}
    elseif noblock and line:lower():match("using%s(.+)") then
        groupStack:append{group,line_num,"<USING>",line}
    elseif noblock and line:lower():match("version%s(.+)") then
        groupStack:append{group,line_num,"<VERSION>",line}
    elseif line:match("choice%s+\".+\"") then
        groupStack:append{group,line_num,"<CHOICE_BLOCK>",line}
        choice = true
    elseif line:match("::([_:,%w%(%)]+)::") then
        groupStack:append{group,line_num,"<LABEL_BLOCK>",line}
    elseif line:match("for%s*[_%w]-%s") then
        groupStack:append{group,line_num,"<FOR_BLOCK>",line}
    elseif line:match("%s*while%s*.+") then
        groupStack:append{group,line_num,"<WHILE_BLOCK>",line}
    elseif choice then
        choice = false
        if line:match("\".*\"%s*[_:,%w%(%)]+%(.*%)") then
            groupStack:append{group,line_num,"<CHOICE_OPTION>",line}
            choice = true
        else
            goto back
        end
    elseif line:match("[%s,_%w]*=.-%(.+%)") then
        groupStack:append{group,line_num,"<FUNCWR>",line}
    elseif line:match(".-%(.+%)") then
        groupStack:append{group,line_num,"<FUNCNR>",line}
    elseif line:match("[%s,_%w]*=(.+)") then
        groupStack:append{group,line_num,"<ASSIGNMENT>",line}
    elseif line:match("\"(.+)\"") then
        groupStack:append{group,line_num,"<DISP_MSG>",line}
    else
        groupStack:append{group,line_num,"<UNKNOWN_BLOCK>",line}
    end
    ::continue::
end