/**
* Module for parsing scopes.
*
* License: MIT (https://github.com/Royal Programming Language/bl/blob/master/LICENSE)
*
* Copyright 2019 © Royal Programming Language - All Rights Reserved.
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
import parser.forparser;
import parser.foreachparser;
import parser.whileparser;

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
  /// A for loop statement.
  ForLoop forLoop;
  /// A foreach loop statement.
  ForeachLoop foreachLoop;
  /// A while loop statement.
  WhileLoop whileLoop;
  /// The state of the scope.
  ScopeState scopeState;
  /// Nested scopes.
  ScopeObject[] nestedScopes;
  /// The line for the scope object.
  size_t line;
}

/// Alias for a function pointer for scope handlers.
private alias SCOPE_HANDLER = bool function(Token,size_t,ref ScopeObject);

/// A scope handler.
private class ScopeHandler
{
  /// The handler.
  SCOPE_HANDLER handler;
  /// The name.
  string name;
  /// The counter.
  size_t counter;
}

/// The global scope handlers.
private ScopeHandler[string] _globalScopeHandlers;

/**
* Sets a global scope handler. (Remove to call removeGlobalScopeHandler())
* Params:
*   name = The name of the scope handler.
*/
void setGlobalScopeHandler(string name, lazy SCOPE_HANDLER handler)
{
  auto scopeHandler = _globalScopeHandlers.get(name, null);

  if (!scopeHandler)
  {
    scopeHandler = new ScopeHandler;
    scopeHandler.handler = handler;
    scopeHandler.name = name;
    scopeHandler.counter = 1;
    _globalScopeHandlers[name] = scopeHandler;
  }
  else
  {
    scopeHandler.counter += 1;
  }
}

/**
* Removes a global scope handler.
* Params:
*   name = The name of the global scope handler to remove.
*/
void removeGlobalScopeHandler(string name)
{
  if (!_globalScopeHandlers)
  {
    return;
  }

  auto scopeHandler = _globalScopeHandlers.get(name, null);

  if (!scopeHandler)
  {
    return;
  }

  scopeHandler.counter -= 1;

  if (!scopeHandler.counter)
  {
    _globalScopeHandlers.remove(name);
  }
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
ScopeObject[] parseScopes(Token scopeToken, string source, size_t line, string scopeName, string sourceIdentifier, SCOPE_HANDLER customScopeHandler = null)
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

    if (hasDoWhileLoop && parserType != ParserType.WHILE && parserType != ParserType.UNKNOWN && parserType != ParserType.EMPTY)
    {
      line.printError(source, "Missing while statement from do-while declaration.");
      continue;
    }

    if (!token.statement || !token.statement.length)
    {
      if (token.tokens && token.tokens.length)
      {
        auto nestedScopeObjects = parseScopes(token, source, line, "scope", "scope");

        if (nestedScopeObjects && nestedScopeObjects.length)
        {
          scopeObject.nestedScopes = nestedScopeObjects.dup;
        }

        scopeObjects ~= scopeObject;

        scopeObject = new ScopeObject;
        continue;
      }
    }

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

      case ParserType.FOR:
        auto forLoop = parseForLoop(token, source);

        if (forLoop)
        {
          scopeObject.forLoop = forLoop;
          scopeObjects ~= scopeObject;

          scopeObject = new ScopeObject;
        }
        else
        {
          if (!printQueuedErrors())
          {
            line.printError(source, "Invalid for statement: %s", token.statement);
          }
        }
        break;

        case ParserType.FOREACH:
          auto foreachLoop = parseForeachLoop(token, source);

          if (foreachLoop)
          {
            scopeObject.foreachLoop = foreachLoop;
            scopeObjects ~= scopeObject;

            scopeObject = new ScopeObject;
          }
          else
          {
            if (!printQueuedErrors())
            {
              line.printError(source, "Invalid foreach statement: %s", token.statement);
            }
          }
          break;

        case ParserType.DO:
          if (!parseDoStatement(token, source))
          {
            if (!printQueuedErrors())
            {
              line.printError(source, "Invalid do-while statement: %s", token.statement);
            }
          }
          break;

        case ParserType.WHILE:
          auto whileLoop = parseWhileLoop(token, source);

          if (whileLoop)
          {
            scopeObject.whileLoop = whileLoop;
            scopeObjects ~= scopeObject;

            scopeObject = new ScopeObject;
          }
          else
          {
            if (!printQueuedErrors())
            {
              line.printError(source, "Invalid foreach statement: %s", token.statement);
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

          if (_globalScopeHandlers && _globalScopeHandlers.length)
          {
            bool parsedScope;
            foreach (scopeHandler; _globalScopeHandlers.values)
            {
              if (scopeHandler.handler !is null && scopeHandler.handler(token,line,scopeObject))
              {
                scopeObjects ~= scopeObject;

                scopeObject = new ScopeObject;
                parsedScope = true;
                break;
              }
            }

            if (parsedScope)
            {
              break;
            }
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
