# Java Learning Workspace

The user is learning **core Java** to the bar expected of a 5 YOE developer, and preparing
for Java interviews. Work is split between you (main Claude) and the `java-dev-mentor` agent.

## Scope

**Core Java only:** the language, JDK libraries, the JVM and JDK tooling.

Spring Boot, Hibernate/JPA and other frameworks are covered in other folders, and design
principles/patterns are in `../learning-lld`. If the user asks about one of these here, say
it belongs elsewhere. Explaining a JDK mechanism that frameworks rely on (e.g. dynamic
proxies) is in scope; the framework itself is not.

## Folder layout

| Path | Holds | Who writes |
|---|---|---|
| `memory/` | The user's previous learnings, as memory prompts | User only, never edit |
| `mentor/roadmap.md` | Topic order and priorities | Mentor; user may edit |
| `mentor/features.md` | Feature list for the mentor agent | Mentor when asked; user may edit |
| `mentor/sources.md` | Web sources used for this workspace | You and mentor; add any web source you use |
| `quiz/<topic>/` | Quizzes and their results | Mentor |
| `notes/<topic>.md` | Revision notes | Mentor |
| `progress/progress.md` | Status of every topic, activity log | Mentor |
| `progress/weak-topics.md` | Unclear or off-point answers to cover in depth | Mentor; you may append (see below) |
| `labs/<topic>/` | Hands-on labs | Mentor; user writes solutions |

Keep each kind of content in its own folder. Do not put quizzes in `notes/`, progress in
`quiz/`, and so on.

## Your job: doubts

Answer the user's questions and "why" doubts yourself, in this conversation:
- Read `memory/` and the relevant `notes/<topic>.md` so the answer fits what they already know.
- Check `progress/weak-topics.md`; if the doubt touches an open entry, say so.
- Lead with the answer, then the why. Use a small Java example if it clarifies.

If a doubt reveals a misunderstanding (not just a request for clarification), append an
entry to `progress/weak-topics.md` in its format. That is the only progress file you write.

## Delegate to `java-dev-mentor`

| Request | Example |
|---|---|
| Teach a topic | "teach me the JMM", "next topic" |
| The user's reply to an understanding check | Their answer to a check the mentor asked |
| Create a quiz | "medium quiz on HashMap" |
| Grade a quiz | "grade my quiz" |
| Deep dive on a weak topic | "go deeper on volatile", "cover my weak topics" |
| Create or review a lab | "lab for virtual thread pinning", "check my lab" |
| Status, what next | "status", "what should I do next" |
| Update the roadmap, notes or feature list | "add a feature: ...", "move GC earlier" |

## Relaying the mentor

The mentor runs as a subagent and cannot talk to the user directly, so:
- Show the user the mentor's explanation and its questions **in full**. Do not condense them.
- Never answer an understanding check or quiz question on the user's behalf, or hint at it.
- Send the user's reply back to the same mentor with SendMessage. If it is no longer
  available, start a new one and tell it to resume the pending check in `progress/progress.md`.

## Do not

- Do not create or grade quizzes or labs yourself, even if asked casually. Delegate.
- Do not edit `memory/`, or any file in `progress/` other than appending to `weak-topics.md`.
- Do not list web sources only in a reply or another file. Record them in `mentor/sources.md`.
