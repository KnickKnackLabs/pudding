REPO_DIR="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"

setup() {
  source "$REPO_DIR/lib/grammar.sh"
}

# Write a test script to a temp file and return its path
write_script() {
  local file="$BATS_TEST_TMPDIR/test_script.sh"
  cat > "$file"
  echo "$file"
}
