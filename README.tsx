/** @jsxImportSource jsx-md */

import { readFileSync, readdirSync } from "fs";
import { join, resolve } from "path";

import {
  Heading, Paragraph, CodeBlock, Blockquote, LineBreak, HR,
  Bold, Code, Link, Italic,
  Badge, Badges, Center, Details, Section,
  Table, TableHead, TableRow, Cell,
  List, Item,
  Raw, HtmlLink, Sub, Align, HtmlTable, HtmlTr, HtmlTd,
} from "readme/src/components";

// ── Dynamic data ─────────────────────────────────────────────

const REPO_DIR = resolve(import.meta.dirname);

// Extract a section between sentinel markers from grammar.sh
// Markers look like: # --- BEGIN GRAMMAR --- / # --- END GRAMMAR ---
const grammarSrc = readFileSync(join(REPO_DIR, "lib/grammar.sh"), "utf-8");
const grammarLines = grammarSrc.split("\n");

function extractSection(name: string): string[] {
  const begin = `# --- BEGIN ${name} ---`;
  const end = `# --- END ${name} ---`;
  const startIdx = grammarLines.findIndex((l) => l.trim() === begin);
  const endIdx = grammarLines.findIndex((l) => l.trim() === end);
  if (startIdx === -1) throw new Error(`Marker not found in grammar.sh: ${begin}`);
  if (endIdx === -1) throw new Error(`Marker not found in grammar.sh: ${end}`);
  return grammarLines
    .slice(startIdx + 1, endIdx)
    .map((l) => l.replace(/^#\s{0,3}/, ""));
}

// Version
const versionMatch = grammarSrc.match(/pudding subset of bash \((v[\d.]+)\)/);
const subsetVersion = versionMatch?.[1] ?? "v0";

// Grammar
const grammar = extractSection("GRAMMAR")
  .filter((l) => !l.startsWith("The pudding subset"))
  .join("\n")
  .trim();

// Inference rules — preserve blank lines for spacing between rules
const inferenceRules = extractSection("SEMANTICS")
  .join("\n")
  .trim();

// Determinism argument
const detArg = extractSection("DETERMINISM")
  .join(" ")
  .trim();

// Excluded constructs — split on commas, filter empties, rejoin
const excluded = extractSection("EXCLUDED")
  .join(" ")
  .split(",")
  .map((s) => s.trim())
  .filter((s) => s.length > 0)
  .join(", ");

// Test names — scan all test files for accepts/rejects
const testDir = join(REPO_DIR, "test");
const testFiles = readdirSync(testDir).filter((f) => f.endsWith(".bats"));
const allTestSrc = testFiles
  .map((f) => readFileSync(join(testDir, f), "utf-8"))
  .join("\n");
const accepts = [...allTestSrc.matchAll(/@test "accepts (.+?)"/g)].map((m) => m[1]);
const rejects = [...allTestSrc.matchAll(/@test "rejects (.+?)"/g)].map((m) => m[1]);
const testCount = accepts.length + rejects.length;

// ── Helpers ──────────────────────────────────────────────────

// Draw a Unicode box around lines of text, auto-sized to content
function box(lines: string[], { padding = 1 }: { padding?: number } = {}): string {
  const maxLen = Math.max(...lines.map((l) => l.length));
  const innerWidth = maxLen + padding * 2;
  const pad = (s: string) => " ".repeat(padding) + s + " ".repeat(innerWidth - s.length - padding);
  const top = "┌" + "─".repeat(innerWidth) + "┐";
  const bot = "└" + "─".repeat(innerWidth) + "┘";
  const mid = lines.map((l) => "│" + pad(l) + "│");
  return [top, ...mid, bot].join("\n");
}

// Draw a labeled box with a title and body lines
function labeledBox(title: string, body: string[], status: string): string[] {
  const maxLen = Math.max(title.length, ...body.map((l) => l.length), status.length);
  const w = maxLen + 2;
  const pad = (s: string) => " " + s + " ".repeat(w - s.length - 1);
  return [
    "┌" + "─".repeat(w) + "┐",
    "│" + pad(title) + "│",
    "│" + " ".repeat(w) + "│",
    ...body.map((l) => "│" + pad(l) + "│"),
    "│" + " ".repeat(w) + "│",
    "│" + pad(status) + "│",
    "└" + "─".repeat(w) + "┘",
  ];
}

// Combine box columns side-by-side with a gap
function sideBySide(columns: string[][], gap = 2): string[] {
  const heights = columns.map((c) => c.length);
  const maxHeight = Math.max(...heights);
  const widths = columns.map((c) => Math.max(...c.map((l) => l.length)));
  const result: string[] = [];
  for (let i = 0; i < maxHeight; i++) {
    result.push(
      columns
        .map((col, ci) => (col[i] ?? " ".repeat(widths[ci])).padEnd(widths[ci]))
        .join(" ".repeat(gap))
    );
  }
  return result;
}

// ── Diagrams ─────────────────────────────────────────────────

const logo = box([
  "{P} A ; guard ; B {Q}",
  "    ════════════",
  "",
  " the proof is in the",
  "       pudding",
], { padding: 2 });

const checkerBox = labeledBox(
  "Checker",
  ['grammar.sh', '', '"is this in', ' the subset?"'],
  "✓ ready",
);

const semanticsBox = labeledBox(
  "Semantics",
  ['Lean 4', '', '"what does', ' it mean?"'],
  "◐ planned",
);

const proofsBox = labeledBox(
  "Proofs",
  ['Lean 4', '', '"what can we', ' prove?"'],
  "◐ planned",
);

const innerBoxes = sideBySide([checkerBox, semanticsBox, proofsBox]);

const legend = [
  "",
  "bash 3.2 ───────────────────── target language",
  "Lean 4 ────────────────────── proof assistant",
  "BATS ──────────────────────── conformance tests",
];

const archContent = [
  "pudding".padStart(Math.floor(innerBoxes[0].length / 2) + 3),
  "",
  ...innerBoxes.map((l) => "  " + l),
  ...legend,
];

const architecture = box(archContent, { padding: 1 });

// ── README ───────────────────────────────────────────────────

const readme = (
  <>
    <Center>
      <Raw>{`<pre>\n${logo}\n</pre>\n\n`}</Raw>

      <Heading level={1}>pudding</Heading>

      <Paragraph>
        <Bold>A formally verified subset of bash.</Bold>
      </Paragraph>

      <Paragraph>
        {"Start small. Prove everything. Grow from there."}
      </Paragraph>

      <Badges>
        <Badge label="subset" value={subsetVersion} color="7c3aed" />
        <Badge label="tests" value={`${testCount} passing`} color="brightgreen" />
        <Badge label="proof assistant" value="Lean 4" color="blue" href="https://lean-lang.org" />
        <Badge label="shell" value="bash 3.2" color="4EAA25" logo="gnubash" logoColor="white" />
      </Badges>
    </Center>

    <LineBreak />

    <Section title="Why?">
      <Paragraph>
        {"Bash is the lingua franca of human/agent collaboration. It's what we write, what agents write, what "}
        <Link href="https://mise.jdx.dev">mise</Link>
        {" tasks run. But bash is also notoriously tricky — subtle semantics, invisible edge cases, behaviors that surprise even experienced users."}
      </Paragraph>

      <Paragraph>
        {"Pudding asks: what if we could "}
        <Bold>prove</Bold>
        {" that a bash script does what it claims? Not test it, not lint it — "}
        <Italic>prove</Italic>
        {" it. Mathematically. Reproducibility becomes a theorem, not an experiment."}
      </Paragraph>

      <Paragraph>
        {"The approach: define a minimal subset of bash with "}
        <Bold>formal operational semantics</Bold>
        {", build a checker that enforces it, and grow the subset one construct at a time — each addition backed by proof."}
      </Paragraph>
    </Section>

    <LineBreak />

    <Section title="Quick start">
      <CodeBlock lang="bash">{`# Install
shiv install pudding

# Check if a script stays within the verified subset
pudding check myscript.sh`}</CodeBlock>

      <Paragraph>
        {"A script that passes "}
        <Code>pudding check</Code>
        {" uses only constructs with defined semantics and provable properties."}
      </Paragraph>
    </Section>

    <LineBreak />

    <Section title="The subset">
      <Paragraph>
        {"Pudding "}
        {subsetVersion}
        {" accepts a deliberately minimal fragment of bash:"}
      </Paragraph>

      <HtmlTable>
        <HtmlTr>
          <HtmlTd width="50%" valign="top">
            <Paragraph><Bold>Inside the subset</Bold></Paragraph>
            <List>
              {accepts.map((a) => <Item><Code>{a}</Code></Item>)}
            </List>
          </HtmlTd>
          <HtmlTd width="50%" valign="top">
            <Paragraph><Bold>Outside the subset</Bold></Paragraph>
            <List>
              {rejects.map((r) => <Item><Code>{r}</Code></Item>)}
            </List>
          </HtmlTd>
        </HtmlTr>
      </HtmlTable>

      <Details summary="Formal grammar">
        <CodeBlock>{grammar}</CodeBlock>
      </Details>

      <Details summary="Intentionally excluded">
        <Paragraph>{excluded}</Paragraph>
      </Details>
    </Section>

    <LineBreak />

    <Section title="Formal semantics">
      <Paragraph>
        {"Every construct in the subset has "}
        <Bold>inference rules</Bold>
        {" — a mathematical definition of what it means. These are the foundation that Lean 4 will mechanize."}
      </Paragraph>

      <Paragraph>
        {"Read "}
        <Code>{`⟨A, σ⟩ ⇓ (n, σ')`}</Code>
        {" as: \"program A, in state σ (all variable bindings), evaluates to exit code n and new state σ'. The line above is the premise; below the line is the conclusion.\""}
      </Paragraph>

      <Center>
        <Raw>{`<pre>\n${inferenceRules}\n</pre>\n\n`}</Raw>
      </Center>

      <Blockquote>
        {detArg}
      </Blockquote>
    </Section>

    <LineBreak />

    <Section title="Composition">
      <Paragraph>
        {"Two verified pudding programs compose correctly when the postcondition of the first satisfies the precondition of the second. When specs don't perfectly align, a validation guard at the boundary catches the gap:"}
      </Paragraph>

      <Center>
        <Raw>{`<pre>
⟨A, σ⟩ ⇓ (0, σ')    guard(P_B, σ') = ok    ⟨B, σ'⟩ ⇓ (n, σ'')
─────────────────────────────────────────────────────────────────
                ⟨A ; guard(P_B) ; B, σ⟩ ⇓ (n, σ'')

⟨A, σ⟩ ⇓ (0, σ')    guard(P_B, σ') = fail
────────────────────────────────────────────
     ⟨A ; guard(P_B) ; B, σ⟩ ⇓ (1, σ')
</pre>\n\n`}</Raw>
      </Center>

      <Paragraph>
        {"The program fails at the boundary rather than silently doing the wrong thing. In bash, this is natural — validate between stages."}
      </Paragraph>
    </Section>

    <LineBreak />

    <Section title="Architecture">
      <Center>
        <Raw>{`<pre>\n${architecture}\n</pre>\n\n`}</Raw>
      </Center>

      <Paragraph>
        {"The checker is the practical tool you use today. The Lean formalization is what makes it "}
        <Italic>trustworthy</Italic>
        {" — it proves the semantics are consistent and the properties actually hold."}
      </Paragraph>
    </Section>

    <LineBreak />

    <Section title="Roadmap">
      <Paragraph>
        {"The subset grows one construct at a time. Each addition is a deliberate decision:"}
      </Paragraph>

      <HtmlTable>
        <HtmlTr>
          <HtmlTd width="50%" valign="top">
            <Paragraph>
              <Bold>Next up</Bold>{"\n"}
              {"Constructs that the checker itself needs — eating our own pudding."}
            </Paragraph>
            <List>
              <Item><Code>source</Code>{" — file inclusion (needed for lib/ pattern)"}</Item>
              <Item><Code>$()</Code>{" — command substitution (the big one)"}</Item>
              <Item>{"Lean 4 AST definition"}</Item>
              <Item>{"Lean 4 operational semantics"}</Item>
            </List>
          </HtmlTd>
          <HtmlTd width="50%" valign="top">
            <Paragraph>
              <Bold>Eventually</Bold>{"\n"}
              {"Where this leads if the foundation holds."}
            </Paragraph>
            <List>
              <Item>{"Verified interpreter for the subset"}</Item>
              <Item>{"External command contracts (axiomatic specs for tools)"}</Item>
              <Item>{"TEE integration for verified channel composition"}</Item>
              <Item>{"Self-hosting: pudding verifies pudding"}</Item>
            </List>
          </HtmlTd>
        </HtmlTr>
      </HtmlTable>
    </Section>

    <LineBreak />

    <Section title="Development">
      <CodeBlock lang="bash">{`git clone https://github.com/KnickKnackLabs/pudding.git
cd pudding && mise trust && mise install
mise run test`}</CodeBlock>

      <Paragraph>
        {`${testCount} tests across ${testFiles.length} suite${testFiles.length === 1 ? "" : "s"} — ${accepts.length} acceptance, ${rejects.length} rejection. Tests use `}
        <Link href="https://github.com/bats-core/bats-core">BATS</Link>
        {"."}
      </Paragraph>
    </Section>

    <LineBreak />

    <Center>
      <HR />

      <Sub>
        {"Bash doesn't have formal semantics."}
        <Raw>{"<br />"}</Raw>{"\n"}
        {"So we're writing them."}
        <Raw>{"<br />"}</Raw>{"\n"}
        <Raw>{"<br />"}</Raw>{"\n"}
        {"This README was created using "}
        <HtmlLink href="https://github.com/KnickKnackLabs/readme">readme</HtmlLink>
        {"."}
      </Sub>
    </Center>
  </>
);

console.log(readme);
