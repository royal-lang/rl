# bl
The primary frontend compiler for bausslang.

---

Bausslang is a static typed programming language created as a simple learning project. The goal is to create a C-like programming language inspired by D, C#, Rust, Go, C and C++.

Eventually the goal is to write the compiler in itself.

It will intiailly use a C compiler as the backend but will be abstract enough to have that changed in the future.

---

### Hello World!

```
fn main()
{
  import std.stdio : writeln;
  
  writeln("Hello World!");
}
```

---

### Current Status

**Tokenization**: Done

**Tokenized Grouping**: Done

**Parser**: In Progress

**-- Module Statement**: Done
  
**-- Import Statement**: Done
  
**-- Functions**: In Progress
  
**CTFE**: Not Started

**Semantic Analysis**: Not Started

**Parse Code To C**: Not Started

**Compile Parsed C Code**: Not Started
