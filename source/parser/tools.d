/**
* Module for different parsing tools.
*
* License: MIT (https://github.com/bausslang/bl/blob/master/LICENSE)
*
* Copyright 2019 © bausslang - All Rights Reserved.
*/
module parser.tools;

import std.container: SList,DList;
import std.range : popFront;

/// An alias for SList to call it Stack.
private alias Stack = SList;
/// An alias for DList to call it Queue.
private alias Queue = DList;

import core.errors;

public:

/**
* Checks whether a given string is a valid number.
* Params:
*   str = The string to validate.
* Returns:
*   True if the string is a valid number.
*/
bool isNumberValue(bool allowNegative, bool allowFloating)(string str)
{
  bool hasDot = false;

  bool isNumberValueChar(char c, size_t index)
  {
    switch (c)
    {
      static if (allowFloating)
      {
        case '.':
          if (!hasDot)
          {
            hasDot = true;
            return index != 0;
          }
          return false;
      }

      case '0':
      case '1':
      case '2':
      case '3':
      case '4':
      case '5':
      case '6':
      case '7':
      case '8':
      case '9':
        return true;

      default:
        return false;
    }
  }

  foreach (i; 0 .. str.length)
  {
    auto c = str[i];

    static if (allowNegative)
    {
      if (i == 0 && c == '-')
      {
        if (str.length == 1)
        {
          return false;
        }

        continue;
      }
    }

    if (!isNumberValueChar(c, i))
    {
      return false;
    }
  }

  return true;
}

/**
* Splits a string using multiple delimeters.
* Params:
*   str = The string to split.
*   delis = The delimeters to use for splitting in an AA controlling whether they should be kept or not.
* Returns:
*   An array of the entries splitted by the string.
*/
string[] splitMultiple(string str, bool[string] delis)
{
  string[] result = [];

  string current = null;

  foreach (c; str)
  {
    import std.conv : to;
    import std.algorithm : canFind;

    auto s = to!string(c);

    if (s in delis)
    {
      if (current && current.length)
      {
        result ~= current;
      }

      if (delis.get(s, false))
      {
        result ~= s;
      }

      current = "";
    }
    else
    {
      current ~= s;
    }
  }

  if (current)
  {
    result ~= current;
  }

  return result;
}

/**
* Creates a shunting yard calculation set from a set of tokens.
* Params:
*   tokens = The tokens to create the calculation set from.
*   source = The source of the tokens.
*   line = The line of the tokens.
*   isMathematicalExpression = Boolean determining whether the tokens are mathematical or not.
*   queueErrors = Boolean determining whether errors should be printed directly or queued.
* Returns:
*   Returns a set of calculation tokens ordered by the shunting yard algorithm.
*/
string[] shuntingYardCalculation(string[] tokens, string source, size_t line, bool isMathematicalExpression, bool queueErrors)
{
  if (isMathematicalExpression)
  {
    initializeMathOperators();
  }
  else
  {
    initializeBooleanOperators();
  }

  import std.array : array;
  import std.algorithm : reverse;
  import std.string : strip;

  auto output = Queue!string([""]);
  auto operators = Stack!string([""]);

  foreach (token; tokens)
  {
      if (!token || !token.strip.length)
      {
        continue;
      }

      if (token.isIllegalSymbol)
      {
        if (queueErrors) line.queueError(source, "Found illegal symbol in expression: '%s'", token);
        else line.printError(source, "Found illegal symbol in expression: '%s'", token);
        return null;
      }

      if (!token.isSymbol)
      {
          output.enqueue(token);
      }
      else if (token.isSymbol && token != "(" && token != ")")
      {
          while (operators.peek() != "(")
          {
              auto pp = token.prec(operators.peek());
              auto isLeft = token.isLeftAssociate;

              if (isLeft && ((pp == Prec.lowerThan) || ((pp == Prec.lowerThan || pp == Prec.equal))))
              {
                auto operator = operators.pop();
              	output.enqueue(operator);
              }
              else
              {
                  break;
              }
          }

          operators.push(token);
      }
      else if (token == "(")
      {
          operators.push(token);
      }
      else if (token == ")")
      {
          while (!operators.isEmpty && operators.peek() != "(")
          {
              auto operator = operators.pop();
              output.enqueue(operator);
          }

          if (operators.isEmpty || operators.peek() != "(")
          {
            if (queueErrors) line.queueError(source, "Missing '(' from expression.");
            else line.printError(source, "Missing '(' from expression.");
            return null;
          }
          else
          {
              operators.pop();
          }
      }
  }

  while (!operators.isEmpty)
  {
      auto operator = operators.pop();
      output.enqueue(operator);
  }

  string[] result = [];

  while (!output.isEmpty)
  {
      result ~= output.dequeue();
  }

  return result;
}

