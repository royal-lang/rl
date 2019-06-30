/**
* Module for parsing if statements.
*
* License: MIT (https://github.com/Royal Programming Language/bl/blob/master/LICENSE)
*
* Copyright 2019 © Royal Programming Language - All Rights Reserved.
*/
module parser.ifparser;

import core.tokenizer;
import core.errors;
import core.debugging;

import parser.meta;
import parser.tools;

import parser.expressionparser;
import parser.scopeparser;

/// An if statement.
class IfStatement
{
  /// The boolean expression of the if statement.
  Expression expression;

  /// The scopes of the if statement.
  ScopeObject[] scopes;
}

/**
* Parses an if statement.
* Params:
*   token = The token of the if statement.
*   source = The source of the if statement.
* Returns:
*   An if statement object if parsed correctly, null otherwise.
*/
IfStatement parseIfStatement(Token token, string source)
{
  auto line = token.retrieveLine;

  return parseIfStatement(token, token.statement, source, line);
}

/**
* Parses an if statement.
* Params:
*   token = The token of the if statement.
*   statement = The statement of the if statement.
*   source = The source of the if statement.
* Returns:
*   An if statement object if parsed correctly, null otherwise.
*/
IfStatement parseIfStatement(Token token, STRING[] statement, string source, size_t line)
{
  import std.array : array;
  import std.algorithm : map;

  return parseIfStatement(token, statement.map!(s => s.s).array, source, line);
}

/**
* Parses an if statement.
* Params:
*   token = The token of the if statement.
*   statement = The statement of the if statement.
*   source = The source of the if statement.
* Returns:
*   An if statement object if parsed correctly, null otherwise.
*/
IfStatement parseIfStatement(Token token, string[] statement, string source, size_t line)
{
  if (!statement || statement.length < 2)
  {
    line.printError(source, "Empty if statement found.");
    return null;
  }

  if (statement[0] != Keyword.IF)
  {
    line.printError(source, "Expected '%s' but found '%s'", cast(string)Keyword.IF, statement[0]);
    return null;
  }

  auto expression = statement[1 .. $];

  auto booleanExpression = parseRightHandExpression(expression ~ ";", source, line, false, true);

  if (!booleanExpression)
  {
    line.printError(source, "Invalid if statement expression. Make sure the expression is a boolean expression only.");
    return null;
  }

  auto ifStatement = new IfStatement;
  ifStatement.expression = booleanExpression;

  auto scopeObjects = parseScopes(token, source, line, "else", "else");

  if (scopeObjects && scopeObjects.length)
  {
    ifStatement.scopes = scopeObjects.dup;
  }

  return ifStatement;
}

/// An else statement or else if statement.
class ElseStatement
{
  /// The if statement tied to the else statement.
  IfStatement ifStatement;

  /// The scopes of the else statement. (Only available if there is no if statement.)
  ScopeObject[] scopes;
}

/**
* Parses an else statement.
* Params:
*   token = The token of the else statement.
*   source = The source of the else statement.
* Returns:
*   An else statement object if parsed correctly, null otherwise.
*/
ElseStatement parseElseStatement(Token token, string source)
{
  auto line = token.retrieveLine;

  return parseElseStatement(token, token.statement, source, line);
}

/**
* Parses an else statement.
* Params:
*   token = The token of the else statement.
*   statement = The statement of the else statement.
*   source = The source of the else statement.
* Returns:
*   An else statement object if parsed correctly, null otherwise.
*/
ElseStatement parseElseStatement(Token token, STRING[] statement, string source, size_t line)
{
  import std.array : array;
  import std.algorithm : map;

  return parseElseStatement(token, statement.map!(s => s.s).array, source, line);
}

/**
* Parses an else statement.
* Params:
*   token = The token of the else statement.
*   statement = The statement of the else statement.
*   source = The source of the else statement.
* Returns:
*   An else statement object if parsed correctly, null otherwise.
*/
ElseStatement parseElseStatement(Token token, string[] statement, string source, size_t line)
{
  if (!statement || !statement.length)
  {
    line.printError(source, "Empty else statement found.");
    return null;
  }

  if (statement[0] != Keyword.ELSE)
  {
    line.printError(source, "Expected '%s' but found %s", cast(string)Keyword.ELSE, statement[0]);
    return null;
  }

  auto elseStatement = new ElseStatement;

  if (statement.length > 1)
  {
    auto ifExpression = statement[1 .. $];

    auto ifStatement = parseIfStatement(token, ifExpression, source, line);

    if (!ifStatement)
    {
      return null;
    }

    elseStatement.ifStatement = ifStatement;
  }
  else
  {
    auto scopeObjects = parseScopes(token, source, line, "else", "else");

    if (scopeObjects && scopeObjects.length)
    {
      elseStatement.scopes = scopeObjects.dup;
    }
  }

  return elseStatement;
}
