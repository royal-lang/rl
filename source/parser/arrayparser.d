/**
* Module for parsing arrays.
*
* License: MIT (https://github.com/Royal Programming Language/bl/blob/master/LICENSE)
*
* Copyright 2019 © Royal Programming Language - All Rights Reserved.
*/
module parser.arrayparser;

import core.tokenizer;
import core.errors;
import core.debugging;

import parser.meta;
import parser.tools;

/// An array expression.
class ArrayExpression
{
  /// The values of the array expression.
  ArrayValue[] values;
  /// The line of the array expression.
  size_t line;
  /// Boolean determining whether the expression is an associative array or not.
  bool isAssociativeArray;
}

/// An array value.
class ArrayValue
{
  /// The values of the array value.
  string[] values;
}

/**
* Parses an array expression.
* Params:
*   tokens = The tokens of the array expression.
*   source = The source of the array expression.
*   line = The line of the array expression.
*   queueErrors = Boolean determining whether errors should be printed directly or queued.
* Returns:
*   Returns an array expression if parsed correctly, null otherwise.
*/
ArrayExpression parseArrayExpression(STRING[] statement, string source, size_t line, bool queueErrors)
{
  import std.algorithm : map;
  import std.array : array;

  return parseArrayExpression(statement.map!(s => s.s).array, source, line, queueErrors);
}

/**
* Parses an array expression.
* Params:
*   tokens = The tokens of the array expression.
*   source = The source of the array expression.
*   line = The line of the array expression.
*   queueErrors = Boolean determining whether errors should be printed directly or queued.
* Returns:
*   Returns an array expression if parsed correctly, null otherwise.
*/
ArrayExpression parseArrayExpression(string[] tokens, string source, size_t line, bool queueErrors)
{
  clearQueuedErrors();

  if (!tokens || tokens.length < 3)
  {
    if (queueErrors) line.queueError(source, "Missing array expression.");
    else line.printError(source, "Missing array expression.");
    return null;
  }

  if (tokens[$-1] != ";")
  {
    if (queueErrors) line.queueError(source, "Expected '%s' but found '%s'", ";", tokens[$-1]);
    else line.printError(source, "Expected '%s' but found '%s'", ";", tokens[$-1]);
    return null;
  }

  if (tokens[0] != "[")
  {
    if (queueErrors) line.queueError(source, "Expected '%s' but found '%s'", "[", tokens[0]);
    else line.printError(source, "Expected '%s' but found '%s'", "]", tokens[0]);
    return null;
  }

  if (tokens[$-2] != "]")
  {
    if (queueErrors) line.queueError(source, "Expected '%s' but found '%s'", "]", tokens[$-2]);
    else line.printError(source, "Expected '%s' but found '%s'", "]", tokens[$-2]);
    return null;
  }

  auto array = new ArrayExpression;
  array.line = line;

  if (tokens.length == 3)
  {
    return array; // Empty array.
  }

  auto parseStatement = tokens[1 .. $-2];

  auto value = new ArrayValue;
  bool lookForAssociative = false;

  foreach (ref i; 0 .. parseStatement.length)
  {
    auto entry = parseStatement[i];
    auto lastEntry = i > 1 ? parseStatement[i - 1] : "";
    auto nextEntry = i < (parseStatement.length - 1) ? parseStatement[i + 1] : "";

    if (entry == ":")
    {
      array.isAssociativeArray = true;
      lookForAssociative = true;
    }
    else if (entry == ",")
    {
      if (!value.values || !value.values.length)
      {
        if (queueErrors) line.queueError(source, "Empty array value.");
        else line.printError(source, "Empty array value.");
        return null;
      }

      if (array.isAssociativeArray && value.values.length != 2)
      {
        if (queueErrors) line.queueError(source, "Missing associative array value.");
        else line.printError(source, "Missing associative array value.");
        return null;
      }

      lookForAssociative = false;

      array.values ~= value;

      value = new ArrayValue;
    }
    else if (value.values && value.values.length && !lookForAssociative)
    {
      if (array.isAssociativeArray)
      {
        if (queueErrors) line.queueError(source, "Missing associative array key.");
        else line.printError(source, "Missing associative array key.");
      }
      else
      {
        if (queueErrors) line.queueError(source, "Missing array value separator.");
        else line.printError(source, "Missing array value separator.");
      }
      return null;
    }
    else
    {
      if (value.values && value.values.length == 2)
      {
        if (queueErrors) line.queueError(source, "Too many values for array entry.");
        else line.printError(source, "Too many values for array entry.");
        return null;
      }

      value.values ~= entry;
    }
  }

  if (!value.values || !value.values.length)
  {
    if (queueErrors) line.queueError(source, "Empty array value.");
    else line.printError(source, "Empty array value.");
    return null;
  }

  if (array.isAssociativeArray && value.values.length != 2)
  {
    if (queueErrors) line.queueError(source, "Missing associative array value.");
    else line.printError(source, "Missing associative array value.");
    return null;
  }

  array.values ~= value;

  return array;
}
