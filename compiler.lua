function tprint (tbl, indent)
  if not indent then indent = 0 end
  for k, v in pairs(tbl) do
    formatting = string.rep("  ", indent) .. k .. ": "
    if type(v) == "table" then
      print(formatting)
      tprint(v, indent+1)
    else
      print(formatting .. tostring(v))
    end
  end
end


Token = {}
Token.__index = Token
local INTEGER, PLUS, EOF, MINUS, MUL, DIV, LPAREN, RPAREN, BEGIN, END, DOT, ID, ASSIGN, SEMI = "INT","+","EOF", "-", "*", "/", "(", ")", "BEGIN", "END", "DOT", "ID", "ASSIGN", "SEMI"
function Token.__tostring(self)
	return string.format("Token(%s, %s)",self.type,self.value)
end
function Token:new(tp,val)
	local c = {}
	setmetatable(c,self)
	c.Type = 'Token'
	c.type = tp
	c.value = val
	--print("Token:"..tp)
	return c
end

Lexer = {}
Lexer.__index = Lexer
function Lexer:new(text)
	local c = {}
	setmetatable(c,self)
	c.Type = 'Lexer'
	c.text = text
	c.pos = 1
	c.current_char = c.text:sub(1,1)
	c.stop = false
	return c
end
function Lexer:advance()
	self.pos = self.pos + 1
	if self.pos > #self.text then
		self.current_char = false
		return
	else
		self.current_char = self.text:sub(self.pos,self.pos)
	end
end
local RESERVED_KEYWORDS = {
	BEGIN = Token:new('BEGIN',BEGIN),
	END = Token:new('END',END)
}
function Lexer:_id()
	local result = ''
	while self.current_char and self.current_char:match("%w") do
		result = result .. self.current_char
		self:advance()
	end
	local token = RESERVED_KEYWORDS[result] or Token:new(ID,result)
	return token
end
function Lexer:peek()
	local peek_pos = self.pos + 1
	if peek_pos > #self.text then
		return
	else
		return self.text:sub(peek_pos,peek_pos)
	end
end
function Lexer:error(err)
	error(err)
end
function Lexer:skip_whitespace()
	while self.current_char and self.current_char:match("%s") do
		self:advance()
	end
end
function Lexer:integer()
	local result = {}
	while self.current_char and self.current_char:match("%d") do
		table.insert(result,self.current_char)
		self:advance()
	end
	return tonumber(table.concat(result))
end
function Lexer:get_next_token()
	while self.current_char do
		::continue::
		if self.current_char and self.current_char:match("%s") then
			self:skip_whitespace()
			goto continue
		end
		if self.current_char and self.current_char:match("%d") then
			return Token:new(INTEGER,self:integer())
		end
		if self.current_char and self.current_char == "+" then
			self:advance()
			return Token:new(PLUS,"+")
		end
		if self.current_char and self.current_char == "-" then--55+77
			self:advance()
			return Token:new(MINUS,"-")
		end
		if self.current_char and self.current_char == "*" then
			self:advance()
			return Token:new(MUL,"*")
		end
		if self.current_char and self.current_char == "/" then
			self:advance()
			return Token:new(DIV,"/")
		end
		if self.current_char and self.current_char == "(" then
			self:advance()
			return Token:new(LPAREN,"(")
		end
		if self.current_char and self.current_char == ")" then
			self:advance()
			return Token:new(RPAREN,")")
		end
		if self.current_char and self.current_char:match("%w") then
			return self:_id()
		end
		if self.current_char and self.current_char == ":" and self:peek() == "=" then
			self:advance()
			self:advance()
			return Token:new(ASSIGN, ":=")
		end
		if self.current_char and self.current_char == ";" then
			self:advance()
			return Token:new(SEMI, ';')
		end
		if self.current_char and self.current_char == "." then
			self:advance()
			return Token:new(DOT,".")
		end
		if self.current_char == false then
			return Token:new(EOF, "EOF")
		end
		self:error("Invalid Symbol! "..tostring(self.current_char))
	end
	return Token:new(EOF, "EOF")
end

AST = {}
AST.__index = AST
function AST:new()
	local c = {}
	setmetatable(c,self)
	c.Type = 'AST'
	return c
end

Compound = {}
Compound.__index = AST
function Compound:new()
	local c = {}
	setmetatable(c,self)
	c.Type = 'Compound'
	c.children = {}
	return c
end

Assign = {}
Assign.__index = AST
function Assign:new(left,op,right)
	local c = {}
	setmetatable(c,self)
	c.Type = 'Assign'
	c.left = left
	c.op = op
	c.token = op
	c.right = right
	return c
end

Var = {}
Var.__index = AST
function Var:new(token)
	local c = {}
	setmetatable(c,self)
	c.Type = "Var"
	c.token = token
	c.value = token.value
	return c
end

NoOp = {}
NoOp.__index = AST
function NoOp:new()
	local c = {}
	setmetatable(c,self)
	c.Type = "NoOp"
	return c
end

UnaryOp = {}
UnaryOp.__index = AST
function UnaryOp:new(op,expr)
	local c = {}
	setmetatable(c,self)
	c.Type = 'UnaryOp'
	c.token = op
	c.op = op
	c.expr = expr
	return c
end

BinOp = {}
BinOp.__index = AST
function BinOp:new(left, op, right)
	local c = {}
	setmetatable(c,self)
	c.Type = 'BinOp'
	c.left = left
	c.token = op
	c.op = op
	c.right = right
	return c
end

Num = {}
Num.__index = AST
function Num:new(token)
	local c = {}
	setmetatable(c,self)
	c.Type = 'Num'
	c.token = token
	c.value = token.value
	return c
end

