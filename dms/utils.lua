-- Utils modify the global enviroment
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
            print(formatting .. tostring(v))		
        else
            print(formatting .. v)
        end
    end
end
function string.split(s,pat)
	local pat=pat or ","
	local res = {}
	local start = 1
	local state = 0
	local c = '.'
    local elem = ''
    local function helper()
        if tonumber(elem) then
            elem = tonumber(elem)
        elseif elem:sub(1,1) == "\"" and elem:sub(-1,-1) == "\"" then
            elem = elem:sub(2,-2)
        elseif elem == "true" then
            elem = true
        elseif elem == "false" then
            elem = false
        elseif elem:sub(1,1) == "{" and elem:sub(-1,-1)=="}" then
            elem = elem:sub(2,-2):split()
        else
            elem = "\1"..elem
        end
    end
	for i = 1, #s do
		c = s:sub(i, i)
		if state == 0 or state == 3 then -- start state or space after comma
			if state == 3 and c == ' ' then
				state = 0 -- skipped the space after the comma
			else
				state = 0
				if c == '"' or c=="'" then
					state = 1
					elem = elem .. '"'
				elseif c=="{" then
					state = 1
                    elem = elem .. '{'
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
			if c == '"' or c=="'" then --quote detection could be done here
				state = 0
				elem = elem .. '"'
			elseif c=="}" then
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
	res[#res + 1] = elem
	return res
end