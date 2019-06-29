# bl
The primary frontend compiler for bausslang.

---

Bausslang is a statically typed programming language created as a simple learning project using a recursive descent parser (along with other algorithms for parsing such as shunting yard for expressions.)

The goal is to create a C-like programming language inspired by D, C#, Rust, Go, C and C++.

Eventually the goal is to write the compiler in itself.

It will intiailly use a C compiler as the backend but will be abstract enough to have that changed in the future.

The language should be as safe as possible, not just memory-wise.

Memory safety will be attempted to be guaranteed with RAII, cleaning up when scopes end, ARC (Automatic Reference Counting) (Avoided whenever possible.), as well compile-time validation using ownership rules similar to Rust. --

Memory is partially manual (You don't need to use malloc() etc. as it's done under the hood.)

For memory critical sections manual memory management can be enabled but only in unsafe code which can only be called from unsafe scopes themselves, which limits unsafe functionality to a subset of the language.

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

#### Prefered

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

**-- Switch Statements**: In Progress

**-- For Statements**: Not Started

**-- Foreach Statements**: Not Started

**-- While Statements**: Not Started

**-- Structs**: Not Started

**-- Constructors**: Not Started
  
**-- Ref Structs**: Not Started

**-- Interfaces**: Not Started

**-- Traits**: Not Started

**-- Static Constructors / Module Constructors**: Not Started

**-- Unsafe Scopes**: Not Started

**-- Lambdas**: Not Started

**-- Templates**: Not Started

**-- Mixins**: Not Started

**-- Compile-time Conditionals**: Not Started

**-- Contracts**: Not Started
  
**CTFE**: Not Started

**Semantic Analysis**: In Progress

**Parse Code To C**: Not Started

**Compile Parsed C Code**: Not Started
