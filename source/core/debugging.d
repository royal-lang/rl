/**
* Module for ddebugging features.
*
* License: MIT (https://github.com/bausslang/bl/blob/master/LICENSE)
*
* Copyright 2019 © bausslang - All Rights Reserved.
*/
module core.debugging;

/// Boolean determining whether the compiler is verbose or not.
bool verboseCompile = false;

/**
* Prints a debug message.
* Params:
*   fmt = A formatted string to use for the debug message.
*   args = The arguments to format with.
*/
void printDebug(T...)(string fmt, T args)
{
  import std.string : format;

  printDebug(format(fmt, args));
}

/**
* Prints a debug message.
* Params:
*   message = The debug message.
*/
void printDebug(string message)
{
  if (!verboseCompile)
  {
    return;
  }

  import std.stdio : writefln;

  writefln("DEBUG: %s", message);
}
