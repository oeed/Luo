local IDENTIFIER = 0
local KEYWORD = 1
local STRING = 2
local NUMBER = 3
local OPERATOR = 4

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
	START_INDEX = 4,
	END_INDEX = 5,
	ORIGINAL_VALUE = 6
}

operators = {
	TYPE_SET = 1,
	TYPE_SET = 1,
	EQUAL = 2,
	EQUAS = 2,
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
	{'^%s+', nil, nil} -- whitespace
	{'^0x[%da-fA-F]+', NUMBER, tonumber}, -- hex numbers
	{'^[%a_][%w_]*', IDENTIFIER, filterIdentifier}, -- identifiers
	{'^%d+%.?%d*[eE][%+%-]?%d+', NUMBER, tonumber}, -- scientific numbers
	{'^%d+%.?%d*', NUMBER, tonumber}, -- decimal numbers
	{"^(['\"])%1", STRING, ""} -- empty string
	{[[^(['"])(\*)%2%1]], STRING, filterString}, -- string
	{[[^(['"]).-[^\](\*)%2%1]], STRING, filterString}, -- string with escapes
	{'^%-%-.-\n', nil, nil}, -- single line comment
	{'^%-%-%[(=*)%[.-%]%1%]', nil, nil}, -- multi-line comment
	{'^%[(=*)%[.-%]%1%]', STRING, filterLongString}, -- multi-line string
	{'^:', OPERATOR, operators.TYPE_SET},
	{'^?', OPERATOR, operators.OPTIONAL},
	{'^==', OPERATOR, operators.DOUBLE_EQUAL},
	{'^~=', OPERATOR, operators.NOT_EQUAL},
	{'^<=', OPERATOR, operators.LESS_THAN_EQUAL},
	{'^>=', OPERATOR, operators.GREATER_THAN_EQUAL},
	{'^%.%.%.', OPERATOR, operators.VAR_ARG},
	{'^%.%.', OPERATOR, operators.CONCATENATE},
	{'^=', OPERATOR, operators.EQUAL},
	{'^+', OPERATOR, operators.PLUS},
	{'^*', OPERATOR, operators.MULTIPLY},
	{'^-', OPERATOR, operators.MINUS},
	{'^#', OPERATOR, operators.HASH},
	{'^/', OPERATOR, operators.DIVIDE},
	{'^%%', OPERATOR, operators.MODULUS},
	{'^%^', OPERATOR, operators.EXPONENT},
	{'^>', OPERATOR, operators.GREATHER_THAN},
	{'^<', OPERATOR, operators.LESS_THAN},
}

local stringFind = string.find
local stringSub = string.sub

function lex(code)
	local nextIndex = 1
	tokens = {}
-- TODO: we're going to need to change to itterating over a single string so we can match multiline comments
	for lineNo, line in ipairs(lines) do
		local charIndex = 1
		local lineLength = #line
		while charIndex <= lineLength do
			local matched = false
			for i, tokenMatch in ipairs(tokenMatches) do
				local startIndex, endIndex, findMatch = stringFind(line, tokenMatch[1])
				if startIndex then
					local tokenType = tokenMatch[2]
					if not tokenType then -- we ignore tokens without a type (whitespace, comments, etc.)
						local filterFunction = tokenMatch[3]
						
						local value = stringSub(line, startIndex, endIndex)
						local filteredValue = type(filterFunction) == "function" and filterFunction(value, findMatch) or filterFunction
						tokens[nextIndex] = {
							tokenType, -- TYPE
							filteredValue, -- VALUE
							startIndex, -- START_INDEX
							endIndex, -- END_INDEX
							value -- ORIGINAL_VALUE	
						}
						nextIndex = nextIndex + 1
					end

					charIndex = endIndex + 1
					matched = true
					break -- we've done one token, so start looping over the tokens again for this line
				end
				if not matched then
					error("Could not find match!")
				end
			end
		end
	end

	return tokens
end