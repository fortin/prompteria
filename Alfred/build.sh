#!/bin/bash
# Build Prompteria.alfredworkflow (zip package for Alfred import)
set -e
cd "$(dirname "$0")"
find workflow -name '.DS_Store' -delete
cd workflow
chmod +x search_prompts.sh add_prompt.sh copy_prompt.sh setup_env.sh test_template_vars.sh
zip -r ../Prompteria.alfredworkflow info.plist icon.png search_prompts.sh add_prompt.sh copy_prompt.sh copy_prompt.py setup_env.sh test_template_vars.sh
echo "Built Prompteria.alfredworkflow"
