/**
* Module for file management during compuler configuration.
*
* License: MIT (https://github.com/Royal Programming Language/bl/blob/master/LICENSE)
*
* Copyright 2019 © Royal Programming Language - All Rights Reserved.
*/
module configuration.files;

/**
* Loads all directory entries.
* Params:
*   directory = The directory to load entries from.
*   files = (out) The file entries of the directory.
*   directories = (out) The sub-directories of the directory.
* Returns:
*   Returns true if the directory has any entries, false otherwise.
*/
bool loadEntries(string directory, out string[] files, out string[] directories)
{
  import std.file : dirEntries, SpanMode, isFile, isDir;
  import std.array : replace;
  import std.algorithm : endsWith;

  files = [];
  directories = [];

  foreach (string entryName; dirEntries(directory, SpanMode.shallow))
  {
    if (isFile(entryName) && entryName.endsWith(".rl"))
    {
      files ~= entryName.replace("\\", "/");
    }
    else if (isDir(entryName))
    {
      directories ~= entryName.replace("\\", "/");
    }
  }

  return (files && files.length) || (directories && directories.length);
}
