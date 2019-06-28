module parser.meta;

import core.tokenizer;
import core.errors;
import core.debugging;

import parser.tools;

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
  DO = "do",
  /// The ptr keyword.
  PTR = "ptr",
  /// The immutable keyword.
  IMMUTABLE = "immutable",
  /// The const keyword.
  CONST = "const",
  /// The mut keyword.
  MUT = "mut"
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
    symbol == "|=" ||
    symbol == "@=";
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
    case Keyword.PTR:
    case Keyword.IMMUTABLE:
    case Keyword.CONST:
    case Keyword.MUT:
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
  /// The attribute parser type.
  ATTRIBUTE,
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

  parserTypes[Keyword.PUBLIC] = ParserType.ATTRIBUTE;
  parserTypes[Keyword.PRIVATE] = ParserType.ATTRIBUTE;
  parserTypes[Keyword.PACKAGE] = ParserType.ATTRIBUTE;
  parserTypes[Keyword.PROTECTED] = ParserType.ATTRIBUTE;
  parserTypes[Keyword.IMMUTABLE] = ParserType.ATTRIBUTE;
  parserTypes[Keyword.CONST] = ParserType.ATTRIBUTE;
  parserTypes[Keyword.MUT] = ParserType.ATTRIBUTE;
  parserTypes[Keyword.STATIC] = ParserType.ATTRIBUTE;

  parserTypes[Keyword.RETURN] = ParserType.RETURN;
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
  auto lastKeyword = token.statement[$-1];

  if (keyword == "@" && lastKeyword == ":")
  {
    return ParserType.ATTRIBUTE;
  }

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

bool isAttribute(string token)
{
  if (!token || !token.length)
  {
    return false;
  }

  return
    token == Keyword.PUBLIC ||
    token == Keyword.PRIVATE ||
    token == Keyword.PROTECTED ||
    token == Keyword.PACKAGE ||
    token == Keyword.STATIC ||
    token == Keyword.IMMUTABLE ||
    token == Keyword.CONST ||
    token == Keyword.MUT;
}
