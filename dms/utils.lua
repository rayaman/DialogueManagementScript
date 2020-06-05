-- Utils modify the global enviroment
local symcount = {}
local syms = {}
for i=65,90 do
    syms[#syms+1] = string.char(i)
end
for i=97,122 do
    syms[#syms+1] = string.char(i)
end
local count = #syms+1
function gen(symbol,flush)
    if flush == true then
        symcount[symbol] = {1, 0}
        return
    end
    symbol = symbol or "__"
    if symcount[symbol] then
        symcount[symbol][2] = symcount[symbol][2] + 1
		if symcount[symbol][2]%count==0 then
			symcount[symbol][2] = 1
			symcount[symbol][1] = symcount[symbol][1] + 1
		end
        return symbol .. syms[symcount[symbol][1]%count]..syms[symcount[symbol][2]%count]
    else
        symcount[symbol] = {1, 0}
        return gen(symbol)
    end
end
function isLetter(c)
    return c:lower():match("[%$_%l]")
end
function isDigit(c)
    return c:lower():match("%d")
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
function string.trim(self)
    return (self:gsub("^%s*(.-)%s*$", "%1"))
end
function tprint (tbl, indent)
    if not indent then indent = 0 end
    for k, v in pairs(tbl) do
        formatting = string.rep("  ", indent) .. k .. ": "
        if type(v) == "table" then
            print(formatting)
            tprint(v, indent+1)
        elseif type(v) == 'boolean' then
            print(formatting .. "<" .. type(v).. ">" .. tostring(v))		
        else
            print(formatting .. "<" .. type(v).. ">" .. tostring(v))
        end
    end
end