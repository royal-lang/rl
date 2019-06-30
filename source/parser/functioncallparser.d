/**
* Module for parsing function calls.
*
* License: MIT (https://github.com/Royal Programming Language/bl/blob/master/LICENSE)
*
* Copyright 2019 © Royal Programming Language - All Rights Reserved.
*/
module parser.functioncallparser;

import core.tokenizer;
import core.errors;
import core.debugging;

import parser.meta;
import parser.tools;

import parser.arrayparser;

/// A function call expression.
class FunctionCallExpression
{
  /// The identifier of the function call.
  string identifier;
  /// The parameters passed to the function call.
  FunctionCallParameter[] templateParameters;
  /// The parameters passed to the function call.
  FunctionCallParameter[] parameters;
  /// The chain of calls originated from this call.
  FunctionCallExpression[] chain;
  /// The line of the function call expression.
  size_t line;
}

/// A function call parameter.
class FunctionCallParameter
{
  /// An array expression parameter.
  ArrayExpression arrayExpression;
  /// A raw parameter.
  string rawParameter;
}

/**
* Parses a function call expression.
* Params:
*   token = The token of the function.
*   source = The source parsed from.
*   line = The line parsed from.
* Returns:
*   The function call expression created.
*/
FunctionCallExpression parseFunctionCallExpression(Token token, string source, size_t line, bool skipEndCheck = false, bool chainedCallsAllowed = true)
{
  return parseFunctionCallExpression(token.statement, source, line, skipEndCheck, chainedCallsAllowed);
}

/**
* Parses a function call expression.
* Params:
*   statement = The statement to parse.
*   source = The source parsed from.
*   line = The line parsed from.
* Returns:
*   The function call expression created.
*/
FunctionCallExpression parseFunctionCallExpression(STRING[] statement, string source, size_t line, bool skipEndCheck = false, bool chainedCallsAllowed = true)
{
  import std.algorithm : map;
  import std.array : array;

  return parseFunctionCallExpression(statement.map!(s => s.s).array, source, line, skipEndCheck, chainedCallsAllowed);
}

