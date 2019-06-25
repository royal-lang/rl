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

        import std.file : write;
        write("parsertrees/parsertree_" ~ moduleObject.name ~ ".json", rootToken.toJson(0));

        writeln();
        writeln();
        writeln();

        writeln("Module: ", moduleObject.name);

        if (moduleObject.imports)
        {
          foreach (imp; moduleObject.imports)
          {
            writeln("Import: ", imp.modulePath);
            writeln("Members: ", imp.members);
          }
        }

        if (moduleObject.includes)
        {
          foreach (inc; moduleObject.includes)
          {
            writeln("Include: ", inc.headerPath);
          }
        }

        if (moduleObject.internalFunctions)
        {
          foreach (fn; moduleObject.internalFunctions)
          {
            writeln("Internal Function: ", fn.name);
            writeln("Definition: ", fn.definitionArguments);
            writeln("Template Args:");

            foreach (arg; fn.templateParameters)
            {
              writeln("Type: ", arg.type);
              writeln("Name: ", arg.name);
            }

            writeln("Parameters:");

            foreach (arg; fn.parameters)
            {
              writeln("Type: ", arg.type);
              writeln("Name: ", arg.name);
            }

            writeln("---");
          }
        }

        if (moduleObject.functions)
        {
          foreach (fn; moduleObject.functions)
          {
            writeln("Function: ", fn.name);
            writeln("Definition: ", fn.definitionArguments);
            writeln("Template Args:");

            foreach (arg; fn.templateParameters)
            {
              writeln("Type: ", arg.type);
              writeln("Name: ", arg.name);
            }

            writeln("Parameters:");

            foreach (arg; fn.parameters)
            {
              writeln("Type: ", arg.type);
              writeln("Name: ", arg.name);
            }

            if (fn.scopes)
            {
              writeln("Body:");

              foreach (s; fn.scopes)
              {
                if (s.assignmentExpression)
                {
                  if (s.assignmentExpression.rightHandCall)
                  {
                    writefln("%s %s %s(%s)", s.assignmentExpression.leftHand, s.assignmentExpression.operator, s.assignmentExpression.rightHandCall.identifier, s.assignmentExpression.rightHandCall.parameters);
                  }
                  else
                  {
                    writefln("%s %s %s", s.assignmentExpression.leftHand, s.assignmentExpression.operator, s.assignmentExpression.rightHand);
                  }
                }
                else if (s.functionCallExpression)
                {
                  writefln("%s(%s)", s.functionCallExpression.identifier, s.functionCallExpression.parameters);
                }
                else if (s.returnExpression)
                {
                  if (s.returnExpression.returnCall)
                  {
                    writefln("Return: %s(%s)", s.returnExpression.returnCall.identifier, s.returnExpression.returnCall.parameters);
                  }
                  else
                  {
                    writeln("Return: ", s.returnExpression.arguments);
                  }
                }
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

      if (hasErrors)
      {
        return;
      }

      // Semantic analysis

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

    if (directories && directories.length)
    {
      foreach (directory; directories)
      {
        handle(directory);
      }
    }
  }
}
