#!/usr/bin/env bash

PROJECT_ROOT=$(dirname "$(dirname "$(readlink --canonicalize-existing "${BATS_TEST_FILENAME}" 2>/dev/null)")")
readonly PROJECT_ROOT

SCRIPT_PATH="${PROJECT_ROOT}/script.sh"
readonly SCRIPT_PATH
