<div align="center">

```
┌─────────────────────────┐
│  {P} A ; guard ; B {Q}  │
│      ════════════       │
│                         │
│   the proof is in the   │
│         pudding         │
└─────────────────────────┘
```

# pudding

**A formally verified subset of bash.**

Start small. Prove everything. Grow from there.

![subset: v0.1](https://img.shields.io/badge/subset-v0.1-7c3aed?style=flat)
![tests: 22 passing](https://img.shields.io/badge/tests-22%20passing-brightgreen?style=flat)
[![proof assistant: Lean 4](https://img.shields.io/badge/proof%20assistant-Lean%204-blue?style=flat)](https://lean-lang.org)
![shell: bash 3.2](https://img.shields.io/badge/shell-bash%203.2-4EAA25?style=flat&logo=gnubash&logoColor=white)

</div>

<br />

## Why?

Bash is the lingua franca of human/agent collaboration. It's what we write, what agents write, what [mise](https://mise.jdx.dev) tasks run. But bash is also notoriously tricky — subtle semantics, invisible edge cases, behaviors that surprise even experienced users.

Pudding asks: what if we could **prove** that a bash script does what it claims? Not test it, not lint it — *prove* it. Mathematically. Reproducibility becomes a theorem, not an experiment.

The approach: define a minimal subset of bash with **formal operational semantics**, build a checker that enforces it, and grow the subset one construct at a time — each addition backed by proof.

<br />

## Quick start

```bash
# Install
shiv install pudding

# Check if a script stays within the verified subset
pudding check myscript.sh
```

A script that passes `pudding check` uses only constructs with defined semantics and provable properties.

<br />

## The subset

Pudding v0.1 accepts a deliberately minimal fragment of bash:

<table>
  <tr>
    <td width="50%" valign="top">

**Inside the subset**

- `empty file`
- `comments`
- `shebang`
- `variable assignment`
- `if/then/else/fi`
- `&& (short-circuit AND)`
- `|| (short-circuit OR)`
- `chained && and ||`
- `echo to stdout`
- `echo to stderr via >&2`
- `a valid pudding script`
- `&& with if`


</td>
    <td width="50%" valign="top">

**Outside the subset**

- `pipes`
- `command substitution with \$()`
- `command substitution with backticks`
- `loops`
- `eval`
- `heredocs`
- `file redirection`
- `background execution`
- `functions`
- `source`


</td>
  </tr>
</table>

<details>
<summary><b>Formal grammar</b></summary>

```
program     := statement*
statement   := assignment | conditional | command | compound | comment
assignment  := NAME '=' STRING
conditional := 'if' test '; then' body ('else' body)? 'fi'
test        := '[' expr ']' | '[[' expr ']]'
expr        := STRING '=' STRING | STRING '!=' STRING
             | '-z' STRING | '-n' STRING
body        := statement*
compound    := statement '&&' statement    # short-circuit AND
             | statement '||' statement    # short-circuit OR
command     := 'exit' NUMBER | 'return' NUMBER | 'true' | 'false'
             | 'echo' STRING*              # stdout
             | 'echo' STRING* '>&2'        # stderr
comment     := '#' .*
STRING      := '"' [^"]* '"' | "'" [^']* "'" | NAME | '$' NAME | '${' NAME '}'
NAME        := [a-zA-Z_][a-zA-Z0-9_]*
NUMBER      := [0-9]+
```

</details>

<details>
<summary><b>Intentionally excluded</b></summary>

pipes, subshells, command substitution, arithmetic, arrays, functions, loops, globs, parameter expansion, here-docs, process substitution, eval, source

</details>

<br />

## Formal semantics

Every construct in the subset has **inference rules** — a mathematical definition of what it means. These are the foundation that Lean 4 will mechanize.

Read `⟨A, σ⟩ ⇓ (n, σ')` as: "program A, in state σ (all variable bindings), evaluates to exit code n and new state σ'. The line above is the premise; below the line is the conclusion."

```
&& (short-circuit AND):
  ⟨A, σ⟩ ⇓ (0, σ')      ⟨B, σ'⟩ ⇓ (n, σ'')
  ——————————————————————————————————————————————
          ⟨A && B, σ⟩ ⇓ (n, σ'')
  ⟨A, σ⟩ ⇓ (n, σ')      n ≠ 0
  ——————————————————————————————
      ⟨A && B, σ⟩ ⇓ (n, σ')
|| (short-circuit OR):
  ⟨A, σ⟩ ⇓ (0, σ')
  ————————————————————
  ⟨A || B, σ⟩ ⇓ (0, σ')
  ⟨A, σ⟩ ⇓ (n, σ')      n ≠ 0      ⟨B, σ'⟩ ⇓ (m, σ'')
  ————————————————————————————————————————————————————————
            ⟨A || B, σ⟩ ⇓ (m, σ'')
>&2 (stderr redirection):
  Redirects output of a command to file descriptor 2 (stderr).
  No other redirection targets are permitted in the subset.
```

> Key property: determinism. Given the same program and initial state, evaluation always produces the same exit code and final state. Provable by structural induction on the AST — each rule's applicability is determined solely by the exit code of sub-evaluations, which are themselves deterministic by the inductive hypothesis.

<br />

## Composition

Two verified pudding programs compose correctly when the postcondition of the first satisfies the precondition of the second. When specs don't perfectly align, a validation guard at the boundary catches the gap:

```
  ⟨A, σ⟩ ⇓ (0, σ')    guard(P_B, σ') = ok    ⟨B, σ'⟩ ⇓ (n, σ'')
  ─────────────────────────────────────────────────────────────────
                  ⟨A ; guard(P_B) ; B, σ⟩ ⇓ (n, σ'')

  ⟨A, σ⟩ ⇓ (0, σ')    guard(P_B, σ') = fail
  ────────────────────────────────────────────
       ⟨A ; guard(P_B) ; B, σ⟩ ⇓ (1, σ')
```

The program fails at the boundary rather than silently doing the wrong thing. In bash, this is natural — validate between stages.

<br />

## Architecture

```
┌───────────────────────────────────────────────────────┐
│                      pudding                          │
│                                                       │
│   ┌───────────────┐  ┌────────────┐  ┌──────────────┐ │
│   │ Checker       │  │ Semantics  │  │ Proofs       │ │
│   │               │  │            │  │              │ │
│   │ grammar.sh    │  │ Lean 4     │  │ Lean 4       │ │
│   │               │  │            │  │              │ │
│   │ "is this in   │  │ "what does │  │ "what can we │ │
│   │  the subset?" │  │  it mean?" │  │  prove?"     │ │
│   │               │  │            │  │              │ │
│   │ ✓ ready       │  │ ◐ planned  │  │ ◐ planned    │ │
│   └───────────────┘  └────────────┘  └──────────────┘ │
│                                                       │
│ bash 3.2 ───────────────────── target language        │
│ Lean 4 ────────────────────── proof assistant         │
│ BATS ──────────────────────── conformance tests       │
└───────────────────────────────────────────────────────┘
```

The checker is the practical tool you use today. The Lean formalization is what makes it *trustworthy* — it proves the semantics are consistent and the properties actually hold.

<br />

## Roadmap

The subset grows one construct at a time. Each addition is a deliberate decision:

<table>
  <tr>
    <td width="50%" valign="top">

**Next up**
Constructs that the checker itself needs — eating our own pudding.

- `source` — file inclusion (needed for lib/ pattern)
- `$()` — command substitution (the big one)
- Lean 4 AST definition
- Lean 4 operational semantics


</td>
    <td width="50%" valign="top">

**Eventually**
Where this leads if the foundation holds.

- Verified interpreter for the subset
- External command contracts (axiomatic specs for tools)
- TEE integration for verified channel composition
- Self-hosting: pudding verifies pudding


</td>
  </tr>
</table>

<br />

## Development

```bash
git clone https://github.com/KnickKnackLabs/pudding.git
cd pudding && mise trust && mise install
mise run test
```

22 tests across 1 suite — 12 acceptance, 10 rejection. Tests use [BATS](https://github.com/bats-core/bats-core).

<br />

<div align="center">

---

<sub>
Bash doesn't have formal semantics.<br />
So we're writing them.<br />
<br />
This README was created using <a href="https://github.com/KnickKnackLabs/readme">readme</a>.
</sub></div>
