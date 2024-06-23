# EvalInModuleREPLMode.jl

Adds an additional mode to the julia REPL accessable by pressing `:` that allows easy
evalution of code inside a given module.

## Installation

```
Pkg.add(url="https://github.com/tehrengruber/EvalInModuleREPLMode.git")
```

## Example

Consider that you have defined a module like this:

```
module Foo end
```

Press `:` inside the REPL to switch the mode. Afterwards enter the module
you want to evaluate your code in, which is in this case `Foo`. Confirm
by pressing enter again and proceed with pasting your code.

```
julia> module Foo end
eval in module: Foo
Foo> a=1
println(Foo.a)
```

Note that in case you press `:` and confirm with enter without actually typing
a module the module used in the previous execution will be used.
