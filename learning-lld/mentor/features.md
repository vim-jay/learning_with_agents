# LLD Mentor — Features

This file is the source of truth for the `lld-mentor` agent's behavior.
Edit freely: change a section, delete one, or add a new `F<n>` section.
Set `Status: disabled` to switch a feature off without deleting it.

---

## F1 — Real-world example / analogy

**Status:** enabled
**Trigger:** only when requested ("give me an analogy", "explain simply").

Format: **"Analogy format"** in `mentor/teaching-style.md`.

---

## F2 — Concept explanation (principles & patterns)

**Status:** enabled

Format: **"Full topic explanation format"** in `mentor/teaching-style.md`
(shared with main Claude so doubt answers match the same style).
After explaining, set the topic status to `learning` in progress.json.

---

## F3 — Topic-wise quizzes (markdown)

**Status:** enabled
**Trigger:** learner says they're clear on a concept and asks for a quiz.

**Files**
- Quiz: `quizzes/<topic>/quiz-NN.md` — learner writes answers inline under each
  `> **Your answer:**` marker.
- Answer key: `.answer-keys/quizzes/<topic>/quiz-NN.key.md` — written at creation time,
  before the learner answers (so grading is fair and fixed).
- Result: `quizzes/<topic>/quiz-NN.result.md`.

**Composition (8–10 questions)**
- Design-judgement questions only — no objective MCQ or OOP trivia. Mix of:
  *spot the violation* in a code snippet, *which pattern/principle fits this scenario*,
  *critique this design*, *redesign it*, *what does this change request break*, and
  *when would this be overkill*.
- Difficulty spread: ~30% easy, ~50% medium, ~20% hard. Tag each question `[E]`, `[M]`, `[H]`.
- At least 2 questions must be traps aimed at known pitfalls — the learner's active
  pitfalls from progress.json first, otherwise common misconceptions for the topic.
- No trivia (who invented it, GoF page numbers).

Grading rules are in F5; XP rules in F6.

---

## F4 — Design exercises

**Status:** enabled
**Trigger:** learner asks for an exercise on a specific pattern/principle (usually after
passing its quiz). Use maximum critical thinking here — exercise quality is the core value.

**Scope: don't drag it.** Solvable in ~45–90 minutes. ≤ 5 core requirements.
Realistic domain (parking lot, notification service, payment gateway, rate limiter,
text editor…), not toy `Animal/Dog` examples.

**Each exercise must**
- Make the target pattern the *natural* answer without naming it in the problem text
  (the learner must recognise it). The topic folder is fine; the README must not say
  "use the Strategy pattern".
- Contain at least one deliberate trap from the learner's active pitfalls, or the
  pattern's classic misuse (e.g. God-Singleton, Decorator that breaks the interface,
  Observer with memory leaks / ordering assumptions).
- Include a **Change Request** stage, kept hidden in `.answer-keys/` until the first
  submission. It tests extensibility: a good design absorbs it with additions, a weak
  design needs edits across many classes.
- Be tiered by difficulty (F6 decides the tier):
  - **Tier 1** — single pattern, clear requirements.
  - **Tier 2** — pattern + one principle tension (e.g. OCP vs YAGNI), an edge case or two.
  - **Tier 3** — pattern combined with another pattern, ambiguous requirements the
    learner must clarify via assumptions, concurrency or lifecycle concerns.

**Files** in `exercises/<topic>/ex-NN-<slug>/`
- `README.md` — scenario, requirements, constraints, what to submit, how to run tests.
- Starter code — interfaces/skeletons only where needed; never the solution shape.
- `tests/` — visible behavioural tests (the spec).
- In `.answer-keys/exercises/<topic>/ex-NN-<slug>/`: hidden tests, change request,
  design rubric, list of targeted pitfalls.

Use the simplest test setup available for the learner's language (check the toolchain
with Bash first; install nothing heavy without asking).

---

## F5 — Evaluation via test cases

**Status:** enabled

### Quizzes
Each question in the answer key has explicit **test cases**:
- `must_include` — points the answer must contain to pass.
- `disqualifiers` — statements that make the answer wrong regardless of anything else.
- `partial` — what earns half credit.
Grade each question against its cases: full / partial / zero. Show per-question
verdict and the correct reasoning in the result file.
**Pass threshold:** 70%.

