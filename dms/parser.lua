require("dms.utils")
local Stack = require("dms.stack")
local Chunk = require("dms.chunk")
local Cmd = require("dms.cmd")
local ENTR,ENAB,DISA,LOAD,VERN,USIN,STAT,DISP,ASGN,LABL,CHOI,OPTN,FORE,UNWN,WHLE,FNWR,FNNR,IFFF,ELIF,ELSE,DEFN = "ENTR","ENAB","DISA","LOAD","VERN","USIN","STAT","DISP","ASGN","LABL","CHOI","OPTN","FORE","????","WHLE","FNWR","FNNR","IFFF","ELIF","ELSE","DEFN"
local controls = {STAT,CHOI,FORE,WHLE,IFFF,ELIF,ELSE}
local flags = {ENTR,ENAB,DISA,LOAD,VERN,USIN,DEFN}
local recognizedFlags = {
    "debugging",
    "noprint",
    "warnings"
}
local parser = {}
parser.__index = parser
function parser:new(path)
    local c = {}
    setmetatable(c,self)
    c.filename = path or error("Must provied a path!")
    c.content = io.open(c.filename,"rb"):read("*a")
    c.flags = {}
    c.chunks = {}
    c.ver = {1,0,0}
    c.pos = 0
    c.lines = {}
    return c
end
function parser:setVersion(ver)
    self.ver = ver
end
-- Output Stuffs
function parser:debug(...)
    if not self.flags.debugging then return end
    self:print(...)
end
function parser:print(...)
    if self.flags.noprint then return end
    print(...)
end
function parser:error(err,line)
    if not line then print(err) os.exit() end
    print("Error: <"..line[4]..":"..line[1].."> \""..line[5].."\" "..err)
    os.exit()
end
function parser:warn(msg,line)
    if not self.flags.warnings then return end
    if not line then print(msg) return end
    print("Warning: <"..line[4]..":"..line[1].."> \""..line[5].."\" "..msg)
end

function parser:manageFlag(line)
    if self:isFlag(line) then
        local flag = line[3]
        local dat = line[5]:match("%s+(.+)$")
        if flag == ENTR then
            if self.entry then
                self:error("Entry was already set to: "..self.entry,line)
            else
                self.entry = dat
            end
        elseif flag == ENAB then
            if not self:isRecognizedFlag(dat) then self:warn("Flag \""..dat.."\" is not recognized!",line) end
            self.flags[dat] = true
        elseif flag == DISA then
            if not self:isRecognizedFlag(dat) then self:warn("Flag \""..dat.."\" is not recognized!",line) end
            self.flags[dat] = false
        elseif flag == LOAD then
            -- TODO
        elseif flag == VERN then
            local v
            local a,b,c = dat:match("(%d*)%.?(%d*)%.?(%d*)")
            a,b,c = tonumber(a),tonumber(b) or 0,tonumber(c) or 0
            if a>self.ver[1] or a>self.ver[2] then
                self:warn("This script was created for a different version of the DMS! Code may behave unexpectedly or not work at all!",line)
            end
        elseif flag == USIN then
            -- TODO
        end
    else
        self:error("Flag Expected! Got: "..line[3],line)
    end
end
function parser:isControl(line)
    for i,v in pairs(controls) do
        if line[3] == v then
            return true
        end
    end
    return false
end
function parser:isFlag(line)
    for i,v in pairs(flags) do
        if line[3] == v then
            return true
        end
    end
    return false
end
function parser:isRecognizedFlag(flag)
    for i,v in pairs(recognizedFlags) do
        if v == flag:lower() then
            return true
        end
    end
    return false
