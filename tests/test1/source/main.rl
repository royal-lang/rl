/**
* Initial test module.
*/
module main;

fn main(string[]:const args)
{
  var array = [1,2,3];
  foreach (item, array)
  {
      writeln(item);
  }

  foreach (i, 0 .. array.length)
  {
      var item = array.get(i);

      writeln(item);
  }

  var aa = ["First Number": 1, "Second Item": 2];

  foreach (k,v, aa)
  {
      writefln("Key: %s, Value: %d", k, v);
  }

  foreach (k,v, 0 .. aa.length)
  {
      writefln("Key: %s, Value: %d", k, v);
  }
}
