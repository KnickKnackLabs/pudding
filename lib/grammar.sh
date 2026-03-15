#!/usr/bin/env bash
# grammar.sh — pudding subset grammar definition and parser
#
# The pudding subset of bash (v0):
#   program     := statement*
#   statement   := assignment | conditional | command | comment
#   assignment  := NAME '=' STRING
#   conditional := 'if' test '; then' body ('else' body)? 'fi'
#   test        := '[' expr ']' | '[[' expr ']]'
#   expr        := STRING '=' STRING | STRING '!=' STRING
#                | '-z' STRING | '-n' STRING
#   body        := statement*
#   command     := 'exit' NUMBER | 'return' NUMBER | 'true' | 'false'
#   comment     := '#' .*
#   STRING      := '"' [^"]* '"' | "'" [^']* "'" | NAME | '$' NAME | '${' NAME '}'
#   NAME        := [a-zA-Z_][a-zA-Z0-9_]*
#   NUMBER      := [0-9]+
#
# Intentionally excluded from v0:
#   pipes, subshells, command substitution, arithmetic,
#   arrays, functions, loops, globs, parameter expansion,
#   here-docs, process substitution, eval, source

# Patterns that indicate a script has left the pudding subset
FORBIDDEN_PATTERNS=(
  # Pipes and process control
  '|'
  '&'
  # Command substitution
  '$('
  '`'
  # Arithmetic
  '$(('
  'let '
  # Arrays
  'declare -a'
  'declare -A'
  # Loops
  'for '
  'while '
  'until '
  # Functions
  'function '
  # Dangerous builtins
  'eval '
  'source '
  '\. '
  # Heredocs
  '<<'
  # Globs and process substitution
  '<('
  '>('
  # Redirection (for now)
  '>'
  '<'
)

# Check if a line contains only constructs in the pudding subset
# Returns 0 if the line is within the subset, 1 otherwise
check_line() {
  local line="$1"
  local trimmed="${line#"${line%%[![:space:]]*}"}"

  # Empty lines and comments are always valid
  [[ -z "$trimmed" || "$trimmed" == \#* ]] && return 0

  # Shebang is valid
  [[ "$trimmed" == "#!/"* ]] && return 0

  # set -euo pipefail is valid (common preamble)
  [[ "$trimmed" == "set -"* ]] && return 0

  # Check for forbidden patterns
  for pattern in "${FORBIDDEN_PATTERNS[@]}"; do
    if [[ "$trimmed" == *"$pattern"* ]]; then
      # Allow '=' in assignments (not '|' in pipes etc.)
      # Allow '#' in comments (already handled above)
      echo "$pattern"
      return 1
    fi
  done

  return 0
}

# Check an entire file against the pudding subset
# Returns 0 if the file is within the subset
# Prints violations to stderr
check_file() {
  local file="$1"
  local violations=0
  local line_num=0

  while IFS= read -r line || [[ -n "$line" ]]; do
    line_num=$((line_num + 1))
    local forbidden
    if forbidden=$(check_line "$line"); then
      : # line is valid
    else
      echo "  line $line_num: forbidden construct '$forbidden'" >&2
      echo "    $line" >&2
      ((violations++))
    fi
  done < "$file"

  return "$violations"
}