end
function parser:parse()
    local link = self
    local line_num = 0
    local choice
    local group = 0
    local lastgroup = 0
    local groupStack = Stack:new({})
    local lastpop
    local noblock = true
    local arr = {}
    local multilined = false
    function groupStack:append(t)
        local c = self:peek()
        val = pcall(function()
            table.insert(c,1,t)
        end)
        if not val then
            link:error("Inconsistant indentation!",t)
        end
    end
    groupStack:push({})
    for line in self.content:gmatch("(.-)\n") do
        line_num = line_num + 1
        line = line:gsub("//(.+)$","") -- Filter out comments
        if not multilined and line:match("/%*(.+)$") then
            multilined = true
            line = line:gsub("/%*(.*)$","")
        end
        if multilined then
            if line:match("%*/") then
                multilined = false
                line = line:gsub("(.+)%*/","")
                if #line:trim() == 0 then
                    goto continue
                end
            else
                goto continue
            end
        end
        if line:trim()=="" then goto continue end -- Skip all whitespace completely
        lastgroup = group
        group = line:tabs()
        if lastgroup>group then
            for i=1,lastgroup-group do
                local c = groupStack:pop()
                lastpop = c
                for i,v in pairs(c) do
                    table.insert(arr,v)
                end
            end
        elseif lastgroup<group then
            groupStack:push({})
        end
        if line=="" then goto continue end
        ::back::
        if line:match("^%[[_:,%w%(%)]+%]") then
            groupStack:append{line_num,group,STAT,self.filename,line:trim()}
            noblock = false
        -- We gonna define header stuff
        elseif noblock and line:lower():match("enable%s(.+)") then
            groupStack:append{line_num,group,ENAB,self.filename,line:trim()}
        elseif noblock and line:lower():match("disable%s(.+)") then
            groupStack:append{line_num,group,DISA,self.filename,line:trim()}
        elseif noblock and line:lower():match("loadfile%s(.+)") then
            groupStack:append{line_num,group,LOAD,self.filename,line:trim()}
        elseif noblock and line:lower():match("entry%s(.+)") then
            groupStack:append{line_num,group,ENTR,self.filename,line:trim()}
        elseif noblock and line:lower():match("using%s(.+)") then
            groupStack:append{line_num,group,USIN,self.filename,line:trim()}
        elseif noblock and line:lower():match("version%s(.+)") then
            groupStack:append{line_num,group,VERN,self.filename,line:trim()}
        elseif line:match("choice%s+\".+\"") then
            groupStack:append{line_num,group,CHOI,self.filename,line:trim()}
            choice = true
        elseif line:match("::([_:,%w%(%)]+)::") then
            groupStack:append{line_num,group,LABL,self.filename,line:trim()}
        elseif line:match("for%s*[_%w]-%s") then
            groupStack:append{line_num,group,FORE,self.filename,line:trim()}
        elseif line:match("%s*while%s*.+") then
            groupStack:append{line_num,group,WHLE,self.filename,line:trim()}
        elseif choice then
            choice = false
            if line:match("\".*\"%s*[_:,%w%(%)]+%(.*%)") then
                groupStack:append{line_num,group,OPTN,self.filename,line:trim()}
                choice = true
            else
                goto back
            end
        elseif line:match("[%s,_%w]*=.-%(.+%)") then
            groupStack:append{line_num,group,FNWR,self.filename,line:trim()}
        elseif line:match(".-%(.+%)") then
            groupStack:append{line_num,group,FNNR,self.filename,line:trim()}
        elseif line:match("[%s,_%w]*=(.+)") then
            groupStack:append{line_num,group,ASGN,self.filename,line:trim()}
        elseif line:match("\"(.+)\"") then
            groupStack:append{line_num,group,DISP,self.filename,line:trim()}
        elseif line:match("elseif%s*(.+)") then
            groupStack:append{line_num,group,ELIF,self.filename,line:trim()}
        elseif line:match("if%s*(.+)") then
            groupStack:append{line_num,group,IFFF,self.filename,line:trim()}
        elseif line:match("else%s*(.+)") then
            groupStack:append{line_num,group,ELSE,self.filename,line:trim()}
        else
            groupStack:append{line_num,group,UNWN,self.filename,line:trim()}
        end
        ::continue::
    end
    -- Final Pop
    for i = 1,groupStack:count() do
        local c = groupStack:pop()
        for i,v in pairs(c) do
            table.insert(arr,v)
        end
    end
    table.sort(arr,function(k1,k2)
        return k1[1]<k2[1]
    end)
    self.lines = arr
    local chunks = {}
    local handler = Stack:new()
    local v = self:next()
    while v ~= nil do
        if self:isFlag(v) then
            self:manageFlag(v)
        elseif self:isControl(v) then
            if v[3] == STAT then
                print("BLOCK",table.concat(v,"\t"))
                if self.current_chunk then
                    chunks[self.current_chunk.chunkname] = self.current_chunk
                end
                local cname,ctype = v[5]:match("%[(%w+):*(.-)%]")
                if #ctype == 0 then ctype = "block" end
                self:debug("Registering Block: \""..cname.."\" type: \""..(ctype:match("(.+)%(") or ctype).."\"")
                self.current_chunk = Chunk:new(cname,ctype,v[4])
                if chunks[cname] then self:error("Chunk \""..cname.."\" has already been defined!",v) end
            elseif v[3] == CHOI then
                self:parseChoice(v)
            else
                --print("CTRL",table.concat(v,"\t"))
            end
        else
            if v[3] == DISP then
                self:parseDialogue(v)
            elseif v[3] == FNNR then
                self:parseFNNR(v)
            elseif v[3] == FNWR then
                self:parseFNWR(v)
            elseif v[3] == ASGN then
                self:parseASGN(v)
            elseif v[3] == LABL then
                self.current_chunk:addLabel(v[5]:match("::(.+)::"))
            end
            --print("FUNC",table.concat(v,"\t"))
        end
        v = self:next()
    end
    if current_chunk then
        chunks[current_chunk.chunkname] = current_chunk
    end
    for i,v in pairs(chunks) do
        print(i,v)
    end