private:
/**
* Pushes a value to the stack.
* Params:
*   stack = The stack.
*   value = The value to push.
*/
void push(T)(Stack!T stack, T value)
{
    stack.insertFront(value);
}

/**
* Pops a value from the stack.
* Params:
*   stack = The stack.
* Returns:
*   The value popped.
*/
T pop(T)(Stack!T stack)
{
    auto value = stack.front;
    stack.removeFront();
    return value;
}

/**
* Peeks a value from the stack.
* Params:
*   stack = The stack.
* Returns:
*   The value peeked.
*/
T peek(T)(Stack!T stack)
{
    return stack.front;
}

/**
* Checks whether a stack is empty or not.
* Params:
*   stack = The stack.
* Returns:
*   Returns a boolean determining whether the stack is empty or not.
*/
bool isEmpty(T)(Stack!T stack)
{
    import std.array : array;
    return stack.array.length <= 1;
}

/**
* Enqueues a value to the queue.
* Params:
*   queue = The queue.
*   value = The value to push.
*/
void enqueue(T)(Queue!T queue, T value)
{
    queue.insertFront(value);
}

/**
* Dequeues a value from the queue.
* Params:
*   queue = The queue.
* Returns:
*   The value dequeued.
*/
T dequeue(T)(Queue!T queue)
{
    queue.removeBack();
    auto value = queue.back;
    return value;
}

/**
* Peeks a value from the queue.
* Params:
*   queue = The queue.
* Returns:
*   The value peeked.
*/
T peek(T)(Queue!T queue)
{
    return queue.front;
}

/**
* Checks whether a queue is empty or not.
* Params:
*   queue = The queue.
* Returns:
*   Returns a boolean determining whether the queue is empty or not.
*/
bool isEmpty(T)(Queue!T queue)
{
    import std.array : array;
    return queue.array.length <= 1;
}

/// An operator for an expression.
struct OP
{
  /// The precedence of the operator.
  size_t prec;
  /// Whether the operator has right association or not.
  bool rightAssociation;
}

/// Collection of current valid operators.
OP[string] _operators;
/// Collection of current invalid operators.
OP[string] _illegalOperators;

/// Initialized operators for math expressions.
void initializeMathOperators()
{
  if (_operators)
  {
    _operators.clear();
  }

  if (_illegalOperators)
  {
    _illegalOperators.clear();
  }

  // Mathematical Expression:
  _operators["+"] = OP(1,false); // add
  _operators["-"] = OP(1,false); // sub
  _operators["*"] = OP(2,false); // mul
  _operators["/"] = OP(2,false); // div
  _operators["%"] = OP(2,false); // mod

  // Binary Expression:
  _operators["^"] = OP(3,true); // xor
  _operators["<<"] = OP(3,true); // shift-left
  _operators[">>"] = OP(3,true); // shift-right
  _operators["|"] = OP(3,true); // or
  _operators["~"] = OP(3,true); // complement
  _operators["&"] = OP(3,true); // and

  // pow(x,y)
  _operators["^^"] = OP(3,true); // power

  // Boolean Expression:
  _illegalOperators["||"] = OP(1, true); // or
  _illegalOperators["&&"] = OP(2, true); // and

  // Comparison
  _illegalOperators[">"] = OP(4, true); // greater than
  _illegalOperators[">="] = OP(4, true); // greater than or equal
  _illegalOperators["<="] = OP(4, true); // low than or equal
  _illegalOperators["<"] = OP(4, true); // lower than
  _illegalOperators["!="] = OP(4, true); // not equal
  _illegalOperators["!"] = OP(4, true); // false
  _illegalOperators["!!"] = OP(4, true); // falsey
  _illegalOperators["=="] = OP(4, true); // equal
}

