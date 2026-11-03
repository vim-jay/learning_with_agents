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

## JVM internals: `jvm-memory-areas`

Pages fetched and read for the relevant sections, not search summaries. Claims were then tested
on the local JDK where possible.

- 2026-11-03 | [JVMS SE 25, Chapter 2: run-time data areas and frames](https://docs.oracle.com/javase/specs/jvms/se25/html/jvms-2.html) | §2.5 areas and their errors, method area location not mandated, §2.6 frame contents and compile-time sizing
- 2026-11-03 | [The java command, JDK 25](https://docs.oracle.com/en/java/javase/25/docs/specs/man/java.html) | Flag descriptions and defaults, `-Xss` per platform, scope of `-XX:+HeapDumpOnOutOfMemoryError`, `MetaspaceSize` meaning, GC overhead limit
- 2026-11-03 | [Troubleshoot memory leaks, JDK 25](https://docs.oracle.com/en/java/javase/25/troubleshoot/troubleshooting-memory-leaks.html) | `OutOfMemoryError` detail messages, native allocation failure and the fatal error log
- 2026-11-03 | [Diagnostic tools, JDK 25](https://docs.oracle.com/en/java/javase/25/troubleshoot/diagnostic-tools.html) | Native Memory Tracking: reserved vs committed, overhead, non-JVM code not tracked, baseline and diff
- 2026-11-03 | [Troubleshoot system crashes, JDK 25](https://docs.oracle.com/en/java/javase/25/troubleshoot/troubleshoot-system-crashes.html) | Java and native frames share one stack in HotSpot, shadow pages
- 2026-11-03 | [JEP 122: Remove the permanent generation](https://openjdk.org/jeps/122) | Release 8; metadata to native memory, interned strings and statics to the heap
- 2026-11-03 | [JEP 197: Segmented code cache](https://openjdk.org/jeps/197) | Release 9; the three code heaps
- 2026-11-03 | [JEP 387: Elastic metaspace](https://openjdk.org/jeps/387) | Release 16; per-class-loader arenas, returning memory to the OS
- 2026-11-03 | [JEP 444: Virtual threads](https://openjdk.org/jeps/444) | Release 21; stack chunk objects on the heap, maximum depth
- 2026-11-03 | [JDK-8146115: container detection and resource configuration](https://bugs.openjdk.org/browse/JDK-8146115) | Fix version 10; JVM uses the cgroup memory limit, `UseContainerSupport` on by default

## Verified locally

- 2026-11-03 | OpenJDK 25.0.2 (Homebrew) | Ran the feature and flag checks listed in `mentor/roadmap.md`
- 2026-11-03 | OpenJDK 25.0.2 (Homebrew) and its `lib/src.zip` | `jvm-memory-areas`: each failure mode, dump and exit flag behaviour, NMT, stack, code cache and direct buffer experiments; read `java/nio/Bits.java`, `java/nio/DirectByteBuffer.java`, `sun/nio/ch/IOUtil.java`, `sun/nio/ch/Util.java`
- 2026-11-03 | Temurin 21.0.11 in Docker (`apache/kafka:latest`, already on this machine; no JDK 25 Linux image was pulled) | Container limit sets default heap, cgroup kill gives exit 137 with `OOMKilled=true`. This is JDK 21, not 25
