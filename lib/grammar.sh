#!/usr/bin/env bash
# grammar.sh — pudding subset grammar definition and parser
#
# --- BEGIN GRAMMAR ---
# The pudding subset of bash (v0.1):
#   program     := statement*
#   statement   := assignment | conditional | command | compound | comment
#   assignment  := NAME '=' STRING
#   conditional := 'if' test '; then' body ('else' body)? 'fi'
#   test        := '[' expr ']' | '[[' expr ']]'
#   expr        := STRING '=' STRING | STRING '!=' STRING
#                | '-z' STRING | '-n' STRING
#   body        := statement*
#   compound    := statement '&&' statement    # short-circuit AND
#                | statement '||' statement    # short-circuit OR
#   command     := 'exit' NUMBER | 'return' NUMBER | 'true' | 'false'
#                | 'echo' STRING*              # stdout
#                | 'echo' STRING* '>&2'        # stderr
#   comment     := '#' .*
#   STRING      := '"' [^"]* '"' | "'" [^']* "'" | NAME | '$' NAME | '${' NAME '}'
#   NAME        := [a-zA-Z_][a-zA-Z0-9_]*
#   NUMBER      := [0-9]+
# --- END GRAMMAR ---
#
# --- BEGIN SEMANTICS ---
#   && (short-circuit AND):
#     ⟨A, σ⟩ ⇓ (0, σ')      ⟨B, σ'⟩ ⇓ (n, σ'')
#     ——————————————————————————————————————————————
#             ⟨A && B, σ⟩ ⇓ (n, σ'')
#
#     ⟨A, σ⟩ ⇓ (n, σ')      n ≠ 0
#     ——————————————————————————————
#         ⟨A && B, σ⟩ ⇓ (n, σ')
#
#   || (short-circuit OR):
#     ⟨A, σ⟩ ⇓ (0, σ')
#     ————————————————————
#     ⟨A || B, σ⟩ ⇓ (0, σ')
#
#     ⟨A, σ⟩ ⇓ (n, σ')      n ≠ 0      ⟨B, σ'⟩ ⇓ (m, σ'')
#     ————————————————————————————————————————————————————————
#               ⟨A || B, σ⟩ ⇓ (m, σ'')
#
#   >&2 (stderr redirection):
#     Redirects output of a command to file descriptor 2 (stderr).
#     No other redirection targets are permitted in the subset.
# --- END SEMANTICS ---
#
# --- BEGIN DETERMINISM ---
# Key property: determinism. Given the same program and initial state,
# evaluation always produces the same exit code and final state.
# Provable by structural induction on the AST — each rule's applicability
# is determined solely by the exit code of sub-evaluations, which are
# themselves deterministic by the inductive hypothesis.
# --- END DETERMINISM ---
#
# --- BEGIN EXCLUDED ---
# pipes, subshells, command substitution, arithmetic,
# arrays, functions, loops, globs, parameter expansion,
# here-docs, process substitution, eval, source
# --- END EXCLUDED ---

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

  # --- Forbidden constructs (order matters: check specific before general) ---

  # Command substitution
  if [[ "$trimmed" == *'$('* || "$trimmed" == *'`'* ]]; then
    echo 'command substitution'
    return 1
  fi

  # Arithmetic
  if [[ "$trimmed" == *'$(('* || "$trimmed" == 'let '* ]]; then
    echo 'arithmetic'
    return 1
  fi

  # Arrays
  if [[ "$trimmed" == 'declare -a'* || "$trimmed" == 'declare -A'* ]]; then
    echo 'arrays'
    return 1
  fi

  # Loops
  if [[ "$trimmed" == 'for '* || "$trimmed" == 'while '* || "$trimmed" == 'until '* ]]; then
    echo 'loops'
    return 1
  fi

  # Functions
  if [[ "$trimmed" == 'function '* ]] || [[ "$trimmed" == *'() {'* ]]; then
    echo 'functions'
    return 1
  fi

  # Dangerous builtins
  if [[ "$trimmed" == 'eval '* || "$trimmed" == 'source '* || "$trimmed" == '. '* ]]; then
    echo 'dangerous builtin'
    return 1
  fi

  # Heredocs
  if [[ "$trimmed" == *'<<'* ]]; then
    echo 'heredocs'
    return 1
  fi

  # Process substitution
  if [[ "$trimmed" == *'<('* || "$trimmed" == *'>('* ]]; then
    echo 'process substitution'
    return 1
  fi

  # Pipes (but not ||)
  if [[ "$trimmed" == *'|'* && "$trimmed" != *'||'* ]]; then
    echo 'pipes'
    return 1
  fi

  # Background execution
  # & at end of line (but not &&)
  if [[ "$trimmed" == *'&' && "$trimmed" != *'&&'* ]]; then
    echo 'background execution'
    return 1
  fi

  # Redirection — allow >&2 only, reject everything else
  # Strip >&2 from the line, then check for remaining redirection
  local stripped="${trimmed//>&2/}"
  if [[ "$stripped" == *'>'* || "$stripped" == *'<'* ]]; then
    echo 'redirection'
    return 1
  fi

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
