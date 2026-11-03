# Sources

Web sources used for this workspace. Add new ones at the bottom of the matching section.

Format: `- YYYY-MM-DD | [title](url) | what it was used for`

## Roadmap: interview topics

Search-result summaries only; these pages were not read in full. They are mostly prep guides,
not hiring data.

- 2026-11-03 | [Java interview questions: JVM internals, concurrency, design patterns](https://www.techinterview.org/post/3233460836/java-interview-questions-advanced/) | JMM, `volatile`, classloader hierarchies and leaks
- 2026-11-03 | [Java interview questions: core concepts, concurrency, JVM](https://www.techinterview.org/post/3233460430/java-interview-questions/) | `ConcurrentHashMap` internals and check-then-act races, `CompletableFuture`
- 2026-11-03 | [Java interview questions 2025: virtual threads, records, GC, concurrency](https://www.techinterview.org/post/3233474451/java-interview-questions-2025-virtual-threads-records-sealed-classes-stream-api-garbage-collection-concurrency-spring-boot/) | `OutOfMemoryError` causes, GC log signals, static collection leaks
- 2026-11-03 | [Java developer interview questions (KORE1)](https://www.kore1.com/java-developer-interview-questions/) | JVM flag tuning, GC problem vs application design problem, Java 17/21 expectations
- 2026-11-03 | [Java interview questions and answers, 2026 guide (hackajob)](https://hackajob.com/talent/technical-assessment/java-technical-interview-preparation-guide?hsLang=en) | Senior topic coverage
- 2026-11-03 | [Top Java interview questions 2026 (Interview Kickstart)](https://interviewkickstart.com/blogs/interview-questions/java-for-software-developers) | Senior topic coverage
- 2026-11-03 | [150+ Java questions: JVM internals and GC (Javarevisited)](https://javarevisited.substack.com/p/150-java-interview-questions-for-0c5) | JVM internals and GC coverage

## Roadmap: Java version features

Search-result summaries only. Feature status was then checked on the local JDK (see below).

- 2026-11-03 | [Java 25 released (InfoQ)](https://www.infoq.com/news/2025/09/java25-released) | Java 25 JEP list
- 2026-11-03 | [Reasons to move to Java 25 (Microsoft)](https://learn.microsoft.com/en-us/java/openjdk/reasons-to-move-to-java-25) | Virtual thread pinning fix, scoped values
- 2026-11-03 | [Project Loom in IntelliJ IDEA (JetBrains)](https://blog.jetbrains.com/idea/2026/08/project-loom-in-intellij-idea-virtual-threads-scoped-values-and-structured-concurrency/) | Loom feature status

## Verified locally

- 2026-11-03 | OpenJDK 25.0.2 (Homebrew) | Ran the feature and flag checks listed in `mentor/roadmap.md`
