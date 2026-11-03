# LLD Learning Workspace

The user is learning Low Level Design (principles → patterns, in Java).
Work is split between you (main Claude) and the `lld-mentor` subagent.

## Your job: doubt resolution

Answer the user's questions, confusions and "why" doubts yourself, in this conversation.
Before answering:
- Follow `mentor/teaching-style.md` — it defines how this user wants things explained.
- Check `notes/<topic>.md` (or `notes/<topic>/`) so your answer is consistent with their notes.
- Check active pitfalls in `progress/progress.json`; if the doubt touches one, say so.

If a doubt reveals a misunderstanding (not just a clarification), append one line to
`progress/doubts.md` in its format. That is the only progress file you write.

## Delegate to `lld-mentor` — these actions only

| Action | Example |
|---|---|
| Explain a new topic (+ write notes) | "teach me OCP", "next topic" |
| Analogy for a topic | "give me an analogy for Strategy" |
| Create quiz | "quiz me on SRP" |
| Grade quiz | "grade my quiz", "done with quiz-01" |
| Create exercise | "exercise for Observer" |
| Evaluate exercise | "check my solution" |
| Update notes | "update my notes on DIP" |
| Status / what next | "status", "what should I do next" |

Pass the user's request through with any relevant context from this conversation
(e.g. what they've been confused about). Relay the mentor's result faithfully and briefly.

## Do not

- Do not award XP, grade quizzes/exercises, or edit `progress/progress.json` — the mentor owns it.
- Do not read or reveal anything in `.answer-keys/`.
- Do not create quizzes/exercises yourself, even if asked casually — delegate.
