/**
* Initial test module.
*/
module main;

fn main(string[]:const args)
{
  enum Color
  {
    red = 0;
    blue = 1;
    green;
  }

  enum Flag : ubyte
  {
    flag1;
    flag2 = 4;
    flag3;
  }

  enum A = 200 * 2 + 3 + b;
  enum B = A * 20;
  enum C = getC();
}
