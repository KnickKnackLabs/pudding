#!/usr/bin/env bash
# common.sh — shared helpers for pudding tasks

# The pudding tool's own repo
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# The target repo is always CALLER_PWD (set by shiv shim)
TARGET_DIR="${CALLER_PWD:-.}"
