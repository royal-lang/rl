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
bool isValidIdentifier(string identifier)
{
  import std.conv : to;

  if (!identifier || !identifier.length)
  {
    return false;
  }

  auto result =
    !identifier.isKeyword &&
    !identifier.isOperatorSymbol &&
    !identifier.isQualifiedSymbol;

  if (identifier.length > 2)
  {
    result = result && isValidIdentifier(to!string(identifier[0 .. 2]));
  }
  else if (identifier.length > 1)
  {
    result = result && isValidIdentifier(to!string(identifier[0]));
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
    case "==":
    case "!!":
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

  return moduleObject;
}

/// An import object.
class ImportObject
{
  /// The module path of the import.
  string modulePath;
  string[] members;
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

  return importObject;
}

/// An import object.
class IncludeObject
{
  /// The module path of the import.
  string headerPath;
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
  includeObject.headerPath = name;

  return includeObject;
}

/// A function object.
class FunctionObject
{
  /// The name of the function.
  string name;
  /// The definition arguments of the function such as return type etc.
  string[] definitionArguments;
  /// The template parameters of the function.
  Parameter[] templateParameters;
  /// The parameters of the function.
  Parameter[] parameters;
  /// The scopes of the function.
  ScopeObject[] scopes;
}

/// A parameter.
class Parameter
{
  /// The type.
  string type;
  /// The name.
  string name;
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
  import std.array : join;

  auto functionObject = new FunctionObject;

  size_t line = functionToken.retrieveLine;

  if (!functionToken.statement || functionToken.statement.length < 4)
  {
    line.printError(source, "Invalid function definition.");
    return null;
  }

  bool parseBody = functionToken.statement[$-1] != ";";

  string[] beforeParameters = [];
  string[] parameters1 = [];
  string[] parameters2 = [];
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

  Parameter[] parametersObjects1 = [];
  Parameter[] parametersObjects2 = [];

  if (parameters1 && parameters1.length)
  {
    string[] args;
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
    string[] args;
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

  // TODO: Parse defition arguments such as return type, access modifier etc.

  if (parseBody)
  {
    auto scopeObjects = parseScopes(functionToken, source, line, "function", functionObject.name);

    if (scopeObjects && scopeObjects.length)
    {
      functionObject.scopes = scopeObjects.dup;
    }
  }

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

  foreach (token; scopeToken.tokens[1 .. $-1])
  {
    line = token.retrieveLine;

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
        auto assignmentExpression = parseAssignmentExpression(token, source, line);

        if (assignmentExpression)
        {
          scopeObject.assignmentExpression = assignmentExpression;
          scopeObjects ~= scopeObject;

          scopeObject = new ScopeObject;
        }
        else
        {
          auto functionCallExpression = parseFunctionCallExpression(token, source, line);

          if (functionCallExpression)
          {
            scopeObject.functionCallExpression = functionCallExpression;
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
  /// The right-hand function call expression.
  FunctionCallExpression rightHandCall;
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

  writeln(exp.rightHand);

  auto functionCallExpression = parseFunctionCallExpression(exp.rightHand, source, line);

  if (functionCallExpression)
  {
    exp.rightHandCall = functionCallExpression;
  }

  clearQueuedErrors(); // clean up errors

  return exp;
}

/// A function call expression.
class FunctionCallExpression
{
  /// The identifier of the function call.
  string identifier;
  /// The parameters passed to the function call.
  string[] parameters;
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
FunctionCallExpression parseFunctionCallExpression(string[] statement, string source, size_t line)
{
  import std.array : join;

  clearQueuedErrors();

  if (!statement || statement.length < 4)
  {
    return null;
  }

  if (statement[1] != "(")
  {
    line.queueError(source, "Missing '%s' from function call.", "(");
    return null;
  }

  if (statement[$-2] != ")")
  {
    line.queueError(source, "Missing '%s' from function call.", ")");
    return null;
  }

  if (statement[$-1] != ";")
  {
    line.queueError(source, "Expected '%s' but found '%s'", ";", statement[$-1]);
    return null;
  }

  auto functionCallExpression = new FunctionCallExpression;
  functionCallExpression.identifier = statement[0];

  if (!functionCallExpression.identifier.isValidIdentifier)
  {
    line.queueError(source, "Invalid identifier for function call.");
    return null;
  }

  string[] values = [];
  bool inArray = false;

  foreach (entry; statement[2 .. $-2])
  {
    if (inArray && entry == "]")
    {
      inArray = false;
      values ~= entry;

      functionCallExpression.parameters ~= values.join("");
      values = [];
    }
    else if (!inArray && entry == "[")
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
      line.queueError(source, "Found '%s' when expected parameter.", ",");
      return null;
    }
    else if (inArray)
    {
      values ~= entry;
    }
    else
    {
      functionCallExpression.parameters ~= entry;
    }
  }

  if (inArray)
  {
    line.queueError(source, "Array expression is never closed.");
    return null;
  }

  return functionCallExpression;
}

/// A return expression.
class ReturnExpression
{
  /// The arguments of the return expression.
  string[] arguments;
  /// The function call expression of the return expression.
  FunctionCallExpression returnCall;
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
  returnExpression.arguments = token.statement[1 .. $].map!(s => s.s).array;

  auto functionCallExpression = parseFunctionCallExpression(returnExpression.arguments, source, line);

  if (functionCallExpression)
  {
    returnExpression.returnCall = functionCallExpression;
  }
  else
  {
    printQueuedErrors();
  }

  return returnExpression;
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
