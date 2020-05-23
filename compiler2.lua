file = io.open("test.dms","rb")
content = file:read("*a")
line_num = 0
function string:trim()
    return (self:gsub("^%s*(.-)%s*$", "%1"))
end
local choice
for line in content:gmatch("(.-)\n") do
    line_num = line_num + 1
    line = line:trim()
    ::back::
    if line:match("^%[[_:,%w%(%)]+%]") then
        print(line_num,"BLOCK_START",line)
    elseif line:match("choice%s+\".+\"%s*:") then
        print(line_num,"CHOICE_BLOCK",line)
        choice = true
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
end