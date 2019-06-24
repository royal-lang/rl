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
    char c = content[i];
    char last = i > 0 ? content[i - 1] : '\0';
    char next = i < (content.length - 1) ? content[i + 1] : '\0';

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
      else if (isSymbol(c))
      {
        if (token && token.strip.length) tokens ~= token;

        token = to!string(c);

        tokens ~= token;
        token = "";
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
    case '.':
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
      return true;

    default:
      return false;
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
  auto rootToken = new Token;
  auto currentToken = new Token(rootToken);
  currentToken.parent.tokens ~= currentToken;

  foreach (token; tokens)
  {
    if (token == ";")
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
