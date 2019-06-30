/**
* Module for semantic analysis.
*
* License: MIT (https://github.com/Royal Programming Language/bl/blob/master/LICENSE)
*
* Copyright 2019 © Royal Programming Language - All Rights Reserved.
*/
module core.semantic;

import core.errors;

import parser;

void analyzeSemantic(ModuleObject[string] modules)
{
  foreach (mod; modules.values)
  {
    analyzeModule(modules, mod);
  }
}

void analyzeModule(ModuleObject[string] modules, ModuleObject mod)
{
  analyzeImports(modules, mod.source, mod.imports);
  analyzeIncludes(mod.source, mod.includes);
}

void analyzeImports(ModuleObject[string] modules, string source, ImportObject[] imports)
{
  if (!imports || !imports.length)
  {
    return;
  }

  foreach (imp; imports)
  {
    if (imp.modulePath !in modules)
    {
      imp.line.printError(source, "Specified import for '%s' but the module was not found.", imp.modulePath);
    }
  }
}

void analyzeIncludes(string source, IncludeObject[] includes)
{
  if (!includes || !includes.length)
  {
    return;
  }

  foreach (inc; includes)
  {
    import std.file : exists;

    if (!exists(inc.headerPath))
    {
      inc.line.printError(source, "The header file '%s' was not found.", inc.headerPath);
    }
  }
}
