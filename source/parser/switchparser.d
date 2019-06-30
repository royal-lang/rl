/**
* Module for parsing switch statements.
*
* License: MIT (https://github.com/Royal Programming Language/bl/blob/master/LICENSE)
*
* Copyright 2019 © Royal Programming Language - All Rights Reserved.
*/
module parser.switchparser;

import core.tokenizer;
import core.errors;
import core.debugging;

import parser.meta;
import parser.tools;

import parser.expressionparser;
import parser.scopeparser;

/// A switch statement.
class SwitchStatement
{
  /// The expression of the switch.
  Expression switchExpression;
  /// The cases of the switch.
  CaseStatement[] cases;
  /// The default case of the switch.
  CaseStatement defaultCase;
  /// The final case of the switch.
  CaseStatement finalCase;
}

class CaseStatement
{
  /// The values of the case.
  string[] values;
  /// Boolean determining whether the case value is a range.
  bool isRange;
  /// The scopes of the case.
  ScopeObject[] scopes;
}

/**
* Parses a switch statement.
* Params:
*   token = The token of the switch statement.
*   statement = The statement of the switch statement.
*   source = The source of the switch statement.
* Returns:
*   Returns the switch statement if parsed correctly, null otherwise.
*/
SwitchStatement parseSwitchStatement(Token token, string source)
{
  import std.array : array;
  import std.algorithm : map;

  return parseSwitchStatement(token, token.statement.map!(s => s.s).array, source);
}

/**
* Parses a switch statement.
* Params:
*   token = The token of the switch statement.
*   statement = The statement of the switch statement.
*   source = The source of the switch statement.
* Returns:
*   Returns the switch statement if parsed correctly, null otherwise.
*/
SwitchStatement parseSwitchStatement(Token token, string[] statement, string source)
{
  size_t line = token.retrieveLine;

  if (!statement || statement.length < 2)
  {
    line.printError(source, "Empty switch statement found.");
    return null;
  }

  if (statement[0] != Keyword.SWITCH)
  {
    line.printError(source, "Expected '%s' but found '%s'", cast(string)Keyword.SWITCH, statement[0]);
    return null;
  }

  auto expression = statement[1 .. $];

  auto switchExpression = parseRightHandExpression(expression ~ ";", source, line, false, false);

  if (!switchExpression)
  {
    line.printError(source, "Invalid switch statement expression.");
    return null;
  }

  auto switchStatement = new SwitchStatement;
  switchStatement.switchExpression = switchExpression;

  foreach (child; token.tokens[1 .. $-1])
  {
    if ((!child.statement || !child.statement.length) && (!child.tokens || !child.tokens.length))
    {
      continue;
    }

    auto childLine = child.retrieveLine;

    if (!child.tokens || !child.tokens.length)
    {
      childLine.printError(source, "Empty case found: %s", child.statement);
      return null;
    }

    auto caseStatement = new CaseStatement;

    if (!child.statement || !child.statement.length)
    {
      childLine.printError(source, "Expected '%s' but found '%s'", cast(string)Keyword.CASE, child.statement[0]);
      return null;
    }
    else if (child.statement.length == 1)
    {
      if (child.statement[0] == Keyword.DEFAULT)
      {
        if (switchStatement.defaultCase)
        {
          childLine.printError(source, "A switch statement can only have one default scope.");
          return null;
        }

        switchStatement.defaultCase = caseStatement;
      }
      else if (child.statement[0] == Keyword.FINAL)
      {
        if (switchStatement.finalCase)
        {
          childLine.printError(source, "A switch statement can only have one final scope.");
          return null;
        }

        switchStatement.finalCase = caseStatement;
      }
      else
      {
        childLine.printError(source, "Expected '%s' or '%s' but found '%s'", cast(string)Keyword.DEFAULT, cast(string)Keyword.FINAL, child.statement[1]);
        return null;
      }
    }
    else if (child.statement[0] != Keyword.CASE)
    {
      childLine.printError(source, "Expected '%s' but found '%s'", cast(string)Keyword.CASE, child.statement[0]);
      return null;
    }
    else
    {
      if (child.statement.length == 4 && child.statement[2] != ".." && child.statement[2] != ",")
      {
        childLine.printError(source, "Expected '%s' or '%s' but found '%s'", ",", "..", child.statement[1]);
        return null;
      }

      if (child.statement.length == 4 && child.statement[2] == "..")
      {
        caseStatement.values = [child.statement[0].s, child.statement[1].s];
        caseStatement.isRange = true;
      }
      else
      {
        string lastArg;
        auto paramIndex = 0;

        foreach (e; child.statement[1 .. $])
        {
          string entry = e.s;

          if (entry == ",")
          {
            if (!lastArg || !lastArg.length)
            {
              childLine.printError(source, "Missing arguments for value: %s", paramIndex);
              return null;
            }
            else
            {
              caseStatement.values ~= lastArg;
              paramIndex++;
              lastArg = null;
            }
          }
          else if (lastArg)
          {
            childLine.printError(source, "Expected '%s' but found '%s'", ",", entry);
            return null;
          }
          else
          {
            lastArg = entry;
          }
        }

        if (!lastArg || !lastArg.length)
        {
          childLine.printError(source, "Missing arguments for value: %s", paramIndex);
          return null;
        }
      }
    }

    auto scopeObjects = parseScopes(child, source, line, "case", "case", &handleCaseScope);

    if (scopeObjects && scopeObjects.length)
    {
      caseStatement.scopes = scopeObjects.dup;
    }
  }

  return switchStatement;
}

private:
/**
* Handles custom scope elements for a switch statement such as "break".
* Params:
*   token = The token to handle.
*   line = The line of the token.
*   scopeObject = (ref) The current scope object.
* Returns:
*   Returns true if the scope element was handled and parsed correctly. False otherwise, which will trigger a compiler error.
*/
bool handleCaseScope(Token token, size_t line, ref ScopeObject scopeObject)
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

    // TODO: Implement GOTO.
    // case Keyword.GOTO:
    //   break;

    default:
      return false;
  }
}
