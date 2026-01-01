#!/usr/bin/env bash
# vim: set ft=bash

set -o errexit
set -o nounset
set -o pipefail

# shellcheck disable=SC2034
{
  SCRIPT_DIR=$(dirname "$(readlink --canonicalize-existing "${0}" 2>/dev/null)")
  readonly SCRIPT="${0##*/}"
  readonly SCRIPT_PATH="${SCRIPT_DIR}/${SCRIPT}"

  readonly A="══"
  readonly B="──"
  readonly C="┄┄"
  readonly S=" "
  readonly E=" "
  readonly NL="
"

  declare -A OPTIONS
  OPTIONS["dry_run"]=0
  OPTIONS["verbose"]=0
}

declare -A SCRIPT_ARGS
declare -A EXAMPLES
SCRIPT_ARGS["h"]="help; Print this help and exit"
EXAMPLES["h"]="
${SCRIPT} -h
  Print usage and exit

${SCRIPT} --help
  Print usage and exit
"
SCRIPT_ARGS["n"]="dry-run; Dry run only"
SCRIPT_ARGS["v"]="Produce verbose output"
SCRIPT_ARGS["d::"]="date; [=format]; Print current date"
EXAMPLES["d::"]="
${SCRIPT} -d
  Prints current date via the \"date\" command

${SCRIPT} -d\"%Y\"
  Prints current year via the \"date\" command and \"%Y\" format string

${SCRIPT} --date=\"%Y\"
  Prints current year via the \"date\" command and \"%Y\" format string

Common mistakes when providing the '-d'/'--date' argument

${SCRIPT} -d=\"%Y\"
  '=\"%Y\"' is taken as the full argument to \"-d\", instead of just '\"%Y\"'

${SCRIPT} -d \"%Y\"
  '\"%Y\"' is now a positional parameter, and not an argument to '-d'

${SCRIPT} --date \"%Y\"
  '\"%Y\"' is now a positional parameter, and not an argument to '--date'
"
SCRIPT_ARGS["g:"]="greeting; ='word'; Word to greet with"
SCRIPT_ARGS["c:"]="copy-to; ='path'; Copy this script to the given 'path'"
readonly SCRIPT_ARGS
readonly EXAMPLES

function strip_trailing_colon {
  printf '%s' "${1%%:}"
}

function strip_trailing_double_colon {
  printf '%s' "${1%%::}"
}

function trim_leading_ws {
  printf '%s' "${1#"${1%%[![:space:]]*}"}"
}

function expand_tilde {
  if [[ ! "${HOME-}" ]]; then
    # We want to abort here actually
    true
  fi
  printf '%s' "${1/#~/${HOME}}"
}

