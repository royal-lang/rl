/**
* Module for parsing while / do-while loops.
*
* License: MIT (https://github.com/Royal Programming Language/bl/blob/master/LICENSE)
*
* Copyright 2019 © Royal Programming Language - All Rights Reserved.
*/
module parser.whileparser;

import core.tokenizer;
import core.errors;
import core.debugging;

import parser.meta;
import parser.tools;

import parser.variableparser;
import parser.expressionparser;
import parser.assignmentparser;
import parser.scopeparser;

/// A while loop.
class WhileLoop
{
  /// Boolean detherming whether it's a do-while or not.
  bool isDo;
  /// The condition of the while loop.
  Expression condition;
  /// The scopes of the while loop statement.
  ScopeObject[] scopes;
}

/// Cached scope from a do-while.
private ScopeObject[] _cachedDoScopes;

/// Checks whether there is a do-while loop scope cached.
bool hasDoWhileLoop()
{
  return _cachedDoScopes !is null;
}

/**
* Parses a do statement for a do-while loop. Does not parse the while part.
* Params:
*   token = The token.
*   source = The source.
* Returns:
*   True if the do-while declaration was parsed correctly.
*/
bool parseDoStatement(Token token, string source)
{
  size_t line = token.retrieveLine;

  if (!token.statement || !token.statement.length)
  {
    line.printError(source, "Missing do-while loop declaration.");
    return false;
  }

  if (token.statement.length != 1)
  {
    line.printError(source, "Too many arguments for do-while declaration.");
    return false;
  }

  if (_cachedDoScopes !is null || _cachedDoScopes.length)
  {
    line.printError(source, "Multiple do-while loop declaration found.");
    return false;
  }

  setGlobalScopeHandler("do_while", &handleWhileScope);

  auto scopeObjects = parseScopes(token, source, line, "do-while", "do-while");

  removeGlobalScopeHandler("do_while");

  if (scopeObjects && scopeObjects.length)
  {
    _cachedDoScopes = scopeObjects.dup;
  }

  if (_cachedDoScopes is null)
  {
    _cachedDoScopes = [];
  }

  return true;
}

/**
* Parses a while loop.
* Params:
*   token = The token of the while loop.
*   source = The source of the while loop.
* Returns:
*   Returns ture while loop if parsed correctly, null otherwise.
*/
WhileLoop parseWhileLoop(Token token, string source)
{
  size_t line = token.retrieveLine;

  if (!token.statement || !token.statement.length)
  {
    line.printError(source, "Missing while loop declaration.");
    return null;
  }

  if (token.statement[$-1] != ";" && hasDoWhileLoop)
  {
    line.printError(source, "Expected '%s' but found '%s'", ";", token.statement[$-1]);
    return null;
  }

  if (hasDoWhileLoop && token.tokens && token.tokens.length)
  {
    line.printError(source, "Extra scope found for do-while loop.");
    return null;
  }

  import std.algorithm : map;
  import std.array : array;

  auto statement = token.statement.map!(s => s.s).array;

  if (hasDoWhileLoop)
  {
    statement = statement[0 .. $-1];
  }

  if (statement.length == 1)
  {
    statement ~= "1";
  }

  statement = statement[1 .. $];

  auto loop = new WhileLoop;

  auto conditionExpression = parseRightHandExpression(statement ~ ";", source, line, false, true);

  if (!conditionExpression || (!conditionExpression.tokens && !conditionExpression.arrayExpression))
  {
    if (!hasQueuedErrors)
    {
      line.queueError(source, "Failed to parse condition expression.");
    }
    return null;
  }

  loop.condition = conditionExpression;

  if (hasDoWhileLoop)
  {
    loop.isDo = true;
    loop.scopes = _cachedDoScopes.dup;
    _cachedDoScopes = null;
  }
  else
  {
    setGlobalScopeHandler("while", &handleWhileScope);

    auto scopeObjects = parseScopes(token, source, line, "while", "while");

    removeGlobalScopeHandler("while");

    if (scopeObjects && scopeObjects.length)
    {
      loop.scopes = scopeObjects.dup;
    }
  }

  return loop;
}

private:
/**
* Handles custom scope elements for a while loop statement such as "break".
* Params:
*   token = The token to handle.
*   line = The line of the token.
*   scopeObject = (ref) The current scope object.
* Returns:
*   Returns true if the scope element was handled and parsed correctly. False otherwise, which will trigger a compiler error.
*/
bool handleWhileScope(Token token, size_t line, ref ScopeObject scopeObject)
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
