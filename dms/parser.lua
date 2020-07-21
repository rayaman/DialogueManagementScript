require("dms.utils")
local char = string.char
local Stack = require("dms.stack")
local Chunk = require("dms.chunk")
local Cmd = require("dms.cmd")
local Queue = require("dms.queue")
local ENTR,ENAB,DISA,LOAD,VERN,USIN,STAT,DISP,ASGN,LABL,CHOI,OPTN,FORE,UNWN,WHLE,FNWR,FNNR,IFFF,ELIF,ELSE,DEFN,SKIP,COMP,INDX,JMPZ,NOOP,INST = "ENTR","ENAB","DISA","LOAD","VERN","USIN","STAT","DISP","ASGN","LABL","CHOI","OPTN","FORE","????","WHLE","FNWR","FNNR","IFFF","ELIF","ELSE","DEFN","SKIP","COMP","INDX","JMPZ","NOOP","INST"
local controls = {STAT,CHOI,FORE,WHLE,IFFF,ELIF,ELSE}
local flags = {ENTR,ENAB,DISA,LOAD,VERN,USIN,DEFN}
local recognizedFlags = {
    "debugging",
    "noprint",
    "warnings"
}
local parser = {}
parser.__index = parser
local controlStack = Stack:new() -- Handles If/elseif/else while/for loops
function parser:new(path,cc)
    local c = {}
    setmetatable(c,self)
    if cc then
        c.internal = true
    end
    c.filename = path or error("Must provied a path!")
    c.content = io.open(c.filename,"rb"):read("*a") .. "\n"
    c.flags = {}
    c.chunks = cc or {}
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
            parser:new(dat,self.chunks):parse()
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
function parser:split(s,pat,l)
	local pat=pat or ","
	local res = {}
	local start = 1
	local state = 0
	local c = '.'
    local elem = ''
    local v
    local counter = 0
    local function next()
        counter = counter + 1
        return s:sub(counter,counter)
    end
    local function peek()
        return s:sub(counter + 1,counter + 1)
    end
    local function index(right)
        local ind = ""
        c = peek()
        while c ~= "]" do
            next()
            ind = ind..c
            c = peek()
        end
        c = next()
        print(elem,ind)
        local vv = gen("$")
        self:buildIndex(elem,ind,vv)
        elem = vv
        if not(c=="]") then
            self:error("']' expected to close '['")
        end
    end
    
    local function packTable(tab)
        print("Doing list!")
        local vv = gen("&")
        for i,k in ipairs(tab) do
            v = gen("&")
            self:parseASGN({self.current_line[1],self.current_line[2],ASGN,self.current_line[4],v.." = "..tostring(k)})
            self:buildInsert(vv,i,v)
            print(vv,i,v,k)
        end
        return vv
    end
    local function helper()
        if tonumber(elem) then
            elem = tonumber(elem)
        elseif elem:sub(1,1) == "\"" and elem:sub(-1,-1) == "\"" then
            elem = elem
        elseif elem == "true" then
            elem = true
        elseif elem == "false" then
            elem = false
        elseif elem:sub(1,1)=="{" and elem:sub(-1,-1)=="}" then
            elem = packTable()
        elseif elem:match("[%-%+/%%%(%)%*%^]") then
            gen("$",true) -- Flush the temp variables
            elem = self:parseExpr(elem)
        else
            --\1 Tells the interperter that we need to do a lookup
            elem = elem
        end
    end
    local function getarr()
        local a = peek()
        local str = ""
        local open = 1
        while open~=0 and a~="" do
            a = next()
            if a == "{" then 
                open = open+1
            end
            if a == "}" then
                open = open-1
                if open == 0 then
                    next()
                    return str
                end
            end
            str = str .. a
            a = peek()
        end
        next()
        return str
    end
	while c~="" do
		c = next()
		if state == 0 or state == 3 then -- start state or space after comma
            if state == 3 and c == ' ' then
				state = 0 -- skipped the space after the comma
			else
				state = 0
				if c == '"' then
                    c = peek()
                    str = ""
                    while c~="\"" do
                        next()
                        if c=="\\" and peek()=="\"" then
                            next()
                            str = str .. "\""
                        else
                            str = str .. c
                        end
                        c = peek()
                    end
                    elem = elem .. "\""..str.."\""
                    next()
                elseif c == "'" then
                    elem = elem .. "'"
                    c = peek()
                    while c~="'" do
                        next()
                        if c=="\\" and peek()=="'" then
                            next()
                            elem = elem + "'"
                        else
                            elem = elem .. c
                        end
                        c = peek()
                    end
                    elem = elem .. "\""..str.."\""
                    next()
                elseif c == "[" then
                    index()
                elseif c=="{" then
                    local t = self:split(getarr(),nil,true)
                    res[#res + 1] = packTable(t)
                    elem = ''
                    state = 3
                elseif c == pat then
                    helper()
					res[#res + 1] = elem
					elem = ''
					state = 3 -- skip over the next space if present
				elseif c == "(" then
					state = 1
					elem = elem .. '('
				else
					elem = elem .. c
				end
			end
		elseif state == 1 then -- inside quotes
			if c=="}" then
				state = 0
                elem = elem .. '}'
			elseif c==")" then
				state = 0
                elem = elem .. ')'
			elseif c == '\\' then
				state = 2
			else
				elem = elem .. c
			end
		elseif state == 2 then -- after \ in string
			elem = elem .. c
            state = 1
		end
    end
    helper()
    if elem ~= "" then
        res[#res + 1] = elem
    end
    if l then
        setmetatable(res,{
            __tostring = function(self)
                local str = "{"
                for i,v in ipairs(self) do
                    str = str .. tostring(v) .. ", "
                end
                return str:sub(1,-3).."}"
            end
        })
    else
        setmetatable(res,{
            __tostring = function(self)
                local str = "("
                for i,v in ipairs(self) do
                    str = str .. tostring(v) .. ", "
                end
                return str:sub(1,-3)..")"
            end
        })
    end
	return res
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
        elseif line:match("[%s,_%w]*=%s*[%l_][%w_]-%(.+%)") then
            groupStack:append{line_num,group,FNWR,self.filename,line:trim()}
        elseif line:trim():match("[%s_%w]-\".+\"") == line:trim():match(".+") then
            groupStack:append{line_num,group,DISP,self.filename,line:trim()}
        elseif line:match("elseif%s*(.+)") then
            groupStack:append{line_num,group,ELIF,self.filename,line:trim()}
        elseif line:match("if%s*(.+)") then
            groupStack:append{line_num,group,IFFF,self.filename,line:trim()}
        elseif line:match("else%s*(.+)") then
            groupStack:append{line_num,group,ELSE,self.filename,line:trim()}
        elseif line:match("[%l_][%w_]-%(.+%)") and not line:match("[%s,_%w]-=(.+)") then
            groupStack:append{line_num,group,FNNR,self.filename,line:trim()}
        elseif line:match("[%s,_%w]-=(.+)") and not line:match("[%l_][%w_]-%(.+%)") then
            groupStack:append{line_num,group,ASGN,self.filename,line:trim()}
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
    local handler = Stack:new()
    local v = self:next()
    while v ~= nil do
        self.current_line = v
        if self:isFlag(v) then
            self:manageFlag(v)
        elseif self:isControl(v) then
            --print("CTRL",table.concat(v,"\t"))
            if v[3] == STAT then
                if self.current_chunk then
                    self.current_chunk:finished()
                    self.chunks[self.current_chunk.chunkname] = self.current_chunk
                end
                local cname,ctype = v[5]:match("%[(%w+):*(.-)%]")
                if #ctype == 0 then ctype = "block" end
                self:debug("Registering Block: \""..cname.."\" type: \""..(ctype:match("(.+)%(") or ctype).."\"")
                self.current_chunk = Chunk:new(cname,ctype,v[4])
                if self.chunks[cname] then self:error("Chunk \""..cname.."\" has already been defined in file: "..self.chunks[cname].filename,v) end
            elseif v[3] == CHOI then
                self:parseChoice(v)
            elseif v[3] == IFFF then
                self:parseIFFF(v)
            elseif v[3] == ELIF then
                self:parseELIF(v)
            elseif v[3] == ELSE then
                self:parseELSE(v)
            elseif v[3] == NOOP then
                self:NOOP()
            end
        else
            --print("FUNC",table.concat(v,"\t"))
            if v[3] == DISP then
                self:parseDialogue(v)
            elseif v[3] == FNNR then
                self:parseFNNR(v)
            elseif v[3] == FNWR then
                self:parseFNWR(v)
            elseif v[3] == ASGN then
                self:parseASGN(v)
            elseif v[3] == LABL then
                self:parseLABL(v)
            end
        end
        v = self:next()
    end
    if self.current_chunk then
        self.current_chunk:finished()
        self.chunks[self.current_chunk.chunkname] = self.current_chunk
    end
    return self.chunks
end
local EQ,GTE,LTE,NEQ,GT,LT = "=",char(242),char(243),char(247),">","<"
function parser:JMPZ(v,label)
    if not v then error("Fix this now!!!") end
    local cmd = Cmd:new({self.current_line[1],self.current_line[2],JMPZ,self.current_line[4],"?"},JMPZ,{label = label,var = v})
    function cmd:tostring()
        return self.args.var.."\0" .. ", " ..self.args.label.."\0"
    end
    self.current_chunk:addCmd(cmd)
end
function parser:NOOP()
    local cmd = Cmd:new({self.current_line[1],self.current_line[2],NOOP,self.current_line[4],"?"},NOOP,{})
    function cmd:tostring()
        return ""
    end
    self.current_chunk:addCmd(cmd)
end
local fStack = Stack:new()
local function checkELIS()
    local stackfix = fStack:peek()[3]
    --print("STACK TEST:",stackfix)
    if stackfix then stackfix() fStack:peek()[3]=nil end
end
function parser:processIFFFBlock()
    local test = self:peek()
    local dat = fStack:peek()
    local labelE,labelN = dat[1],dat[2]
    --print("Current line is an",self.current_line[3],self.current_line[5])
    --print(test[3])
    if self.current_line[3] == ELIF then
        self:parseFNNR({self.current_line[1],self.current_line[2],self.current_line[3],self.current_line[4],"JUMP(\""..labelE.."\")"})
        self:parseLABL({self.current_line[1],self.current_line[2],self.current_line[3],self.current_line[4],"::"..labelN.."::"})
    elseif self.current_line[3] == ELSE then
        self:parseFNNR({self.current_line[1],self.current_line[2],self.current_line[3],self.current_line[4],"JUMP(\""..labelE.."\")"})
        self:parseLABL({self.current_line[1],self.current_line[2],self.current_line[3],self.current_line[4],"::"..labelN.."::"})
    else
        --print("Popping FStack")
        fStack:pop()
        self:parseFNNR({self.current_line[1],self.current_line[2],self.current_line[3],self.current_line[4],"JUMP(\""..labelE.."\")"})
        self:parseLABL({self.current_line[1],self.current_line[2],self.current_line[3],self.current_line[4],"::"..labelE.."::"})
    end
end
function parser:parseELSE(line)
    checkELIS()
    local cmd = Cmd:new()
    self:NOOP()
    --self:parseLABL({self.current_line[1],self.current_line[2],self.current_line[3],self.current_line[4],"::".."WTF".."::"})
    self.current_chunk:setScope(function()
        local labelE = fStack:pop()[1]
        self:parseLABL({self.current_line[1],self.current_line[2],self.current_line[3],self.current_line[4],"::"..labelE.."::"})
    end) -- Finishes the IFFF scope
end
function parser:parseIFFF(line)
    local tempfunc
    if fStack:count()>0 then
        --print("We have a nested if going on... Lets work on this")
        local dat = fStack:peek()
        local lE,lN = dat[1],dat[2]
        local lG = gen("$labelNext_")
        fStack:peek()[3] = function()
            --print("HERE WE ARE!",lE,lN,lG)
            self:parseFNNR({self.current_line[1],self.current_line[2],self.current_line[3],self.current_line[4],"JUMP(\""..lE.."\")"})
            self:parseLABL({self.current_line[1],self.current_line[2],self.current_line[3],self.current_line[4],"::"..lN.."::"})
        end
    end
    local l = self:logicChop(line[5])
    local v = self:parseExpr(l)
    local labelE = gen("$labelEnd_")
    local labelN = gen("$labelNext_")
    self:JMPZ(v,labelN)
    fStack:push({labelE,labelN})
    self.current_chunk:setScope(function()
        self:processIFFFBlock()
    end) -- Sets the scope to IFFF. The chunk object handles everything
end
function parser:parseELIF(line)
    checkELIS()
    line[5] = line[5]:sub(5,-1)
    line[5] = self:logicChop(line[5])
    local v = self:parseExpr(line[5])
    local labelN = gen("$labelNext_")
    fStack:peek()[2]=labelN
    self:JMPZ(v,labelN)
    self.current_chunk:setScope(function()
        self:processIFFFBlock()
    end) -- Continues the scope to ELIF.
end
function parser:buildLogic(l,o,r,v)
    local cmd = Cmd:new({self.current_line[1],self.current_line[2],COMP,self.current_line[4],"?"},COMP,{left=l,op=o,right=r,var=v})
    function cmd:tostring()
        return table.concat({self.args.op,tostring(self.args.left).."\0",tostring(self.args.right).."\0"},", ")..", "..self.args.var.."\0"
    end
    self.current_chunk:addCmd(cmd)
end
function parser:buildInsert(name,ind,v)
    local cmd = Cmd:new({self.current_line[1],self.current_line[2],INST,self.current_line[3],"?"},INST,{name = name, index = ind, var = v})
    function cmd:tostring()
        return table.concat({tostring(self.args.name),tostring(self.args.index)},"\0, ")..", "..self.args.var.."\0"
    end
    self.current_chunk:addCmd(cmd)
end
function parser:buildIndex(name,ind,v)
    local cmd = Cmd:new({self.current_line[1],self.current_line[2],INDX,self.current_line[3],"?"},INDX,{name = name, index = ind, var = v})
    function cmd:tostring()
        return table.concat({tostring(self.args.name),tostring(self.args.index)},"\0, ")..", "..self.args.var.."\0"
    end
    self.current_chunk:addCmd(cmd)
end
function parser:logicChop(expr)
    expr = expr:gsub("([_%w]+)(%b())",function(func,args)
        local v = gen("$")
        local fnwr = {self.current_line[1],self.current_line[2],FWNR,self.current_line[4],v.." = "..func..args}
        self:parseFNWR(fnwr)
        return v
    end)
    local counter = 0
    local v
    local function next()
        counter = counter + 1
        return expr:sub(counter,counter)
    end
    local function prev()
        counter = counter - 1
    end
    local function peek()
        return expr:sub(counter + 1,counter + 1)
    end
    local c = "."
    local l,o,r = '','',''
    local state = 0
    local start = 1
    local elem = ""
    local function setOp(op)
        if l~='' then
            o = op
        else
            self:error("Invalid Syntax",self.current_line)
        end
    end
    local function index(right)
        local ind = ""
        c = peek()
        while c ~= "]" do
            next()
            ind = ind..c
            c = peek()
        end
        c = next()
        if right then
            local vv = gen("$")
            v = gen("$")
            r = right
            self:buildIndex(r,ind,vv)
            self:buildLogic(l,o,vv,v)
            l,o,r = '','',''
            elem = elem .. v
        elseif l~= "" and r=="" then
            v = gen("$")
            l = v
        end
        if not(c=="]") then
            self:error("']' expected to close '['")
        end
    end
    local function default()
        if c == "=" and peek()=="=" then
            next() -- eat second =
            setOp(EQ)
        elseif c == ">" and peek()=="=" then
            next()
            setOp(GTE)
        elseif c == "<" and peek()=="=" then
            next()
            setOp(LTE)
        elseif c == "!" or c == "~" and peek()== "=" then
            next()
            setOp(NEQ)
        elseif c == "<" then
            setOp(LT)
        elseif c == ">" then
            setOp(GT)
        elseif c == "[" then -- handle index stuff
            index()
        elseif c == "o" and peek()=="r" then
            next()
            elem = elem .. "+"
        elseif c == "a" and peek()=="n" then
            if next() == "n" and peek()=="d" then
                next()
                elem = elem .. "*"
            else
                --self:error("Invalid syntax!"..c) -- Grab the current line
            end
        elseif c == "i" and peek()=="f" then
            next()
        elseif c == ' ' then
            -- Ignore white space if not part of a string
        elseif isDigit(c) then
            local dot = false
            prev()
            c = peek()
            local digit = ""
            while isDigit(c) or (dot==false and c==".") do
                next()
                if c=="." then
                    dot = true
                    digit = digit .. "."
                elseif isDigit(c) then
                    digit = digit .. c
                end
                c = peek()
            end
            digit = tonumber(digit)
            if l=="" then
                l = digit
            elseif r=="" then
                r = digit
                v = gen("$")
                self:buildLogic(l,o,r,v)
                l,o,r = '','',''
                elem = elem .. v
            end
        elseif isLetter(c) then
            if l=='' then
                l=c
                local k = peek()
                while isLetter(k) or isDigit(k) do
                    next()
                    l=l..k
                    k = peek()
                end
                if l == "true" then
                    l = true
                elseif l == "false" then
                    l = false
                else
                    l = l
                end
            elseif o~= '' then
                r=c
                local k = peek()
                while isLetter(k) or isDigit(k) do
                    next()
                    r=r..k
                    k = peek()
                end
                if k == "[" then
                    next()
                    index(r)
                else
                    if r == "true" then
                        r = true
                    elseif r == "false" then
                        r = false
                    else
                        r = r
                    end
                    v = gen("$")
                    self:buildLogic(l,o,r,v)
                    l,o,r = '','',''
                    elem = elem .. v
                end
            else
                self:error("Invalid syntax!",self.current_line)
            end
        else
            elem = elem .. c
        end
    end
    local str = ""
    while c~="" do
        c = next()
        if c == '"' then
            c = peek()
            str = ""
            while c~="\"" do
                next()
                if c=="\\" and peek()=="\"" then
                    next()
                    str = str .. "\""
                else
                    str = str .. c
                end
                c = peek()
            end
            str = "\""..str.."\""
            if l=="" then
                l = str
            elseif r=="" then
                r = str
                v = gen("$")
                self:buildLogic(l,o,r,v)
                l,o,r = '','',''
                elem = elem .. v
            end
            next()
        elseif c == "'" then
            elem = elem .. '"'
            c = peek()
            while c~="\"" do
                next()
                if c=="\\" and peek()=="'" then
                    next()
                    elem = elem + "'"
                else
                    elem = elem .. c
                end
                c = peek()
            end
            str = "\""..str.."\""
            if l=="" then
                l = str
            elseif r=="" then
                r = str
                v = gen("$")
                self:buildLogic(l,o,r,v)
                l,o,r = '','',''
                elem = elem .. v
            end
            next()
        else
            default()
        end
    end
    return elem
end
function parser:chop(expr)
    for l,o,r in expr:gmatch("(.-)([/%^%+%-%*%%])(.+)") do
        if r:match("(.-)([/%^%+%-%*%%])(.+)") then
            local v = gen("$")
            self:buildMFunc(l,o,self:chop(r),v)
            return v
        else
            local v = gen("$")
            self:buildMFunc(l,o,r,v)
            return v
        end
    end
end
function parser:buildMFunc(l,o,r,v)
    local fnwr = {self.current_line[1],self.current_line[2],FWNR,self.current_line[4]}
    local line
    if o == "+" then
        line = v.." = ADD("..table.concat({l,r},",")..")"
    elseif o == "-" then
        line = v.." = SUB("..table.concat({l,r},",")..")"
    elseif o == "*" then
        line = v.." = MUL("..table.concat({l,r},",")..")"
    elseif o == "/" then
        line = v.." = DIV("..table.concat({l,r},",")..")"
    elseif o == "%" then
        line = v.." = MOD("..table.concat({l,r},",")..")"
    elseif o == "^" then
        line = v.." = POW("..table.concat({l,r},",")..")"
    else 
        -- Soon we will allow for custom symbols for now error
    end
    table.insert(fnwr,line)
    self:parseFNWR(fnwr)
end
function parser:parseExpr(expr)
    if not expr:match("[/%^%+%-%*%%]") then --[[print("No math to do!")]] return expr end
    -- handle pharanses
    expr=expr:gsub("([%W])(%-%d)",function(b,a)
		return b.."(0-"..a:match("%d+")..")"
    end)
    -- Work on functions
    expr = expr:gsub("([_%w]+)(%b())",function(func,args)
        local v = gen("$")
        local fnwr = {self.current_line[1],self.current_line[2],FWNR,self.current_line[4],v.." = "..func..args}
        self:parseFNWR(fnwr)
        return v
    end)
    expr = expr:gsub("(%b())",function(a)
        return self:parseExpr(a:sub(2,-2))
    end)
    return self:chop(expr)
end
function parser:parseChoice(line)
    local text = line[5]:match("\"(.+)\"")
    local copt = self:peek()
    local choice = {text = text,options = {}}
    local cmd = Cmd:new(line,CHOI,choice)
    function cmd:tostring()
        return self.args.text.."\0, "..table.concat(self.args.options,"\0, ").."\0"-- disp choices
    end
    self.current_chunk:addCmd(cmd)
    if copt[3]~=OPTN then
        self:error("Choices must have at least one option to choose!")
        return
    end
    local opts = {}
    while copt do
        copt = self:next()
        local a,b = copt[5]:match("(.+) %s*(.+)")
        table.insert(choice.options,a:sub(2,-2))
        table.insert(opts,b)
        copt = self:peek()
        if copt[3]~=OPTN then
            break
        end
    end
    local s = ((#opts-1)*2-1)
    local c = s
    for i=1,#opts do
        self:parseFNNR({copt[1],copt[2],FNNR,copt[4],opts[i]})
        if i~=#opts then
            self:parseFNNR({copt[1],copt[2],FNNR,copt[4],"SKIP(".. c ..")"})
        end
        c=c-2
    end
end
function parser:parseFNNR(line)
    local fname, args = line[5]:match("(.-)%((.*)%)")
    if #args==0 then 
        args = {} 
    else 
        args = self:split(args)
    end
    local cmd = Cmd:new(line,FNNR,{func=fname,args=args})
    function cmd:tostring()
        if #args==0 then
            return fname.."\0"
        else
            return table.concat({fname,table.concat(args,"\0, ")},"\0, ").."\0"
        end
    end
    self.current_chunk:addCmd(cmd)
end
function parser:parseFNWR(line)
    local vars, fname, args = line[5]:match("(.-)%s*=%s*(.-)%((.+)%)")
    vars = self:split(vars)
    if #args==0 then 
        args = {} 
    else 
        args = self:split(args)
    end
    local cmd = Cmd:new(line,FNWR,{func=fname,args=args,vars=vars})
    function cmd:tostring()
        return table.concat({fname,table.concat(args,"\0, ")},"\0, ").."\0, ".. table.concat(vars,"\0, ").."\0"
    end
    self.current_chunk:addCmd(cmd)
end
function parser:parseASGN(line)
    local vars,assigns = line[5]:match("(.-)%s*=%s*(.+)")
    vars = self:split(vars)
    assigns = self:split(assigns)
    local list = {}
    for i,v in ipairs(vars) do
        table.insert(list,{tostring(assigns[i]).."\0",v.."\0"})
    end
    local cmd = Cmd:new(line,ASGN,list)
    function cmd:tostring()
        local str = ""
        for i,v in ipairs(self.args) do
            str = str .. "(" .. tostring(v[1]) .. ", ".. v[2] ..")" .. ", "
        end
        return str:sub(1,-3)
    end
    self.current_chunk:addCmd(cmd)
end
function parser:parseLABL(line)
    local label = line[5]:match("::(.+)::")
    if not label then
        self:error("Invalid Label Definition",line)
    end
    local cmd = Cmd:new(line,LABL,{label = label})
    function cmd:tostring()
        return self.args.label.."\0"
    end
    self.current_chunk:addCmd(cmd)
end
function parser:parseDialogue(line)
    local targ,text = line[5]:match("(%w*)%s*(.*)")
    if #targ == 0 then targ = nil end
    local cmd = Cmd:new(line,DISP,{text=text,target=targ})
    function cmd:tostring()
        return table.concat({targ or "@",text},"\0, ").."\0"
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