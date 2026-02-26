# My `bash` script template

Use like so

```sh
./script --copy-to=~/.local/bin/vvnraman/new-script
```

## Table of contents

- [Full usage](#full-usage)
- [Tests (Bats)](#tests-bats)

## Full usage

```sh
Usage:
    script.sh -d/--date[=format] -v -n/--dry-run -h/--help -c/--copy-to='path' -g/--greeting='word' 

Description:
    A template bash script to be used to create new bash scripts.

Options:
  -d, --date[=format]
        Print current date
  -v,
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

script.sh -d
  Prints current date via the "date" command

script.sh -d"%Y"
  Prints current year via the "date" command and "%Y" format string

script.sh --date="%Y"
  Prints current year via the "date" command and "%Y" format string

Common mistakes when providing the '-d'/'--date' argument

script.sh -d="%Y"
  '="%Y"' is taken as the full argument to "-d", instead of just '"%Y"'

script.sh -d "%Y"
  '"%Y"' is now a positional parameter, and not an argument to '-d'

script.sh --date "%Y"
  '"%Y"' is now a positional parameter, and not an argument to '--date'

script.sh -h
  Print usage and exit

script.sh --help
  Print usage and exit

```

## Tests (Bats)

Run all tests:

```sh
make test
```

This builds an Arch-based Docker image (`Dockerfile`) with `bats` installed, then runs
`tests/*.bats` inside the container.

Other useful targets:

```sh
make test-verbose
make test-shell
make clean-test-image
```

### Usage

Output of `make`:

```text
clean-test-image               Remove the local test image
help                           Show available targets
test                           Run bats test suite
test-image                     Build the Arch test image
test-shell                     Open an interactive container shell
test-verbose                   Run bats with test names
```
