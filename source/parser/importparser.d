/**
* Module for parsing imports.
*
* License: MIT (https://github.com/Royal Programming Language/bl/blob/master/LICENSE)
*
* Copyright 2019 © Royal Programming Language - All Rights Reserved.
*/
module parser.importparser;

import core.tokenizer;
import core.errors;
import core.debugging;

import parser.meta;
import parser.tools;

import parser.attributeparser;
import parser.moduleparser;

/// An import object.
class ImportObject
{
  /// The module path of the import.
  string modulePath;
  /// The members to import.
  string[] members;
  /// The line of the import object.
  size_t line;
  /// Attributes tied to this import declaration.
  AttributeObject[] attributes;
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
  auto attributes = getAttributes();

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
  importObject.attributes = attributes;

  printDebug("Finished parsing import ...");

  return importObject;
}
