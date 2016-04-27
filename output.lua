local function __CLASS__0(m)error(m,3)end local function __CLASS__1(_,k)__CLASS__0("attempted to access non-existant enum '"..k.."' of class '"..tostring(_).."'")end local function __CLASS__2(_,k,v)__CLASS__0("attempted to mutate class '"..tostring(_).."' using key '"..k.."'")end local function __CLASS__3(_,k)__CLASS__0("attempted to access non-existant property '"..tostring(_).."' enum '"..k.."'")end local function __CLASS__4(_,k,v)__CLASS__0("attempted to set non-existant property '"..k.."' of '"..tostring(_).."' to '"..v.."'")end local function __CLASS__5(_,k,v)__CLASS__0("attempted to set value of function '"..k.."' of '"..tostring(_).."' to '"..v.."'")end local function __CLASS__6(_,k)__CLASS__0("attempted to access non-existant key '"..k.."' from enum '"..tostring(_).."'")end local function __CLASS__7(_,k,v)__CLASS__0("attempted to mutate enum '"..tostring(_).."' key '"..tostring(k).."' to '"..v.."'")end local function __CLASS__8(_,k)if k=="super"then __CLASS__0("tried to access super of '" .. tostring(_) .. "', which does not have a super")else __CLASS__0("attempted to access invalid index '" .. k .. "' of super '" .. tostring(_) .. "'")end end local function __CLASS__9(_,k,v)__CLASS__0("attempted to mutate super '"..tostring(_).."' using key '"..k.."'")end local function __CLASS__A(_,k,v)__CLASS__0("attempted to set read only property '"..k.."' of '"..tostring(_).."' to '"..v.."'")end local function __CLASS__B(_,k,t,v)__CLASS__0("attempted to set property '"..k.."' of '"..tostring(_).."' to an invalid value '"..tostring(v).."', expected '"..t.."'")end local function __CLASS__C(_,k,f,t,v)__CLASS__0("attempted to pass parameter '"..k.."' of '"..tostring(_).."."..f.."' an invalid value '"..tostring(v).."', expected '"..t.."'")end local function __CLASS__D(v)return v==nil or type(v)~="string"end local function __CLASS__E(f,e,...)return setfenv(f, e)(...)end local function __CLASS__F(name, startLine, func)
	return select(2, xpcall(func,  function(err)
		local _, trace = pcall(error, "<@", 3)
		local lineNumber = trace:match(":(%d+): <@")
		if not lineNumber then print(err)
		else
			print(name .. ":" .. lineNumber + startLine - 1 .. ": " .. err:match(":" .. lineNumber .. ": (.*)$"))
		end
	end))
end dofile("serialise")

