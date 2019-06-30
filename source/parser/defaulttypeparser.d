/**
* Module for parsing default values. TODO: Handle this from semantics since it didn't really work during the parsing phase. I did an oopsie thinking that would work.
*
* License: MIT (https://github.com/Royal Programming Language/bl/blob/master/LICENSE)
*
* Copyright 2019 © Royal Programming Language - All Rights Reserved.
*/
module parser.defaulttypeparser;

import core.tokenizer;
import core.errors;
import core.debugging;

import parser.meta;
import parser.tools;

import parser.expressionparser;

enum DefaultType
{
  unknownType,
  emptyArray,
  int32Array,
  uint32Array,
  int64Array,
  uint64Array,
  doubleArray,
  stringArray,
  charArray,
  charType,
  stringType,
  structType,
  functionReturnType,
  int32Type,
  uint32Type,
  int64Type,
  uint64Type,
  doubleType,
  boolType
}

DefaultType[] parseDefaultType(Expression expression)
{
  // TODO: Parse this during semantics instead because we actually need to retrieve variable types etc.
  if (expression.arrayExpression)
  {
    auto array = expression.arrayExpression;

    if (!array.values || !array.values.length)
    {
      return [DefaultType.emptyArray];
    }

    auto firstValue = array.values[0];

    if (array.isAssociativeArray)
    {
      return [parseDefaultType(firstValue.values[0]), parseDefaultType(firstValue.values[1])];
    }
    else
    {
      switch (parseDefaultType(firstValue.values[0]))
      {
        case DefaultType.int32Type: return [DefaultType.int32Array];
        case DefaultType.uint32Type: return [DefaultType.uint32Array];
        case DefaultType.int64Type: return [DefaultType.int64Array];
        case DefaultType.uint64Type: return [DefaultType.uint64Array];
        case DefaultType.doubleType: return [DefaultType.doubleArray];
        case DefaultType.stringType: return [DefaultType.stringArray];
        case DefaultType.charType: return [DefaultType.charArray];

        default: return [DefaultType.unknownType];
      }
    }
  }

  if (!expression.tokens)
  {
    return [DefaultType.unknownType];
  }

  if (expression.tokens.length == 1 && expression.tokens[0].isFunctionCall)
  {
    // TODO: Get the actual return type
    return [DefaultType.functionReturnType];
  }

  bool[DefaultType] hash;

  DefaultType firstType = DefaultType.unknownType;

  foreach (expToken; expression.tokens)
  {
    if (expToken.tokens && expToken.tokens.length)
    {
      foreach (token; expToken.tokens)
      {
        if (!token.isQualifiedSymbol)
        {
          auto defaultType = parseDefaultType(token);

          if (firstType == DefaultType.unknownType)
          {
            firstType = defaultType;
          }

          // TODO: Find the return type of each function token etc.
        }
      }
    }
  }

  if (hash)
  {
    if (hash.length > 2)
    {
      return [DefaultType.unknownType];
    }
    else
    {
      return [hash.keys[0]];
    }
  }

  return [DefaultType.unknownType];
}

DefaultType parseDefaultType(string value)
{
  import std.conv : to;

  if (value[0] == '"' && value[$-1] == '"')
  {
    return DefaultType.stringType;
  }
  else if (value[0] == '\'' && value[$-1] == '\'')
  {
    return DefaultType.charType;
  }
  else if (value == "true" || value == "false")
  {
    return DefaultType.boolType;
  }
  else if (value[0] == '-' && isNumberValue!(true,false)(value)) // signed int
  {
    auto num = to!long(value);

    if (num <= int.max)
    {
      return DefaultType.int32Type;
    }

    return DefaultType.int64Type;
  }
  else if (isNumberValue!(false,false)(value)) // int32 / uint32 / int64 / uint64
  {
    auto num = to!ulong(value);

    if (num <= cast(ulong)int.max)
    {
      return DefaultType.int32Type;
    }

    if (num <= cast(ulong)uint.max)
    {
      return DefaultType.uint32Type;
    }

    if (num <= cast(ulong)long.max)
    {
      return DefaultType.int64Type;
    }

    return DefaultType.uint64Type;
  }
  else if (isNumberValue!(true,true)(value)) // floating point
  {
    return DefaultType.doubleType;
  }

  return DefaultType.unknownType;
}
