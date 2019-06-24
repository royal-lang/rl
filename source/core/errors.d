/**
* Module for error handling within the compiler.
*
* License: MIT (https://github.com/bausslang/bl/blob/master/LICENSE)
*
* Copyright 2019 © bausslang - All Rights Reserved.
*/
module core.errors;

/// Boolean determining whether the compiler has had errors or not.
private bool _hasErrors;

/// Gets a boolean determining whether the compiler has had errors or not.
@property bool hasErrors()
{
  return _hasErrors;
}

/**
* Prints a compilation error.
* Params:
*   line = The line where the compilation error happened.
*   source = The source of the compilation error (ex. the file)
*   fmt = A formatted string to use for the error message.
*   args = The arguments to format with.
*/
void printError(T...)(size_t line, string source, string fmt, T args)
{
  import std.string : format;

  printError(line, source, format(fmt, args));
}

/**
* Prints a compilation error.
* Params:
*   line = The line where the compilation error happened.
*   source = The source of the compilation error (ex. the file)
*   message = The error message of the compilation error.
*/
void printError(size_t line, string source, string message)
{
  _hasErrors = true;

  import std.stdio : stderr;
  import std.array : replace;

  version (Windows)
  {
    stderr.writefln("%s(%s) Error: %s", source.replace("/", "\\"), line, message);
  }
  else
  {
    stderr.writefln("%s(%s) Error: %s", source, line, message);
  }
}
