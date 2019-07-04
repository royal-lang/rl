/**
* Module for parsing variables.
*
* License: MIT (https://github.com/Royal Programming Language/bl/blob/master/LICENSE)
*
* Copyright 2019 © Royal Programming Language - All Rights Reserved.
*/
module parser.variableparser;

import core.tokenizer;
import core.errors;
import core.debugging;

import parser.meta;
import parser.tools;

import parser.expressionparser;
import parser.typeinformationparser;
import parser.attributeparser;
import parser.moduleparser;

/// A variable.
class Variable
{
  /// The name of the variable.
  string name;
  /// The variable type of the function.
  string type;
  /// The expression of the variable.
  Expression expression;
  /// The line of the variable.
  size_t line;
  /// The variable type information.
  TypeInformation variableTypeInformation;
  /// Attributes tied to this variable declaration.
  AttributeObject[] attributes;
}


/**
* Parses a variable.
* Params:
*   token = The token.
*   source = The source.
* Returns:
*   The variable if parsed correctly, null otherwise.
*/
Variable parseVariable(Token token, string source)
{
  return parseVariable(token, token.statement, source);
}

/**
* Parses a variable.
* Params:
*   token = The token.
*   statement = The statement of the token.
*   source = The source.
* Returns:
*   The variable if parsed correctly, null otherwise.
*/
Variable parseVariable(Token token, STRING[] statement, string source)
{
  import std.array : array;
  import std.algorithm : map;

  return parseVariable(token, statement.map!(s => s.s).array, source);
}

/**
* Parses a variable.
* Params:
*   token = The token.
*   tokenStatement = The statement of the token.
*   source = The source.
* Returns:
*   The variable if parsed correctly, null otherwise.
*/
Variable parseVariable(Token token, string[] tokenStatement, string source)
{
  auto attributes = getAttributes();

  size_t line = token.retrieveLine;

  if (!tokenStatement || !tokenStatement.length)
  {
    line.printError(source, "Missing variable declaration.");
    return null;
  }

  auto statement = tokenStatement[1 .. $];

  string[] leftHand = [];
  string operator;
  string[] rightHand = [];

  foreach (entry; statement)
  {
    if (!rightHand.length && (!operator || !operator.length) && entry == "=")
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

  if (operator && operator != "=")
  {
    line.printError(source, "Expected '%s' but found '%s'", "=", operator ? operator : "");
    return null;
  }

  if (!leftHand || !leftHand.length)
  {
    line.printError(source, "Missing left-hand declaration for variable.");
    return null;
  }

  if (operator && (!rightHand || !rightHand.length))
  {
    line.printError(source, "Missing right-hand declaration for variable.");
    return null;
  }

  auto variable = new Variable;

  if (leftHand.length == 1)
  {
    variable.name = leftHand[0];
  }
  else
  {
    import std.array : join;

    variable.type = leftHand[0 .. $-1].join("");
    variable.name = leftHand[$-1];

    variable.variableTypeInformation = parseTypeInformation(variable.type, source, line, false);
  }

  if (rightHand && rightHand.length)
  {
    auto rightHandExpression = parseRightHandExpression(rightHand, source, line, false);

    if (!rightHandExpression || (!rightHandExpression.tokens && !rightHandExpression.arrayExpression))
    {
      if (!hasQueuedErrors)
      {
        line.queueError(source, "Failed to parse right-hand expression.");
      }
      return null;
    }

    variable.expression = rightHandExpression;
  }

  variable.attributes = attributes;

  return variable;
}
