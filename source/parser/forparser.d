/**
* Module for parsing for loops.
*
* License: MIT (https://github.com/Royal Programming Language/bl/blob/master/LICENSE)
*
* Copyright 2019 © Royal Programming Language - All Rights Reserved.
*/
module parser.forparser;

import core.tokenizer;
import core.errors;
import core.debugging;

import parser.meta;
import parser.tools;

import parser.variableparser;
import parser.expressionparser;
import parser.assignmentparser;
import parser.scopeparser;

/// A for loop.
class ForLoop
{
  /// The initialization variable for the for loop.
  Variable initialization;
  /// The condition of the for loop.
  Expression condition;
  /// The post expression of the for loop.
  AssignmentExpression postExpression;
  /// The scopes of the for loop statement.
  ScopeObject[] scopes;
}

/**
* Parses a for loop.
* Params:
*   token = The token of the for loop.
*   source = The source of the for loop.
*/
ForLoop parseForLoop(Token token, string source)
{
  size_t line = token.retrieveLine;

  if (!token.statement || !token.statement.length)
  {
    line.printError(source, "Missing for loop declaration.");
    return null;
  }

  string[] initialization;
  string[] condition;
  string[] postExpression;
  size_t state = 1;

  foreach (entry; token.statement[1 .. $])
  {
    if (entry == ",")
    {
      state++;
    }
    else if (state == 1)
    {
      initialization ~= entry;
    }
    else if (state == 2)
    {
      condition ~= entry;
    }
    else if (state == 3)
    {
      postExpression ~= entry;
    }
    else
    {
      line.printError(source, "A for loop can only have 3 expressions. Found: %s expressions.", state);
      return null;
    }
  }

  auto loop = new ForLoop;

  if (!condition || !condition.length)
  {
    line.printError(source, "Missing condition from for loop.");
    return null;
  }
  else
  {
    auto conditionExpression = parseRightHandExpression(condition ~ ";", source, line, false, true);

    if (!conditionExpression || (!conditionExpression.tokens && !conditionExpression.arrayExpression))
    {
      if (!hasQueuedErrors)
      {
        line.queueError(source, "Failed to parse condition expression.");
      }
      return null;
    }

    loop.condition = conditionExpression;
  }

  if (!postExpression || !postExpression.length)
  {
    line.printError(source, "Missing post-expression from for loop.");
    return null;
  }
  else
  {
    auto postAssignmentExpression = parseAssignmentExpression(token, postExpression ~ ";", source, line);

    if (!postAssignmentExpression)
    {
      if (!hasQueuedErrors)
      {
        line.queueError(source, "Failed to parse post-expression.");
      }
      return null;
    }

    loop.postExpression = postAssignmentExpression;
  }

  if (initialization && initialization.length)
  {
    auto variable = parseVariable(token, initialization ~ ";", source);

    if (!variable)
    {
      return null;
    }

    loop.initialization = variable;
  }

  setGlobalScopeHandler("for_loop", &handleForScope);

  auto scopeObjects = parseScopes(token, source, line, "for", "for");

  removeGlobalScopeHandler("for_loop");

  if (scopeObjects && scopeObjects.length)
  {
    loop.scopes = scopeObjects.dup;
  }

  return loop;
}

private:
/**
* Handles custom scope elements for a for loop statement such as "break".
* Params:
*   token = The token to handle.
*   line = The line of the token.
*   scopeObject = (ref) The current scope object.
* Returns:
*   Returns true if the scope element was handled and parsed correctly. False otherwise, which will trigger a compiler error.
*/
bool handleForScope(Token token, size_t line, ref ScopeObject scopeObject)
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