end
function parser:parseFNNR(line)
    local fname, args = line[5]:match("(.-)%((.+)%)")
    args = args:split()
    local cmd = Cmd:new(line,FNNR,{func=fname,args=args})
    function cmd:tostring()
        return table.concat({fname,table.concat(args,", ")},", ")
    end
    self.current_chunk:addCmd(cmd)
end
function parser:parseFNWR(line)
    local vars, fname, args = line[5]:match("(.-)%s*=%s*(.-)%((.+)%)")
    vars = vars:split()
    args = args:split()
    local cmd = Cmd:new(line,FNWR,{func=fname,args=args,vars=vars})
    function cmd:tostring()
        return table.concat({fname,table.concat(args,", ")},", ").." -> ".. table.concat(vars,", ")
    end
    self.current_chunk:addCmd(cmd)
end
function parser:parseASGN(line)
    local vars,assigns = line[5]:match("(.-)%s*=%s*(.+)")
    vars = vars:split()
    assigns = assigns:split()
    local cmd = Cmd:new(line,ASGN,{vars = vars, assigns = assigns})
    function cmd:tostring()
        return "DATA -> "..table.concat(vars,", ")
    end
    self.current_chunk:addCmd(cmd)
    -- TODO: make dict lookups builtin
end
function parser:parseChoice(line)
    local text = line[5]:match("\"(.+)\"")
    local copt = self:peek()
    local choice = {text = text}
    local cmd = Cmd:new(line,CHOI,choice)
    if copt[3]~=OPTN then
        self:error("Choices must have at least one option to choose!")
        return
    end
    while copt do
        copt = self:next()
        local a,b = copt[5]:match("(.+) %s*(.+)")
        print(a,"|",b)
        copt = self:peek()
        if copt[3]~=OPTN then
            break
        end
    end
    -- We need to get functions working first
end
function parser:parseDialogue(line)
    local targ,text = line[5]:match("(%w*)%s*(.*)")
    if #targ == 0 then targ = nil end
    local cmd = Cmd:new(line,DISP,{text=text,target=targ})
    function cmd:tostring()
        return table.concat({targ or "@",text},", ")
    end
    self.current_chunk:addCmd(cmd)
end
function parser:peek()
    return self.lines[self.pos + 1]
end
function parser:next()
    self.pos = self.pos + 1
    return self.lines[self.pos]
end
return parser