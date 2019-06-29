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
import parser.variableparser;
import parser.ifparser;
import parser.switchparser;

/// Enumeration of scope states.
enum ScopeState
{
  /// Breaks out of current scope. Limited to certain scopes.
  scopeBreak,
  /// Returns from the function. Must have a ReturnExpression associated.
  scopeReturn,
  /// For loops scopes this will skip the current iteration and go to the next iteration.
  scopeContinue,
  /// For loop scopes this will break out of all nested scopes except for the outer-most scope.
  scopeEnd
}

/// A scope object.
class ScopeObject
{
  /// The assignment expression of the scope.
  AssignmentExpression assignmentExpression;
  /// The function call expression of the scope.
  FunctionCallExpression functionCallExpression;
  /// The return expression of the scope.
  ReturnExpression returnExpression;
  /// Variable declaration.
  Variable variable;
  /// An if statement.
  IfStatement ifStatement;
  /// An else statement.
  ElseStatement elseStatement;
  /// An else statement.
  SwitchStatement switchStatement;
  /// The state of the scope.
  ScopeState scopeState;
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
*   customScopeHandler = A custom scope handler to handle specific scope elements such as "break" which is only valid in certain scopes.
* Returns:
*   The scope objects created.
*/
ScopeObject[] parseScopes(Token scopeToken, string source, size_t line, string scopeName, string sourceIdentifier, bool function(Token,size_t,ref ScopeObject) customScopeHandler = null)
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

    auto parserType = token.getParserType;

    switch (parserType)
    {
      case ParserType.RETURN:
        auto returnExpression = parseReturnExpression(token, source, line);

        if (returnExpression)
        {
          scopeObject.returnExpression = returnExpression;
          scopeObject.scopeState = ScopeState.scopeReturn;
          scopeObjects ~= scopeObject;

          scopeObject = new ScopeObject;
        }
        else
        {
          if (!printQueuedErrors())
          {
            line.printError(source, "Invalid return statement: %s", token.statement);
          }
        }
        break;

      case ParserType.VARIABLE:
        auto variable = parseVariable(token, source);

        if (variable)
        {
          scopeObject.variable = variable;
          scopeObjects ~= scopeObject;

          scopeObject = new ScopeObject;
        }
        else
        {
          if (!printQueuedErrors())
          {
            line.printError(source, "Invalid variable declaration: %s", token.statement);
          }
        }
        break;

      case ParserType.IF:
        auto ifStatement = parseIfStatement(token, source);

        if (ifStatement)
        {
          scopeObject.ifStatement = ifStatement;
          scopeObjects ~= scopeObject;

          scopeObject = new ScopeObject;
        }
        else
        {
          if (!printQueuedErrors())
          {
            line.printError(source, "Invalid if statement: %s", token.statement);
          }
        }
        break;

      case ParserType.ELSE:
        auto elseStatement = parseElseStatement(token, source);

        if (elseStatement)
        {
          scopeObject.elseStatement = elseStatement;
          scopeObjects ~= scopeObject;

          scopeObject = new ScopeObject;
        }
        else
        {
          if (!printQueuedErrors())
          {
            line.printError(source, "Invalid else statement: %s", token.statement);
          }
        }
        break;

        case ParserType.SWITCH:
          auto switchStatement = parseSwitchStatement(token, source);

          if (switchStatement)
          {
            scopeObject.switchStatement = switchStatement;
            scopeObjects ~= scopeObject;

            scopeObject = new ScopeObject;
          }
          else
          {
            if (!printQueuedErrors())
            {
              line.printError(source, "Invalid switch statement: %s", token.statement);
            }
          }
          break;

      case ParserType.EMPTY: break;

      default:
        if (parserType != ParserType.UNKNOWN)
        {
          if (customScopeHandler !is null && customScopeHandler(token,line,scopeObject))
          {
            scopeObjects ~= scopeObject;

            scopeObject = new ScopeObject;
            break;
          }

          line.printError(source, "Invalid declaration for scope: %s", token.statement && token.statement.length ? token.statement[0] : "");
          break;
        }

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
