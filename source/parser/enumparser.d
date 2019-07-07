/**
* Module for parsing enums.
*
* License: MIT (https://github.com/Royal Programming Language/bl/blob/master/LICENSE)
*
* Copyright 2019 © Royal Programming Language - All Rights Reserved.
*/
module parser.enumparser;

import core.tokenizer;
import core.errors;
import core.debugging;

import parser.meta;
import parser.tools;

import parser.variableparser;
import parser.typeinformationparser;
import parser.attributeparser;
import parser.moduleparser;

/// Enum enum.
class Enum
{
  /// The name of the enum.
  string name;
  /// The enum type information.
  TypeInformation enumTypeInformation;
  /// Attributes tied to this enum declaration.
  AttributeObject[] attributes;
  /// The members of the enum.
  Variable[] members;
  /// The member of the enum.
  Variable member;
}

/**
* Parses an enum.
* Params:
*   token = The token.
*   source = The source.
* Returns:
*   An enum object if parsed correctly, null otherwise.
*/
Enum parseEnum(Token token, string source)
{
  size_t line = token.retrieveLine;

  auto attributes = getAttributes();

  if (!token.statement || !token.statement.length)
  {
    line.printError(source, "Missing enum declaration.");
    return null;
  }

  import std.algorithm : map;
  import std.array : array;

  auto statement = token.statement.map!(s => s.s).array;

  auto enumObject = new Enum;

  if (statement[$-1] != ";")
  {
    if (token.tokens && token.tokens.length >= 2)
    {
      auto firstToken = token.tokens[0];
      auto lastToken = token.tokens[$-1];

      auto firstStatement = firstToken.statement;
      auto lastStatement = lastToken.statement;

      auto firstLine = firstToken.retrieveLine;
      auto lastLine = lastToken.retrieveLine;

      if (!firstStatement || firstStatement.length != 1)
      {
        firstLine.printError(source, "Missing start scope declaration for %s", "enum");
        return null;
      }

      if (firstStatement[0] != "{")
      {
        firstLine.printError(source, "Expected '%s' but found '%s'", "{", firstStatement[0]);
        return null;
      }

      if (!lastStatement || lastStatement.length != 1)
      {
        lastLine.printError(source, "Missing end scope declaration for %s", "enum");
        return null;
      }

      if (lastStatement[0] != "}")
      {
        lastLine.printError(source, "Expected '%s' but found '%s'", "}", lastStatement[0]);
        return null;
      }

      string name;
      string type;
      bool findType;

      foreach (entry; statement[1 .. $])
      {
        if (entry == ":")
        {
          findType = true;
        }
        else if (!findType && (name && name.length))
        {
          line.printError(source, "Multiple name declaration for enum: %s", entry);
          return null;
        }
        else if (findType)
        {
          type ~= entry;
        }
        else
        {
          name ~= entry;
        }
      }

      if (!name || !name.length)
      {
        line.printError(source, "Missing name declaration for enum.");
        return null;
      }

      enumObject.name = name;

      if (findType && (!type || !type.length))
      {
        line.printError(source, "Missing type declaration for enum.");
        return null;
      }
      else if (type && type.length)
      {
        enumObject.enumTypeInformation = parseTypeInformation(type, source, line, false);
      }

      foreach (enumToken; token.tokens[1 .. $-1])
      {
        auto enumStatement = enumToken.statement.map!(s => s.s).array;
        size_t tokenLine = enumToken.retrieveLine;

        if (enumStatement && enumStatement.length)
        {
          enumStatement = ["var"] ~ enumStatement;

          auto variable = parseVariable(token, enumStatement, source);

          if (variable)
          {
            enumObject.members ~= variable;
          }
          else
          {
            tokenLine.printError(source, "Invalid variable declaration: %s", enumToken.statement);
            return null;
          }
        }
      }
    }
    else
    {
      line.printError(source, "Expected '%s' but found '%s'", ";", statement[$-1]);
      return null;
    }
  }
  else
  {
    statement[0] = "var";

    auto variable = parseVariable(token, statement, source);

    if (variable)
    {
      enumObject.member = variable;
    }
    else
    {
      line.printError(source, "Invalid variable declaration: %s", token.statement);
      return null;
    }
  }

  enumObject.attributes = attributes;

  return enumObject;
}
