/**
* Module for parsing modules.
*
* License: MIT (https://github.com/Royal Programming Language/bl/blob/master/LICENSE)
*
* Copyright 2019 © Royal Programming Language - All Rights Reserved.
*/
module parser.moduleparser;

import core.tokenizer;
import core.errors;
import core.debugging;

import parser.meta;
import parser.tools;

import parser.importparser;
import parser.includeparser;
import parser.functionparser;
import parser.attributeparser;
import parser.variableparser;
import parser.aliasparser;

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
  /// The variables of the module.
  Variable[] variables;
  /// The aliases of the module.
  Alias[] aliases;
  /// The line of the module object.
  size_t line;
  /// The source of the module object.
  string source;
  /// Attributes tied to this function declaration.
  AttributeObject[] attributes;
}

/// Collection of currently declared attributes for the module.
private AttributeObject[] _attributes;

/// Gets the current attributes that can be tied to the current declaration.
AttributeObject[] getAttributes()
{
  if (!_attributes)
  {
    return null;
  }

  auto attributes = _attributes.dup;

  _attributes = null;

  return attributes;
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
        auto attributes = getAttributes();

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
            line.printError(source, "Expected '%s' for module statement.", ";");
            break;
          }

          if (!token.statement[1].isValidIdentifier)
          {
            line.printError(source, "Invalid name for module statement.");
            break;
          }

          moduleObject.name = token.statement[1];
          moduleObject.attributes = attributes;
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

      case ParserType.ATTRIBUTE:
        auto attribute = parseAttribute(token, source);

        if (attribute)
        {
          _attributes ~= attribute;
        }
        break;

      case ParserType.VARIABLE:
        auto variable = parseVariable(token, source);

        if (variable)
        {
          moduleObject.variables ~= variable;
        }
        break;

      case ParserType.ALIAS:
        auto aliasObject = parseAlias(token, source);

        if (aliasObject)
        {
          moduleObject.aliases ~= aliasObject;
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
