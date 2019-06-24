/**
* Module for the parser.
*
* License: MIT (https://github.com/bausslang/bl/blob/master/LICENSE)
*
* Copyright 2019 © bausslang - All Rights Reserved.
*/
module core.parser;

import std.stdio : writefln, writeln, readln;

import core.tokenizer;
import core.errors;

/// Enumeration of keywords (Types are not included.)
enum Keyword : string
{
  /// The module keyword.
  MODULE = "module",
  /// The import keyword.
  IMPORT = "import",
  /// The include keyword.
  INCLUDE = "include",
  /// The internal keyword.
  INTERNAL = "internal",
  /// The alias keyword.
  ALIAS = "alias",
  /// The this keyword.
  THIS = "this",
  /// The static keyword.
  STATIC = "static",
  /// The shared keyword.
  SHARED = "shared",
  /// The function keyword.
  FUNCTION = "fn",
  /// The ref keyword.
  REF = "ref",
  /// The struct keyword.
  STRUCT = "struct",
  /// The interface keyword.
  INTERFACE = "interface",
  /// The template keyword.
  TEMPLATE = "template",
  /// The traits keyword.
  TRAITS = "traits",
  /// The if keyword.
  IF = "if",
  /// The else keyword.
  ELSE = "else",
  /// The var keyword.
  VARIABLE = "var",
  /// The public keyword.
  PUBLIC = "public",
  /// The private keyword.
  PRIVATE = "private",
  /// The package keyword.
  PACKAGE = "package",
  /// The protected keyword.
  PROTECTED = "protected"
}

/**
* Checks whether a string is a keyword or not.
* Params:
*   keyword = The string to check.
* Returns:
*   True if the string is a keyword, false otherwise.
*/
bool isKeyword(STRING keyword)
{
  return isKeyword(keyword.s);
}

/**
* Checks whether a string is a keyword or not.
* Params:
*   keyword = The string to check.
* Returns:
*   True if the string is a keyword, false otherwise.
*/
bool isKeyword(string keyword)
{
  switch (keyword)
  {
    case Keyword.MODULE:
    case Keyword.IMPORT:
    case Keyword.INCLUDE:
    case Keyword.INTERNAL:
    case Keyword.ALIAS:
    case Keyword.THIS:
    case Keyword.STATIC:
    case Keyword.SHARED:
    case Keyword.FUNCTION:
    case Keyword.REF:
    case Keyword.STRUCT:
    case Keyword.INTERFACE:
    case Keyword.TEMPLATE:
    case Keyword.TRAITS:
    case Keyword.IF:
    case Keyword.ELSE:
    case Keyword.VARIABLE:
    case Keyword.PUBLIC:
    case Keyword.PRIVATE:
    case Keyword.PACKAGE:
    case Keyword.PROTECTED:
      return true;

    default: return keyword.isStandardTypeName;
  }
}

/**
* Checks whether a string is the name of a standard type or not.
* Params:
*   typeName = The string to check.
* Returns:
*   True if the string is a standard type, false otherwise.
*/
bool isStandardTypeName(string typeName)
{
  return
    typeName == "bool" ||
    typeName == "byte" ||
    typeName == "ushort" ||
    typeName == "uint" ||
    typeName == "ulong" ||
    typeName == "ucent" ||
    typeName == "sbyte" ||
    typeName == "short" ||
    typeName == "int" ||
    typeName == "long" ||
    typeName == "cent" ||
    typeName == "float" ||
    typeName == "double" ||
    typeName == "decimal" ||
    typeName == "real" ||
    typeName == "void" ||
    typeName == "ptr" ||
    // Alias types
    typeName == "char" ||
    typeName == "schar" ||
    typeName == "string" ||
    typeName == "size_t" ||
    typeName == "ptrdiff_t" ||
    typeName == "object";
}

