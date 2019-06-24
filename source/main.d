/**
* Module for the entry point and main handling of the compiler.
*
* License: MIT (https://github.com/bausslang/bl/blob/master/LICENSE)
*
* Copyright 2019 © bausslang - All Rights Reserved.
*/
module main;

import std.stdio : writeln, readln;

import configuration;
import core;

private:

/// The entry point.
void main()
{
  try
  {
    run();
  }
  catch (Throwable t)
  {
    writeln(t);
  }

  readln(); // So it won't just stop right away, making it easier to debug with print statements.
}

/// The function that runs the compiler.
void run()
{
  auto settings = loadProjectSettings("tests/test1", "project.lp");

  if (settings.sourcePaths)
  {
    foreach (sourcePath; settings.sourcePaths)
    {
      handle(settings.projectPath  ~ "/" ~ sourcePath);
    }
  }
}

/**
* Handles and compiles a specific source directory.
*/
void handle(string sourceDirectory)
{
  string[] files = [];
  string[] directories = [];

  if (loadEntries(sourceDirectory, files, directories))
  {
    ModuleObject[] modules = [];
    if (files && files.length)
    {
      foreach (file; files)
      {
        // Tokenize
        auto tokens = tokenizeFile(file, false);

        auto rootToken = groupTokens(tokens);

        // Parse tokens into semantic data

        writeln();
        writeln();
        writeln();

        auto moduleObject = parseModule(rootToken, file);

        writeln();
        writeln();
        writeln();

        writeln("Module: ", moduleObject.name);

        if (moduleObject.imports)
        {
          foreach (imp; moduleObject.imports)
          {
            writeln("Import: ", imp.modulePath);
          }
        }

        if (moduleObject.functions)
        {
          foreach (fn; moduleObject.functions)
          {
            writeln("Function: ", fn.name);
            writeln("Definition: ", fn.definitionArguments);
            writeln("Template Args: ", fn.templateParameters);
            writeln("Parameters: ", fn.parameters);

            if (fn.scopes)
            {
              writeln("Body:");

              foreach (s; fn.scopes)
              {
                writeln(s.temp);
              }
            }

            writeln("---");
          }
        }

        modules ~= moduleObject;
      }

      if (hasErrors)
      {
        return;
      }

      // CTFE etc.

      // Semantic analysis

      // Parse code to external soruce (ex. C)

      // Compile code (ex. generated C code)
    }

    if (directories && directories.length)
    {
      foreach (directory; directories)
      {
        handle(directory);
      }
    }
  }
}
