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
import core.debugging;

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
  PROTECTED = "protected",
  /// The return keyword.
  RETURN = "return",
  /// The break keyword.
  BREAK = "break",
  /// The continue keyword.
  CONTINUE = "continue",
  /// The default keyword.
  DEFAULT = "default",
  /// The switch keyword.
  SWITCH = "switch",
  /// The case keyword.
  CASE = "case",
  /// The for keyword.
  FOR = "for",
  /// The foreach keyword.
  FOREACH = "foreach",
  /// The while keyword.
  WHILE = "while",
  /// The do keyword.
  DO = "do"
}

/**
* Checks whether an identifier valid or not.
* Params:
*   identifier = The identifier to validate.
* Returns:
*   True if the identifier is valid.
*/
bool isValidIdentifier(string identifier, bool isNested = false)
{
  import std.conv : to;

  if (!identifier || !identifier.length)
  {
    return false;
  }

  if (!isNested)
  {
    printDebug("Validating identifier: %s", identifier);
  }

  auto result =
    !identifier.isKeyword &&
    !identifier.isOperatorSymbol &&
    !identifier.isQualifiedSymbol;

  if (identifier.length > 2)
  {
    result = result && isValidIdentifier(to!string(identifier[0 .. 2]), true);
  }
  else if (identifier.length > 1)
  {
    result = result && isValidIdentifier(to!string(identifier[0]), true);
  }

  return result;
}

/**
* Checks whether a given string is a qualified symbol.
* Params:
*   c = The string to check.
* Returns:
*   True if the string is a qualified symbol, false otherwise.
*/
bool isQualifiedSymbol(string symbol)
{
  switch (symbol)
  {
    case "||":
    case "&&":
    case "^^":
    case "!!":
    case "==":
    case ">":
    case ">=":
    case "<=":
    case "<":
    case "!=":
    case ".":
    case ",":
    case "(":
    case ")":
    case "[":
    case "]":
    case "{":
    case "}":
    case "+":
    case "-":
    case "*":
    case "/":
    case "=":
    case "?":
    case ":":
    case "%":
    case "!":
    case ";":
    case "^":
    case "~":
    case "&":
    case "#":
    case "$":
    case "@":
      return true;

    default: return false;
  }
}

/**
* Checks whether a symbol is a valid operator or not.
* Params:
*   symbol = The symbol to validate.
* Returns:
*   True if the symbol is a valid operator, false otherwise.
*/
bool isOperatorSymbol(string symbol)
{
  return
    symbol == "++" ||
    symbol == "--" ||
    symbol == "+=" ||
    symbol == "-=" ||
    symbol == "/=" ||
    symbol == "*=" ||
    symbol == "%=" ||
    symbol == "^=" ||
    symbol == ":=" ||
    symbol == "!=" ||
    symbol == "=" ||
    symbol == "~=" ||
    symbol == "|=";
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
    case Keyword.RETURN:
    case Keyword.BREAK:
    case Keyword.CONTINUE:
    case Keyword.DEFAULT:
    case Keyword.SWITCH:
    case Keyword.CASE:
    case Keyword.FOR:
    case Keyword.FOREACH:
    case Keyword.WHILE:
    case Keyword.DO:
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
  ACCESS_MODIFIER,
  /// The return parser type.
  RETURN
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
  parserTypes[Keyword.RETURN] = ParserType.RETURN;
}

/// A module object.
class ModuleObject
{
  /// The name of the module.
  string name;
  /// The imports of the module.
  ImportObject[] imports;
  // C header includes.
  IncludeObject[] includes;
  /// The internal functions of the module.
  FunctionObject[] internalFunctions;
  /// The functions of the module.
  FunctionObject[] functions;
  /// The line of the module object.
  size_t line;
  /// The source of the module object.
  string source;
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
  printDebug("Parsing module ...");

  auto moduleObject = new ModuleObject;
  moduleObject.source = source;

  size_t line = 0;