/// Enumeration of parser types. These types have parser functions associated with them.
enum ParserType
{
  /// An unknown parser type. Causes compilation error.
  UNKNOWN,
  /// An empty parser type. Will be ignored.
  EMPTY,
  /// The module parser type.
  MODULE,
  /// The import parser type.
  IMPORT,
  /// The include parser type.
  INCLUDE,
  /// The internal parser type.
  INTERNAL,
  /// The alias parser type.
  ALIAS,
  /// The this parser type.
  THIS,
  /// The static this parser type.
  STATIC_THIS,
  /// The function parser type.
  FUNCTION,
  /// The function parser type.
  STRUCT,
  /// The struct parser type.
  INTERFACE,
  /// The interface parser type.
  TEMPLATE,
  /// The traits parser type.
  TRAITS,
  /// The static if parser type.
  STATIC_IF,
  /// The static else parser type.
  STATIC_ELSE,
  /// The variable parser type.
  VARIABLE,
  /// The access modifier parser type.
  ACCESS_MODIFIER
}

/// Hash map of parser types.
private ParserType[string] parserTypes;

/// Static constructor of the parser module.
static this()
{
  parserTypes[Keyword.MODULE] = ParserType.MODULE;
  parserTypes[Keyword.IMPORT] = ParserType.IMPORT;
  parserTypes[Keyword.INCLUDE] = ParserType.INCLUDE;
  parserTypes[Keyword.INTERNAL] = ParserType.INTERNAL;
  parserTypes[Keyword.ALIAS] = ParserType.ALIAS;
  parserTypes[Keyword.THIS] = ParserType.THIS;
  parserTypes[Keyword.STATIC ~ Keyword.THIS] = ParserType.STATIC_THIS;
  parserTypes[Keyword.SHARED ~ Keyword.STATIC ~ Keyword.THIS] = ParserType.STATIC_THIS;
  parserTypes[Keyword.FUNCTION] = ParserType.FUNCTION;
  parserTypes[Keyword.STRUCT] = ParserType.STRUCT;
  parserTypes[Keyword.REF ~ Keyword.STRUCT] = ParserType.STRUCT;
  parserTypes[Keyword.INTERFACE] = ParserType.INTERFACE;
  parserTypes[Keyword.TEMPLATE] = ParserType.TEMPLATE;
  parserTypes[Keyword.TRAITS] = ParserType.TRAITS;
  parserTypes[Keyword.STATIC ~ Keyword.IF] = ParserType.STATIC_IF;
  parserTypes[Keyword.STATIC ~ Keyword.ELSE] = ParserType.STATIC_ELSE;
  parserTypes[Keyword.VARIABLE] = ParserType.VARIABLE;
  parserTypes[Keyword.PUBLIC] = ParserType.ACCESS_MODIFIER;
  parserTypes[Keyword.PRIVATE] = ParserType.ACCESS_MODIFIER;
  parserTypes[Keyword.PACKAGE] = ParserType.ACCESS_MODIFIER;
  parserTypes[Keyword.PROTECTED] = ParserType.ACCESS_MODIFIER;
}

/// A module object.
class ModuleObject
{
  /// The name of the module.
  string name;
  /// The imports of the module.
  ImportObject[] imports;
  /// The functions of the module.
  FunctionObject[] functions;
}

/**
* Parses a module.
* Params:
*   moduleToken = The root token of the module. (The module members must be tokens of the root token.)
*   source = The source parsed from.
* Returns:
*   The module object created.
*/
ModuleObject parseModule(Token moduleToken, string source)
{
  auto moduleObject = new ModuleObject;

  size_t line = 0;

  foreach (token; moduleToken.tokens)
  {
    line = token.retrieveLine;

    switch (token.getParserType)
    {
      case ParserType.MODULE:
        if (moduleObject.name)
        {
          line.printError(source, "Only one module statement is allowed per module.");
        }
        else if (!token.statement || token.statement.length < 3)
        {
          line.printError(source, "Missing name argument for module statement.");
        }
        else
        {
          auto result = "";

          foreach (entry; token.statement[1 .. $-1])
          {
            if (entry.isKeyword)
            {
              line.printError(source, "Found keyword when expected name entry: %s", entry);
              break;
            }
            else
            {
              result ~= entry;
            }
          }

          moduleObject.name = result;
        }
        break;

      case ParserType.IMPORT:
        auto importObject = parseImport(token, source, line);

        if (importObject)
        {
          moduleObject.imports ~= importObject;
        }
        break;

      case ParserType.FUNCTION:
        auto functionObject = parseFunction(token, source);

        if (functionObject)
        {
          moduleObject.functions ~= functionObject;
        }
        break;

      case ParserType.EMPTY: break;

      default:
        line.printError(source, "Invalid declaration for modules: %s", token.statement && token.statement.length ? token.statement[0] : "");
        break;
    }
  }

  return moduleObject;
}

