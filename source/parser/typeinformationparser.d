module parser.typeinformationparser;

import core.tokenizer;
import core.errors;
import core.debugging;

import parser.meta;
import parser.tools;

/// Type information.
class TypeInformation
{
  /// The size of an array.
  string size;
  /// Boolean determining whether the type is a dynamic array.
  bool dynamicArray;
  /// Boolean determining whether the type is a static array.
  bool staticArray;
  /// The mutability of the type.
  string mutability;
  /// Boolean determining whether the type is a pointer or not.
  bool isPointer;
  /// The type if not an array.
  string type;
  /// Boolean determining whether the type is an associative array.
  bool associativeArray;

  /// The type entries for array types.
  TypeEntry[] entries;
}

/// A type entry.
class TypeEntry
{
  /// Boolean determining whether the entry is a pointer.
  bool isPointer;
  /// The type of the entry.
  string type;
  /// The mutability of the entry.
  string mutability;
}

/**
* Parses type information from a given type string.
* Params:
*   typeString = The type string to parse.
*   source = The source of the type.
*   line = The line of the type.
*   queueErrors = Boolean determining whether errors should be printed directly or queued.
* Returns:
*   The type information parsed if parsed correctly, null otherwise.
*/
TypeInformation parseTypeInformation(string typeString, string source, size_t line, bool queueErrors)
{
  clearQueuedErrors();

  auto data = typeString.splitMultiple([":":false, "[":true, "]":true]);

  string pointer;
  string mutability;
  string size;
  string type;

  bool inArray;
  bool canHaveSize = true;
  bool dynamicArray = false;
  bool staticArray = false;

  auto typeInfo = new TypeInformation;

  foreach (ref i; 0 .. data.length)
  {
    auto entry = data[i];
    auto last = i > 1 ? data[i - 1] : "";
    auto next = i < (data.length - 1) ? data[i + 1] : "";

    if (inArray && entry != "]")
    {
      if (size && size.length)
      {
        if (queueErrors) line.queueError(source, "Multiple sizes declared.");
        else line.printError(source, "Multiple sizes declared.");
        return null;
      }
      else
      {
        import std.string : strip;
        size = entry.strip;
      }
    }
    else if (entry == Keyword.PTR)
    {
      if (type)
      {
        auto typeEntry = new TypeEntry;
        typeEntry.isPointer = pointer == Keyword.PTR;
        typeEntry.type = type;
        typeEntry.mutability = mutability;
        typeInfo.entries ~= typeEntry;

        pointer = null;
        mutability = null;
        type = null;
      }

      if (!mutability && !type && !size)
      {
        if (!pointer)
        {
          pointer = entry;
        }
        else
        {
          if (queueErrors) line.queueError(source, "Only one pointer allowed per type.");
          else line.printError(source, "Only one pointer allowed per type.");
          return null;
        }
      }
      else
      {
        if (queueErrors) line.queueError(source, "The pointer attribute must be declared before the type.");
        else line.printError(source, "The pointer attribute must be declared before the type.");
        return null;
      }
    }
    else if (entry == Keyword.IMMUTABLE || entry == Keyword.CONST || entry == Keyword.MUT)
    {
      if (!type && canHaveSize)
      {
        if (queueErrors) line.queueError(source, "The '%s' attribute must be declared after the type.", entry);
        else line.printError(source, "The '%s' attribute must be declared after the type.", entry);
        return null;
      }
      else
      {
        mutability = entry;

        if (!type)
        {
          if (queueErrors) line.queueError(source, "Declared the '%s' attribute before a type was declared.", entry);
          else line.printError(source, "Declared the '%s' attribute before a type was declared.", entry);
          return null;
        }
        else
        {
          auto typeEntry = new TypeEntry;
          typeEntry.isPointer = pointer == Keyword.PTR;
          typeEntry.type = type;
          typeEntry.mutability = mutability;
          typeInfo.entries ~= typeEntry;

          pointer = null;
          mutability = null;
          type = null;
        }
      }
    }
    else if (entry == "]")
    {
      if (!inArray)
      {
        if (queueErrors) line.queueError(source, "Expected '%s' but found '%s' only", "[", entry);
        else line.printError(source, "Expected '%s' but found '%s' only", "[", entry);
        return null;
      }
      else
      {
        inArray = false;

        if (!size || !size.length)
        {
          dynamicArray = true;
        }
        else
        {
          staticArray = true;
        }

        if (i == (data.length - 1) || i == (data.length - 2))
        {
          if (i == (data.length - 2))
          {
            if (next == Keyword.IMMUTABLE || next == Keyword.CONST || next == Keyword.MUT)
            {
              mutability = next;
            }
            else if (next && next.length)
            {
              if (queueErrors) line.queueError(source, "Unknown mutability attribute. Attribute: '%s", next);
              else line.printError(source, "Unknown mutability attribute. Attribute: '%s", next);
              return null;
            }

            i++;
          }
        }
        else
        {
          if (queueErrors) line.queueError(source, "Too many post-type attributes.");
          else line.printError(source, "Too many post-type attributes.");
          return null;
        }
      }
    }
    else if (entry == "[")
    {
      if (!canHaveSize)
      {
        if (queueErrors) line.queueError(source, "Multiple array declarations found.");
        else line.printError(source, "Multiple array declarations found.");
        return null;
      }
      else
      {
        inArray = true;
        canHaveSize = false;

        if (type)
        {
          auto typeEntry = new TypeEntry;
          typeEntry.isPointer = pointer == Keyword.PTR;
          typeEntry.type = type;
          typeEntry.mutability = mutability;
          typeInfo.entries ~= typeEntry;

          pointer = null;
          mutability = null;
          type = null;
        }
      }
    }
    else
    {
      if (type)
      {
        auto typeEntry = new TypeEntry;
        typeEntry.isPointer = pointer == Keyword.PTR;
        typeEntry.type = type;
        typeEntry.mutability = mutability;
        typeInfo.entries ~= typeEntry;

        type = null;
        pointer = null;
        mutability = null;
      }

      type = entry;
    }
  }

  if (size && size.length)
  {
    if (!isNumberValue!(false,false)(size))
    {
      if (queueErrors) line.queueError(source, "The size of an array or associative array must be an unsigned integer.");
      else line.printError(source, "The size of an array or associative array must be an unsigned integer.");
      return null;
    }

    typeInfo.size = size;
  }

  typeInfo.dynamicArray = dynamicArray;
  typeInfo.staticArray = staticArray;

  if (type)
  {
    typeInfo.type = type;
  }

  if (mutability)
  {
    typeInfo.mutability = mutability;
  }

  if (pointer)
  {
    typeInfo.isPointer = pointer == Keyword.PTR;
  }

  if (typeInfo.entries)
  {
    if (typeInfo.dynamicArray && typeInfo.entries.length > 2)
    {
      if (queueErrors) line.queueError(source, "Too many types declared for array.");
      else line.printError(source, "Too many types declared for array.");
      return null;
    }
    else if (!typeInfo.dynamicArray && !typeInfo.staticArray && typeInfo.entries.length > 1)
    {
      if (queueErrors) line.queueError(source, "Too many types declared.");
      else line.printError(source, "Too many types declared.");
      return null;
    }
  }

  if (!typeInfo.dynamicArray && !typeInfo.staticArray && typeInfo.entries && typeInfo.entries.length)
  {
    auto entry = typeInfo.entries[0];
    typeInfo.type = entry.type;
    typeInfo.isPointer = entry.isPointer;
    typeInfo.mutability = entry.mutability;
  }
  else if (typeInfo.entries && typeInfo.entries.length == 2 && (typeInfo.dynamicArray || typeInfo.staticArray))
  {
    typeInfo.associativeArray = true;
    typeInfo.dynamicArray = false;
    typeInfo.staticArray = false;
  }

  return typeInfo;
}
