lexer = require "lexer"

local h = io.open("Example.luo", "r")
local line = h:read()
local str = ""
while line do
	str = str .. line .. "\n"
	line = h:read()
end

for k,v in lexer.lua(str) do
	print(k,v)
end