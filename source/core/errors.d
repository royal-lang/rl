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
* Prints a compilation error. Compilation will halt after the current step.
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
* Prints a compilation error. Compilation will halt after the current step.
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

/// Queued compiler error messages.
private string[] queuedMessages = [];

/**
* Queues a compilation error. Compilation will not halt after the current step unless printQueuedErrors() is called.
* Params:
*   line = The line where the compilation error happened.
*   source = The source of the compilation error (ex. the file)
*   fmt = A formatted string to use for the error message.
*   args = The arguments to format with.
*/
void queueError(T...)(size_t line, string source, string fmt, T args)
{
  import std.string : format;

  queueError(line, source, format(fmt, args));
}

/**
* Queues a compilation error. Compilation will not halt after the current step unless printQueuedErrors() is called.
* Params:
*   line = The line where the compilation error happened.
*   source = The source of the compilation error (ex. the file)
*   message = The error message of the compilation error.
*/
void queueError(size_t line, string source, string message)
{
  import std.string : format;
  import std.array : replace;

  version (Windows)
  {
    queuedMessages ~= format("%s(%s) Error: %s", source.replace("/", "\\"), line, message);
  }
  else
  {
    queuedMessages ~= format("%s(%s) Error: %s", source, line, message);
  }
}

/**
* Prints all queued errors. If there are any queued errors then compilation will stop after the current step.
* Returns:
*   True if there were any queued errors, false otherwise.
*/
bool printQueuedErrors()
{
  if (queuedMessages && queuedMessages.length)
  {
    _hasErrors = true;

    foreach (msg; queuedMessages)
    {
      import std.stdio : stderr;

      stderr.writeln(msg);
    }

    queuedMessages = [];

    return true;
  }
  else
  {
    return false;
  }
}

/// Clears all queued errors. This means printQueuedErrors() will no longer halt the compilation either.
void clearQueuedErrors()
{
  queuedMessages = [];
}
