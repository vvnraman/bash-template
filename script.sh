#!/usr/bin/env bash
# vim: set ft=bash

set -o errexit
set -o nounset
set -o pipefail

SCRIPT_DIR=$(dirname "$(readlink --canonicalize-existing "${0}" 2>/dev/null)")
readonly SCRIPT="${0##*/}"
readonly SCRIPT_PATH="${SCRIPT_DIR}/${SCRIPT}"
if [[ "${SCRIPT}" == *.sh ]]; then
  readonly SCRIPT_BASENAME="${SCRIPT%.sh}"
else
  readonly SCRIPT_BASENAME="${SCRIPT}"
fi
readonly SCRIPT_LIB="${SCRIPT_BASENAME}-lib.sh"
readonly SCRIPT_LIB_PATH="${SCRIPT_DIR}/${SCRIPT_LIB}"

# shellcheck disable=SC1090
source "${SCRIPT_LIB_PATH}"
# After sourcing script-lib.sh and calling init_common_state, we have:
# - readonly log decorators (non-color prefixes): A, B, C, S, E, NL
# - OPTIONS associative array initialized as: dry_run=0, verbose=0
init_common_state

readonly SCRIPT_DESCRIPTION="A template bash script to be used to create new bash scripts."

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

# Builds parser/help globals from SCRIPT_ARGS/EXAMPLES:
# - SHORT_FLAGS, LONG_FLAGS (used by getopt inside script-lib.sh:parse_options_with_handler)
# - QUICK_HELP_ARGS_STR, HELP_EXPANDED_STR, EXAMPLES_STR (used by usage output)
construct_help_str_and_flags
readonly HELP_EXPANDED_STR
readonly EXAMPLES_STR

function usage {
  # Renders usage text using SCRIPT, QUICK_HELP_ARGS_STR, HELP_EXPANDED_STR, EXAMPLES_STR.
  print_usage "${SCRIPT_DESCRIPTION}"
}

declare DATE_ARG=0
declare DATE_FORMAT=""
declare GREETING_ARG=""
declare COPY_ARG=""
declare HELP_ARG=0

function handle_option_cb {
  case "${1}" in
  -d | --date)
    DATE_ARG=1
    if [[ -n "${2:-}" ]]; then
      DATE_FORMAT="${2}"
      PARSE_SHIFT=2
    else
      PARSE_SHIFT=1
    fi
    ;;
  -c | --copy-to)
    COPY_ARG="${2}"
    PARSE_SHIFT=2
    ;;
  -g | --greeting)
    GREETING_ARG="${2}"
    PARSE_SHIFT=2
    ;;
  -v)
    OPTIONS["verbose"]=1
    PARSE_SHIFT=1
    ;;
  -n | --dry-run)
    OPTIONS["dry_run"]=1
    PARSE_SHIFT=1
    ;;
  -h | --help)
    HELP_ARG=1
    PARSE_SHIFT=1
    ;;
  *)
    log_e "unknown option '${1}'"
    PARSE_SHIFT=1
    ;;
  esac
}

function main {
  local -r args=("${@}")

  DATE_ARG=0
  DATE_FORMAT=""
  GREETING_ARG=""
  COPY_ARG=""
  HELP_ARG=0
  # Parses args and dispatches each option to handle_option_cb.
  # Sets shared globals:
  # - REMAINING_ARGS: positional args left after option parsing
  # - PARSE_SHIFT: per-option shift value consumed by parser internals
  parse_options_with_handler "handle_option_cb" "${args[@]}"

  if ((OPTIONS["dry_run"])); then
    echo "${B} Dry run output wanted"
  fi

  if ((OPTIONS["verbose"])); then
    echo "${B} verbose output wanted"
  fi

  ((OPTIONS["verbose"])) && echo "${B} Remaining args = ${REMAINING_ARGS[*]}"
  if ((DATE_ARG)); then
    do_date "${DATE_FORMAT}"
  fi

  if [[ -n "${GREETING_ARG}" ]]; then
    do_greeting "${GREETING_ARG}"
  fi

  if [[ -n "${COPY_ARG}" ]]; then
    do_copy_to "${COPY_ARG}"
  fi

  if ((HELP_ARG)); then
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

function do_greeting {
  local -r greeting_word="${1}"
  echo "${S}${greeting_word}"
}

function do_copy_to {
  local copy_to="${1}"
  echo "${B} Copying '${SCRIPT_PATH}' to '${copy_to}'"

  # Expands leading '~' to HOME.
  local -r dest="$(expand_tilde "${copy_to}")"

  if [[ -d "${dest}" ]]; then
    echo "${E} '${copy_to}' is a directory. Provide a destination file path."
    return 1
  fi

  local -r dest_file="${dest}"
  local -r dest_dir="$(dirname "${dest_file}")"
  local -r dest_script_name="${dest_file##*/}"
  local dest_script_basename
  if [[ "${dest_script_name}" == *.sh ]]; then
    dest_script_basename="${dest_script_name%.sh}"
  else
    dest_script_basename="${dest_script_name}"
  fi
  local -r dest_lib_file="${dest_dir}/${dest_script_basename}-lib.sh"

  ((OPTIONS["verbose"])) && echo "${C} Copying '${SCRIPT_PATH}' to '${dest_file}'"

  if [[ ! -d "${dest_dir}" ]]; then
    echo "${E} destination directory '${dest_dir}' does not exist."
    return 1
  elif [[ -e "${dest_file}" ]]; then
    echo "${E} '${copy_to}' already exists."
    return 1
  elif [[ -e "${dest_lib_file}" ]]; then
    echo "${E} destination library '${dest_lib_file}' already exists."
    return 1
  elif [[ ! -f "${SCRIPT_LIB_PATH}" ]]; then
    echo "${E} missing library '${SCRIPT_LIB_PATH}'"
    return 1
  else
    if ! ((OPTIONS["dry_run"])); then
      cp "${SCRIPT_PATH}" "${dest_file}"
      echo "# created by copying ${SCRIPT_PATH} on $(date --utc +'%Y%m%d_%H%M%S')" >>"${dest_file}"

      echo "${B} Copying '${SCRIPT_LIB_PATH}' to '${dest_lib_file}'"
      cp "${SCRIPT_LIB_PATH}" "${dest_lib_file}"
      echo "# created by copying ${SCRIPT_LIB_PATH} on $(date --utc +'%Y%m%d_%H%M%S')" >>"${dest_lib_file}"
    fi
  fi

}

main "${@}"
