module c.stdio;

include "stdio.h";

alias CSTRING = ptr:byte;

internal fn printf(CSTRING message);

fn printf(string:const message)
{
  var cstring = message.toStringz();

  printf(cstring);
}
