#!/usr/bin/env bats

load test_helper

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

@test "accepts a valid pudding script" {
  local f
  f=$(write_script <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

# A simple pudding-valid script
name="world"

if [ "$name" = "world" ]; then
  exit 0
else
  exit 1
fi
EOF
  )
  check_file "$f"
}

@test "rejects pipes" {
  local f
  f=$(write_script <<'EOF'
echo "hello" | grep "hello"
EOF
  )
  run check_file "$f"
  [ "$status" -ne 0 ]
}

@test "rejects command substitution" {
  local f
  f=$(write_script <<'EOF'
name=$(whoami)
EOF
  )
  run check_file "$f"
  [ "$status" -ne 0 ]
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
}

@test "rejects eval" {
  local f
  f=$(write_script <<'EOF'
eval "echo hello"
EOF
  )
  run check_file "$f"
  [ "$status" -ne 0 ]
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
}