  foreach (token; moduleToken.tokens)
  {
    line = token.retrieveLine;

    switch (token.getParserType)
    {
      case ParserType.MODULE:
        printDebug("Parsing module statement: %s", token.statement);

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
          if (!token.statement || token.statement.length != 3)
          {
            line.printError(source, "Invalid amount of arguments for module statement.");
            break;
          }

          if (token.statement[$-1] != ";")
          {
            line.printError(source, "Expected '%s' module statement.", ";");
            break;
          }

          if (!token.statement[1].isValidIdentifier)
          {
            line.printError(source, "Invalid name for module statement.");
            break;
          }

          moduleObject.name = token.statement[1];
        }
        break;

      case ParserType.IMPORT:
        auto importObject = parseImport(token, source, line);

        if (importObject)
        {
          moduleObject.imports ~= importObject;
        }
        break;

      case ParserType.INCLUDE:
          auto includeObject = parseInclude(token, source, line);

          if (includeObject)
          {
            moduleObject.includes ~= includeObject;
          }
          break;

      case ParserType.FUNCTION:
        auto functionObject = parseFunction(token, source);

        if (functionObject)
        {
          moduleObject.functions ~= functionObject;
        }
        break;

      case ParserType.INTERNAL:
        auto internalFunctionObject = parseInternalFunction(token, source);

        if (internalFunctionObject)
        {
          moduleObject.internalFunctions ~= internalFunctionObject;
        }
        break;

      case ParserType.EMPTY: break;

      default:
        line.printError(source, "Invalid declaration for modules: %s", token.statement && token.statement.length ? token.statement[0] : "");
        break;
    }
  }

  printDebug("Finished parsing module ...");

  return moduleObject;
}

/// An import object.
class ImportObject
{
  /// The module path of the import.
  string modulePath;
  /// The members to import.
  string[] members;
  /// The line of the import object.
  size_t line;
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
  printDebug("Parsing import: %s", token.statement);

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

  string name;
  string[] members = [];
  bool subMembers = false;

  foreach (entry; token.statement[1 .. $-1])
  {
    if (!name || !name.length)
    {
      name = entry;
    }
    else if (subMembers)
    {
      members ~= entry;
    }
    else if (entry == ":" && !subMembers)
    {
      subMembers = true;
    }
    else
    {
      line.printError(source, "Invalid amount of arguments for import statement.");
    }
  }

  if (!name || !name.length)
  {
    line.printError(source, "Missing name for import statement.");
    return null;
  }

  if (!name.isValidIdentifier)
  {
    line.printError(source, "Invalid name for import statement.");
    return null;
  }

  auto importObject = new ImportObject;
  importObject.modulePath = name;
  importObject.members = members.dup;
  importObject.line = line;

  printDebug("Finished parsing import ...");

  return importObject;
}

/// An import object.
class IncludeObject
{
  /// The path of the header included.
  string headerPath;
  /// The line of the include object.
  size_t line;
}

/**
* Parses an include statement.
* Params:
*   token = The token of the include statement.
*   source = The source parsed from.
*   line = The current line parsed from.
* Returns:
*   The include object created.
*/
IncludeObject parseInclude(Token token, string source, size_t line)
{
  printDebug("Parsing include: %s", token.statement);

  if (!token.statement || token.statement.length != 3)
  {
    line.printError(source, "Missing path argument for include statement.");
    return null;
  }

  if (token.statement[$-1] != ";")
  {
    line.printError(source, "Expected '%s' include statement.", ";");
    return null;
  }

  string name = token.statement[1];

  if (!name || name.length < 3)
  {
    line.printError(source, "Missing path for include statement.");
    return null;
  }

  if (name[0] != '"' && name[$-1] != '"')
  {
    line.printError(source, "The path of the header file must be a string.");
    return null;
  }

  auto includeObject = new IncludeObject;
  includeObject.headerPath = name[1 .. $-1];
  includeObject.line = line;

  printDebug("Finished parsing include ...");

  return includeObject;
}

/// A function object.
class FunctionObject
{
  /// The name of the function.
  string name;
  /// The return type of the function.
  string returnType;
  /// The template parameters of the function.
  Parameter[] templateParameters;
  /// The parameters of the function.
  Parameter[] parameters;
  /// The scopes of the function.
  ScopeObject[] scopes;
  /// The line of the function object.
  size_t line;
}

/// A parameter.
class Parameter
{
  /// The type.
  string type;
  /// The name.
  string name;
  /// The line of the parameter.
  size_t line;
}

