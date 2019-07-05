/**
* Module for parsing foreach loops.
*
* License: MIT (https://github.com/Royal Programming Language/bl/blob/master/LICENSE)
*
* Copyright 2019 © Royal Programming Language - All Rights Reserved.
*/
module parser.foreachparser;

import core.tokenizer;
import core.errors;
import core.debugging;

import parser.meta;
import parser.tools;

import parser.variableparser;
import parser.expressionparser;
import parser.assignmentparser;
import parser.scopeparser;

/// A foreach loop.
class ForeachLoop
{
  /// The first index object.
  string index1;
  /// The second index object.
  string index2;
  /// The first range object.
  string range1;
  /// The second range object.
  string range2;
  /// The scopes of the foreach loop statement.
  ScopeObject[] scopes;
}

/**
* Parses a foreach loop.
* Params:
*   token = The token of the foreach loop.
*   source = The source of the foreach loop.
*/
ForeachLoop parseForeachLoop(Token token, string source)
{
  size_t line = token.retrieveLine;

  if (!token.statement || !token.statement.length)
  {
    line.printError(source, "Missing foreach loop declaration.");
    return null;
  }

  auto statement = token.statement[1 .. $];

  if (statement[0] == "(" && statement[$-1] == ")")
  {
    statement = statement[1 .. $-1];
  }

  import std.algorithm : map;
  import std.array : array,join,split;

  auto loop = new ForeachLoop;

  auto data = statement.map!(s => s.s).array.join("").split(",");

  if (data.length != 2 && data.length != 3)
  {
    line.printError(source, "Missing foreach loop entry.");
    return null;
  }

  if (data.length == 2)
  {
    loop.index1 = data[0];

    auto rangeData = data[1].split("..");

    if (rangeData.length > 2)
    {
      line.printError(source, "Invalid range statement.");
      return null;
    }

    loop.range1 = rangeData[0];

    if (rangeData.length == 2)
    {
      loop.range2 = rangeData[1];
    }
  }
  else if (data.length == 3)
  {
    loop.index1 = data[0];
    loop.index2 = data[1];

    auto rangeData = data[2].split("..");

    if (rangeData.length > 2)
    {
      line.printError(source, "Invalid range statement.");
      return null;
    }

    loop.range1 = rangeData[0];

    if (rangeData.length == 2)
    {
      loop.range2 = rangeData[1];
    }
  }
  else
  {
    line.printError(source, "Invalid foreach loop.");
    return null;
  }

  setGlobalScopeHandler("foreach_loop", &handleForeachScope);

  auto scopeObjects = parseScopes(token, source, line, "foreach", "foreach");

  removeGlobalScopeHandler("foreach_loop");

  if (scopeObjects && scopeObjects.length)
  {
    loop.scopes = scopeObjects.dup;
  }

  return loop;
}

private:
/**
* Handles custom scope elements for a foreach loop statement such as "break".
* Params:
*   token = The token to handle.
*   line = The line of the token.
*   scopeObject = (ref) The current scope object.
* Returns:
*   Returns true if the scope element was handled and parsed correctly. False otherwise, which will trigger a compiler error.
*/
bool handleForeachScope(Token token, size_t line, ref ScopeObject scopeObject)
{
  if (!token.statement || token.statement.length < 2)
  {
    return false;
  }

  switch (token.statement[0].s)
  {
    case Keyword.BREAK:
      if (token.statement.length != 2)
      {
        return false;
      }

      scopeObject.scopeState = ScopeState.scopeBreak;
      return true;

    default:
      return false;
  }
}
