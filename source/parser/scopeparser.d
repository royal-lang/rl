/**
* Module for parsing scopes.
*
* License: MIT (https://github.com/bausslang/bl/blob/master/LICENSE)
*
* Copyright 2019 © bausslang - All Rights Reserved.
*/
module parser.scopeparser;

import core.tokenizer;
import core.errors;
import core.debugging;

import parser.meta;
import parser.tools;

import parser.assignmentparser;
import parser.functioncallparser;
import parser.returnparser;

/// A scope object.
class ScopeObject
{
  /// The assignment expression of the scope.
  AssignmentExpression assignmentExpression;
  /// The function call expression of the scope.
  FunctionCallExpression functionCallExpression;
  /// The return expression of the scope.
  ReturnExpression returnExpression;
  /// The line for the scope object.
  size_t line;
}

/**
* Parses scopes.
* Params:
*   token = The scope token.
*   source = The source parsed from.
*   line = The line parsed from.
*   scopeName = The name of the scope.
*   sourceIdentifier = The identifier of the source. Ex. a function name.
* Returns:
*   The scope objects created.
*/
ScopeObject[] parseScopes(Token scopeToken, string source, size_t line, string scopeName, string sourceIdentifier)
{
  printDebug("Parsing scope.");

  if (!scopeToken.tokens || scopeToken.tokens.length < 2)
  {
    line.printError(source, "Missing %s body.", scopeName);
    return null;
  }

  auto firstToken = scopeToken.tokens[0];
  auto lastToken = scopeToken.tokens[$-1];

  auto firstStatement = firstToken.statement;
  auto lastStatement = lastToken.statement;

  auto firstLine = firstToken.retrieveLine;
  auto lastLine = lastToken.retrieveLine;

  if (!firstStatement || firstStatement.length != 1)
  {
    firstLine.printError(source, "Missing start scope declaration for %s: %s", scopeName, sourceIdentifier);
    return null;
  }

  if (firstStatement[0] != "{")
  {
    firstLine.printError(source, "Expected '%s' but found '%s'", "{", firstStatement[0]);
    return null;
  }

  if (!lastStatement || lastStatement.length != 1)
  {
    lastLine.printError(source, "Missing end scope declaration for %s: %s", scopeName, sourceIdentifier);
    return null;
  }

  if (lastStatement[0] != "}")
  {
    lastLine.printError(source, "Expected '%s' but found '%s'", "}", lastStatement[0]);
    return null;
  }

  ScopeObject[] scopeObjects = [];

  auto scopeObject = new ScopeObject;

  foreach (token; scopeToken.tokens[1 .. $-1])
  {
    line = token.retrieveLine;
    scopeObject.line = line;

    switch (token.getParserType)
    {
      case ParserType.RETURN:
        auto returnExpression = parseReturnExpression(token, source, line);

        if (returnExpression)
        {
          scopeObject.returnExpression = returnExpression;
          scopeObjects ~= scopeObject;

          scopeObject = new ScopeObject;
        }
        else
        {
          if (!printQueuedErrors())
          {
            line.printError(source, "Invalid return statement: %s", token.statement && token.statement.length ? token.statement[0] : "");
          }
        }
        break;

      case ParserType.EMPTY: break;

      default:
        auto functionCallExpression = parseFunctionCallExpression(token, source, line);

        if (functionCallExpression)
        {
          scopeObject.functionCallExpression = functionCallExpression;
          scopeObjects ~= scopeObject;

          scopeObject = new ScopeObject;
        }
        else
        {
          auto assignmentExpression = parseAssignmentExpression(token, source, line);

          if (assignmentExpression)
          {
            scopeObject.assignmentExpression = assignmentExpression;
            scopeObjects ~= scopeObject;

            scopeObject = new ScopeObject;
          }
          else
          {
            if (!printQueuedErrors())
            {
              line.printError(source, "Invalid declaration: %s", token.statement && token.statement.length ? token.statement[0] : "");
            }
          }
        }
        break;
    }
  }

  printDebug("Finished parsing scope.");

  return scopeObjects;
}