/// Initializes operators for boolean expressions.
void initializeBooleanOperators()
{
  if (_operators)
  {
    _operators.clear();
  }

  if (_illegalOperators)
  {
    _illegalOperators.clear();
  }

  // Mathematical Expression:
  _illegalOperators["+"] = OP(1,false); // add
  _illegalOperators["-"] = OP(1,false); // sub
  _illegalOperators["*"] = OP(2,false); // mul
  _illegalOperators["/"] = OP(2,false); // div
  _illegalOperators["%"] = OP(2,false); // mod

  // Binary Expression:
  _illegalOperators["^"] = OP(3,true); // xor
  _illegalOperators["<<"] = OP(3,true); // shift-left
  _illegalOperators[">>"] = OP(3,true); // shift-right
  _illegalOperators["|"] = OP(3,true); // or
  _illegalOperators["&"] = OP(3,true); // and

  // pow(x,y)
  _illegalOperators["^^"] = OP(3,true); // power

  // Boolean Expression:
  _operators["||"] = OP(1, true); // or
  _operators["&&"] = OP(2, true); // and
  _operators["~"] = OP(3, false); // concat

  // Comparison
  _operators[">"] = OP(4, true); // greater than
  _operators[">="] = OP(4, true); // greater than or equal
  _operators["<="] = OP(4, true); // low than or equal
  _operators["<"] = OP(4, true); // lower than
  _operators["!="] = OP(4, true); // not equal
  _operators["!"] = OP(4, true); // false
  _operators["!!"] = OP(4, true); // falsey
  _operators["=="] = OP(4, true); // equal
}

/**
* Checks whether a symbol is illegal or not.
* Params:
*   symbol = The symbol to check.
* Returns:
*   Returns true if the symbol is illegal, false otherwise.
*/
bool isIllegalSymbol(string symbol)
{
  return cast(bool)(symbol in _illegalOperators);
}

/**
* Checks whether a symbol is qualified.
* Params:
*   symbol = The symbol to check.
* Returns:
*   Returns true if the symbol is qualified, false otherwise.
*/
bool isSymbol(string symbol)
{
  return cast(bool)(symbol in _operators) || symbol == "(" || symbol == ")";
}

/// Enumeration of precedences.
enum Prec
{
  /// The precedence is lower than.
  lowerThan,
  /// The precedence is equal to.
  equal,
  /// The precedence is greater than.
  greaterThan
}

/**
* Gets the precedence between two symbols.
* Params:
*   symbol1 = The first symbol.
*   symbol2 = The second symbol.
* Returns:
*   Returns the precedence between two symbols.
*/
Prec prec(string symbol1, string symbol2)
{
    auto p1 = _operators.get(symbol1, OP(0, false));
    auto p2 = _operators.get(symbol2, OP(0, p1.rightAssociation));

    if ((p1.prec) > (p2.prec))
    {
        return Prec.greaterThan;
    }
    else if ((p1.prec) < (p2.prec))
    {
        return Prec.lowerThan;
    }

    return Prec.equal;
}

/**
* Checks whether a symbol is left associated or not.
* Params:
*   symbol = The symbol to check.
* Returns:
*   Returns true if the symbol is left associate, false otherwise.
*/
bool isLeftAssociate(string symbol)
{
    auto p = _operators.get(symbol, OP(0, false));

    return !p.rightAssociation;
}

/**
* Checks whether a symbol is right associated or not.
* Params:
*   symbol = The symbol to check.
* Returns:
*   Returns true if the symbol is right associate, false otherwise.
*/
bool isRightAssociate(string symbol)
{
    return !isLeftAssociate(symbol);
}
