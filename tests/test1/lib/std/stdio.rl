module std.stdio;

import c.stdio : printf;

fn writeln(string message)
{
  printf(message);
}
