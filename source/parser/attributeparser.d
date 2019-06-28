/**
* Module for parsing attributes.
*
* License: MIT (https://github.com/bausslang/bl/blob/master/LICENSE)
*
* Copyright 2019 © bausslang - All Rights Reserved.
*/
module parser.attributeparser;

import core.tokenizer;
import core.errors;
import core.debugging;

import parser.meta;
import parser.tools;

import parser.functioncallparser;

/// An attribute object.
class AttributeObject
{
  /// The identifier;
  string identifier;
  /// The ctor call.
  FunctionCallExpression ctorCall;
}

/**
* Parses an attribute.
* Params:
*   token = The token of the attribute.
*   source = The source of the token.
* Returns:
*   The attribute object parsed, if parsed correct. Null otherwise.
*/
AttributeObject parseAttribute(Token token, string source)
{
  size_t line = token.retrieveLine;

  if (!token.statement || !token.statement.length)
  {
    line.queueError(source, "Missing attribute declaration.");
    return null;
  }

  if (token.statement[$-1] != ":")
  {
    line.queueError(source, "Expected '%s' but found '%s'", ":", token.statement[$-1]);
    return null;
  }

  auto attr = new AttributeObject;

  if (token.statement[0] == "@")
  {
    auto ctorCall = parseFunctionCallExpression(token.statement[1 .. $-1], source, line, true);

    if (ctorCall)
    {
      attr.identifier = ctorCall.identifier;
      attr.ctorCall = ctorCall;
    }
    else
    {
      if (!printQueuedErrors())
      {
        line.printError(source, "Invalid attribute declaration: %s", token.statement);
        return null;
      }
    }
  }
  else if (token.statement.length < 2)
  {
    line.printError(source, "Missing attribute declaration.");
    return null;
  }
  else if (token.statement.length > 3)
  {
    line.printError(source, "Invalid attribute declaration.");
    return null;
  }
  else
  {
    attr.identifier = token.statement[0];
  }

  return attr;
}
