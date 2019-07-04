/**
* Module for parsing aliases.
*
* License: MIT (https://github.com/Royal Programming Language/bl/blob/master/LICENSE)
*
* Copyright 2019 © Royal Programming Language - All Rights Reserved.
*/
module parser.aliasparser;

import core.tokenizer;
import core.errors;
import core.debugging;

import parser.meta;
import parser.tools;

import parser.expressionparser;
import parser.typeinformationparser;
import parser.attributeparser;
import parser.moduleparser;

/// An alias object.
class Alias
{
  /// The name of the alias.
  string name;
  /// The expression for the alias.
  Expression expression;
  /// The alias type information.
  TypeInformation aliasTypeInformation;
  /// The parameters of the alias.
  string[] parameters;
  /// The line of the alias.
  size_t line;
  /// Attributes tied to this alias declaration.
  AttributeObject[] attributes;
}

/**
* Parses an alias statement.
* Params:
*   token = The token of the alias statement.
*   source = The source parsed from.
* Returns:
*   The alias created.
*/
Alias parseAlias(Token token, string source)
{
  auto line = token.retrieveLine;

  auto attributes = getAttributes();

  printDebug("Parsing alias: %s", token.statement);

  if (!token.statement || token.statement.length < 4)
  {
    line.printError(source, "Missing name argument for alias statement.");
    return null;
  }

  if (token.statement[$-1] != ";")
  {
    line.printError(source, "Expected '%s' but found '%s' for alias statement.", ";", token.statement[$-1]);
    return null;
  }

  auto statement = token.statement[1 .. $];

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
    line.printError(source, "Missing left-hand declaration for alias.");
    return null;
  }

  if (operator && (!rightHand || !rightHand.length))
  {
    line.printError(source, "Missing right-hand declaration for alias.");
    return null;
  }

  import std.array : join,split;
  import std.string : strip;

  auto aliasObject = new Alias;
  aliasObject.name = leftHand[0];

  if (leftHand.length > 1)
  {
    leftHand = leftHand[1 .. $];

    if (leftHand.length < 3)
    {
      line.printError(source, "Missing parameters for alias.");
      return null;
    }

    if (leftHand[0] != "(")
    {
      line.printError(source, "Expected '%s' but found '%s'", "(", leftHand[0]);
      return null;
    }

    if (leftHand[$-1] != ")")
    {
      line.printError(source, "Expected '%s' but found '%s'", ")", leftHand[$-1]);
      return null;
    }

    auto params = leftHand[1 .. $-1].join("").split(",");

    foreach (param; params)
    {
      if (!param || !param.strip.length)
      {
        line.printError(source, "Empty alias parameter found.");
        return null;
      }

      aliasObject.parameters ~= param;
    }
  }

  if (rightHand && rightHand.length)
  {
    auto rightHandExpression = parseRightHandExpression(rightHand, source, line, true);

    if (!rightHandExpression || (!rightHandExpression.tokens && !rightHandExpression.arrayExpression))
    {
      clearQueuedErrors();

      auto typeInformation = parseTypeInformation(rightHand.join(""), source, line, true);

      if (!typeInformation)
      {
        clearQueuedErrors();

        line.printError(source, "Failed to parse right-hand declaration.");
        return null;
      }

      aliasObject.aliasTypeInformation = typeInformation;
    }
    else
    {
      aliasObject.expression = rightHandExpression;
    }
  }

  aliasObject.attributes = attributes;

  return aliasObject;
}
