--~ t = debug.getmetatable ("")
--~ t.__index = function(self,k)
--~ 	if type(k)=="number" then
--~ 		return string.sub(self,k,k)
--~ 	end
--~ end
Token = {}
Token.__index = Token
local INTEGER, PLUS, EOF, MINUS, MUL, DIV, LPAREN, RPAREN = "INT","+","EOF", "-", "*", "/", "(", ")"
function Token.__tostring(self)
	return string.format("Token(%s, %s)",self.type,self.value)
end
function Token:new(tp,val)
	local c = {}
	setmetatable(c,self)
	c.type = tp
	c.value = val
	print("Token:"..tp)
	return c
end

Lexer = {}
Lexer.__index = Lexer
function Lexer:new(text)
	local c = {}
	setmetatable(c,self)
	self.text = text
	self.pos = 1
	self.current_char = self.text:sub(1,1)
	self.stop = false
	return c
end
function Lexer:advance()
	self.pos = self.pos + 1
	if self.pos > #self.text then
		self.current_char = false
	else
		self.current_char = self.text:sub(self.pos,self.pos)
	end
end
function Lexer:error()
	error("Invalid character")
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
		if self.current_char:match("%s") then
			self:skip_whitespace()
			goto continue
		end
		if self.current_char:match("%d") then
			return Token:new(INTEGER,self:integer())
		end
		if self.current_char == "+" then
			self:advance()
			return Token:new(PLUS,"+")
		end
		if self.current_char == "-" then--55+77
			self:advance()
			return Token:new(MINUS,"-")
		end
		if self.current_char == "*" then
			self:advance()
			return Token:new(MUL,"*")
		end
		if self.current_char == "/" then
			self:advance()
			return Token:new(DIV,"/")
		end
		if self.current_char == "(" then
			self:advance()
			return Token:new(LPAREN,"(")
		end
		if self.current_char == ")" then
			self:advance()
			return Token:new(RPAREN,")")
		end
		self:error("Invalid Symbol!")
	end
	return Token:new(EOF, nil)
end

Interpreter = {}
Interpreter.__index = Interpreter
function Interpreter:new(lexer)
	local c = {}
	setmetatable(c,self)
	c.lexer = lexer
	c.current_token = c.lexer:get_next_token()
	return c
end
function Interpreter:error()
	error('Error Invalid Syntax')
end
function Interpreter:eat(token_type)
	if self.current_token.type == token_type then
		self.current_token = self.lexer:get_next_token()
	else
		self:error()
	end
end
function Interpreter:factor()
	local token = self.current_token
	if token.type == INTEGER then
		self:eat(INTEGER)
		return token.value
	elseif token.type == LPAREN then
		self:eat(LPAREN)
		local result = self:expr()
		self:eat(RPAREN)
		return result
	end
end
function Interpreter:term()
	local result = self:factor()
	local token
	while self.current_token.type == MUL or self.current_token.type == DIV do
		token = self.current_token
		if token.type == MUL then
			self:eat(MUL)
			result = result * self:factor()
		elseif token.type == DIV then
			self:eat(DIV)
			result = result / self:factor()
		end
	end
	return result
end
function Interpreter:expr()
	local result = self:term()
	local token
	while self.current_token.type == PLUS or self.current_token.type == MINUS do
		token = self.current_token
		if token.type == PLUS then
			self:eat(PLUS)
			result = result + self:term()
		elseif token.type == MINUS then
			self:eat(MINUS)
			result = result - self:term()
		end
	end
	return result
end
while true do
	io.write("calc> ")
	local text = io.read()
	if text then
		l = Lexer:new(text)
		i = Interpreter:new(l)
		result = i:expr()
		print(result)
	end
end
