/**
* Module for tokenizing content into parsable tokens.
*
* License: MIT (https://github.com/bausslang/bl/blob/master/LICENSE)
*
* Copyright 2019 © bausslang - All Rights Reserved.
*/
module core.tokenizer;

/// A token string. It's the same as a string but contains line information.
struct TOKENSTRING
{
  /// The string data.
  string s;

  /// The line of the token string.
  size_t line;

  /// An alias to provide implicit string management.
  alias s this;
}

/// An alias for TOKENSTRING to be used like STRING.
public alias STRING = TOKENSTRING;

/**
* Tokenizes a file.
* Params:
*   file = The file to tokenize the content of.
*   includeComments = Boolean determining whether the final tokenization should include comments.
* Returns:
*   An array of tokens.
*/
STRING[] tokenizeFile(string file, bool includeComments)
{
  import std.file : readText;

  return tokenize(readText(file), includeComments);
}

/**
* Tokenizes content
* Params:
*   content = The content to tokenize.
*   includeComments = Boolean determining whether the final tokenization should include comments.
* Returns:
*   An array of tokens.
*/
STRING[] tokenize(string content, bool includeComments)
{
  import std.string : strip;
  import std.uni : isWhite;
  import std.conv : to;

  STRING[] tokens = [];

  if (!content || !content.strip.length)
  {
    return tokens;
  }

  STRING token;
  token.s = "";
  bool isInMultiComment;
  bool isInComment;
  bool isInChar;
  bool isInString;

  size_t line = 1;

  foreach (ref i; 0 .. content.length)
  {
    char findLast()
    {
      auto index = i - 1;
      char l = '\0';

      if (i > 0)
      {
        while (index > 0 && (l == '\0' || l.isWhite))
        {
          l = content[index];
          index--;
        }
      }

      return l;
    }

    char findNext()
    {
      auto index = i + 1;
      char n = '\0';

      if (i < (content.length - 1))
      {
        while (index < (content.length - 1)  && (n == '\0' || n.isWhite))
        {
          n = content[index];

          index++;
        }
      }

      return n;
    }

    char c = content[i];
    char last = findLast();
    char next = findNext();

    if (c == '\r' && !isInString)
    {
      continue;
    }

    token.line = line;

    if (c == '\n')
    {
      line++;
    }

    if (isInMultiComment && c == '*' && next == '/')
    {
      if (includeComments)
      {
        tokens ~= token;
        token = to!string(c) ~ to!string(next);
        tokens ~= token;
      }

      token = "";
      i++;
      isInMultiComment = false;
    }
    else if (isInString && c == '"' && last != '\\')
    {
      if (token && token.strip.length) tokens ~= token;
      token = to!string(c);
      tokens ~= token;
      token = "";
      isInString = false;
    }
    else if (isInChar && c == '\'' && last != '\\')
    {
      if (token && token.strip.length) tokens ~= token;
      token = to!string(c);
      tokens ~= token;
      token = "";
      isInChar = false;
    }
    else if (isInComment && (c == '\n' || (c == '\r' && next == '\n')))
    {
      if (includeComments)
      {
        if (token && token.strip.length) tokens ~= token;
        token = to!string(c);
        if (c == '\r' && next == '\n') token ~= to!string(c);
        tokens ~= token;
      }

      token = "";
      if (c == '\r' && next == '\n') i++;
      isInComment = false;
    }
    else if (!isInString && !isInChar && !isInComment && !isInMultiComment)
    {
      if (c == '/' && next == '/')
      {
        isInComment = true;

        if (token && token.strip.length) tokens ~= token;

        if (includeComments)
        {
          token = to!string(c) ~ to!string(next);
          tokens ~= token;
        }

        token = "";
        i++;
      }
      else if (c == '/' && next == '*')
      {
        isInMultiComment = true;

        if (token && token.strip.length) tokens ~= token;

        if (includeComments)
        {
           token = to!string(c) ~ to!string(next);
           tokens ~= token;
        }

        token = "";
        i++;
      }
      else if (c == '"')
      {
        isInString = true;

        if (token && token.strip.length) tokens ~= token;
        token = to!string(c);
        tokens ~= token;
        token = "";
      }
      else if (c == '\'')
      {
        isInChar = true;

        if (token && token.strip.length) tokens ~= token;
        token = to!string(c);
        tokens ~= token;
        token = "";
      }
      else if (isSymbol(c) || (last == ')' && c == '.'))
      {
        if (isSymbol(next) && c != ',' && next != ',' && c != '(' && c != '{' && c != ')' && c != '}' && next != '(' && next != '{' && next != ')' && next != '}' && c != ']')
        {
          if (token && token.strip.length) tokens ~= token;

          token = to!string(c) ~ to!string(next);

          tokens ~= token;
          token = "";

          i++;
        }
        else
        {
          if (token && token.strip.length) tokens ~= token;

          token = to!string(c);

          tokens ~= token;
          token = "";
        }
      }
      else if (c.isWhite)
      {
        if (token && token.strip.length) tokens ~= token;

        token = "";
      }
      else if (!c.isWhite)
      {
        token ~= c;
      }
    }
    else
    {
      token ~= c;
    }
  }

  return tokens;
}

