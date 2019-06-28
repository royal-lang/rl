module parser.importparser;

import core.tokenizer;
import core.errors;
import core.debugging;

import parser.meta;
import parser.tools;

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
    line.printError(source, "Expected '%s' for import statement.", ";");
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
