# Pudding Formal Semantics

This directory will contain the Lean 4 formalization of the pudding bash subset.

## Planned structure

```
semantics/
├── Pudding/
│   ├── Syntax.lean       -- AST definition for the pudding subset
│   ├── Semantics.lean    -- Small-step operational semantics
│   ├── Properties.lean   -- Determinism, termination, type safety proofs
│   └── Checker.lean      -- Verified subset checker (replaces grammar.sh)
└── lakefile.lean          -- Lean 4 build configuration
```

## The plan

1. Define the abstract syntax (AST) for the pudding subset
2. Define an operational semantics (what each construct *means*)
3. Prove basic properties: determinism (same input = same output), termination for the subset
4. Build a verified checker: a Lean program, proved correct, that determines subset membership
5. Eventually: a verified interpreter that can execute pudding scripts

The bash checker in `lib/grammar.sh` is the prototype. It exists to validate the approach.
The Lean formalization is the real thing.
