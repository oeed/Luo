#Luo
***TL;DR:*** This is _Luo_, a fully featured object oriented class system Lua based ’language’ that compiles to pure Lua. It's somewhat inspired by Swift. It’s awesome.

##Features

###Awesome Syntax

I designed Luo based around the syntax I wanted. Sure, there are tons of existing class systems and languages that have OOP, even almost identical functionality (such as Swift, which this was heavily inspired by). However, they’re often a bit ugly or painful to use.

I love Lua's syntax and aimed to keep this as "Lua like" as possible. Here's an example snippet. Notice that it's all keyword based, yet it still strongly resembles traditional class declarations.

```lua
class Person

	property Boolean isMale
	property Number age = 0
	property String firstName = "John"
	property String lastName = "Smith"
	property Language language = EnglishLanguage.static

	function initialise(firstName, lastName, isMale)
		self.firstName = firstName
		self.lastName = lastName
		self.isMale = isMale
	end

end
```

###Fast, _Really Fast_

One of my core goals when creating Luo was to make it run as fast as conceivably possible with Lua. My previous class system have often be about 50+ times slower than regular tables and have had multiple second long startup times. This, however, is not the case in Luo. As everything is compiled _once_ and is compiled statically there are no unnecessary calculations or calls.

In fact, Luo classes are so fast that they often **perform at the same speed as standard tables**.

###Type Checking

I've found that type errors can become increasingly common as your project size increases. They can sometimes also be hard to track down, especially with `nil`. There are ways around this in plain Lua, by adding type checking calls manually, but that is _super_ tedious.

Luo type checks all inputs and outputs of functions, as well as properties. For speed, it does not do any checking on code within functions, however. For example, this function checks that the first argument is a string and the second is a number. It also checks that it returns a number.

```lua
function Number combine(String name, Number score)
	return #name + score
end
```

####Allowing Nil Values

As previously mentioned, `nil` values can often cause issues. By default, types do _not_ allow nil values. To solve this issue Luo uses an `allowsNil` modifier. For example, this function would check that the first argument is a string and that the second is either a number or `nil`.

```lua
function Number combine(String name, Number allowsNil score)
	return #name + (score and score or 0)
end
```

###Getters and Setters

Getters and setters make your code much, much tidier. Rather than having methods like `os.getComputerLabel` you simply have a property. For example, to set the computer label you'd do `os.computerLabel = "my label"`.

Luo also adopts Swift's `didSet` and `willSet` methods, to further extend functionality.

The syntax for a setter is the following:
```lua
set firstName(firstName)
	firstName = firstName:upper()
end
```