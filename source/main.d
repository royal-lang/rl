/**
* Module for the entry point and main handling of the compiler.
*
* License: MIT (https://github.com/bausslang/bl/blob/master/LICENSE)
*
* Copyright 2019 © bausslang - All Rights Reserved.
*/
module main;

import std.stdio : writeln, writefln, readln;

import configuration;
import core;

private:

/// The entry point.
void main()
{
  try
  {
    printDebug("Starting compilation ...");
    run();
    printDebug("Compilation has finished ...");
  }
  catch (Throwable t)
  {
    writeln(t);
  }

  readln(); // So it won't just stop right away, making it easier to debug with print statements during development.
}

/// The function that runs the compiler.
void run()
{
  printDebug("Loading settings ...");

  auto settings = loadProjectSettings("tests/test1", "project.lp");

  printDebug("Loaded settings ...");

  if (settings.sourcePaths)
  {
    ModuleObject[string] modules;

    foreach (sourcePath; settings.sourcePaths)
    {
      printDebug("Handling source path: %s", sourcePath);

      foreach (mod; handle(settings.projectPath  ~ "/" ~ sourcePath))
      {
        printDebug("Parsed module: %s", mod.name);
        modules[mod.name] = mod;
      }
    }

    // Semantic analysis

    printDebug("Starting semantic analysis ...");

    analyzeSemantic(modules);

    if (hasErrors)
    {
      return;
    }

    // Parse code to external soruce (ex. C)

    if (hasErrors)
    {
      return;
    }

    // Compile code (ex. generated C code)

    if (hasErrors)
    {
      return;
    }
  }
}

/**
* Handles and compiles a specific source directory.
* Params:
*   sourceDirectory = The source directory to handle.
* Returns:
*   An array of module objects parsed from the source files in the directory.
*/
ModuleObject[] handle(string sourceDirectory)
{
  string[] files = [];
  string[] directories = [];

  ModuleObject[] modules = [];

  if (loadEntries(sourceDirectory, files, directories))
  {
    if (files && files.length)
    {
      printDebug("Parsing files ...");

      foreach (file; files)
      {
        printDebug("Parsing file: %s", file);

        // Tokenize
        printDebug("Splitting the file into tokens ...");

        auto tokens = tokenizeFile(file, false);

        printDebug("Grouping tokens ...");

        auto rootToken = groupTokens(tokens);

        printDebug("Parsing the tokens ...");

        auto moduleObject = parseModule(rootToken, file);

        printDebug("Writing parser tree ...");

        import std.file : write;
        write("parsertrees/parsertree_" ~ moduleObject.name ~ ".json", rootToken.toJson(0));

        printDebug("Wrote parser tree to file: parsertrees/parsertree_%s.json", moduleObject.name);

        modules ~= moduleObject;
      }

      if (hasErrors)
      {
        return [];
      }

      // CTFE etc.

      // if (hasErrors)
      // {
      //   return;
      // }
    }

    if (directories && directories.length)
    {
      foreach (directory; directories)
      {
        modules ~= handle(directory);
      }
    }
  }

  return modules;
}
