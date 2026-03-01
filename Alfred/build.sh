#!/bin/bash
# Build Promptastic.alfredworkflow (zip package for Alfred import)
set -e
cd "$(dirname "$0")"
find workflow -name '.DS_Store' -delete
cd workflow
zip -r ../Promptastic.alfredworkflow info.plist search_prompts.sh add_prompt.sh
echo "Built Promptastic.alfredworkflow"
