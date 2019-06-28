module parser.returnparser;

import core.tokenizer;
import core.errors;
import core.debugging;

import parser.meta;
import parser.tools;

import parser.expressionparser;

/// A return expression.
class ReturnExpression
{
  /// The expression of the return expression.
  Expression expression;
  /// The line of the return expression.
  size_t line;
}

/**
* Parses a return expression.
* Params:
*   token = The token to parse.
*   source = The source parsed from.
*   line = The line parsed from.
* Returns:
*   The function call expression created.
*/
ReturnExpression parseReturnExpression(Token token, string source, size_t line)
{
  import std.algorithm : map;
  import std.array : array;

  if (!token.statement || token.statement.length < 2)
  {
    line.queueError(source, "Missing return statement arguments.");
    return null;
  }

  if (token.statement[$-1] != ";")
  {
    line.queueError(source, "Expected '%s' but found '%s'", ";", token.statement[$-1]);
    return null;
  }

  auto returnExpression = new ReturnExpression;

  auto rightHandExpression = parseRightHandExpression(token.statement[1 .. $].map!(s => s.s).array, source, line, false);

  if (!rightHandExpression || (!rightHandExpression.tokens && !rightHandExpression.arrayExpression))
  {
    if (!hasQueuedErrors)
    {
      line.queueError(source, "Failed to parse right-hand expression.");
    }
    return null;
  }

  returnExpression.expression = rightHandExpression;

  returnExpression.line = line;

  return returnExpression;
}
