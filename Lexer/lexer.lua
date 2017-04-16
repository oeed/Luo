local stringFind = string.find
local stringSub = string.sub

local IDENTIFIER = 1
local KEYWORD = 2
local STRING = 3
local NUMBER = 4
local OPERATOR = 5

tokenTypes = {
	IDENTIFIER = IDENTIFIER,
	KEYWORD = KEYWORD,
	STRING = STRING,
	NUMBER = NUMBER,
	OPERATOR = OPERATOR,
}

tokenKeys = {
	TYPE = 1,
	VALUE = 2,
	LINE_NUMBER = 3,
	COLUMN_NUMBER = 4,
	START_INDEX = 5,
	END_INDEX = 6,
	ORIGINAL_VALUE = 7
}

operators = {
	TYPE_SET = 1,
	OPTIONAL = 2,
	DOUBLE_EQUAL = 3,
	NOT_EQUAL = 4,
	LESS_THAN_EQUAL = 5,
	GREATER_THAN_EQUAL = 6,
	VAR_ARG = 7,
	CONCATENATE = 8,
	PLUS_PLUS = 9,
	MINUS_MINUS = 10,
	PLUS_EQUAL = 11,
	MINUS_EQUAL = 12,
	MULTIPLY_EQUAL = 13,
	DIVIDE_EQUAL = 14,
	MODULUS_EQUAL = 15,
	EXPONENT_EQUAL = 16,
	EQUAL = 17,
	PLUS = 18,
	MULTIPLY = 19,
	MINUS = 20,
	HASH = 21,
	DIVIDE = 22,
	MODULUS = 23,
	EXPONENT = 24,
	GREATHER_THAN = 25,
	LESS_THAN = 26,
	DOT = 27,
	SQUARE_BRACKET_LEFT = 28,
	SQUARE_BRACKET_RIGHT = 29,
	ROUND_BRACKET_LEFT = 30,
	ROUND_BRACKET_RIGHT = 31,
	CURLY_BRACKET_LEFT = 32,
	CURLY_BRACKET_RIGHT = 33,
	COMMA = 34
}

keywords = {
	AND = 1,
	BREAK = 2,
	DO = 3,
	ELSE = 4,
	ELSEIF = 5,
	END = 6,
	FALSE = 7,
	FOR = 8,
	FUNCTION = 9,
	IF = 10,
	IN = 11,
	LOCAL = 12,
	NIL = 13,
	NOT = 14,
	OR = 15,
	REPEAT = 16,
	RETURN = 17,
	THEN = 18,
	UNTIL = 19,
	WHILE = 20,
	CLASS = 21,
	PROPERTY = 22,
	IS = 23
}

local lookupKeywords = {
	["and"] = keywords.AND, ["break"] = keywords.BREAK,  ["do"] = keywords.DO,
    ["else"] = keywords.ELSE, ["elseif"] = keywords.ELSEIF, ["end"] = keywords.END,
    ["false"] = keywords.FALSE, ["for"] = keywords.FOR, ["function"] = keywords.FUNCTION,
    ["if"] = keywords.IF, ["in"] = keywords.IN,  ["local"] = keywords.LOCAL, ["nil"] = keywords.NIL,
    ["not"] = keywords.NOT, ["or"] = keywords.OR, ["repeat"] = keywords.REPEAT,
    ["return"] = keywords.RETURN, ["then"] = keywords.THEN, ["true"] = keywords.TRUE,
    ["until"] = keywords.UNTIL,  ["while"] = keywords.WHILE, ["class"] = keywords.CLASS, ["property"] = keywords.PROPERTY,
    ["is"] = keywords.IS
}

-- Filter functions. Gets the actual value we want from the string

local function filterString(str)
	return stringSub(str, 2, -2)
end

