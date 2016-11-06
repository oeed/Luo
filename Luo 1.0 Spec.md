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

**valid name** - any valid Lua variable name (excluding those only accessible by table lookup)

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
- MUST have a unique, valid name. Any invalid names MUST error at compile time.
- MUST NOT contain any classes within itself, even within code blocks.
- MAY have ANY NUMBER of properties.

##Properties

###Declaration

- MUST have a unique, valid name.
- MUST be either a static or instance member
- MAY have a single Type.
- MAY have a single Interface Link.
- MAY have a valid Default Value which SHOULD be checked for validity at compile time when possible.
- MAY have one each of `get`, `set`, `willSet` `didSet` Property Methods.

##Functions

###Declaration

- MUST have a unique, valid name.
- MUST be either a static or instance member
- MAY specify ANY NUMBER of Return Types, all of which which MUST be returned.
- If zero Return Types are specified then the function MUST allow ANY NUMBER of values to be returned of ANY Return Type.
- MAY specify ANY NUMBER of Parameter Types.
- All parameter values MUST be supplied, unless the Parameter Type allows nil.
- All supplied parameter values MUST be Type Checked and valid.
- MUST have one code block which MUST contain valid Luo code. ANY non-runtime errors such as type and syntax MUST error at compile time.