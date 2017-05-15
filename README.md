# Luo

Basically if Lua and Swift met each other at a club one night and Lua got pregnant.

## What is this? Why 'Luo'?

_Is there any reason you picked Luo as opposed to something that involves Swift. I guess the Lu comes from Lua and the o from object-oriented, but this isn't inherently obvious. It doesn't have to of course. Basically, what does the name stand for, and is the current name final?_ - @InDieTasten

> Originally this was going to be a complete subset of Lua, meaning that any vanilla Lua code would be valid Luo code. While Luo won't be an exact subset I am still sticking very closely to Lua, the syntax is more or less the same. It's basically statically typed Lua with classes.
> 
> The only main thing which might prevent some vanilla Lua from working in Luo is that types are inferred when not defined. This means that local animal = "Cat" will be inferred as a String type, and hence doing animal = 5 would cause a compile time error as you can't assign a Number to a String. There are ways to get around this though, such as doing local animal: Any? = "Cat".
> 
> This language is basically designed to be used for Silica, at least that was the original intention. As such it will, for the moment, only compile to Lua. Not machine code or anything like that. But as I'm designing it as the language I want I wouldn't be surprised if I end up compiling it to something a bit more low level in the future.
> 
> Where Swift comes in to this is in the class system and typing. I'm essentially copying Swift's classes, enums and types as close as reasonably possible. That's also the reason I'm writing the compiler in Swift, it makes converting it to Luo later on much quicker and easier. But other than that it doesn't have anything to do with Swift.