local __CLASS__instance_create = function(instance, instanceType, instanceVariables, instanceFunctions, defaultValues, environmentClass, name, instance__index, instance__newindex, supers_names, typeOfTree, ...)
-- print("creating instance")
-- print("instance: " .. tostring(instance))
-- print("instanceType: " .. tostring(instanceType))
-- print("instanceVariables: " .. tostring(instanceVariables))
-- print("instanceFunctions: " .. tostring(instanceFunctions))
-- print("initialiseFunction: " .. tostring(initialiseFunction))
-- print("defaultValues: " .. tostring(defaultValues))
-- print("environmentClass: " .. tostring(environmentClass))
-- print("name: " .. tostring(name))
-- print("instance__index: " .. tostring(instance__index))
-- print("instance__newindex: " .. tostring(instance__newindex))
-- print("supers_names: " .. tostring(supers_names))
-- print("typeOfTree: " .. tostring(typeOfTree))
	local instanceEnvironment
	if instanceVariables then
		instanceEnvironment = setmetatable({}, {
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
			instanceEnvironment[k] = __CLASS__D(v, environmentClass)
		end
	else
		instanceEnvironment = environmentClass
	end
	local values = {}
	if defaultValues then
		for k,v in pairs(defaultValues) do
			values[k] = __CLASS__D(v, environmentClass)
		end
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

	if supers_names then
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
	end

	if instanceFunctions then
		for k, funcs in pairs(instanceFunctions) do
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
			values[k] = setfenv(funcs[1](instance, superFuncs[1]), instanceEnvironment)
		end
	end

	values.typeOf = function(_,other)
		return typeOfTree[other] == 1
	end

	print("shoudl init here?")
	print(initialiseFunction)
	local initialiseFunction = values.initialise
	if initialiseFunction then
		print("yeah man")
		initialiseFunction(instance, ...)
		-- __CLASS__D(initialiseFunction, instanceEnvironment, instance, ...)
	end
	return instance
end

local __CLASS__G=setmetatable({},{__index=_G})local __CLASS__H=setmetatable({},{__index=_G})AlertWindow={}local __CLASS__I="class 'AlertWindow': "..tostring(AlertWindow):sub(8)local __CLASS__J={}View={}local __CLASS__K="class 'View': "..tostring(View):sub(8)local __CLASS__L={}Cat={}local __CLASS__M="class 'Cat': "..tostring(Cat):sub(8)local __CLASS__N={}Window={}local __CLASS__O="class 'Window': "..tostring(Window):sub(8)local __CLASS__P={}local function __CLASS__Q(_,k,v)return v[k] end local function __CLASS__R(_,k,n,v)v[k]=n end local __CLASS__S={__index=__CLASS__1,__newindex=__CLASS__2}local __CLASS__T={__index=__CLASS__3,__newindex=__CLASS__4}local __CLASS__U=setmetatable({static=__CLASS__L},__CLASS__S)local __CLASS__V={}local __CLASS__W={[View]=1,[__CLASS__L]=1}local __CLASS__X={["aBoolean"]=loadstring("return true\9"),}local function __CLASS__Y(self,super)return function(self)
		print("window shit")
	end end local function __CLASS__Z(self,super)return function(self)
		print("view shit")
	end end local __CLASS__a={["initialise"]={__CLASS__Y},["capitaliseAndLocation"]={__CLASS__Z}}local function __CLASS__b(self,super)return function(self,aBoolean)
		self.aBoolean = true
	end end local __CLASS__c=setmetatable({["aBoolean"]=__CLASS__Q,["initialise"]=__CLASS__Q,["capitaliseAndLocation"]=__CLASS__Q},__CLASS__T)local __CLASS__d=setmetatable({["aBoolean"]=function(_,k,n,v,e,l)if l[k]then v[k]=n else l[k]=true __CLASS__E(__CLASS__b,e,_,n)l[k]=nil end end,["initialise"]=__CLASS__5,["capitaliseAndLocation"]=__CLASS__5},__CLASS__T)local __CLASS__e={[View]=1}setmetatable(View,{__index=__CLASS__U,__newindex=__CLASS__2,__call=function(_,...)return __CLASS__instance_create({},"instance",nil,__CLASS__a,nil,__CLASS__G,"View",__CLASS__c,__CLASS__d,nil,__CLASS__e,...)end,__tostring=function()return __CLASS__K end})__CLASS__instance_create(__CLASS__L,"static",nil,nil,nil,__CLASS__G,"View",__CLASS__T,__CLASS__T,nil,__CLASS__W,...)local __CLASS__f=setmetatable({static=__CLASS__P},__CLASS__S)local __CLASS__g={}local __CLASS__h={[Window]=1,[__CLASS__P]=1,[View]=1,[__CLASS__L]=1}local __CLASS__i={"View"}local __CLASS__j={["aString"]=loadstring("return \"wow\"\9"),["aBoolean"]=loadstring("return false\9"),}local function __CLASS__k(self,super)return function(self)
		print("window shit")
	end end local __CLASS__l={["capitaliseAndLocation"]={__CLASS__k,__CLASS__Z}}local __CLASS__m=setmetatable({["aString"]=__CLASS__Q,["aNumber"]=__CLASS__Q,["aBoolean"]=__CLASS__Q,["animal"]=__CLASS__Q,["capitaliseAndLocation"]=__CLASS__Q},__CLASS__T)local __CLASS__n=setmetatable({["aString"]=__CLASS__R,["aNumber"]=__CLASS__R,["aBoolean"]=function(_,k,n,v,e,l)if l[k]then v[k]=n else l[k]=true __CLASS__E(__CLASS__b,e,_,n)l[k]=nil end end,["animal"]=__CLASS__R,["capitaliseAndLocation"]=__CLASS__5},__CLASS__T)local __CLASS__o={[Window]=1,[View]=1}local __CLASS__p={"View"}setmetatable(Window,{__index=__CLASS__f,__newindex=__CLASS__2,__call=function(_,...)return __CLASS__instance_create({},"instance",nil,__CLASS__l,nil,__CLASS__G,"Window",__CLASS__m,__CLASS__n,__CLASS__p,__CLASS__o,...)end,__tostring=function()return __CLASS__O end})__CLASS__instance_create(__CLASS__P,"static",nil,nil,nil,__CLASS__G,"Window",__CLASS__T,__CLASS__T,__CLASS__i,__CLASS__h,...)local __CLASS__q={		LIST = 1;		THUMBNAIL = 2;	}	local __CLASS__r="enum 'AlertWindow.styles': " .. tostring(__CLASS__q):sub(8)local __CLASS__s=setmetatable({static=__CLASS__J,styles=setmetatable(__CLASS__q,{__index=__CLASS__6,__newindex=__CLASS__7,__tostring=function()return __CLASS__r end})},__CLASS__S)local __CLASS__t={}local function __CLASS__u(self,super)return function(self,message )

	end end local __CLASS__v={["display"]={__CLASS__u}}local function __CLASS__w(self,super)return function(self,thingy)
		-- a setter. here you must manually set the value yourself (i.e. if you don't change it it will stay as-is)
		thingy = string.upper( thingy )
		self.thingy = thingy
	end end local __CLASS__x=setmetatable({["thingy"]=__CLASS__Q,["display"]=__CLASS__Q},__CLASS__T)local __CLASS__y=setmetatable({["thingy"]=function(_,k,n,v,e,l)if l[k]then v[k]=n else l[k]=true __CLASS__E(__CLASS__w,e,_,n)l[k]=nil end end,["display"]=__CLASS__5},__CLASS__T)local __CLASS__z={["aStaticInstanceVariable"]=loadstring([[return "starting value"	]])}local __CLASS__00={[AlertWindow]=1,[__CLASS__J]=1,[Window]=1,[__CLASS__P]=1,[View]=1,[__CLASS__L]=1}local __CLASS__01={"Window","View"}local __CLASS__02={["aString"]=loadstring("return \"hello there\" .. \" concated!\" \9.. \"oh but there's more!\"\9\9"),["thing"]=loadstring("return \"this is a default value\"\9\9"),["another"]=loadstring("return {\9\9one = 1;\9\9two = 2;\9\9three = 3;\9\9four = 4;\9}\9"),["aBoolean"]=loadstring("return true \9"),["animal"]=loadstring("return Cat( \"Fluffles\" ) \9"),}local function __CLASS__03(self,super)return function(self,arg1,arg2)
		print("ALIVE")
		print(self)
		-- print(super)
	end end local function __CLASS__04(self,super)return function(self,message,title,callback,buttons,defaultButton)
		local location = name:find( "o" )
		return name:upper(), location
	end  end local __CLASS__05={["initialise"]={__CLASS__03,[3]=__CLASS__Y},["capitaliseAndLocation"]={__CLASS__04,__CLASS__k,__CLASS__Z}}local function __CLASS__06(self,super)return function(self)
		-- a getter. here you must manually set the value yourself (i.e. if you don't change it it will stay as-is)
		return self.thing
	end end local function __CLASS__07(self,super)return function(self,thing)
		-- the 'name' value has just been changed
		log( "Name set to " .. name )
	end end local function __CLASS__08(self,super)return function(self,aBoolean)
		self.aBoolean = not aBoolean
	end end local function __CLASS__09(self,super)return function(self,thing)
		-- a setter. here you must manually set the value yourself (i.e. if you don't change it it will stay as-is)
		thing = string.upper( thing )
		self.thing = thing
	end end local __CLASS__0A=setmetatable({["stringTable"]=__CLASS__Q,["aNumber"]=__CLASS__Q,["aString"]=__CLASS__Q,["okayButton"]=__CLASS__Q,["thing"]=function(_,k,v,e,l)if l[k]then return v[k]else l[k]=true local v=__CLASS__E(__CLASS__06,e,_)l[k]=nil return v end end,["aBoolean"]=__CLASS__Q,["animal"]=__CLASS__Q,["initialise"]=__CLASS__Q,["capitaliseAndLocation"]=__CLASS__Q},__CLASS__T)local __CLASS__0B=setmetatable({["stringTable"]=__CLASS__A,["aNumber"]=__CLASS__R,["aString"]=__CLASS__R,["okayButton"]=__CLASS__R,["thing"]=function(_,k,n,v,e,l)if l[k]then v[k]=n else l[k]=true __CLASS__E(__CLASS__09,e,_,n)__CLASS__E(__CLASS__07,e,_,n)l[k]=nil end end,["aBoolean"]=function(_,k,n,v,e,l)if l[k]then v[k]=n else l[k]=true __CLASS__E(__CLASS__08,e,_,n)l[k]=nil end end,["animal"]=__CLASS__R,["initialise"]=__CLASS__5,["capitaliseAndLocation"]=__CLASS__5},__CLASS__T)local __CLASS__0C={["anInstanceVariable"]=loadstring([[return A_CONSTANT	]])}local __CLASS__0D={[AlertWindow]=1,[Window]=1,[View]=1}local __CLASS__0E={"Window","View"}setmetatable(AlertWindow,{__index=__CLASS__s,__newindex=__CLASS__2,__call=function(_,...)return __CLASS__instance_create({},"instance",__CLASS__0C,__CLASS__05,nil,__CLASS__G,"AlertWindow",__CLASS__0A,__CLASS__0B,__CLASS__0E,__CLASS__0D,...)end,__tostring=function()return __CLASS__I end})__CLASS__instance_create(__CLASS__J,"static",__CLASS__z,__CLASS__v,nil,__CLASS__G,"AlertWindow",__CLASS__x,__CLASS__y,__CLASS__01,__CLASS__00,...)local __CLASS__0F=setmetatable({static=__CLASS__N},__CLASS__S)local __CLASS__0G={}local __CLASS__0H={[Cat]=1,[__CLASS__N]=1}local __CLASS__0I={}local function __CLASS__0J(self,super)return function(self,colour)
		print(CONST_VARIABLE)
		self.colour = colour
	end end local __CLASS__0K={["initialise"]={__CLASS__0J}}local __CLASS__0L={[Cat]=1}setmetatable(Cat,{__index=__CLASS__0F,__newindex=__CLASS__2,__call=function(_,...)return __CLASS__instance_create({},"instance",nil,__CLASS__0K,nil,__CLASS__H,"Cat",__CLASS__T,__CLASS__T,nil,__CLASS__0L,...)end,__tostring=function()return __CLASS__M end})__CLASS__instance_create(__CLASS__N,"static",nil,nil,nil,__CLASS__H,"Cat",__CLASS__T,__CLASS__T,nil,__CLASS__0H,...)__CLASS__F("AlertWindow.luo",1,setfenv(loadstring([[local A_CONSTANT = "hello"


]]), __CLASS__G))__CLASS__F("AlertWindow.luo",82,setfenv(loadstring([[

local otherStuff = 5


]]), __CLASS__G))__CLASS__F("Cat.luo",1,setfenv(loadstring([[local CONST_VARIABLE = "THING"



]]), __CLASS__H))