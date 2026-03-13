#!/usr/bin/env bash
set -euo pipefail

SRC_JSON="${SRCROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}/Prompteria/Resources/Examples/examples-prompts.json"
DEST_DIR="${BUILT_PRODUCTS_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/Examples"
DEST_JSON="${DEST_DIR}/examples-prompts.json"

if [[ ! -f "${SRC_JSON}" ]]; then
  echo "examples-prompts.json not found at ${SRC_JSON}" >&2
  exit 1
fi

# Basic JSON validation
if ! /usr/bin/plutil -lint -s "${SRC_JSON}" >/dev/null 2>&1; then
  echo "examples-prompts.json is not valid JSON" >&2
  /usr/bin/plutil -lint "${SRC_JSON}"
  exit 1
fi

mkdir -p "${DEST_DIR}"
cp "${SRC_JSON}" "${DEST_JSON}"

echo "Validated and copied examples-prompts.json to ${DEST_JSON}"

