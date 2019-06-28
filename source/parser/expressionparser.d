module parser.expressionparser;

import core.tokenizer;
import core.errors;
import core.debugging;

import parser.meta;
import parser.tools;

import parser.functioncallparser;
import parser.arrayparser;

/// An expression. (Typically right-hand expressions.)
class Expression
{
  /// Boolean determining whether the expression is mathematical. If false then it'll be assumed to be a boolean expression.
  bool isMathematicalExpression;
  /// The tokens of the expression.
  ExpressionToken[] tokens;
  /// The array expression, if not a standard expression.
  ArrayExpression arrayExpression;
  /// The line of the expression.
  size_t line;
}

/// An expression token.
class ExpressionToken
{
  /// The tokens of the expression token.
  string[] tokens;
  /// Boolean determining whether the token is a function call or not.
  bool isFunctionCall;
  /// The function call of the token.
  FunctionCallExpression functionCallExpression;
  /// The line of the token.
  size_t line;
}

/**
* Checks whether a specific symbol is a qualified symbol for the given expression type.
* Params:
*   symbol = The symbol to check for qualification.
*   isMathematicalExpression = Boolean determining whether the expression to validate for is mathematical or boolean.
* Returns:
*   Returns true if the symbol is qualified, false otherwise.
*/
bool isQualifiedExpressionSymbol(string symbol, bool isMathematicalExpression)
{
  if (isMathematicalExpression)
  {
    switch (symbol)
    {
      case "(":
      case ")":
      case "+":
      case "-":
      case "*":
      case "/":
      case "%":
      case "^":
      case "<<":
      case ">>":
      case "|":
      case "~":
      case "&":
      case "^^":
        return true;

      default: return false;
    }
  }
  else
  {
    switch (symbol)
    {
      case "(":
      case ")":
      case "||":
      case "&&":
      case "~":
      case ">":
      case ">=":
      case "<=":
      case "<":
      case "!=":
      case "!":
      case "!!":
      case "==":
        return true;

      default: return false;
    }
  }
}

