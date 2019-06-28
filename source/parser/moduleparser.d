module parser.moduleparser;

import core.tokenizer;
import core.errors;
import core.debugging;

import parser.meta;
import parser.tools;

import parser.importparser;
import parser.includeparser;
import parser.functionparser;

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
            line.printError(source, "Expected '%s' for module statement.", ";");
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
