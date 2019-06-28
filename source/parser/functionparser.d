/**
* Module for parsing functions.
*
* License: MIT (https://github.com/bausslang/bl/blob/master/LICENSE)
*
* Copyright 2019 © bausslang - All Rights Reserved.
*/
module parser.functionparser;

import core.tokenizer;
import core.errors;
import core.debugging;

import parser.meta;
import parser.tools;

import parser.scopeparser;
import parser.typeinformationparser;

/// A function object.
class FunctionObject
{
  /// The name of the function.
  string name;
  /// The return type of the function.
  string returnType;
  /// The template parameters of the function.
  Parameter[] templateParameters;
  /// The parameters of the function.
  Parameter[] parameters;
  /// The scopes of the function.
  ScopeObject[] scopes;
  /// The line of the function object.
  size_t line;
  /// The return type information.
  TypeInformation returnTypeInformation;
}

/// A parameter.
class Parameter
{
  /// The type.
  string type;
  /// The name.
  string name;
  /// The line of the parameter.
  size_t line;
  /// The type information.
  TypeInformation typeInformation;
}

/**
* Parses an internal function.
* Params:
*   token = The token of the function.
*   source = The source parsed from.
* Returns:
*   The function object created.
*/
FunctionObject parseInternalFunction(Token functionToken, string source)
{
  printDebug("Parsing internal function: %s", functionToken.statement);

  size_t line = functionToken.retrieveLine;

  functionToken.statement = functionToken.statement[1 .. $];

  if (functionToken.statement[$-1] != ";")
  {
    line.printError(source, "Expected '%s' but found '%s'", ";", functionToken.statement[$-1]);
    return null;
  }

  return parseFunction(functionToken, source);
}