/**
* Checks whether a character is a symbol.
* Params:
*   c = The character to check.
* Returns:
*   True if the character is a symbol, false otherwise.
*/
bool isSymbol(char c)
{
  switch (c)
  {
    //case '.': -- Stripped because it makes it easier to provide identifiers etc.
    case ',':
    case '(':
    case ')':
    case '[':
    case ']':
    case '{':
    case '}':
    case '+':
    case '-':
    case '*':
    case '/':
    case '=':
    case '?':
    case ':':
    case '%':
    case '!':
    case ';':
    case '^':
    case '~':
    case '&':
    case '#':
    case '$':
    case '@':
    case '>':
    case '<':
    case '|':
      return true;

    default: return false;
  }
}

/// A token definition.
class Token
{
  /// An array of token statements.
  STRING[] statement;
  /// An array of child tokens.
  Token[] tokens;
  /// The parent token.
  Token parent;

  /**
  * Creates a new token.
  * Params:
  *   parent = (optional) The parent token.
  */
  this(Token parent = null)
  {
    this.parent = parent;
    tokens = [];
  }
}

/**
* Groups all token statements into actual tokens.
* Params:
*   tokens = The tokens to group.
* Returns:
*   Returns the root token with all tokens grouped together.
*/
Token groupTokens(STRING[] tokens)
{
  import parser.meta : isAttribute;

  auto rootToken = new Token;
  auto currentToken = new Token(rootToken);
  currentToken.parent.tokens ~= currentToken;

  bool inString = false;

  STRING combine;
  combine.s = "";

  foreach (ref i; 0 .. tokens.length)
  {
    auto token = tokens[i];
    auto last = i > 0 ? tokens[i - 1] : STRING("", 0);
    auto next = i < (tokens.length - 1) ? tokens[i + 1] : STRING("", 0);

    if (token != "\"" && inString)
    {
      combine ~= token;
    }
    else if (token == "\"" && inString)
    {
      inString = false;

      combine ~= token;

      currentToken.statement ~= combine;
      combine.s = "";
    }
    else if (token == "\"" && !inString)
    {
      inString = true;

      combine ~= token;
    }
    else if (next == ":" && ((token.isAttribute && (!currentToken.statement || !currentToken.statement.length)) || (currentToken.statement && currentToken.statement.length && currentToken.statement[0] == "@")))
    {
      currentToken.statement ~= token;
      currentToken.statement ~= next;

      currentToken = new Token(currentToken.parent);
      currentToken.parent.tokens ~= currentToken;

      i++;
    }
    else if (token == ";")
    {
      currentToken.statement ~= token;

      currentToken = new Token(currentToken.parent);
      currentToken.parent.tokens ~= currentToken;
    }
    else if (token == "{")
    {
      currentToken = new Token(currentToken);
      currentToken.statement ~= token;
      currentToken.parent.tokens ~= currentToken;

      currentToken = new Token(currentToken.parent);
      currentToken.parent.tokens ~= currentToken;
    }
    else if (token == "}")
    {
      if (!currentToken.parent || !currentToken.parent.parent)
      {
        continue;
      }
      
      currentToken = new Token(currentToken.parent);
      currentToken.statement ~= token;
      currentToken.parent.tokens ~= currentToken;

      currentToken = new Token(currentToken.parent.parent);
      currentToken.parent.tokens ~= currentToken;
    }
    else
    {
      currentToken.statement ~= token;
    }
  }

  return rootToken;
}

/**
* Quick and dirty way to convert a token to json.
* A simple debug function that will eventaully be stripped from the compiler etc.
* Params:
*   token = The token to convert to json.
*   indent = The amount of indentation to provide.
* Returns:
*   A string equivalent to the json generated.
*/
string toJson(Token token, size_t indent)
{
  if ((!token.tokens || !token.tokens.length) && (!token.statement || !token.statement.length))
  {
    return null;
  }

  string json = `%s{
%s%s"statement": %s,
%s%s"tokens": [%s]
%s}`;

  import std.algorithm : map,filter;
  import std.array : array, join;
  import std.string : format,strip;

  string indents = "";
  string memberIndents = "";

  foreach (_; 0 .. indent)
  {
    indents ~= "  ";
    memberIndents ~= "  ";
  }

  if (indent == 0)
  {
    memberIndents = "  ";
  }

  return json.format
  (
    "",
    memberIndents, indents, token.statement ? token.statement : [],
    memberIndents, indents, (token.tokens ? (token.tokens.map!(t => toJson(t, indent + 1)).filter!(e => e && e.length).array.join(",").strip) : ""),
    indents
  );
}
