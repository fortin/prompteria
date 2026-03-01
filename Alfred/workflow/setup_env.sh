#!/bin/bash
# Create a micromamba environment for the Prompteria Alfred workflow.
# This env includes Python with tkinter for template variable dialogs.
# Run once: ./setup_env.sh
#
# Requires: micromamba (https://mamba.readthedocs.io/en/latest/installation/micromamba-installation.html)
#   curl -Ls https://micro.mamba.pm/api/micromamba/darwin-arm64/latest | tar -xvj bin/micromamba

set -e

ENV_NAME="prompteria"
ENV_DIR="$HOME/micromamba/envs/$ENV_NAME"

if command -v micromamba &>/dev/null; then
    echo "Creating env '$ENV_NAME' at ~/micromamba/envs/$ENV_NAME"
    mkdir -p "$HOME/micromamba/envs"
    micromamba create -y -n "$ENV_NAME" python=3.12 tk -r "$HOME/micromamba"
elif command -v mamba &>/dev/null; then
    echo "Creating env '$ENV_NAME' at: $ENV_DIR"
    mamba create -y -n "$ENV_NAME" python=3.12 tk
elif command -v conda &>/dev/null; then
    echo "Creating env '$ENV_NAME'"
    conda create -y -n "$ENV_NAME" python=3.12 tk
else
    echo "micromamba, mamba, or conda not found. Install micromamba:"
    ARCH=$(uname -m)
    case "$ARCH" in
        arm64) URL="darwin-arm64" ;;
        x86_64) URL="darwin-x64" ;;
        *) URL="darwin-arm64" ;;
    esac
    echo "  curl -Ls https://micro.mamba.pm/api/micromamba/$URL/latest | tar -xvj bin/micromamba"
    echo "  sudo mv bin/micromamba /usr/local/bin/"
    exit 1
fi
echo ""
echo "Done. Env is at ~/micromamba/envs/$ENV_NAME"
echo "Re-import the Prompteria workflow if needed."
