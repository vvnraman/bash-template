# Argument Parsing

This document explains the reusable argument-definition format and how
`construct_help_str_and_flags` turns that format into:

- parser inputs for `getopt`
- help text shown to users

## Mental Model

The high-level flow is:

1. We define option metadata once in `SCRIPT_ARGS` and `EXAMPLES`.
2. `construct_help_str_and_flags` derives parser-ready and help-ready globals.
3. `parse_options_with_handler` consumes parser globals.
4. `usage`/`print_usage` consumes help globals.

So the contract is: **input schema -> generated globals -> parser/help behavior**.
This function is the central place where that contract stays consistent.

## Input Format: `SCRIPT_ARGS`

`SCRIPT_ARGS` is an associative array where:

- the **key** encodes short-flag shape (`h`, `d:`, `d::`, etc.)
- the **value** is a semicolon-delimited string with 1-3 parts

From `script.sh`:

```bash
SCRIPT_ARGS["h"]="help; Print this help and exit"
SCRIPT_ARGS["n"]="dry-run; Dry run only"
SCRIPT_ARGS["v"]="Produce verbose output"
SCRIPT_ARGS["d::"]="date; [=format]; Print current date"
```

### Key syntax

- `h` -> short flag `-h`, no value
- `c:` -> short flag `-c`, required value
- `d::` -> short flag `-d`, optional value

### Value syntax

The value is split by `;` into `values[]`.

There are 3 accepted shapes:

1. **1 part**: `help text`
   - used by: `SCRIPT_ARGS["v"]="Produce verbose output"`
   - components:
     - `key` (`v`) defines short flag `-v`
     - `values[0]` is help text
     - no long flag is generated

2. **2 parts**: `long-name; help text`
   - used by:
     - `SCRIPT_ARGS["h"]="help; Print this help and exit"`
     - `SCRIPT_ARGS["n"]="dry-run; Dry run only"`
   - components:
     - `key` (`h` / `n`) defines short flag (`-h` / `-n`)
     - `values[0]` defines long flag name (`help` / `dry-run`)
     - `values[1]` is help text

3. **3+ parts**: `long-name; value-descriptor; help text`
   - used by: `SCRIPT_ARGS["d::"]="date; [=format]; Print current date"`
   - components:
     - `key` (`d::`) defines short flag `-d` with optional arg
     - `values[0]` defines long flag name (`date`)
     - `values[1]` is value descriptor shown in usage (`[=format]`)
     - `values[2...]` are joined as help text

Notes:

- `value-descriptor` is display-oriented (help text), for example `[=format]`.
- whether the value is required/optional is still controlled by the **key** (`:` vs `::`).

## Input Format: `EXAMPLES`

`EXAMPLES` is also an associative array keyed by the same option key (`h`, `d::`, etc.).

- each value is a preformatted multiline text block
- all blocks are concatenated into one examples section

Example:

```bash
EXAMPLES["h"]="
${SCRIPT} -h
  Print usage and exit

${SCRIPT} --help
  Print usage and exit
"
```

## Generated Variables

`construct_help_str_and_flags` writes these globals:

- `SHORT_FLAGS`: compact short spec for `getopt --options`
- `LONG_FLAGS`: comma-separated long spec for `getopt --longoptions`
- `QUICK_HELP_ARGS_STR`: one-line usage flags (`-h/--help -d/--date[=format] ...`)
- `HELP_EXPANDED_STR`: multiline options section
- `EXAMPLES_STR`: concatenated examples section

These are recomputed from scratch on each call.

## How `construct_help_str_and_flags` Works

### 1) Iterate over `SCRIPT_ARGS`

For each entry:

- split the value by `;` into `values[]`
- inspect key suffix (`:`, `::`, or none)
- build short/long flag display strings
- append parser specs (`SHORT_FLAGS`, `LONG_FLAGS`)
- append help display strings (`QUICK_HELP_ARGS_STR`, `HELP_EXPANDED_STR`)

### 2) Handle the three value-shapes

- **1-part value**
  - no long flag
  - uses short flag only
  - appends short flag to quick help

- **2-part value**
  - first part is long flag name
  - second part is help text
  - appends long flag to parser + help strings

- **3+ part value**
  - first part is long flag name
  - second part is value descriptor for help output
  - remaining text is help text
  - appends long flag plus descriptor to help strings

### 3) Build examples block

After options processing, all `EXAMPLES[...]` entries are concatenated into `EXAMPLES_STR`.