/**
* Parses a function call expression.
* Params:
*   statement = The statement to parse.
*   source = The source parsed from.
*   line = The line parsed from.
* Returns:
*   The function call expression created.
*/
FunctionCallExpression parseFunctionCallExpression(string[] statement, string source, size_t line, bool skipEndCheck = false, bool chainedCallsAllowed = true, bool isChainedCall = false)
{
  printDebug("Parsing function call: %s", statement);
  statement = statement.dup;

  import std.array : join;

  if (!isChainedCall)
  {
    clearQueuedErrors();
  }

  if (skipEndCheck)
  {
    if (!statement || !statement.length)
    {
      line.queueError(source, "Missing function call expression.");
      return null;
    }

    if (statement[$-1] != ";")
    {
      statement ~= ";";
    }
  }

  if (!statement || statement.length < 4)
  {
    return null;
  }

  if (chainedCallsAllowed)
  {
    string[][] chainedStatements;

    string[] currentStatement;

    foreach (i; 0 .. statement.length)
    {
      auto entry = statement[i];
      auto lastEntry = i > 1 ? statement[i - 1] : "";

      if (entry == "." && lastEntry == ")")
      {
        currentStatement ~= ";";
        chainedStatements ~= currentStatement;
        currentStatement = [];
      }
      else
      {
        currentStatement ~= entry;
      }
    }

    if (currentStatement)
    {
      chainedStatements ~= currentStatement;
    }

    if (chainedStatements && chainedStatements.length > 1)
    {
      FunctionCallExpression rootCall;

      foreach (chainedStatement; chainedStatements)
      {
        auto call = parseFunctionCallExpression(chainedStatement, source, line, false, false, true);

        if (!rootCall)
        {
          rootCall = call;
        }
        else
        {
          rootCall.chain ~= call;
        }
      }

      return rootCall;
    }
  }


  if (statement[1] != "(")
  {
    line.queueError(source, "Missing '%s' from function call. Found '%s' instead.", "(", statement[1]);
    return null;
  }

  if (statement[$-2] != ")")
  {
    line.queueError(source, "Missing '%s' from function call. Found '%s' instead.", ")", statement[1]);
    return null;
  }

  if (statement[$-1] != ";")
  {
    line.queueError(source, "Expected '%s' but found '%s'", ";", statement[$-1]);
    return null;
  }

  auto functionCallExpression = new FunctionCallExpression;
  functionCallExpression.identifier = statement[0];
  functionCallExpression.line = line;

  if (!functionCallExpression.identifier.isValidIdentifier)
  {
    line.queueError(source, "Invalid identifier for function call.");
    return null;
  }

  string[] parameters1 = [];
  string[] parameters2 = null;

  string[] values = [];
  bool parsedTemplate = false;

  bool inArray = false;

  auto parseStatement = statement[2 .. $-2];

  foreach (ref i; 0 .. parseStatement.length)
  {
    auto entry = parseStatement[i];
    auto lastEntry = i > 1 ? parseStatement[i - 1] : "";
    auto nextEntry = i < (parseStatement.length - 1) ? parseStatement[i + 1] : "";

    if (!inArray && entry == ")" && nextEntry == "(")
    {
      if (parsedTemplate)
      {
        line.queueError(source, "Invalid function call.");
        return null;
      }

      if (values && values.length)
      {
        if (parsedTemplate) parameters2 ~= values.join("");
        else parameters1 ~= values.join("");

        values = [];
      }

      parsedTemplate = true;
      parameters2 = [];

      i++;
    }
    else if (inArray && entry == "]")
    {
      inArray = false;
      values ~= entry;
    }
    else if (!inArray && entry == "[" && !values && !values.length)
    {
      values ~= entry;
      inArray = true;
    }
    else if (inArray && entry == "[")
    {
      line.queueError(source, "Nested array expression found.");
      return null;
    }
    else if (!inArray && entry == "]")
    {
      line.queueError(source, "Array expression missing. No matching array expression start.");
      return null;
    }
    else if (!inArray && entry == ",")
    {
      if (!values || !values.length)
      {
        line.queueError(source, "Missing values for entry.");
        return null;
      }

      foreach (value; values)
      {
        if ((value != "!" && value != "!!" && value != "[" && value != "]" && value != "," && value != ":" && value.isQualifiedSymbol) || value == "()")
        {
          line.queueError(source, "Invalid parameter value: %s", value);
          return null;
        }
      }

      if (parsedTemplate) parameters2 ~= values.join("");
      else parameters1 ~= values.join("");

      values = [];
    }
    else if (inArray)
    {
      values ~= entry;
    }
    else
    {
      values ~= entry;
    }
  }

  if (inArray)
  {
    line.queueError(source, "Array expression is never closed.");
    return null;
  }

  if (values && values.length)
  {
    foreach (value; values)
    {
      if ((value != "!" && value != "!!" && value != "[" && value != "]" && value != "," && value != ":" && value.isQualifiedSymbol) || value == "()")
      {
        line.queueError(source, "Invalid parameter value: %s", value);
        return null;
      }
    }

    if (parsedTemplate) parameters2 ~= values.join("");
    else parameters1 ~= values.join("");

    values = [];
  }

  FunctionCallParameter[] callParameters1;

  if (parameters1 && parameters1.length)
  {
    foreach (param; parameters1)
    {
      auto callParameter = new FunctionCallParameter;
      callParameter.rawParameter = param;

      if (param[0] == '[')
      {
        auto arrayTokens = tokenize(param ~ ";", false);
        auto arrayToken = groupTokens(arrayTokens);

        auto arrayExpression = parseArrayExpression(arrayToken.tokens[0].statement, source, line, true);

        if (arrayExpression)
        {
          callParameter.arrayExpression = arrayExpression;
        }
        else
        {
          return null;
        }
      }

      callParameters1 ~= callParameter;
    }
  }

  FunctionCallParameter[] callParameters2;

  if (parameters1 && parameters1.length)
  {
    foreach (param; parameters1)
    {
      auto callParameter = new FunctionCallParameter;
      callParameter.rawParameter = param;

      if (param[0] == '[')
      {
        auto arrayTokens = tokenize(param ~ ";", false);
        auto arrayToken = groupTokens(arrayTokens);

        auto arrayExpression = parseArrayExpression(arrayToken.tokens[0].statement, source, line, true);

        if (arrayExpression)
        {
          callParameter.arrayExpression = arrayExpression;
        }
        else
        {
          return null;
        }
      }

      callParameters2 ~= callParameter;
    }
  }

  if (callParameters1 && callParameters1.length && callParameters2)
  {
    functionCallExpression.parameters = callParameters2;
    functionCallExpression.templateParameters = callParameters1;
  }
  else
  {
    functionCallExpression.parameters = callParameters1;
  }

  return functionCallExpression;
}
