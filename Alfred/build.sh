#!/bin/bash
# Build Prompteria.alfredworkflow (zip package for Alfred import)
set -e
cd "$(dirname "$0")"
find workflow -name '.DS_Store' -delete
cd workflow
zip -r ../Prompteria.alfredworkflow info.plist search_prompts.sh add_prompt.sh
echo "Built Prompteria.alfredworkflow"
