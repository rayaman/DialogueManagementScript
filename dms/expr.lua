local Expr = {}
Expr.__index = Expr
function Expr:new(expr)
    local c = {}
    setmetatable(c,self)
    
    return c
end