/// An import object.
class ImportObject
{
  /// The module path of the import.
  string[] modulePath;
}

/**
* Parses an import statement.
* Params:
*   token = The token of the import statement.
*   source = The source parsed from.
*   line = The current line parsed from.
* Returns:
*   The import object created.
*/
ImportObject parseImport(Token token, string source, size_t line)
{
  if (!token.statement || token.statement.length < 3)
  {
    line.printError(source, "Missing name argument for import statement.");
    return null;
  }

  if (token.statement[$-1] != ";")
  {
    line.printError(source, "Expected '%s' import statement.", ";");
    return null;
  }

  auto importObject = new ImportObject;

  auto result = "";

  foreach (entry; token.statement[1 .. $-1])
  {
    if (entry.isKeyword)
    {
      line.printError(source, "Found keyword when expected name entry: %s", entry);
      return null;
    }
    else
    {
      importObject.modulePath ~= entry;
    }
  }

  if (!importObject.modulePath || !importObject.modulePath.length)
  {
    line.printError(source, "Missing name argument for import statement.");
    return null;
  }

  return importObject;
}

/// A function object.
class FunctionObject
{
  /// The name of the function.
  string name;
  /// The definition arguments of the function such as return type etc.
  string[] definitionArguments;
  /// The template parameters of the function.
  string[] templateParameters;
  /// The parameters of the function.
  string[] parameters;
  /// The scopes of the function.
  ScopeObject[] scopes;
}

/**
* Parses a function.
* Params:
*   token = The token of the function.
*   source = The source parsed from.
* Returns:
*   The function object created.
*/
FunctionObject parseFunction(Token functionToken, string source)
{
  auto functionObject = new FunctionObject;

  size_t line = functionToken.retrieveLine;

  if (!functionToken.statement || functionToken.statement.length < 4)
  {
    line.printError(source, "Invalid function definition.");
    return null;
  }

  string[] beforeParameters = [];
  string[] parameters1 = [];
  string[] parameters2 = [];
  bool emptyParameters = false;

  size_t statementCollection = 0;
  size_t endedCollection = 0;

  bool canDeclareParameters = true;

  foreach (entry; functionToken.statement[1 .. $])
  {
    if (entry == "(" && canDeclareParameters)
    {
      canDeclareParameters = false;

      if (statementCollection == 1)
      {
        statementCollection = 2;
      }
      else if (statementCollection == 0)
      {
        statementCollection = 1;
      }
      else
      {
        line.printError(source, "A function may only have a template parameter declaraction and a function parameter declaration.");
        return null;
      }
    }
    else if (entry == ")")
    {
      canDeclareParameters = true;
      endedCollection++;
    }
    else
    {
      if (statementCollection == 0) beforeParameters ~= entry;
      else if (statementCollection == 1) parameters1 ~= entry;
      else if (statementCollection == 2) parameters2 ~= entry;
    }
  }

  if (!beforeParameters || !beforeParameters.length)
  {
    line.printError(source, "Missing function name.");
    return null;
  }

  if (beforeParameters[$-1].isKeyword)
  {
    line.printError(source, "Found keyword when expected name entry: %s", beforeParameters[$-1]);
    return null;
  }

  functionObject.name = beforeParameters[$-1];

  if (statementCollection == 1 && endedCollection != 1)
  {
    line.printError(source, "Missing '%s' from function declarationz.", ")");
    return null;
  }

  if (statementCollection == 2 && endedCollection != 2)
  {
    line.printError(source, "Missing '%s' from function declarationx.", ")");
    return null;
  }

  if (beforeParameters.length > 1)
  {
    functionObject.definitionArguments = beforeParameters[0 .. $-1].dup;
  }

  if (statementCollection == 2)
  {
    functionObject.templateParameters = parameters1.dup;
    functionObject.parameters = parameters2.dup;
  }
  else
  {
    functionObject.parameters = parameters1.dup;
  }

  // TODO: Parse parameters ...

  if (statementCollection == 0)
  {
    line.printError(source, "Missing '%s' from function definition.", "(");
    return null;
  }

  // TODO: Parse defition arguments such as return type, access modifier etc.

  auto scopeObjects = parseScopes(functionToken, source, line, "function", functionObject.name);

  if (scopeObjects && scopeObjects.length)
  {
    functionObject.scopes = scopeObjects.dup;
  }

  return functionObject;
}

