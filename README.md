# rl
The primary frontend compiler for Royal.

---

Royal is a statically typed programming language created as a simple learning project using a recursive descent parser (along with other algorithms for parsing such as shunting yard for expressions.)

The goal is to create a C-like programming language inspired by D, C#, Rust, Go, C and C++.

Eventually the goal is to write the compiler in itself.

It will intiailly use a C compiler as the backend but will be abstract enough to have that changed in the future.

The language should be as safe as possible, not just memory-wise.

---

### Hello World!


#### Raw

```d
module main;

fn main()
{
  import std.stdio : writeln;
  
  writeln("Hello World!");
}
```

#### Preferred

```d
fn main()
{
    writeln("Hello World!");
}
```

### Main Function Examples

```d
fn int main()
{
    ...

    return 0;
}
```

```d
fn main(string[]:const args)
{
    ...
}
```

---

### Current Status

**Tokenization**: Done

**Tokenized Grouping (Parse Tree Construction)**: Done

**Parser**: In Progress

**-- Module Statement**: Done
  
**-- Import Statement**: Done

**-- Attributes**: Done

**-- Variable Declaration**: Done

**-- Type Information**: Done
  
**-- Functions**: Done

**-- Function Body**: Done

**---- Return Expressions**: Done

**-- Expressions**: Done

**-- Arrays**: Done

**-- Associative Arrays**: Done

**-- Function Calls**: Done

**---- Chained Function Calls**: Done

**-- If/Else/Else If Statements**: Done

**-- Switch Statements**: Done

**-- For Statements**: In Progress

**-- Foreach Statements**: Not Started

**-- While Statements**: Not Started

**-- Enums**: Not Started

**-- Alias**: Not Started

**---- Properties**: Not Started

**-- Structs**: Not Started

**---- Constructors**: Not Started
  
**---- Ref Structs**: Not Started

**------ Virtual Functions**: Not Started

**---- Interfaces**: Not Started

**---- Traits**: Not Started

**-- Synchronization**: Not Started

**-- Static Constructors / Module Constructors**: Not Started

**-- Unsafe Scopes**: Not Started

**-- Exceptions**: Not Started

**-- Delegates / Function Pointers**: Not Started

**-- Lambdas**: Not Started

**-- Templates**: Not Started

**-- Mixins**: Not Started

**-- Compile-time Conditionals**: Not Started

**-- Compile-time Loops**: Not Started

**-- Contracts**: Not Started
  
**CTFE**: Not Started

**Semantic Analysis**: In Progress

**Parse Code To C**: Not Started

**Compile Parsed C Code**: Not Started

### What problems are Royal trying to solve?

#### Memory-safety

Royal aims to provide memory-safety without complexity that creates a barrier for learning and using the language, and also without using GC for all memory management. This will be done using different kind of techniques such as RAII, ownership, ARC (Automatic Reference Counting.)

Depending on the data, scenario etc. different techniques will be applied automatically.

Of course entirely manual memory management is possible too but only usable in **unsafe** scopes and functions, which can only be called from **unsafe** code itself unless the **unsafe** code is marked trusted.

This allows for some memory safety guarantees but also with the ability to completely manage it yourself. (Which of course removes the safety.)

#### Readability

The syntax of Royal aims to be kept as clean as possible, while still being expressive. It should be easy for anyone to view at code written in the language and determine what the code does. A clean syntax assures that code looks less complex and makes it easier to understand.

#### Simplicity

There has to be simplicity but also without removing modern paradigms and concepts, and also while still being an expressive language.

The simplicity is a mixture of implementing language features in user-friendly, innovative ways with a combination of Royal's syntax and keywords.

#### Strictness

Strictness is a necessity for safety in a language. These restrictions will make sure that users don't just blindly do certain things, forcing them to put thought into what they're doing. An example would be this:

Not allowed:

```d
var fooResult = foo(bar(), baz(), boo());
```

Allowed:

```d
var barResult = bar();
var bazResult = baz();
var booResult = boo();
var fooResult = foo(barResult, bazResult, booResult);
```

Not only does it look cleaner, it's also easier to maintain, debug and creates some sensibility to the code.

#### Compile-time Code Generation / Compile-time Function Execution

Code should be able to be generated at compile-time but also executed as well.

This is solved in some languages but often comes with limitations. Royal aims to have no restrictions on IO etc. allowing reading/writing files at compile-time etc.

Being able to perform IO at compile-time is useful for ex. webservers to implement compile-time view generations etc.

The below code is okay in Royal but most languages with CTFE would rejected it because it performs IO.

```d
var directory = openDir("views", DirectoryMode.deep);

foreach (file, directory.files)
{
    var name = "output/" ~ file.name ~ ".html";
    var html = parseHtmlFromTemplate(file.content);
    
    write(name, html);
}
```

This might indicate some security issues for some but there are some restrictions to it.

You can only write/read relative to the project path, this means you can't just do:

```d
var directory = openDir("C:\\windows"); // Error: Can only perform IO relative to the project path.
```

Another restriction to IO at CTFE is that it can only be performed by modules within the project path, which means dependencies cannot perform IO. This makes sure malicious dependencies will not be able to do anything malicious.

```d
// Ex. if this was in a dependency of the project:

var directory = openDir("C:\\windows"); // Error: Dependency 'DEPENDENCY NAME' attempted to perform IO.
```

The compiler will also tell the user which dependency attempted to perform IO which can help users know which dependencies are possibly malicious.

You cannot call external code or internally marked functions (C functions) which means the CTFE subset is limited to Royal modules only that are available at compile-time ex. not already generated object code etc.

#### Easy Learning Curve

The language shouldn't have a steap learning curve and should be easy to adapt when coming from other languages such as C#, Java, C, C++, D etc.

#### Portability / Cross-platform

Code written in Royal should be easily portable and maintainable even when having to compile to different platforms.

Compile-time features such as the **version** keyword, static conditionals **static if**, **static switch** etc. will help  creating cross-platform code.

The standard library should utilize this and build **standard** code around each platform's functionality to avoid users having to implement platform-dependent code.

The compiler itself should also be able to be shipped to multiple platforms. Although initially written on Windows and shipped for that. This will change in the future when it becomes more stable and actually **works**.

#### Async / Concurrent / Networking / Web-based Programming

Royal should focus a lot on its networking domain and have networking concepts and web concepts built-in to its standard library. This includes but not limited to threading, concurrency, sockets, webclients, webservers, dom/xml/html manipulation, json etc.

#### Minimal Compilation

Compiled executables etc. should be as minimal as possible to not waste space both in terms of physical memory but also virtual memory allocated by the compiled program.
