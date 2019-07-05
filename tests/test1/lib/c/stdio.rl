module c.stdio;

fn printf(string:const message)
{
  include "stdio.h";
  
  alias CSTRING = ptr:byte;

  internal fn printf(CSTRING message);

  var cstring = message.toStringz();

  printf(cstring);
}
