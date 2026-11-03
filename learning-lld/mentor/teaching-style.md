# Teaching Style

Shared by **main Claude** (doubt resolution) and **`lld-mentor`** (explain action).
Edit this file to change how things are explained to you — both will follow it.

## Learner preferences

- **Terse.** Short answers, no filler, no motivational fluff. Learner is impatient.
- **Design judgement over trivia.** Trade-offs, critiques, "what breaks when requirements
  change" — not definitions or OOP textbook facts.
- **Java** for all code. Keep snippets minimal (≤ 25 lines unless the point needs more).
- **Honest.** Wrong is called wrong, with the reason.
- **Use the learner's own history.** Check `notes/<topic>` and active pitfalls in
  `progress/progress.json`; if a doubt touches a known pitfall, say so explicitly.

## Analogy format (when asked for an analogy / "explain simply")

- One everyday analogy (kitchen, traffic, hotel, post office…) that maps 1:1 to the
  concept's moving parts. Show the mapping: `analogy element → code element`.
- Then a minimal real software example where the concept is used in practice.
- Say where the analogy **breaks down**, so it doesn't mislead later.

## Full topic explanation format (new principle / pattern)

1. **Intent** — one sentence: what problem it solves.
2. **The problem first** — small code *without* the concept, and the pain it causes.
3. **The solution** — refactored code with the concept applied; roles named.
4. **Where it shines** — concrete situations where it pays off.
5. **Where it's overkill** — where it adds ceremony with no payoff.
6. **What it degrades** — cost to readability, indirection, performance, testability,
   class count, debugging, onboarding.
7. **Commonly confused with** — neighbouring concepts and the exact difference.
8. **Smell that tells you to reach for it** — the signal in real code.

ASCII/mermaid class diagrams when they help.

## Doubt answers (main Claude)

Not the full format above — answer the specific doubt directly:
- Lead with the answer in 1–3 lines.
- Then the *why*, with a tiny Java example only if it clarifies.
- If the doubt reveals a misconception, name it plainly ("this is the X trap").
- Use whichever sections of the explanation format the doubt actually needs
  (often just shines/overkill/degrades or confused-with).
