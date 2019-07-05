/**
* Initial test module.
*/
module main;

fn main(string[]:const args)
{
  var i = 0;

  while i < 10
  {
    writeln(i);

    i++;
  }

  i = 0;

  do
  {
    writeln(i);

    i++;
  } while i < 10;
}
