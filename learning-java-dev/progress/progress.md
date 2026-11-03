# Progress

Maintained by `java-dev-mentor`. Status meanings are defined in the agent file (F5).

**Started:** 2026-11-03 · **Target:** core Java at the 5 YOE bar, Java 25 LTS

## Summary

| Priority | Total | Understood or better |
|---|---|---|
| P0 | 28 | 0 |
| P1 | 21 | 0 |
| P2 | 6 | 0 |

## Pending understanding check

**Topic:** `jvm-memory-areas` · **Asked:** 2026-11-03 · **Attempt:** 1 of 2

1. **Explain back.** In your own words, why can a Java process use far more memory than `-Xmx`?
   Then use this code. Where does each of these live: `m`, the `HashMap` object, `k`, `n`, `v`,
   the `int[]`? Which are gone once `put` returns? For anything that survives, what has to
   happen before its memory can be freed?

   ```java
   import java.util.*;

   class Cache {
       static Map<String, int[]> m = new HashMap<>();

       void put(String k) {
           int n = 10;
           int[] v = new int[n];
           m.put(k, v);
       }
   }
   ```

2. **Predict, then explain.** Run this with `-Xmx1g -XX:MaxDirectMemorySize=64m`. Does it finish
   or fail? Then add `-XX:+DisableExplicitGC`. Does it finish or fail now? Explain the mechanism
   in both runs. For any run that finishes, is it healthy? What would the GC log show?

   ```java
   import java.nio.ByteBuffer;

   public class Churn {
       public static void main(String[] args) {
           for (int i = 1; i <= 2_000; i++) {
               ByteBuffer b = ByteBuffer.allocateDirect(1 << 20); // 1 MiB; reference dropped each loop
               b.put(0, (byte) 1);
           }
           System.out.println("finished");
       }
   }
   ```

3. **Diagnose.** A thread-per-request service runs with `-Xmx4g` and throws
   `OutOfMemoryError: unable to create native thread`. The heap is 30% used. A teammate doubles
   `-Xmx` to 8g. Will that fix it? Could it make things worse, and on what kind of machine? What
   do you check first, and why?

## Topics