/**
* Parses a function.
* Params:
*   token = The token of the function.
*   source = The source parsed from.
* Returns:
*   The function object created.
*/
FunctionObject parseFunction(Token functionToken, string source)
{
  printDebug("Parsing function: %s", functionToken.statement);

  import std.array : join;

  auto functionObject = new FunctionObject;

  size_t line = functionToken.retrieveLine;
  functionObject.line = line;

  if (!functionToken.statement || functionToken.statement.length < 4)
  {
    line.printError(source, "Invalid function definition.");
    return null;
  }

  bool parseBody = functionToken.statement[$-1] != ";";

  STRING[] beforeParameters = [];
  STRING[] parameters1 = [];
  STRING[] parameters2 = [];
  bool emptyParameters = false;

  size_t statementCollection = 0;
  size_t endedCollection = 0;

  bool canDeclareParameters = true;

  foreach (entry; functionToken.statement[1 .. $])
  {
    if (entry == ";")
    {
      break;
    }

    if (entry == "(" && canDeclareParameters)
    {
      canDeclareParameters = false;

      if (statementCollection == 1)
      {
        statementCollection = 2;
      }
      else if (statementCollection == 0)
      {
        statementCollection = 1;
      }
      else
      {
        line.printError(source, "A function may only have a template parameter declaraction and a function parameter declaration.");
        return null;
      }
    }
    else if (entry == ")")
    {
      canDeclareParameters = true;
      endedCollection++;
    }
    else
    {
      if (statementCollection == 0) beforeParameters ~= entry;
      else if (statementCollection == 1) parameters1 ~= entry;
      else if (statementCollection == 2) parameters2 ~= entry;
    }
  }

  if (!beforeParameters || !beforeParameters.length)
  {
    line.printError(source, "Missing function name.");
    return null;
  }

  if (beforeParameters[$-1].isKeyword)
  {
    line.printError(source, "Found keyword when expected name entry: %s", beforeParameters[$-1]);
    return null;
  }

  functionObject.name = beforeParameters[$-1];

  if (!functionObject.name.isValidIdentifier)
  {
    line.printError(source, "Invalid function name.");
    return null;
  }

  if (beforeParameters.length > 1)
  {
    functionObject.returnType ~= beforeParameters[0 .. $-1].join("");
  }
  else
  {
    functionObject.returnType ~= "void";
  }

  functionObject.returnTypeInformation = parseTypeInformation(functionObject.returnType, source, line, false);

  if (!functionObject.returnTypeInformation)
  {
    return null;
  }

  if (statementCollection == 1 && endedCollection != 1)
  {
    line.printError(source, "Missing '%s' from function declarationz.", ")");
    return null;
  }

  if (statementCollection == 2 && endedCollection != 2)
  {
    line.printError(source, "Missing '%s' from function declarationx.", ")");
    return null;
  }

  // TODO: Clean up this mess for the parameter parser. Use a function.

  Parameter[] parametersObjects1 = [];
  Parameter[] parametersObjects2 = [];

  if (parameters1 && parameters1.length)
  {
    STRING[] args;
    auto paramIndex = 0;

    foreach (entry; parameters1)
    {
      if (entry == ",")
      {
        if (!args || args.length < 2)
        {
          line.printError(source, "Missing arguments for parameter: %s", paramIndex);
          return null;
        }
        else
        {
          auto param = new Parameter;
          param.type = args[0 .. $-1].join("");
          param.name = args[$-1];
          param.line = entry.line;
          parametersObjects1 ~= param;

          if (!param.name.isValidIdentifier)
          {
            line.printError(source, "Invalid name for parameter: %s", paramIndex);
            return null;
          }

          paramIndex++;

          args = [];
        }
      }
      else
      {
        args ~= entry;
      }
    }

    if (!args || args.length < 2)
    {
      line.printError(source, "Missing arguments for parameter: %s", paramIndex);
      return null;
    }
    else
    {
      auto param = new Parameter;
      param.type = args[0 .. $-1].join("");
      param.name = args[$-1];
      param.line = args[0].line;
      parametersObjects1 ~= param;

      if (!param.name.isValidIdentifier)
      {
        line.printError(source, "Invalid name for parameter: %s", paramIndex);
        return null;
      }

      paramIndex++;

      args = [];
    }
  }

  if (parameters2 && parameters2.length)
  {
    STRING[] args;
    auto paramIndex = 0;

    foreach (entry; parameters2)
    {
      if (entry == ",")
      {
        if (!args || args.length < 2)
        {
          line.printError(source, "Missing arguments for parameter: %s", paramIndex);
          return null;
        }
        else
        {
          auto param = new Parameter;
          param.type = args[0 .. $-1].join("");
          param.name = args[$-1];
          param.line = entry.line;
          parametersObjects2 ~= param;

          if (!param.name.isValidIdentifier)
          {
            line.printError(source, "Invalid name for parameter: %s", paramIndex);
            return null;
          }

          paramIndex++;

          args = [];
        }
      }
      else
      {
        args ~= entry;
      }
    }

    if (!args || args.length < 2)
    {
      line.printError(source, "Missing arguments for parameter: %s", paramIndex);
      return null;
    }
    else
    {
      auto param = new Parameter;
      param.type = args[0 .. $-1].join("");
      param.name = args[$-1];
      param.line = args[0].line;
      parametersObjects2 ~= param;

      if (!param.name.isValidIdentifier)
      {
        line.printError(source, "Invalid name for parameter: %s", paramIndex);
        return null;
      }

      paramIndex++;

      args = [];
    }
  }

  if (statementCollection == 2)
  {
    functionObject.templateParameters = parametersObjects1;
    functionObject.parameters = parametersObjects2;
  }
  else
  {
    functionObject.parameters = parametersObjects1;
  }

  foreach (p; functionObject.parameters)
  {
    p.typeInformation = parseTypeInformation(p.type, source, line, false);

    if (!p.typeInformation)
    {
      return null;
    }
  }

  if (statementCollection == 0)
  {
    line.printError(source, "Missing '%s' from function definition.", "(");
    return null;
  }

  if (parseBody)
  {
    auto scopeObjects = parseScopes(functionToken, source, line, "function", functionObject.name);

    if (scopeObjects && scopeObjects.length)
    {
      functionObject.scopes = scopeObjects.dup;
    }
  }

  printDebug("Finished parsing function.");

  return functionObject;
}
