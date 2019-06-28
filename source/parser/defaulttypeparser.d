module parser.defaulttypeparser;

import core.tokenizer;
import core.errors;
import core.debugging;

import parser.meta;
import parser.tools;

import parser.expressionparser;

enum DefaultType
{
  // Type selection for integers mostly depends on the size of the value (Lowest is 32 bit). Ex. 500 will become int but 3000000000 will become uint
  int32Array,
  uint32Array,
  int64Array,
  uint64Array,
  doubleArray,
  stringArray,
  charArray,
  charType,
  stringType,
  structType, // Ex. var Foo a; (not-ref) (Equal to: Foo a;) | var a @= Foo; (ref) (Equal to: auto a = new Foo;)
  functionReturnType, // Ex. var a = foo(); // a will have the return type of foo();
  typeReference, // Ex. var a = b; // a will be a type reference to b's type. (Ex. we need to use b to retrieve the type.)
  int32Type,
  uint32Type,
  int64Type,
  uint64Type,
  doubleType,
  boolType,
  pointerReferenceType, // Ex. var a = b.ptr; // a will be set to the pointer type of b. (Same as ptr:T a = b.ptr; where T is the type of b)
}

// Also check if types are mismatching in array etc. (not allowed)
// Pointer ari:
// Get the address:
// var a = b.ptr;
// Get the value:
// var b = a.value;

DefaultType parseDefaultType(Expression expression)
{
  return DefaultType.int32Array;
}
