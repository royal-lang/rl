/**
* Module for compiler settings, project settings etc.
*
* License: MIT (https://github.com/Royal Programming Language/bl/blob/master/LICENSE)
*
* Copyright 2019 © Royal Programming Language - All Rights Reserved.
*/
module configuration.settings;

/// Project settings.
struct Settings
{
  /// The name of the project.
  string name;
  /// The project path.
  string projectPath;
  /// The project file.
  string projectFile;
  /// A list of source paths.
  string[] sourcePaths;
  /// A list of dependencies.
  Dependency[] dependencies;
}

/// A project dependency.
struct Dependency
{
  /// The name of the dependency.
  string name;
  /// The version of the dependency.
  string dependencyVersion;
  /// The path of the dependency.
  string path;
}

/// An entry of the project file.
private class Entry
{
  // The name of the entry.
  string name;
  /// The value of the entry.
  string value;

  /**
  * Creates a new entry.
  * Params:
  *   name = The name of the entry.
  *   value = The value of the entry.
  */
  this(string name, string value)
  {
    this.name = name;
    this.value = value;
  }

  /**
  * Creates a new entry.
  * Params:
  *   name = The name of the entry.
  *   value = The value of the entry.
  *   parentEntry = The parent of the entry.
  */
  this(string name, string value, Entry parentEntry)
  {
    this(name, value);

    this.parentEntry = parentEntry;
  }

  /// The parent entry.
  Entry parentEntry;
  /// The sub entries.
  Entry[string] subEntries;
}

/**
* Loads the project settings.
* Params:
*   projectPath = The path of the project to compile.
*   projectFile = The project file to compile with. (Must be located within the project path.)
* Returns:
*   Returns the project settings.
*/
Settings loadProjectSettings(string projectPath, string projectFile)
{
  import std.stdio : writeln, writefln, readln;

  import std.string : strip;
  import std.file : readText;
  import std.array : replace, split;
  import std.algorithm : countUntil;

  string content = readText(projectPath ~ "/" ~ projectFile).strip.replace("\r", "");

  auto lines = content.split("\n");

  Entry[string] entries;

  Entry currentEntrry;
  size_t currentTabs;

  foreach (line; lines)
  {
    if (!line || !line.strip.length)
    {
      continue;
    }

    const countUntilPred = "a != ' '";

    if (countUntil!countUntilPred(line) == 0)
    {
      auto data = line.split(":");
      currentEntrry = new Entry(data[0], (data.length == 2 ? data[1] : null));

      entries[data[0]] = currentEntrry;
      currentTabs = countUntil!countUntilPred(line);
    }
    else if (currentEntrry)
    {
      if (countUntil!countUntilPred(line) == (currentTabs + 1))
      {
        auto data = line.split(":");
        currentEntrry = new Entry(data[0], (data.length == 2 ? data[1] : null), currentEntrry);
        currentEntrry.parentEntry.subEntries[currentEntrry.name] = currentEntrry;
        currentTabs = countUntil!countUntilPred(line);
      }
      else if (countUntil!countUntilPred(line) == currentTabs)
      {
        auto data = line.split(":");
        currentEntrry = new Entry(data[0], (data.length == 2 ? data[1] : null), currentEntrry.parentEntry);
        currentEntrry.parentEntry.subEntries[currentEntrry.name] = currentEntrry;
        currentTabs = countUntil!countUntilPred(line);
      }
      else if (countUntil!countUntilPred(line) < currentTabs)
      {
        while (currentTabs > countUntil!countUntilPred(line) && currentEntrry.parentEntry)
        {
          currentEntrry = currentEntrry.parentEntry;
          currentTabs--;
        }

        auto data = line.split(":");
        currentEntrry = new Entry(data[0], (data.length == 2 ? data[1] : null), currentEntrry.parentEntry);
        currentEntrry.parentEntry.subEntries[currentEntrry.name] = currentEntrry;
        currentTabs = countUntil!countUntilPred(line);
      }
    }
  }

  Settings settings;

  settings.name = entries["name"].value.strip;
  settings.projectPath = projectPath;
  settings.projectFile = projectFile;

  if ("sourcePaths" in entries && entries["sourcePaths"])
  {
    foreach (sourcePath; entries["sourcePaths"].subEntries)
    {
      settings.sourcePaths ~= sourcePath.name.strip;
    }
  }

  if ("dependencies" in entries && entries["dependencies"])
  {
    foreach (dependency; entries["dependencies"].subEntries)
    {
      string name = dependency.name.strip;
      string dependencyVersion = "";
      string path = "";

      if (dependency.subEntries && dependency.subEntries.length)
      {
        foreach (k,v; dependency.subEntries)
        {
          switch (k.strip)
          {
            case "version":
              dependencyVersion = v.value.strip;
              break;

            case "path":
              path = v.value.strip;
              break;

              default: break;
          }
        }
      }

      settings.dependencies ~= Dependency(name, dependencyVersion, path);
    }
  }

  return settings;
}