Parser = {}
Parser.__index = Parser
function Parser:new(lexer)
	local c = {}
	setmetatable(c,self)
	c.Type = 'Parser'
	c.lexer = lexer
	c.current_token = lexer:get_next_token()
	return c
end
function Parser:error()
	error('Error Invalid Syntax')
end
function Parser:eat(token_type)
	if self.current_token.type == token_type then
		self.current_token = self.lexer:get_next_token()
	else
		self:error()
	end
end
function Parser:program()
	local node = self:compound_statement()
	self:eat(DOT)
	return node
end
function Parser:compound_statement()
	self:eat(BEGIN)
	local nodes = self:statement_list()
	self:eat(END)

	local root = Compound:new()
	for _,node in pairs(nodes) do
		table.insert(root.children,node)
	end

	return root
end
function Parser:statement_list()
	local node = self:statement()

	local results = {node}

	while self.current_token.type == SEMI do
		self:eat(SEMI)
		table.insert(results,self:statement())
	end
	
	if self.current_token.type == ID then
		self:error()
	end

	return results
end
function Parser:statement()
	local node
	if self.current_token.type == BEGIN then
		node = self:compound_statement()
	elseif self.current_token.type == ID then
		node = self:assignment_statement()
	else
		node = self:empty()
	end
	return node
end
function Parser:assignment_statement()
	local left = self:variable()
	local token = self.current_token
	self:eat(ASSIGN)
	local right = self:expr()
	local node = Assign:new(left, token, right)
	return node
end
function Parser:variable()
	local node = Var:new(self.current_token)
	self:eat(ID)
	return node
end
function Parser:empty()
	return NoOp:new()
end
function Parser:factor()
	local token = self.current_token
	local node
	if token.type == PLUS then
		self:eat(PLUS)
		node = UnaryOp:new(token,self:factor())
		return node
	elseif token.type == MINUS then
		self:eat(MINUS)
		node = UnaryOp:new(token,self:factor())
		return node
	elseif token.type == INTEGER then
		self:eat(INTEGER)
		return Num:new(token)
	elseif token.type == LPAREN then
		self:eat(LPAREN)
		local node = self:expr()
		self:eat(RPAREN)
		return node
	else
		node = self:variable()
		return node
	end
end
function Parser:term()
	local node = self:factor()
	local token
	while self.current_token.type == MUL or self.current_token.type == DIV do
		token = self.current_token
		if token.type == MUL then
			self:eat(MUL)
		elseif token.type == DIV then
			self:eat(DIV)
		end
		node = BinOp:new(node,token,self:factor())
	end

	return node
end
function Parser:expr()
	local node = self:term()
	local token
	while self.current_token.type == PLUS or self.current_token.type == MINUS do
		token = self.current_token
		if token.type == PLUS then
			self:eat(PLUS)
		elseif token.type == MINUS then
			self:eat(MINUS)
		end
		node = BinOp:new(node,token,self:term())
	end

	return node
end
function Parser:parse()
	local node = self:program()
	if self.current_token.type ~= EOF then
		self:error()
	end
	return node
end

NodeVisitor = {}
NodeVisitor.__index = NodeVisitor
function NodeVisitor:new(node)
	local c = {}
	setmetatable(c,self)
	c.Type = 'NodeVisitor'
	return c
end
function NodeVisitor:visit(node)
	local visitor = self["visit_".. node.Type] or self.generic_visit
	return visitor(self,node)
end
function NodeVisitor:generic_visit(node)
	error("No visit_"..node.Type.." method")
end

Interpreter = {}
Interpreter.__index = NodeVisitor
function Interpreter:new(parser)
	local c = {}
	setmetatable(c,self)
	c.Type = 'Interpreter'
	c.parser = parser
	c.GLOBAL_SCOPE = {}
	function c:visit_Compound(node)
		for _,child in pairs(node.children) do
			self:visit(child)
		end
	end
	function c:visit_Assign(node)
		local var_name = node.left.value
		self.GLOBAL_SCOPE[var_name] = self:visit(node.right)
	end
	function c:visit_Var(node)
		local var_name = node.value
		local val = self.GLOBAL_SCOPE[var_name]
		if val then
			return val
		else
			error("NameError:"..var_name)
		end
	end
	function c:visit_NoOp(node)
		return
	end
	function c:visit_BinOp(node)
		if node.op.type == PLUS then
			local a,b = self:visit(node.left),self:visit(node.right)
			print("ADD ",a,b)
			return a + b
		elseif node.op.type == MINUS then
			return self:visit(node.left) - self:visit(node.right)
		elseif node.op.type == MUL then
			return self:visit(node.left) * self:visit(node.right)
		elseif node.op.type == DIV then
			return self:visit(node.left) / self:visit(node.right)
		end
	end
	function c:visit_UnaryOp(node)
		local op = node.op.type
		if op == PLUS then
			return self:visit(node.expr)
		elseif op == MINUS then
			return -self:visit(node.expr)
		end
	end
	function c:visit_Num(node)
		return node.value
	end
	function c:interpret()
		local tree = self.parser:parse()
		return self:visit(tree)
	end
	return c
end

text = [[
BEGIN
    ret := 11+a;
END.
]]
lexer = Lexer:new(text)
parser = Parser:new(lexer)
interpreter = Interpreter:new(parser)
interpreter.GLOBAL_SCOPE = {a=100}
interpreter:interpret()
for i,v in pairs(interpreter.GLOBAL_SCOPE) do
	print(i,v)
end
while true do
	io.write("calc> ")
	local text = io.read()
	if text then
		lexer = Lexer:new(text)
		parser = Parser:new(lexer)
		interpreter = Interpreter:new(parser)
		result = interpreter:interpret()
		print(result)
	end
end