### Exercises
Score = **50% tests + 50% design review**.
1. Run visible tests, then hidden tests (copy them in temporarily, run, remove).
2. Reveal the Change Request; learner implements it (it's part of the same attempt).
   Then run the change-request tests.
3. Design review against the rubric: correct pattern application, SOLID adherence,
   coupling/cohesion, naming, unnecessary complexity (over-engineering loses points too),
   how many existing files the Change Request forced them to edit.
4. Write `RESULT.md`: test results, rubric scores with justification, pitfalls hit,
   a short "how a strong solution would look" section (shown only after grading).

**Pass threshold:** 70%. Below that, the learner may resubmit (see F6 for XP on retries).

---

## F6 — XP, levels & adaptive difficulty

**Status:** enabled
**Storage:** `progress/progress.json` (updated after every graded activity).

### XP earned
| Activity | XP |
|---|---|
| Quiz question | `[E]` 5 · `[M]` 10 · `[H]` 20 — half for partial credit |
| Quiz passed (≥70%) bonus | +20 |
| Exercise Tier 1 / 2 / 3 (base) | 60 / 120 / 250 × score% |
| First-attempt pass bonus | +25% of base |
| Change Request absorbed with zero edits to existing classes | +15% of base |
| Each hint used | −10% of base |
| Retry attempt (2nd+) | earns at most 60% of base |

XP is never negative for an activity (floor at 0).

### Levels
| Level | XP |
|---|---|
| Novice | 0 |
| Apprentice | 300 |
| Practitioner | 900 |
| Craftsman | 2000 |
| Architect | 4000 |
| Badass | 7000 |

### Topic mastery (0–100)
- `quiz_passed` when best quiz ≥ 70%.
- `mastered` when best quiz ≥ 85% **and** a Tier 2+ exercise passed **and** no active
  pitfalls remain for that topic.
- `mastery` = weighted: 40% best quiz score, 60% best exercise score scaled by tier
  (Tier 1 caps at 70, Tier 2 at 90, Tier 3 at 100).

### Pitfall tracking
- Every mistake that reveals a misunderstanding (not a typo) becomes or increments a
  pitfall in progress.json with a clear description.
- A pitfall becomes `resolved` after the learner avoids it in 2 consecutive activities
  that targeted it.
- Cross-topic pitfalls (e.g. "uses inheritance where composition fits") are tracked too
  — they're the most valuable ones.

### Adaptive difficulty
When choosing the next quiz/exercise:
- Pick the tier so the expected score is ~60–75%: start Tier 1; move up after a ≥ 85%
  pass; move down after two consecutive fails.
- Always target the learner's active pitfalls first, oldest/most-hit first.
- Also target `open` entries in `progress/doubts.md` (logged by main Claude). A
  misconception that is clearly a real gap becomes a pitfall (mark the entry
  `status: pitfall:<id>`); otherwise mark it `status: used` once targeted.
- On "status" / "what next": show level, XP to next level, per-topic mastery table,
  active pitfalls, and recommend exactly one next action.

---

## F7 — Persistent topic notes

**Status:** enabled
**Trigger:** automatically, whenever a new topic is covered (F2), plus on request
("add notes on X", "update my notes").

**What goes in** — revision notes to read later, not a copy of the explanation:
- The core idea in 2–3 lines.
- Key rules / heuristics as bullets.
- Shines / overkill / degrades — one line each.
- Commonly confused with — the one-line difference.
- A minimal code snippet (learner's preferred language) only if it captures the idea.
- "Watch out" — the learner's own active pitfalls for this topic, from progress.json.
Terse: aim for one screen per file.

**Where it goes** — `notes/`, named by the topic slug from the roadmap:
- One file → `notes/<topic>.md`.
- More than one file for a topic → a folder `notes/<topic>/` holding all of them
  (e.g. `01-core.md`, `02-variants.md`). When a second file is needed, move the existing
  `notes/<topic>.md` into the folder as `01-core.md`; a topic is never both a file and a folder.

**Keep them current**
- Revisiting a topic updates its notes rather than duplicating them.
- After a graded quiz/exercise, refresh that topic's "Watch out" section with new or
  resolved pitfalls.
- If a topic already in progress.json has no notes yet, create them the next time that
  topic comes up.

---

<!-- Add new features below as F8, F9, ... using the same format. -->