declare HELP_EXPANDED_STR=""
declare EXAMPLES_STR=""
declare QUICK_HELP_ARGS_STR=""
declare SHORT_FLAGS=""
declare LONG_FLAGS=""
function construct_help_str_and_flags {
  local long_sep=","
  local long_count=0
  for key in "${!SCRIPT_ARGS[@]}"; do

    long_sep=","
    if [[ ${long_count} -eq 0 ]]; then
      long_sep=""
    fi

    local value="${SCRIPT_ARGS[${key}]}"
    declare -a values
    # size 1, 2 or 3
    IFS=';' read -r -a values <<<"${value}"

    # append to '--options' flag for 'getopt'
    SHORT_FLAGS+="${key}"

    local long_flag_suffix=""

    local short_flag_str
    if [[ $key == *:: ]]; then
      short_flag_str="-$(strip_trailing_double_colon "${key}")"
      long_flag_suffix="::"
    elif [[ $key == *: ]]; then
      short_flag_str="-$(strip_trailing_colon "${key}")"
      long_flag_suffix=":"
    else
      short_flag_str="-${key}"
    fi

    local long_flag_str=""
    local opt_arg=""
    local help_text=""
    local short_long_sep=""

    if [[ ${#values[@]} -eq 1 ]]; then
      # Size 1 means we have no long flag

      help_text="$(trim_leading_ws "${values[*]}")"
      QUICK_HELP_ARGS_STR+="${short_flag_str} "

    elif [[ ${#values[@]} -eq 2 ]]; then
      # Size 2 means we have a long flag, but no argument

      # append optional ',' and the short flag to show in help args
      long_flag_str="--${values[0]}"
      help_text="$(trim_leading_ws "${values[*]:1}")"
      QUICK_HELP_ARGS_STR+="${short_flag_str}/${long_flag_str} "
      LONG_FLAGS+="${long_sep}${values[0]}${long_flag_suffix}"
      short_long_sep=","
      long_count=$((long_count + 1))

    else
      # size 3 (or more) means we have a along flag and an (optional) argument

      opt_arg="$(trim_leading_ws "${values[1]}")"
      long_flag_str="--${values[0]}${opt_arg}"
      help_text="$(trim_leading_ws "${values[*]:2}")"
      QUICK_HELP_ARGS_STR+="${short_flag_str}/${long_flag_str} "
      LONG_FLAGS+="${long_sep}${values[0]}${long_flag_suffix}"
      short_long_sep=","
      long_count=$((long_count + 1))

    fi

    HELP_EXPANDED_STR+="  ${short_flag_str}${short_long_sep} ${long_flag_str}${NL}        ${help_text}${NL}"
  done

  for ex in "${!EXAMPLES[@]}"; do
    EXAMPLES_STR+="${EXAMPLES[${ex}]}"
  done
}
construct_help_str_and_flags
readonly HELP_EXPANDED_STR
readonly EXAMPLES_STR

function usage {

  cat <<USAGE_EOF
Usage:
    ${SCRIPT} ${QUICK_HELP_ARGS_STR}

Description:
    A template bash script to be used to create new bash scripts.

Options:
${HELP_EXPANDED_STR}
Examples:
${EXAMPLES_STR}
USAGE_EOF
}

function main {
  local -r args=("${@}")

  local opts
  opts=$(getopt \
    --options "${SHORT_FLAGS}" \
    --longoptions "${LONG_FLAGS}" \
    -- "${args[@]}")

  if [[ $? -ne 0 ]]; then
    echo "${E} failed to parse some arguments" >&2
    usage
    exit 1
  fi

  eval set -- "${opts}"

  while true; do
    case "${1}" in
    -d | --date)
      local -r date_arg=1
      if [[ -n "${2:-}" ]]; then
        local -r date_format="${2}"
        shift 2
      else
        shift
      fi
      ;;
    -c | --copy-to)
      local -r copy_arg="${2}"
      shift 2
      ;;
    -v)
      OPTIONS["verbose"]=1
      shift
      ;;
    -n | --dry-run)
      OPTIONS["dry_run"]=1
      shift
      ;;
    -h | --help)
      local -r help_arg=1
      shift
      ;;
    --)
      shift
      break
      ;;
    *)
      break
      ;;
    esac
  done

  if ((OPTIONS["dry_run"])); then
    echo "${B} Dry run output wanted"
  fi

  if ((OPTIONS["verbose"])); then
    echo "${B} verbose output wanted"
  fi

  ((OPTIONS["verbose"])) && echo "${B} Remaining args = ${*}"
  if [[ ${date_arg-} ]]; then
    do_date "${date_format-}"
  fi

  if [[ ${copy_arg-} ]]; then
    do_copy_to "${copy_arg}"
  fi

  if [[ ${help_arg-} ]]; then
    usage
    exit
  fi

}

function do_date {
  local date_format="${1}"
  ((OPTIONS["verbose"])) && echo "${B} Date flag provided"
  if [[ ${date_format-} ]]; then
    ((OPTIONS["verbose"])) && echo "${B} Date format provided '${date_format}'"
    date +"${date_format}"
  else
    date
  fi
}

function do_copy_to {
  local copy_to="${1}"
  echo "${B} Copying '${SCRIPT_PATH}' to '${copy_to}'"

  local -r dest="$(expand_tilde "${copy_to}")"

  local dest_file
  if [[ -d "${dest}" && -f "${dest}/${SCRIPT}" ]]; then
    dest_file="${dest}/${SCRIPT}"
  else
    dest_file="${dest}"
  fi

  ((OPTIONS["verbose"])) && echo "${C} Copying '${SCRIPT_PATH}' to '${dest_file}'"

  if [[ -d "${dest}" && -f "${dest_file}" ]]; then
    echo "${E} '${copy_to}' already contains '${SCRIPT}'."
  elif [[ -f "${dest_file}" ]]; then
    echo "${E} '${copy_to}' already exists."
  else
    if ! ((OPTIONS["dry_run"])); then
      cp "${SCRIPT_PATH}" "${dest_file}"
      echo "# created by copying ${SCRIPT_PATH} on $(date --utc +'%Y%m%d_%H%M%S')" >>"${dest_file}"
    fi
  fi

}

main "${@}"
