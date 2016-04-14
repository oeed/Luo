{
	className = "AlertWindow",
	extends = "Window",
	instance = {
		properties = {
			name = {
				type = "String",
				allowsNil = true,
				readOnly = true,
				default = { "string", "default value" },
				set = function( self, name )
					name = string.upper( name )
					__CLASS__SET_INSTANCE_VALUE( self, "name", name ) -- rather than using metatables use functions to do the setting and getting
				end,
				didSet = function( self, name )
					log( "Name set to " .. name )
				end
			},
		},
		defaultValues = {
			subtitle = { "string", "overriding default value" },
			animal = { "instance", "Cat", "Fluffles" }
		},
		eventHandles = {
												 --   phase
			clearApperance = { "ReadyInterfaceEvent", false, function( self, event ) end },
			explode = { "ReadyInterfaceEvent", true, function( self, event ) end },
		},
		functions = {
			welcome = {
				function( self, name )
					log( "Welcome " .. name )
				end,
				31, -- for making error numbers link to the source
				{
					type = "string",
					default = { "string", "oeed" }
				}
			}
		}
	},
	static = {
		properties = {
			thingy = {
				type = "string",
				allowsNil = false,
				readOnly = false,
			},
		},
		functions = {
			display = {
				function( self, name, title, callback, buttons, defaultButton )
					-- this will require knowing what the properties are and determining 
					__CLASS__CALL_INSTANCE_FUNCTION( __CLASS__GET_INSTANCE_VALUE( __CLASS__GET_INSTANCE_VALUE( self, "application" ), "container" ), "insert", AlertWindow() )
				end,
				{
					type = "string",
				}
			}
		}
	}
}