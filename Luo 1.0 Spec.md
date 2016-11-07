#Luo Spec

Luo is derived directly from Lua and all syntax should be aligned as close to vanilla Lua as possible.

Functionally, Luo is heavily based upon Swift. In most instances functionality should be identical or a simplified version of Swift.

##Luo Design Principles

- any Lua code should be valid Luo code
- Luo syntax should be 'Lua-like' in appearance
- standard Lua code (i.e. not Luo code) should be able to interact fully with any compiled Luo classes
- should support Lua 5.1, 5.2 and 5.3 (i.e. LuaJIT, recent CC [through 5.2 compatibility changes] and CraftOS 2) - different compilations may be needed for this though

#Semantics

##Definitions

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in RFC 2119.

**vanilla Lua** - Lua which is executable by the standard Lua interpreter (not Luo)

**ANY NUMBER** - any amount from zero to infinity

**ANY** - any possible valid value, including nil or 'nothing' values

**VALID NAME** - any valid Lua variable name (excluding those only accessible by table lookup)

##Language Summary

Luo is designed to add native support for object oriented programming in to Lua, without having to use messy/hacky approaches like tables. Additionally, it adds support for both static typing within classes and dynamic typing when calling code outside of classes.

Luo aims to retain syntax that feels like Lua, while still using familiar structures found in other object oriented languages. Most functionality is derived or inspired by Swift.

##Luo Files

- Each `.luo` file contains only Luo code and should not be treated as vanilla Lua, however, any Lua code is also valid Luo code.
- A Luo file can contain ANY NUMBER of classes.

##Classes

###Declaration

- MAY extend at most one other class (excluding itself or a subclass).
- MAY have ANY NUMBER of protocols.
- MUST have a unique, valid name. MUST not have the same name as ANY [[Standard Type]]. Any invalid names MUST error at compile time.
- MUST NOT contain any classes within itself, even within code blocks.
- MAY have ANY NUMBER of properties.

##Properties

###Declaration

- MUST have a unique, valid name.
- MUST be either a static or instance member
- MAY have a single [[Property Type]].
- MAY have a valid Default Value which SHOULD be checked for validity at compile time when possible.
- MAY have one each of `get`, `set`, `willSet`, `didSet` Property Methods.

##Functions

###Declaration

- MUST have a unique, valid name.
- MUST be either a static or instance member
- MAY specify ANY NUMBER of [[Return Type]]s, all of which which MUST be returned.
- If zero [[Return Type]]s are specified then the function MUST allow ANY NUMBER of values to be returned of ANY [[Return Type]].
- MAY specify ANY NUMBER of [[Parameter Type]]s.
- All parameter values MUST be supplied, unless the [[Parameter Type]] allows nil.
- All supplied parameter values MUST be Type Checked and valid.
- MUST have one code block which MUST contain valid Luo code. ANY non-runtime errors such as type and syntax MUST error at compile time.

##Types

###[[Type Structures]]

####[[Basic Type]]

The basic building block of Types. For example, a String, Table (with any contents), Instance of a Class, etc.

- MUST only check the value of the property itself and not anything within the value (such as properties, keys, etc).
- MUST NOT be `nil` (see [[Nillable Types]])
- MUST be a VALID NAME.
- MUST be one of the following.
	- A [[Standard Type]].
	- A [[Instance Type]].
	- A Static Type.
	- The Class Type.
	- The [[Any Type]].

####Array Type

- MUST have one specified [[Basic Type]]
- MUST be a table
- MAY be empty
- MUST NOT be `nil` (see [[Nillable Types]])
- MUST only contain values that are of the specified [[Basic Type]]
- MUST error when inserting an invalid values at compile time if within Luo code or at runtime within Lua code

> It might be necessary to type check these when passed as parameters (if someone modifies the metatable), but it is obviously advantageous not to for performance reasons

####Dictionary Type

- MUST have two specified [[Basic Type]] (one for the key, one for the value)
- MUST be a table
- MAY be empty
- MUST NOT be `nil` (see [[Nillable Types]])
- MUST only contain keys and values that are of the respective specified key and value [[Basic Type]]s

> It might be necessary to type check these when passed as parameters (if someone modifies the metatable), but it is obviously advantageous not to for performance reasons

###Standard Types

These are the standard types from Lua. Their names are simply the built-in type names with the first letter capitalised.

- MUST be a [[Basic Type]]
- the return value of `type()` MUST equal the corresponding Type String below when given the value

| Name | Type String |
| :--: | :---------: |
| String   | string   |
| Number   | number   |
| Boolean  | boolean  |
| Table    | table    |
| Function | function |
| Thread   | thread   |
| Userdata | userdata |

###[[Instance Type]]

This Type represents an Instance of a Class.

###[[Any Type]]

The [[Any Type]] allows any value, other than `nil`.

- MUST NOT have the value `nil`

####[[Nillable Any Type]]

This allows absolutely ANY value and hence does not need to be Type Checked at all.

- MUST accept any value, including `nil`

###[[Nillable Types]]

- MAY be of any [[Type Structure]]
- MAY have the value `nil`

###[[Linked Type]]

This is mainly for linking things like buttons

- MUST only be a [[Basic Type]]
- If a [[Nillable Type]]: MUST link to desired value, if it exists
- If not a [[Nillable Type]]: MUST link to desired value, error if it doesn't exist
- linked value MUST be of the

###[[Property Type]]

- MUST be ANY one of the [[Type Structures]].
- MAY be a [[Nillable Type]]
- MAY be a [[Linked Type]]

###[[Parameter Type]]

- MUST be ANY one of the [[Type Structures]]
- MAY be a [[Nillable Type]]
- MAY NOT be a [[Linked Type]]
- MUST error at compile time and run time if invalid

###[[Return Type]]

- MUST be ANY one of the [[Type Structures]]
- MAY be a [[Nillable Type]]
- MAY NOT be a [[Linked Type]]
- MUST error at compile time and run time if invalid

###Unspecified Type

This Type is only used if a [[Type Structure]] is not provided.

*This is identical to [[Nillable Any Type]].*

###VarArg Type

This Type is only used for each of a function's vararg (`...`) argument values.

*This is identical to [[Nillable Any Type]].*
