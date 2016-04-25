local function __CLASS__0(m)error(m,3)end local function __CLASS__1(_,k)__CLASS__0("attempted to access non-existant enum '"..k.."' of class '"..tostring(_).."'")end local function __CLASS__2(_,k,v)__CLASS__0("attempted to mutate class '"..tostring(_).."' using key '"..k.."'")end local function __CLASS__3(_,k)__CLASS__0("attempted to access non-existant property '"..tostring(_).."' enum '"..k.."'")end local function __CLASS__4(_,k,v)__CLASS__0("attempted to set non-existant property '"..k.."' of '"..tostring(_).."' to '"..v.."'")end local function __CLASS__5(_,k)__CLASS__0("attempted to access non-existant key '"..k.."' from enum '"..tostring(_).."'")end local function __CLASS__6(_,k,v)__CLASS__0("attempted to mutate enum '"..tostring(_).."' key '"..tostring(k).."' to '"..v.."'")end local function __CLASS__7(_,k)if k=="super"then __CLASS__0("tried to access super of '" .. tostring(_) .. "', which does not have a super")else __CLASS__0("attempted to access invalid index '" .. k .. "' of super '" .. tostring(_) .. "'")end end local function __CLASS__8(_,k,v)__CLASS__0("attempted to mutate super '"..tostring(_).."' using key '"..k.."'")end local function __CLASS__9(_,k,v)__CLASS__0("attempted to set read only property '"..k.."' of '"..tostring(_).."' to '"..v.."'")end local function __CLASS__A(_,k,t,v)__CLASS__0("attempted to set property '"..k.."' of '"..tostring(_).."' to an invalid value '"..tostring(v).."', expected '"..t.."'")end local function __CLASS__B(_,k,f,t,v)__CLASS__0("attempted to pass parameter '"..k.."' of '"..tostring(_).."."..f.."' an invalid value '"..tostring(v).."', expected '"..t.."'")end local function __CLASS__C(v)return v==nil or type(v)~="string"end local function __CLASS__D(f,e,...)return setfenv(f, e)(...)end local function __CLASS__E(name, startLine, func)
	return select(2, xpcall(func,  function(err)
		local _, trace = pcall(error, "<@", 3)
		local lineNumber = trace:match(":(%d+): <@")
		print(name .. ":" .. lineNumber + startLine - 1 .. ": " .. err:match(":" .. lineNumber .. ": (.*)$"))
	end))
end dofile("serialise")

local __CLASS__instance_create = function(instanceType, instanceVariables, instanceFunctions, initialiseFunction, defaultValues, environmentClass, name, instance__index, instance__newindex, supers_names, typeOfTree, ...)
	local instance = {}
	local instanceEnvironment = setmetatable({}, {
		__index = function(_, k)
			if not instanceVariables[k] then -- if an instance variable is nil and there is an upvalue local with the same name the instance variable will hide the upvalue, even when nil
				return environmentClass[k]
			end
		end,
		__newindex = function(_, k, v)
			if not instanceVariables[k] then -- all instance variables hide upvalues, regardless of their value
				environmentClass[k] = v -- TODO: should this be the class environment, or _G?
			else
				rawset(_, k, v)
			end
		end
	})
	for k, v in pairs(instanceVariables) do
		instanceEnvironment[k] = __CLASS__E(v, environmentClass)
	end
	local values = {}
	for k,v in pairs(defaultValues) do
		values[k] = __CLASS__E(v, environmentClass)
	end
	local getLocks, setLocks = {}, {}
	local supers = {}
	local supers__tostrings = {}
	local supersEnvironments = {}
	local supersValues = {}
	local __tostring = instanceType .. " of '" .. name .. "': " .. tostring(instance):sub(8)
	setmetatable(instance, {
		__index = function(_,k)
			return instance__index[k](instance, k, values, instanceEnvironment, getLocks)
		end,
		__newindex = function(_,k,v)
			instance__newindex[k](instance, k, v, values, instanceEnvironment, setLocks)
		end,
		__tostring = function() return __tostring end
	})

	for i, super_name in ipairs(supers_names) do
		local super = {}
		-- local superValues = setmetatable({}, {__index = values, __newindex = function(_,k,v)values[k] = v end})
		local super__tostring = "super '" .. super_name .. "': " .. tostring(super):sub(8) .. " of " .. __tostring
		local super__tostring_func = function() return super__tostring end
		setmetatable(super, {
			__index = function(_,k)
				return instance__index[k](super, k, values, instanceEnvironment, getLocks)
			end,
			__newindex = function(_,k,v)
				instance__newindex[k](super, k, v, values, instanceEnvironment, setLocks)
			end,
			__tostring = super__tostring_func
		})
		supers[i +1] = super
		supers__tostrings[i +1] = super__tostring_func
	end

	-- TODO: we might be able to place the function contents in here rather than calling it
	for k, funcs in pairs(instanceFunctions) do
		print("supers for ".. k)
		local isFirst = true
		local superFuncs = {}
		local stack = {}
		local n = 1
		for superI, func in pairs(funcs) do
			if not isFirst then
				stack[n] = {superI, func}
				n = n + 1
			else
				isFirst = false
			end
		end
		for i = n - 1, 1, -1 do
			local details = stack[i]
			local superI = details[1]
			local func = setfenv(details[2](supers[superI], superFuncs[i + 1]), instanceEnvironment)
			local super = superFuncs[i + 1]
			local __index
			if super then
				__index = function(_, k, v)
					if k == "super" then
						return super
					else
						__CLASS__7(_, k, v)
					end
				end
			else
				__index = __CLASS__7
			end
			superFuncs[i] = setmetatable({}, {__index = __index, __newindex = __CLASS__8, __tostring = supers__tostrings[superI], __call = function(_, ...)return func(super, ...) end})
		end
		print(superFuncs[1])
		values[k] = setfenv(funcs[1](instance, superFuncs[1]), instanceEnvironment)
	end

	local typeOfTree = {
		Cat = true,
		Animal = true,
		Object = true,
	}
	values.typeOf = function(_,other)
		return typeOfTree[other]
	end

	if initialiseFunction then
		__CLASS__E(initialiseFunction, instanceEnvironment, instance, ...)
	end
	return instance
end

local __CLASS__F=setmetatable({},{__index=_G})local __CLASS__G=setmetatable({},{__index=_G})AlertWindow={}local __CLASS__H={}Cat={}local __CLASS__I={}Window={}local __CLASS__J={}local __CLASS__K={		LIST = 1;		THUMBNAIL = 2;	}	local __CLASS__L={}local __CLASS__M={["aNumber"]=loadstring([[return 0x10c + 20 	]]),["aString"]=loadstring([[return "hello there" .. " concated!" 	.. "oh but there's more!"		]]),["thing"]=loadstring([[return "this is a default value"	]]),["another"]=loadstring([[return {		one = 1;		two = 2;		three = 3;		four = 4;	}	]]),["aBoolean"]=loadstring([[return true 	]]),["animal"]=loadstring([[return Cat( "Fluffles" ) 	]]),}local __CLASS__N={}local __CLASS__O={}local __CLASS__P={}local __CLASS__Q={}__CLASS__E("AlertWindow.luo",1,setfenv(loadstring([[local A_CONSTANT = "hello"


]]), __CLASS__F))__CLASS__E("AlertWindow.luo",77,setfenv(loadstring([[

local otherStuff = 5


]]), __CLASS__F))__CLASS__E("Cat.luo",1,setfenv(loadstring([[local CONST_VARIABLE = "THING"
local window = AlertWindow()


]]), __CLASS__G))