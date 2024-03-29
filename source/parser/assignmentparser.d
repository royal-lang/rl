/**
* Module for parsing assignments.
*
* License: MIT (https://github.com/Royal Programming Language/bl/blob/master/LICENSE)
*
* Copyright 2019 © Royal Programming Language - All Rights Reserved.
*/
module parser.assignmentparser;

import core.tokenizer;
import core.errors;
import core.debugging;

import parser.meta;
import parser.tools;

import parser.expressionparser;

/// An assignment expression.
class AssignmentExpression
{
  /// The left-hand operation.
  string[] leftHand;
  /// The operator.
  string operator;
  /// The right-hand operation.
  string[] rightHand;
  /// The line of the assignment expression.
  size_t line;
  /// The right hand expression of the assignment.
  Expression rightHandExpression;
}

/**
* Parses an assignment expression.
* Params:
*   token = The token of the assignment.
*   source = The source parsed from.
*   line = The line parsed from.
* Returns:
*   The assignment expression created.
*/
AssignmentExpression parseAssignmentExpression(Token token, string source, size_t line)
{
  return parseAssignmentExpression(token, token.statement, source, line);
}

/**
* Parses an assignment expression.
* Params:
*   token = The token of the assignment.
*   statement = The statement of the token.
*   source = The source parsed from.
*   line = The line parsed from.
* Returns:
*   The assignment expression created.
*/
AssignmentExpression parseAssignmentExpression(Token token, STRING[] statement, string source, size_t line)
{
  import std.array : array;
  import std.algorithm : map;

  return parseAssignmentExpression(token, statement.map!(s => s.s).array, source, line);
}

/**
* Parses an assignment expression.
* Params:
*   token = The token of the assignment.
*   statement = The statement of the token.
*   source = The source parsed from.
*   line = The line parsed from.
* Returns:
*   The assignment expression created.
*/
AssignmentExpression parseAssignmentExpression(Token token, string[] statement, string source, size_t line)
{
  import std.algorithm : countUntil;

  if (statement.countUntil("(") == -1 || statement.countUntil(")") == -1)
  {
    clearQueuedErrors();
  }

  printDebug("Parsing assignment expression or increment/decrement expression. Tokens: %s", statement);

  string[] leftHand = [];
  string operator = "";
  string[] rightHand = [];

  foreach (entry; statement)
  {
    if (!rightHand.length && (!operator || !operator.length) && entry.isOperatorSymbol)
    {
      operator = entry;
    }
    else if (operator && operator.length)
    {
      rightHand ~= entry;
    }
    else if (!operator || !operator.length)
    {
      leftHand ~= entry;
    }
  }

  auto exp = new AssignmentExpression;

  if (operator == "++" || operator == "--")
  {
    if (!rightHand || rightHand.length != 1)
    {
      line.queueError(source, "Missing '%s' from the expression.", ";");
      return null;
    }

    if (rightHand[0] != ";")
    {
      line.queueError(source, "Expected '%s' but found '%s'", ";", rightHand[0]);
      return null;
    }

    if (!leftHand || !leftHand.length)
    {
      line.queueError(source, "Missing left-hand operation from expression.");
      return null;
    }

    exp.leftHand = leftHand.dup;
    exp.operator = operator;
    exp.rightHand = rightHand.dup;
    exp.line = line;

    return exp;
  }

  if (!leftHand || !leftHand.length)
  {
    line.queueError(source, "Missing left-hand operation from expression.");
    return null;
  }

  if (leftHand.length > 1)
  {
    line.queueError(source, "Too many left-hand operands.");
    return null;
  }

  if (!operator || !operator.length)
  {
    line.queueError(source, "Missing operator from expression.");
    return null;
  }

  if (!rightHand ||  rightHand.length < 2)
  {
    line.queueError(source, "Missing right-hand operation from expression.");
    return null;
  }

  if (rightHand[$-1] != ";")
  {
    line.queueError(source, "Expected '%s' but found '%s'", ";", rightHand[$-1]);
    return null;
  }

  exp.leftHand = leftHand.dup;
  exp.operator = operator;
  exp.rightHand = rightHand.dup;
  exp.line = line;

  if (exp.rightHand && exp.rightHand.length)
  {
    auto rightHandExpression = parseRightHandExpression(exp.rightHand, source, line, true);

    if (!rightHandExpression || (!rightHandExpression.tokens && !rightHandExpression.arrayExpression))
    {
      if (!hasQueuedErrors)
      {
        line.queueError(source, "Failed to parse right-hand expression.");
      }
      return null;
    }

    exp.rightHandExpression = rightHandExpression;
  }

  clearQueuedErrors(); // clean up errors

  printDebug("Finished parsing assignment expression or increment/decrement expression.");

  return exp;
}
