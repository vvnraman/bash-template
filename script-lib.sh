#!/usr/bin/env bash

function init_common_state {
  # shellcheck disable=SC2034
  {
    readonly A="══"
    readonly B="──"
    readonly C="┄┄"
    readonly S=" "
    readonly E=" "
    readonly NL="
"

    declare -g -A OPTIONS
    OPTIONS["dry_run"]=0
    OPTIONS["verbose"]=0
  }
}

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

function check_cmd {
  local -r tool="${1}"
  if ! command -v "${tool}" >/dev/null 2>&1; then
    log_e "'${tool}' is missing from the system"
    return 1
  fi
  log_c "'${tool}' is available"
  return 0
}

function element_in_array {
  local needle="${1}"
  shift
  local haystack=("${@}")

  for item in "${haystack[@]}"; do
    [[ "${needle}" == "${item}" ]] && return 0
  done
  return 1
}

function log {
  if ! ((OPTIONS["verbose"])); then
    return 0
  fi
  echo "${@}" >&1
}

function log_a {
  echo "${A}" "${@}" >&1
}

function log_b {
  log "${B}" "${@}"
}

function log_c {
  log "${C}" "${@}"
}

function log_s {
  echo "${S}" "${@}" >&1
}

function log_e {
  echo "${E}" "${@}" >&2
}

declare HELP_EXPANDED_STR=""
declare EXAMPLES_STR=""
declare QUICK_HELP_ARGS_STR=""
declare SHORT_FLAGS=""
declare LONG_FLAGS=""
function construct_help_str_and_flags {
  HELP_EXPANDED_STR=""
  EXAMPLES_STR=""
  QUICK_HELP_ARGS_STR=""
  SHORT_FLAGS=""
  LONG_FLAGS=""

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

    local long_flag_suffix=""
    local help_args_str=""
    local short_quick_help=""

    local short_flag_str
    if [[ $key == -* ]]; then
      short_flag_str="  "
      short_quick_help=""
      help_args_str="   "
    else
      # append to '--options' flag for 'getopt'
      SHORT_FLAGS+="${key}"

      if [[ $key == *:: ]]; then
        short_flag_str="-$(strip_trailing_double_colon "${key}")"
        long_flag_suffix="::"
      elif [[ $key == *: ]]; then
        short_flag_str="-$(strip_trailing_colon "${key}")"
        long_flag_suffix=":"
      else
        short_flag_str="-${key}"
      fi
      short_quick_help="${short_flag_str}/"
      help_args_str="${short_flag_str},"
    fi

    local long_flag_str=""
    local opt_arg=""
    local help_text=""

    if [[ ${#values[@]} -eq 1 ]]; then
      # Size 1 means we have no long flag

      help_text="$(trim_leading_ws "${values[*]}")"

      if [[ "${short_flag_str}" == "  " ]]; then
        log_e "No short and long flag for '${help_text}'"
        return 1
      fi

      QUICK_HELP_ARGS_STR+="${short_flag_str} "

    elif [[ ${#values[@]} -eq 2 ]]; then
      # Size 2 means we have a long flag, but no argument

      # append optional ',' and the short flag to show in help args
      long_flag_str="--${values[0]}"
      help_text="$(trim_leading_ws "${values[*]:1}")"
      QUICK_HELP_ARGS_STR+="${short_quick_help}${long_flag_str} "
      LONG_FLAGS+="${long_sep}${values[0]}${long_flag_suffix}"
      help_args_str+=" ${long_flag_str}"
      long_count=$((long_count + 1))

    else
      # size 3 (or more) means we have a along flag and an (optional) argument

      opt_arg="$(trim_leading_ws "${values[1]}")"
      long_flag_str="--${values[0]}${opt_arg}"
      help_text="$(trim_leading_ws "${values[*]:2}")"
      QUICK_HELP_ARGS_STR+="${short_quick_help}${long_flag_str} "
      LONG_FLAGS+="${long_sep}${values[0]}${long_flag_suffix}"
      help_args_str+=" ${long_flag_str}"
      long_count=$((long_count + 1))

    fi

    HELP_EXPANDED_STR+="  ${help_args_str}${NL}        ${help_text}${NL}"
  done

  for ex in "${!EXAMPLES[@]}"; do
    EXAMPLES_STR+="${EXAMPLES[${ex}]}"
  done
}

function print_usage {
  local -r description="${1}"

  cat <<USAGE_EOF
Usage:
    ${SCRIPT} ${QUICK_HELP_ARGS_STR}

Description:
    ${description}

Options:
${HELP_EXPANDED_STR}
Examples:
${EXAMPLES_STR}
USAGE_EOF
}

declare PARSE_SHIFT=0
declare -a REMAINING_ARGS=()
function parse_options_with_handler {
  local -r handler_cb="${1}"
  shift

  local -a args=("${@}")
  local opts
  opts=$(getopt \
    --options "${SHORT_FLAGS}" \
    --longoptions "${LONG_FLAGS}" \
    -- "${args[@]}")

  if [[ $? -ne 0 ]]; then
    echo "${E} failed to parse some arguments" >&2
    usage
    return 1
  fi

  eval set -- "${opts}"

  while true; do
    case "${1}" in
    --)
      shift
      break
      ;;
    *)
      PARSE_SHIFT=0
      "${handler_cb}" "${@}"
      if ((PARSE_SHIFT <= 0)); then
        echo "${E} parser produced invalid shift for '${1}'" >&2
        return 1
      fi
      shift "${PARSE_SHIFT}"
      ;;
    esac
  done

  REMAINING_ARGS=("${@}")
}