/// a scope object.
class ScopeObject
{
  // Temp ...
  string[][] temp;
}

/**
* Parses scopes.
* Params:
*   token = The scope token.
*   source = The source parsed from.
*   line = The line parsed from.
*   scopeName = The name of the scope.
*   sourceIdentifier = The identifier of the source. Ex. a function name.
* Returns:
*   The scope objects created.
*/
ScopeObject[] parseScopes(Token scopeToken, string source, size_t line, string scopeName, string sourceIdentifier)
{
  if (!scopeToken.tokens || scopeToken.tokens.length < 2)
  {
    line.printError(source, "Missing %s body.", scopeName);
    return null;
  }

  auto firstToken = scopeToken.tokens[0];
  auto lastToken = scopeToken.tokens[$-1];

  auto firstStatement = firstToken.statement;
  auto lastStatement = lastToken.statement;

  auto firstLine = firstToken.retrieveLine;
  auto lastLine = lastToken.retrieveLine;

  if (!firstStatement || firstStatement.length != 1)
  {
    firstLine.printError(source, "Missing start scope declaration for %s: %s", scopeName, sourceIdentifier);
    return null;
  }

  if (firstStatement[0] != "{")
  {
    firstLine.printError(source, "Expected '%s' but found '%s'", "{", firstStatement[0]);
    return null;
  }

  if (!lastStatement || lastStatement.length != 1)
  {
    lastLine.printError(source, "Missing end scope declaration for %s: %s", scopeName, sourceIdentifier);
    return null;
  }

  if (lastStatement[0] != "}")
  {
    lastLine.printError(source, "Expected '%s' but found '%s'", "}", lastStatement[0]);
    return null;
  }

  ScopeObject[] scopeObjects = [];

  auto scopeObject = new ScopeObject;
  scopeObjects ~= scopeObject;

  foreach (token; scopeToken.tokens[1 .. $-1])
  {
    // TODO: parse ...

    import std.algorithm : map;
    import std.array : array;

    if (token.statement && token.statement.length) scopeObject.temp ~= token.statement.map!(s => s.s).array;
  }

  return scopeObjects;
}

ParserType getParserType(Token token)
{
  if (!token.statement || !token.statement.length)
  {
    return ParserType.EMPTY;
  }

  auto keyword = token.statement[0];
  auto nextKeyword = token.statement.length > 1 ? token.statement[1] : null;
  auto nextNextKeyword = token.statement.length > 2 ? token.statement[2] : null;

  if (!parserTypes || !parserTypes.length)
  {
    return ParserType.UNKNOWN;
  }

  if
  (
    (keyword == Keyword.STATIC && nextKeyword == Keyword.THIS) ||
    (keyword == Keyword.REF && nextKeyword == Keyword.STRUCT) ||
    (keyword == Keyword.STATIC && nextKeyword == Keyword.IF) ||
    (keyword == Keyword.STATIC && nextKeyword == Keyword.ELSE)
  )
  {
    keyword = keyword ~ nextKeyword;
  }

  if (keyword == Keyword.SHARED && nextKeyword == Keyword.STATIC && nextNextKeyword == Keyword.THIS)
  {
    keyword = keyword ~ nextKeyword ~ nextNextKeyword;
  }

  return parserTypes.get(keyword, ParserType.UNKNOWN);
}

size_t retrieveLine(Token token)
{
  size_t line = 0;

  if (token.statement && token.statement.length)
  {
    foreach (statement; token.statement)
    {
      line = statement.line;
    }
  }

  return line;
}
