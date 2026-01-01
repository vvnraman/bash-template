# My `bash` script template

Use like so

```sh
./script --copy-to=~/.local/bin/vvnraman/new-script
```

## Full usage

```sh
Usage:
    script -d/--date[=format] -v -n/--dry-run -h/--help -c/--copy-to='path' -g/--greeting='word'

Description:
    A template bash script to be used to create new bash scripts.

Options:
  -d, --date[=format]
        Print current date
  -v 
        Produce verbose output
  -n, --dry-run
        Dry run only
  -h, --help
        Print this help and exit
  -c, --copy-to='path'
        Copy this script to the given 'path'
  -g, --greeting='word'
        Word to greet with

Examples:

script -d
  Prints current date via the "date" command

script -d"%Y"
  Prints current year via the "date" command and "%Y" format string

script --date="%Y"
  Prints current year via the "date" command and "%Y" format string

Common mistakes when providing the '-d'/'--date' argument

script -d="%Y"
  '="%Y"' is taken as the full argument to "-d", instead of just '"%Y"'

script -d "%Y"
  '"%Y"' is now a positional parameter, and not an argument to '-d'

script --date "%Y"
  '"%Y"' is now a positional parameter, and not an argument to '--date'

script -h
  Print usage and exit

script --help
  Print usage and exit
```
