#!/usr/bin/env bats

load test_helper.bash

setup() {
  TMP_DIR=$(mktemp -d)
}

teardown() {
  rm -rf "${TMP_DIR}"
}

@test "help prints usage" {
  run "${SCRIPT_PATH}" -h

  [ "${status}" -eq 0 ]
  [[ "${output}" == *"Usage:"* ]]
  [[ "${output}" == *"Options:"* ]]
}

@test "date with format prints a 4 digit year" {
  run "${SCRIPT_PATH}" -d"%Y"

  [ "${status}" -eq 0 ]
  [[ "${output}" =~ ^[0-9]{4}$ ]]
}

@test "dry-run copy does not create destination file" {
  destination="${TMP_DIR}/copied-script.sh"

  run "${SCRIPT_PATH}" --dry-run --copy-to="${destination}"

  [ "${status}" -eq 0 ]
  [ ! -e "${destination}" ]
}

@test "copy-to creates destination file" {
  destination="${TMP_DIR}/copied-script.sh"
  destination_lib="${TMP_DIR}/copied-script-lib.sh"

  run "${SCRIPT_PATH}" --copy-to="${destination}"

  [ "${status}" -eq 0 ]
  [ -f "${destination}" ]
  [ -f "${destination_lib}" ]
}

@test "copy-to errors for directory destination" {
  run "${SCRIPT_PATH}" --copy-to="${TMP_DIR}"

  [ "${status}" -ne 0 ]
  [[ "${output}" == *"is a directory"* ]]
}

@test "copy-to errors when destination lib already exists" {
  destination="${TMP_DIR}/copied-script.sh"
  destination_lib="${TMP_DIR}/copied-script-lib.sh"
  touch "${destination_lib}"

  run "${SCRIPT_PATH}" --copy-to="${destination}"

  [ "${status}" -ne 0 ]
  [[ "${output}" == *"destination library"* ]]
}

@test "copied script runs with sibling lib" {
  destination="${TMP_DIR}/copied-script.sh"

  run "${SCRIPT_PATH}" --copy-to="${destination}"
  [ "${status}" -eq 0 ]

  run bash "${destination}" -h
  [ "${status}" -eq 0 ]
  [[ "${output}" == *"Usage:"* ]]
}

@test "greeting prints provided word" {
  run "${SCRIPT_PATH}" --greeting="hello"

  [ "${status}" -eq 0 ]
  [[ "${output}" == *"hello"* ]]
}
