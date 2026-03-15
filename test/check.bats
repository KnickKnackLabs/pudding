#!/usr/bin/env bats

load test_helper

# --- Acceptance tests: things inside the pudding subset ---

@test "accepts empty file" {
  local f
  f=$(echo "" | write_script)
  check_file "$f"
}

@test "accepts comments" {
  local f
  f=$(write_script <<'EOF'
# This is a comment
# Another comment
EOF
  )
  check_file "$f"
}

@test "accepts shebang" {
  local f
  f=$(write_script <<'EOF'
#!/usr/bin/env bash
EOF
  )
  check_file "$f"
}

@test "accepts variable assignment" {
  local f
  f=$(write_script <<'EOF'
name="hello"
EOF
  )
  check_file "$f"
}

@test "accepts if/then/else/fi" {
  local f
  f=$(write_script <<'EOF'
if [ "$x" = "yes" ]; then
  exit 0
else
  exit 1
fi
EOF
  )
  check_file "$f"
}

@test "accepts && (short-circuit AND)" {
  local f
  f=$(write_script <<'EOF'
true && exit 0
EOF
  )
  check_file "$f"
}

@test "accepts || (short-circuit OR)" {
  local f
  f=$(write_script <<'EOF'
false || exit 1
EOF
  )
  check_file "$f"
}

@test "accepts chained && and ||" {
  local f
  f=$(write_script <<'EOF'
true && true && exit 0
false || false || exit 1
EOF
  )
  check_file "$f"
}

@test "accepts echo to stdout" {
  local f
  f=$(write_script <<'EOF'
echo "hello world"
EOF
  )
  check_file "$f"
}

@test "accepts echo to stderr via >&2" {
  local f
  f=$(write_script <<'EOF'
echo "error: something went wrong" >&2
EOF
  )
  check_file "$f"
}

@test "accepts a valid pudding script" {
  local f
  f=$(write_script <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

# A simple pudding-valid script
name="world"

if [ "$name" = "world" ]; then
  echo "hello, world"
  exit 0
else
  echo "unknown name" >&2
  exit 1
fi
EOF
  )
  check_file "$f"
}

@test "accepts && with if" {
  local f
  f=$(write_script <<'EOF'
[ "$x" = "yes" ] && exit 0
EOF
  )
  check_file "$f"
}

# --- Rejection tests: things outside the pudding subset ---

@test "rejects pipes" {
  local f
  f=$(write_script <<'EOF'
echo "hello" | grep "hello"
EOF
  )
  run check_file "$f"
  [ "$status" -ne 0 ]
  [[ "$output" == *"pipes"* ]]
}

@test "rejects command substitution with \$()" {
  local f
  f=$(write_script <<'EOF'
name=$(whoami)
EOF
  )
  run check_file "$f"
  [ "$status" -ne 0 ]
  [[ "$output" == *"command substitution"* ]]
}

@test "rejects command substitution with backticks" {
  local f
  f=$(write_script <<'EOF'
name=`whoami`
EOF
  )
  run check_file "$f"
  [ "$status" -ne 0 ]
  [[ "$output" == *"command substitution"* ]]
}

@test "rejects loops" {
  local f
  f=$(write_script <<'EOF'
for i in 1 2 3; do
  true
done
EOF
  )
  run check_file "$f"
  [ "$status" -ne 0 ]
  [[ "$output" == *"loops"* ]]
}

@test "rejects eval" {
  local f
  f=$(write_script <<'EOF'
eval "echo hello"
EOF
  )
  run check_file "$f"
  [ "$status" -ne 0 ]
  [[ "$output" == *"dangerous builtin"* ]]
}

@test "rejects heredocs" {
  local f
  f=$(write_script <<'OUTER'
cat <<EOF
hello
EOF
OUTER
  )
  run check_file "$f"
  [ "$status" -ne 0 ]
  [[ "$output" == *"heredocs"* ]]
}

@test "rejects file redirection" {
  local f
  f=$(write_script <<'EOF'
echo "data" > output.txt
EOF
  )
  run check_file "$f"
  [ "$status" -ne 0 ]
  [[ "$output" == *"redirection"* ]]
}

@test "rejects background execution" {
  local f
  f=$(write_script <<'EOF'
sleep 10 &
EOF
  )
  run check_file "$f"
  [ "$status" -ne 0 ]
  [[ "$output" == *"background execution"* ]]
}

@test "rejects functions" {
  local f
  f=$(write_script <<'EOF'
function greet() {
  echo "hi"
}
EOF
  )
  run check_file "$f"
  [ "$status" -ne 0 ]
  [[ "$output" == *"functions"* ]]
}

@test "rejects source" {
  local f
  f=$(write_script <<'EOF'
source lib/common.sh
EOF
  )
  run check_file "$f"
  [ "$status" -ne 0 ]
  [[ "$output" == *"dangerous builtin"* ]]
}