local function filterLongString(string, findMatch)
    local quoteLength = 3
    if findMatch then -- find match will be the == between [[, which would increase the length
        quoteLength = quoteLength + findres[3]:len()
    end
    str = stringSub(string, quoteLength, -quoteLength)
    if stringSub(string, 1, 1) == "\n" then
        str = stringSub(string, 2)
    end
    return str
end

local function filterIdentifier(str)
	local keyword = lookupKeywords[str]
	if keyword then
		return keyword, KEYWORD
	else
		return str
	end
end

local tokenMatches = {
	{'^%s+', nil, nil}, -- whitespace
	{'^0x[%da-fA-F]+', NUMBER, tonumber}, -- hex numbers
	{'^[%a_][%w_]*', IDENTIFIER, filterIdentifier}, -- identifiers
	{'^%d+%.?%d*[eE][%+%-]?%d+', NUMBER, tonumber}, -- scientific numbers
	{'^%d+%.?%d*', NUMBER, tonumber}, -- decimal numbers
	{"^(['\"])%1", STRING, ""}, -- empty string
	{[[^(['"])(\*)%2%1]], STRING, filterString}, -- string
	{[[^(['"]).-[^\](\*)%2%1]], STRING, filterString}, -- string with escapes
	{'^%-%-%[(=*)%[.-%]%1%]', nil, nil}, -- multi-line comment
	{'^%-%-.-\n', nil, nil}, -- single line comment
	{'^%[(=*)%[.-%]%1%]', STRING, filterLongString}, -- multi-line string
	{'^:', OPERATOR, operators.TYPE_SET},
	{'^?', OPERATOR, operators.OPTIONAL},
	{'^==', OPERATOR, operators.DOUBLE_EQUAL},
	{'^~=', OPERATOR, operators.NOT_EQUAL},
	{'^<=', OPERATOR, operators.LESS_THAN_EQUAL},
	{'^>=', OPERATOR, operators.GREATER_THAN_EQUAL},
	{'^%.%.%.', OPERATOR, operators.VAR_ARG},
	{'^%.%.', OPERATOR, operators.CONCATENATE},
	{'^++', OPERATOR, operators.PLUS_PLUS},
	{'^%-%-', OPERATOR, operators.MINUS_MINUS},
	{'^+=', OPERATOR, operators.PLUS_EQUAL},
	{'^%-=', OPERATOR, operators.MINUS_EQUAL},
	{'^*=', OPERATOR, operators.MULTIPLY_EQUAL},
	{'^/=', OPERATOR, operators.DIVIDE_EQUAL},
	{'^%%=', OPERATOR, operators.MODULUS_EQUAL},
	{'^%^=', OPERATOR, operators.EXPONENT_EQUAL},
	{'^=', OPERATOR, operators.EQUAL},
	{'^+', OPERATOR, operators.PLUS},
	{'^*', OPERATOR, operators.MULTIPLY},
	{'^%-', OPERATOR, operators.MINUS},
	{'^#', OPERATOR, operators.HASH},
	{'^/', OPERATOR, operators.DIVIDE},
	{'^%%', OPERATOR, operators.MODULUS},
	{'^%^', OPERATOR, operators.EXPONENT},
	{'^>', OPERATOR, operators.GREATHER_THAN},
	{'^<', OPERATOR, operators.LESS_THAN},
	{'^%.', OPERATOR, operators.DOT},
	{'^%[', OPERATOR, operators.SQUARE_BRACKET_LEFT},
	{'^%]', OPERATOR, operators.SQUARE_BRACKET_RIGHT},
	{'^%(', OPERATOR, operators.ROUND_BRACKET_LEFT},
	{'^%)', OPERATOR, operators.ROUND_BRACKET_RIGHT},
	{'^{', OPERATOR, operators.CURLY_BRACKET_LEFT},
	{'^}', OPERATOR, operators.CURLY_BRACKET_RIGHT},
	{'^,', OPERATOR, operators.COMMA},
}

local m = 0

function lex(code)
	local nextIndex = 1
	tokens = {}

	local charIndex = 1
	local codeLength = #code
	local lineIndex = 1
	local lineStartIndex = 1
	while charIndex <= codeLength do
		local matched = false
		for i, tokenMatch in ipairs(tokenMatches) do
			local startIndex, endIndex, findMatch = stringFind(code, tokenMatch[1], charIndex)
			if startIndex then
				local tokenType = tokenMatch[2]
				local value = stringSub(code, startIndex, endIndex)
				if tokenType then -- we ignore tokens without a type (whitespace, comments, etc.)
					local filterFunction = tokenMatch[3]
					
					local filteredValue, replacementType = type(filterFunction) == "function" and filterFunction(value, findMatch) or filterFunction
					tokens[nextIndex] = {
						replacementType or tokenType, -- TYPE
						filteredValue, -- VALUE
						lineIndex, -- LINE_NUMBER
						startIndex - lineStartIndex + 1, -- COLUMN_INDEX
						startIndex, -- START_INDEX
						endIndex, -- END_INDEX
						value -- ORIGINAL_VALUE	
					}
					nextIndex = nextIndex + 1
				end

                if value:find("\n") then
                    -- Update line number.
                    local _, newLineCount = value:gsub("\n", "")
                    lineIndex = lineIndex + newLineCount
                    local prefixStart, prefixEnd, m = value:find("\n[^\n]+$")
					lineStartIndex = endIndex - (prefixStart and (prefixEnd - prefixStart - 1) or -1)
                end
				charIndex = endIndex + 1
				matched = true
				break -- we've done one token, so start looping over the tokens again for this line
			end
		end
		if not matched then
			error("Lexer error: invalid token at: " .. stringSub(code, charIndex, charIndex + 10))
		end
	end
	return tokens
end

return {lex = lex}