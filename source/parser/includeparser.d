module parser.includeparser;

import core.tokenizer;
import core.errors;
import core.debugging;

import parser.meta;
import parser.tools;

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
    line.printError(source, "Expected '%s' for include statement.", ";");
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