/**
* Parses a right-hand expression.
* Params:
*   expression = The expression tokens to parse.
*   source = The source of the right-hand expression.
*   line = The line of the right-hand expression.
*   queueErrors = Boolean determining whether errors are printed directly or queued.
*   isForcedBooleanExpression = Boolean determining whether the expression should be forcefully parsed as a boolean expression. Ex. if statements will force a boolean expression.
* Returns:
*   An expression if parsed correctly, null otherwise.
*/
Expression parseRightHandExpression(string[] expression, string source, size_t line, bool queueErrors, bool isForcedBooleanExpression = false)
{
  clearQueuedErrors();

  auto exp = new Expression;

  if (!expression || !expression.length)
  {
    if (queueErrors) line.queueError(source, "Empty expression.");
    else line.printError(source, "Empty expression.");
    return exp;
  }

  if (expression[$-1] != ";")
  {
    if (queueErrors) line.queueError(source, "Expected '%s' but found '%s'", ";", expression[$-1]);
    else line.printError(source, "Expected '%s' but found '%s'", ";", expression[$-1]);
    return null;
  }

  if (!isForcedBooleanExpression)
  {
    if (expression[0] == "[")
    {
      auto arrayExpression = parseArrayExpression(expression, source, line, queueErrors);

      if (arrayExpression)
      {
        exp.arrayExpression = arrayExpression;
        return exp;
      }
      else
      {
        if (!queueErrors)
        {
          printQueuedErrors();
        }

        return null;
      }
    }
  }

  exp.isMathematicalExpression = expression.isMathematicalExpression;

  if (isForcedBooleanExpression)
  {
    exp.isMathematicalExpression = false;
  }

  auto currentToken = new ExpressionToken;

  bool inFunction = false;
  size_t open = 0;
  size_t closed = 0;
  bool parsedTemplate = false;

  foreach (ref i; 0 .. (expression.length - 1))
  {
    auto token = expression[i];
    auto last = i > 0 ? expression[i - 1] : "";
    auto next = i < (expression.length - 1) ? expression[i + 1] : "";

    auto lastToken = exp.tokens.length ? exp.tokens[$-1] : null;

    if (inFunction)
    {
      if (token == ")")
      {
        currentToken.tokens ~= token;
        currentToken.isFunctionCall = true;

        if (next == "(" && !parsedTemplate)
        {
          parsedTemplate = true;
          i++;
          currentToken.tokens ~= next;
        }
        else if (next == "(" && parsedTemplate)
        {
          if (queueErrors) line.queueError(source, "Invalid function call.");
          else line.printError(source, "Invalid function call.");
          return null;
        }
        else
        {
          inFunction = false;

          exp.tokens ~= currentToken;

          currentToken = new ExpressionToken;
        }
      }
      else
      {
        currentToken.tokens ~= token;
      }
    }
    else if (token.isQualifiedSymbol && !token.isQualifiedExpressionSymbol(exp.isMathematicalExpression))
    {
      if (queueErrors) line.queueError(source, "Illegal symbol found in expression. Symbol: '%s'", token);
      else line.printError(source, "Illegal symbol found in expression. Symbol: '%s'", token);
      return null;
    }
    else if (!token.isQualifiedSymbol  && next == "(")
    {
      if (last && last.length && !last.isQualifiedSymbol && token == "(")
      {
        if (queueErrors) line.queueError(source, "Missing operator from expression. Current token: '%s', last token: '%s'", token, last ? last : "");
        else line.printError(source, "Missing operator from expression. Current token: '%s', last token: '%s'", token, last ? last : "");
        return null;
      }

      if (last && last.length && !last.isQualifiedExpressionSymbol(exp.isMathematicalExpression))
      {
        if (queueErrors) line.queueError(source, "Illegal symbol found in expression. Symbol: '%s'", last ? last : "");
        else line.printError(source, "Illegal symbol found in expression. Symbol: '%s'", last ? last : "");
        return null;
      }

      if (currentToken.tokens && currentToken.tokens.length)
      {
        exp.tokens ~= currentToken;
      }

      currentToken = new ExpressionToken;

      currentToken.tokens ~= token;

      parsedTemplate = false;
      inFunction = true;
      continue;
    }
    else if (last && last.length && !last.isQualifiedSymbol && token == "(" && currentToken.tokens && currentToken.tokens.length)
    {
      if (queueErrors) line.queueError(source, "Missing operator from expression. Current token: '%s', last token: '%s', expression part: %s", token, last ? last : "", currentToken.tokens);
      else line.printError(source, "Missing operator from expression. Current token: '%s', last token: '%s', expression part: %s", token, last ? last : "", currentToken.tokens);
      return null;
    }
    else if ((last && last.length && last.isQualifiedSymbol && !last.isQualifiedExpressionSymbol(exp.isMathematicalExpression)) && token == "(" && currentToken.tokens && currentToken.tokens.length)
    {
      if (queueErrors) line.queueError(source, "Illegal symbol found in expression. Symbol: '%s', current token: '%s', expression parts: %s", last ? last : "", token, currentToken.tokens);
      else line.printError(source, "Illegal symbol found in expression. Symbol: '%s', current token: '%s', expression parts: %s", last ? last : "", token, currentToken.tokens);
      return null;
    }
    else if (token == "(" || token == ")")
    {
      if (token == "(")
      {
        open++;
      }
      else if (token == ")")
      {
        closed++;
      }

      currentToken.tokens ~= token;

      if (currentToken.tokens && currentToken.tokens.length)
      {
        exp.tokens ~= currentToken;

        currentToken = new ExpressionToken;
      }
    }
    else
    {
      currentToken.tokens ~= token;
    }
  }

  if (open != closed)
  {
    if (queueErrors) line.queueError(source, "Missing '%s' from expression.", open > closed ? ")" : "(");
    else line.printError(source, "Missing '%s' from expression.", open > closed ? ")" : "(");
    return null;
  }

  if (currentToken.tokens && currentToken.tokens.length)
  {
    exp.tokens ~= currentToken;
  }

  string[] validationTokens = [];

  foreach (expToken; exp.tokens)
  {
    if (expToken.isFunctionCall)
    {
      auto functionCallExpression = parseFunctionCallExpression(expToken.tokens, source, line, true); // skipEndCheck

      if (functionCallExpression)
      {
        expToken.functionCallExpression = functionCallExpression;
        validationTokens ~= "__FN_" ~ expToken.functionCallExpression.identifier ~  "__"; // Because we just need to test the expression is valid.
      }
      else
      {
        if (!queueErrors)
        {
          printQueuedErrors();
        }

        return null;
      }
    }
    else
    {
      foreach (token; expToken.tokens)
      {
        validationTokens ~= token;
      }
    }
  }

  if (!validationTokens || !validationTokens.length)
  {
    if (queueErrors) line.queueError(source, "Failed to parse expression. Tokens: %s", expression);
    else line.printError(source, "Failed to parse expression. Tokens: %s", expression);
    return null;
  }

  auto r = shuntingYardCalculation(validationTokens, source, line, exp.isMathematicalExpression, queueErrors);

  if (!r || !r.length)
  {
    if (queueErrors) line.queueError(source, "Failed to parse expression.");
    else line.printError(source, "Failed to parse expression.");
    return null;
  }

  return exp;
}

/**
* Checks whether a set of tokens is a mathematical expression or not (boolean expression).
* Params:
*   tokens = The set of tokens to validate.
* Returns:
*   True if the set of tokens are a part of a mathematical expression, false otherwise.
*/
bool isMathematicalExpression(string[] tokens)
{
  const mathSymbols = ["+", "-", "*", "/", "%", "^", "<<", ">>", "|"/*, "~"*/, "&"];
  const booleanSymbols = ["||", "&&"/*, "~"*/, ">", ">=", "<=", "<", "!=", "!", "!!", "=="];
  // ~ is valid for both mathematical and boolean expressions.

  foreach (token; tokens)
  {
    import std.algorithm : canFind;

    foreach (booleanSymbol; booleanSymbols)
    {
      if (token == booleanSymbol)
      {
        return false;
      }
    }

    foreach (mathSymbol; mathSymbols)
    {
      if (token == mathSymbol)
      {
        return true;
      }
    }
  }

  return false;
}
