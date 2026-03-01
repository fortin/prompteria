#!/bin/bash
# Test template variable dialog. Run manually to verify setup works.
# Usage: ./test_template_vars.sh

cd "$(dirname "$0")"
echo 'Test prompt with {{ROOM}} and {{VIBE}} variables.' | ./copy_prompt.sh
echo ""