| # | Phase | Topic | Priority | Status | Easy | Medium | Hard | Lab | Updated |
|---|---|---|---|---|---|---|---|---|---|
| 1 | 0 | `baseline-functional` | P0 | covered-unverified | - | - | - | - | - |
| 2 | 0 | `baseline-oop-dispatch` | P0 | covered-unverified | - | - | - | - | - |
| 3 | 0 | `baseline-modern-types` | P0 | covered-unverified | - | - | - | - | - |
| 4 | 1 | `object-contracts` | P0 | not-started | - | - | - | - | - |
| 5 | 1 | `strings-and-immutability` | P0 | not-started | - | - | - | - | - |
| 6 | 1 | `generics-deep-dive` | P0 | not-started | - | - | - | - | - |
| 7 | 1 | `exceptions` | P0 | not-started | - | - | - | - | - |
| 8 | 1 | `initialization-and-nested-types` | P1 | not-started | - | - | - | - | - |
| 9 | 1 | `record-patterns` | P1 | not-started | - | - | - | - | - |
| 10 | 2 | `hashmap-internals` | P0 | not-started | - | - | - | - | - |
| 11 | 2 | `lists-and-queues` | P0 | not-started | - | - | - | - | - |
| 12 | 2 | `ordered-and-sorted-collections` | P1 | not-started | - | - | - | - | - |
| 13 | 2 | `collection-immutability-and-views` | P1 | not-started | - | - | - | - | - |
| 14 | 2 | `specialized-collections` | P2 | not-started | - | - | - | - | - |
| 15 | 3 | `stream-internals` | P0 | not-started | - | - | - | - | - |
| 16 | 3 | `collectors` | P0 | not-started | - | - | - | - | - |
| 17 | 3 | `optional` | P1 | not-started | - | - | - | - | - |
| 18 | 3 | `lambda-internals` | P1 | not-started | - | - | - | - | - |
| 19 | 3 | `parallel-streams` | P1 | not-started | - | - | - | - | - |
| 20 | 3 | `stream-gatherers` | P2 | not-started | - | - | - | - | - |
| 21 | 4 | `thread-fundamentals` | P0 | not-started | - | - | - | - | - |
| 22 | 4 | `java-memory-model` | P0 | not-started | - | - | - | - | - |
| 23 | 4 | `synchronized-and-monitors` | P0 | not-started | - | - | - | - | - |
| 24 | 4 | `explicit-locks` | P0 | not-started | - | - | - | - | - |
| 25 | 4 | `atomics-and-cas` | P0 | not-started | - | - | - | - | - |
| 26 | 4 | `deadlock-and-liveness` | P0 | not-started | - | - | - | - | - |
| 27 | 4 | `executors-and-thread-pools` | P0 | not-started | - | - | - | - | - |
| 28 | 4 | `concurrent-collections` | P0 | not-started | - | - | - | - | - |
| 29 | 4 | `completable-future` | P0 | not-started | - | - | - | - | - |
| 30 | 4 | `threadlocal` | P1 | not-started | - | - | - | - | - |
| 31 | 4 | `synchronizers` | P1 | not-started | - | - | - | - | - |
| 32 | 4 | `fork-join` | P1 | not-started | - | - | - | - | - |
| 33 | 5 | `virtual-threads` | P0 | not-started | - | - | - | - | - |
| 34 | 5 | `scoped-values` | P1 | not-started | - | - | - | - | - |
| 35 | 5 | `structured-concurrency` | P1 | not-started | - | - | - | - | - |
| 36 | 6 | `jvm-memory-areas` | P0 | learning | - | - | - | - | 2026-11-03 |
| 37 | 6 | `class-loading` | P0 | not-started | - | - | - | - | - |
| 38 | 6 | `gc-fundamentals` | P0 | not-started | - | - | - | - | - |
| 39 | 6 | `gc-collectors` | P0 | not-started | - | - | - | - | - |
| 40 | 6 | `jit-compilation` | P1 | not-started | - | - | - | - | - |
| 41 | 6 | `reference-types` | P1 | not-started | - | - | - | - | - |
| 42 | 6 | `object-layout` | P1 | not-started | - | - | - | - | - |
| 43 | 6 | `bytecode-basics` | P2 | not-started | - | - | - | - | - |
| 44 | 6 | `startup-and-aot` | P2 | not-started | - | - | - | - | - |
| 45 | 7 | `oom-and-memory-leaks` | P0 | not-started | - | - | - | - | - |
| 46 | 7 | `thread-dump-analysis` | P0 | not-started | - | - | - | - | - |
| 47 | 7 | `gc-logs-and-tuning` | P0 | not-started | - | - | - | - | - |
| 48 | 7 | `jfr-and-profiling` | P1 | not-started | - | - | - | - | - |
| 49 | 7 | `benchmarking-with-jmh` | P1 | not-started | - | - | - | - | - |
| 50 | 8 | `reflection-and-proxies` | P1 | not-started | - | - | - | - | - |
| 51 | 8 | `io-and-nio` | P1 | not-started | - | - | - | - | - |
| 52 | 8 | `serialization` | P1 | not-started | - | - | - | - | - |
| 53 | 8 | `date-and-time` | P1 | not-started | - | - | - | - | - |
| 54 | 8 | `modules-jpms` | P2 | not-started | - | - | - | - | - |
| 55 | 8 | `foreign-function-memory` | P2 | not-started | - | - | - | - | - |

## Activity log

Newest at the bottom.

- 2026-11-03: Workspace set up. Phase 0 topics marked `covered-unverified` from `memory/java-8-learning-memory-prompt.md`.
- 2026-11-03: Learner chose to start at Phase 6. Taught `jvm-memory-areas`, wrote `notes/jvm-memory-areas.md`, understanding check pending.