/**
* Parses an internal function.
* Params:
*   token = The token of the function.
*   source = The source parsed from.
* Returns:
*   The function object created.
*/
FunctionObject parseInternalFunction(Token functionToken, string source)
{
  printDebug("Parsing internal function: %s", functionToken.statement);

  size_t line = functionToken.retrieveLine;

  functionToken.statement = functionToken.statement[1 .. $];

  if (functionToken.statement[$-1] != ";")
  {
    line.printError(source, "Expected '%s' but found '%s'", ";", functionToken.statement[$-1]);
    return null;
  }

  return parseFunction(functionToken, source);
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
  printDebug("Parsing function: %s", functionToken.statement);

  import std.array : join;

  auto functionObject = new FunctionObject;

  size_t line = functionToken.retrieveLine;
  functionObject.line = line;

  if (!functionToken.statement || functionToken.statement.length < 4)
  {
    line.printError(source, "Invalid function definition.");
    return null;
  }

  bool parseBody = functionToken.statement[$-1] != ";";

  STRING[] beforeParameters = [];
  STRING[] parameters1 = [];
  STRING[] parameters2 = [];
  bool emptyParameters = false;

  size_t statementCollection = 0;
  size_t endedCollection = 0;

  bool canDeclareParameters = true;

  foreach (entry; functionToken.statement[1 .. $])
  {
    if (entry == ";")
    {
      break;
    }

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

  if (!functionObject.name.isValidIdentifier)
  {
    line.printError(source, "Invalid function name.");
    return null;
  }

  if (beforeParameters.length > 1)
  {
    functionObject.returnType ~= beforeParameters[0 .. $-1].join("");
  }
  else
  {
    functionObject.returnType ~= "void";
  }

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

  Parameter[] parametersObjects1 = [];
  Parameter[] parametersObjects2 = [];

  if (parameters1 && parameters1.length)
  {
    STRING[] args;
    auto paramIndex = 0;

    foreach (entry; parameters1)
    {
      if (entry == ",")
      {
        if (!args || args.length < 2)
        {
          line.printError(source, "Missing arguments for parameter: %s", paramIndex);
          return null;
        }
        else
        {
          auto param = new Parameter;
          param.type = args[0 .. $-1].join("");
          param.name = args[$-1];
          param.line = entry.line;
          parametersObjects1 ~= param;

          if (!param.name.isValidIdentifier)
          {
            line.printError(source, "Invalid name for parameter: %s", paramIndex);
            return null;
          }

          paramIndex++;

          args = [];
        }
      }
      else
      {
        args ~= entry;
      }
    }

    if (!args || args.length < 2)
    {
      line.printError(source, "Missing arguments for parameter: %s", paramIndex);
      return null;
    }
    else
    {
      auto param = new Parameter;
      param.type = args[0 .. $-1].join("");
      param.name = args[$-1];
      param.line = args[0].line;
      parametersObjects1 ~= param;

      if (!param.name.isValidIdentifier)
      {
        line.printError(source, "Invalid name for parameter: %s", paramIndex);
        return null;
      }

      paramIndex++;

      args = [];
    }
  }

  if (parameters2 && parameters2.length)
  {
    STRING[] args;
    auto paramIndex = 0;

    foreach (entry; parameters2)
    {
      if (entry == ",")
      {
        if (!args || args.length < 2)
        {
          line.printError(source, "Missing arguments for parameter: %s", paramIndex);
          return null;
        }
        else
        {
          auto param = new Parameter;
          param.type = args[0 .. $-1].join("");
          param.name = args[$-1];
          param.line = entry.line;
          parametersObjects2 ~= param;

          if (!param.name.isValidIdentifier)
          {
            line.printError(source, "Invalid name for parameter: %s", paramIndex);
            return null;
          }

          paramIndex++;

          args = [];
        }
      }
      else
      {
        args ~= entry;
      }
    }

    if (!args || args.length < 2)
    {
      line.printError(source, "Missing arguments for parameter: %s", paramIndex);
      return null;
    }
    else
    {
      auto param = new Parameter;
      param.type = args[0 .. $-1].join("");
      param.name = args[$-1];
      param.line = args[0].line;
      parametersObjects2 ~= param;

      if (!param.name.isValidIdentifier)
      {
        line.printError(source, "Invalid name for parameter: %s", paramIndex);
        return null;
      }

      paramIndex++;

      args = [];
    }
  }

  if (statementCollection == 2)
  {
    functionObject.templateParameters = parametersObjects1;
    functionObject.parameters = parametersObjects2;
  }
  else
  {
    functionObject.parameters = parametersObjects1;
  }

  if (statementCollection == 0)
  {
    line.printError(source, "Missing '%s' from function definition.", "(");
    return null;
  }

  if (parseBody)
  {
    auto scopeObjects = parseScopes(functionToken, source, line, "function", functionObject.name);

    if (scopeObjects && scopeObjects.length)
    {
      functionObject.scopes = scopeObjects.dup;
    }
  }

  printDebug("Finished parsing function.");

  return functionObject;
}

/// A scope object.
class ScopeObject
{
  /// The assignment expression of the scope.
  AssignmentExpression assignmentExpression;
  /// The function call expression of the scope.
  FunctionCallExpression functionCallExpression;
  /// The return expression of the scope.
  ReturnExpression returnExpression;
  /// The line for the scope object.
  size_t line;
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
  printDebug("Parsing scope.");

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

  foreach (token; scopeToken.tokens[1 .. $-1])
  {
    line = token.retrieveLine;
    scopeObject.line = line;

    switch (token.getParserType)
    {
      case ParserType.RETURN:
        auto returnExpression = parseReturnExpression(token, source, line);

        if (returnExpression)
        {
          scopeObject.returnExpression = returnExpression;
          scopeObjects ~= scopeObject;

          scopeObject = new ScopeObject;
        }
        break;

      case ParserType.EMPTY: break;

      default:
        auto functionCallExpression = parseFunctionCallExpression(token, source, line);

        if (functionCallExpression)
        {
          scopeObject.functionCallExpression = functionCallExpression;
          scopeObjects ~= scopeObject;

          scopeObject = new ScopeObject;
        }
        else
        {
          auto assignmentExpression = parseAssignmentExpression(token, source, line);

          if (assignmentExpression)
          {
            scopeObject.assignmentExpression = assignmentExpression;
            scopeObjects ~= scopeObject;

            scopeObject = new ScopeObject;
          }
          else
          {
            if (!printQueuedErrors())
            {
              line.printError(source, "Invalid declaration: %s", token.statement && token.statement.length ? token.statement[0] : "");
            }
          }
        }
        break;
    }
  }

  printDebug("Finished parsing scope.");

  return scopeObjects;
}

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
*   token = The token of the function.
*   source = The source parsed from.
*   line = The line parsed from.
* Returns:
*   The assignment expression created.
*/
AssignmentExpression parseAssignmentExpression(Token token, string source, size_t line)
{
  printDebug("Parsing assignment expression or increment/decrement expression. Tokens: %s", token.statement);

  string[] leftHand = [];
  string operator = "";
  string[] rightHand = [];

  foreach (entry; token.statement)
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

/// A function call expression.
class FunctionCallExpression
{
  /// The identifier of the function call.
  string identifier;
  /// The parameters passed to the function call.
  string[] templateParameters;
  /// The parameters passed to the function call.
  string[] parameters;
  /// The line of the function call expression.
  size_t line;
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
FunctionCallExpression parseFunctionCallExpression(Token token, string source, size_t line)
{
  import std.algorithm : map;
  import std.array : array;

  return parseFunctionCallExpression(token.statement.map!(s => s.s).array, source, line);
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
FunctionCallExpression parseFunctionCallExpression(string[] statement, string source, size_t line, bool skipEndCheck = false)
{
  printDebug("Parsing function call: %s", statement);

  statement = statement.dup;

  import std.array : join;

  clearQueuedErrors();

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

  if (parameters1 && parameters1.length && parameters2)
  {
    functionCallExpression.parameters = parameters2;
    functionCallExpression.templateParameters = parameters1;
  }
  else
  {
    functionCallExpression.parameters = parameters1;
  }

  return functionCallExpression;
}

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

  import core.tools;
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

/// An array expression.
class ArrayExpression
{
  /// The values of the array expression.
  ArrayValue[] values;
  /// The line of the array expression.
  size_t line;
  /// Boolean determining whether the expression is an associative array or not.
  bool isAssociativeArray;
}

/// An array value.
class ArrayValue
{
  /// The values of the array value.
  string[] values;
}

/**
* Parses an array expression.
* Params:
*   tokens = The tokens of the array expression.
*   source = The source of the array expression.
*   line = The line of the array expression.
*   queueErrors = Boolean determining whether errors should be printed directly or queued.
* Returns:
*   Returns an array expression if parsed correctly, null otherwise.
*/
ArrayExpression parseArrayExpression(string[] tokens, string source, size_t line, bool queueErrors)
{
  clearQueuedErrors();

  if (!tokens || tokens.length < 3)
  {
    if (queueErrors) line.queueError(source, "Missing array expression.");
    else line.printError(source, "Missing array expression.");
    return null;
  }

  if (tokens[$-1] != ";")
  {
    if (queueErrors) line.queueError(source, "Expected '%s' but found '%s'", ";", tokens[$-1]);
    else line.printError(source, "Expected '%s' but found '%s'", ";", tokens[$-1]);
    return null;
  }

  if (tokens[0] != "[")
  {
    if (queueErrors) line.queueError(source, "Expected '%s' but found '%s'", "[", tokens[0]);
    else line.printError(source, "Expected '%s' but found '%s'", "]", tokens[0]);
    return null;
  }

  if (tokens[$-2] != "]")
  {
    if (queueErrors) line.queueError(source, "Expected '%s' but found '%s'", "]", tokens[$-2]);
    else line.printError(source, "Expected '%s' but found '%s'", "]", tokens[$-2]);
    return null;
  }

  auto array = new ArrayExpression;
  array.line = line;

  if (tokens.length == 3)
  {
    return array; // Empty array.
  }

  auto parseStatement = tokens[1 .. $-2];

  auto value = new ArrayValue;
  bool lookForAssociative = false;

  foreach (ref i; 0 .. parseStatement.length)
  {
    auto entry = parseStatement[i];
    auto lastEntry = i > 1 ? parseStatement[i - 1] : "";
    auto nextEntry = i < (parseStatement.length - 1) ? parseStatement[i + 1] : "";

    if (entry == ":")
    {
      array.isAssociativeArray = true;
      lookForAssociative = true;
    }
    else if (entry == ",")
    {
      if (!value.values || !value.values.length)
      {
        if (queueErrors) line.queueError(source, "Empty array value.");
        else line.printError(source, "Empty array value.");
        return null;
      }

      if (array.isAssociativeArray && value.values.length != 2)
      {
        if (queueErrors) line.queueError(source, "Missing associative array value.");
        else line.printError(source, "Missing associative array value.");
        return null;
      }

      lookForAssociative = false;

      array.values ~= value;

      value = new ArrayValue;
    }
    else if (value.values && value.values.length && !lookForAssociative)
    {
      if (array.isAssociativeArray)
      {
        if (queueErrors) line.queueError(source, "Missing associative array key.");
        else line.printError(source, "Missing associative array key.");
      }
      else
      {
        if (queueErrors) line.queueError(source, "Missing array value separator.");
        else line.printError(source, "Missing array value separator.");
      }
      return null;
    }
    else
    {
      if (value.values && value.values.length == 2)
      {
        if (queueErrors) line.queueError(source, "Too many values for array entry.");
        else line.printError(source, "Too many values for array entry.");
        return null;
      }

      value.values ~= entry;
    }
  }

  if (!value.values || !value.values.length)
  {
    if (queueErrors) line.queueError(source, "Empty array value.");
    else line.printError(source, "Empty array value.");
    return null;
  }

  if (array.isAssociativeArray && value.values.length != 2)
  {
    if (queueErrors) line.queueError(source, "Missing associative array value.");
    else line.printError(source, "Missing associative array value.");
    return null;
  }

  array.values ~= value;

  return array;
}

/**
* Gets the parser type of a token.
* Params:
*   token = The token to retrieve the parser type of.
* Returns:
*   The parser type of the token if any, ParserType.UNKNOWN otherwise.
*/
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

/**
* Retrieves the line of a token.
* Params:
*   token = The token to retrieve the line from.
* Returns:
*   The line of the token.
*/
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
