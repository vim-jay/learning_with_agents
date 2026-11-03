# Core Java Roadmap (5 YOE bar, Java 25 LTS)

Built from recurring topics in 2025–26 senior Java interview guides, then adjusted for what
`memory/` says you've already covered. The mentor goes top to bottom. Slugs in backticks are
used as folder names and progress keys.

**Priority**
- **P0:** expected at 5 YOE. Weak answers here are likely to hurt in an interview.
- **P1:** often asked, and useful on the job.
- **P2:** awareness is enough. Learn after P0 and P1.

The priorities are my judgement, based on how often topics recur across the sources. The
sources are mostly prep guides rather than hiring data, so reorder freely.

**Out of scope here:** Spring, Hibernate/JPA and JDBC, microservices, messaging, system design,
build tools (other folders), and SOLID/design patterns (`../learning-lld`).

## Phase 0 — Verify what you've covered

`memory/` shows you've studied these, but not how well you can use them. Each gets one
diagnostic quiz. Passing skips re-teaching; gaps go to `progress/weak-topics.md`.

| # | Topic | Priority | Covers |
|---|---|---|---|
| 1 | `baseline-functional` | P0 | Lambdas vs anonymous classes, functional interfaces, basic streams |
| 2 | `baseline-oop-dispatch` | P0 | Overload vs override, static vs runtime type, field hiding, fragile base class |
| 3 | `baseline-modern-types` | P0 | Records, sealed types, pattern matching for `instanceof` and `switch` |

## Phase 1 — Language depth

You've covered `equals()` and basic generics. These go after the parts that bite later.

| # | Topic | Priority | Covers |
|---|---|---|---|
| 4 | `object-contracts` | P0 | `equals`/`hashCode`/`compareTo` contracts, mutable keys, identity vs equality |
| 5 | `strings-and-immutability` | P0 | String pool, `intern`, compact strings, concatenation cost, building immutable classes, defensive copies |
| 6 | `generics-deep-dive` | P0 | Erasure, wildcards and PECS, bridge methods, heap pollution, why `new T[]` fails |
| 7 | `exceptions` | P0 | Checked vs unchecked, try-with-resources, suppressed exceptions, `finally` traps, wrapping and cost |
| 8 | `initialization-and-nested-types` | P1 | Class and instance init order, static vs inner classes and captured references, enums, flexible constructor bodies (25) |
| 9 | `record-patterns` | P1 | Record deconstruction (21), nested patterns, unnamed `_` (22): the next step from what you know |

## Phase 2 — Collections internals

| # | Topic | Priority | Covers |
|---|---|---|---|
| 10 | `hashmap-internals` | P0 | Hash spreading, buckets, treeification, resizing, load factor, fail-fast iterators |
| 11 | `lists-and-queues` | P0 | `ArrayList` vs `LinkedList` and cache locality, `ArrayDeque`, `PriorityQueue` |
| 12 | `ordered-and-sorted-collections` | P1 | `TreeMap`, `LinkedHashMap` as an LRU cache, sequenced collections (21) |
| 13 | `collection-immutability-and-views` | P1 | `List.of` vs `unmodifiableList` vs `Arrays.asList`, null handling, `subList` traps |
| 14 | `specialized-collections` | P2 | `EnumMap`, `IdentityHashMap`, `WeakHashMap`, `BitSet` |

## Phase 3 — Streams and functional depth

You've used `filter` and `collect`. The depth is in how they execute.

| # | Topic | Priority | Covers |
|---|---|---|---|
| 15 | `stream-internals` | P0 | Laziness, pipeline stages, short-circuiting, stateful ops, `flatMap`, primitive streams and boxing |
| 16 | `collectors` | P0 | `groupingBy`, `partitioningBy`, `toMap` merge traps, `teeing`, writing a custom `Collector` |
| 17 | `optional` | P1 | `orElse` vs `orElseGet`, `map`/`flatMap`, where not to use it |
| 18 | `lambda-internals` | P1 | `invokedynamic`, capturing vs non-capturing, effectively final, memory retention |
| 19 | `parallel-streams` | P1 | Common pool, spliterators, when they get slower, blocking traps |
| 20 | `stream-gatherers` | P2 | Custom intermediate ops (final in 24) |

## Phase 4 — Concurrency

The largest phase and the deepest part of most senior Java interviews. Don't rush it.

| # | Topic | Priority | Covers |
|---|---|---|---|
| 21 | `thread-fundamentals` | P0 | Lifecycle, interruption, daemon threads, `wait`/`notify` and spurious wakeups |
| 22 | `java-memory-model` | P0 | Happens-before, visibility vs atomicity, `volatile`, `final` fields, safe publication, double-checked locking |
| 23 | `synchronized-and-monitors` | P0 | Monitors, reentrancy, lock choice, how the JVM implements locking (biased locking is gone) |
| 24 | `explicit-locks` | P0 | `ReentrantLock`, `Condition`, read-write and stamped locks, fairness, AQS |
| 25 | `atomics-and-cas` | P0 | CAS, ABA, `LongAdder` vs `AtomicLong`, `VarHandle`, false sharing |
| 26 | `deadlock-and-liveness` | P0 | Deadlock conditions, lock ordering, livelock, starvation, spotting them in thread dumps |
| 27 | `executors-and-thread-pools` | P0 | `ThreadPoolExecutor` parameters, queues, rejection, sizing, shutdown, swallowed exceptions |
| 28 | `concurrent-collections` | P0 | `ConcurrentHashMap` internals (CAS + bin locks), check-then-act races, `compute*` traps, `CopyOnWrite*`, `BlockingQueue` |
| 29 | `completable-future` | P0 | `thenApply` vs `thenCompose`, error handling, timeouts, which thread runs what, common pool traps |
| 30 | `threadlocal` | P1 | How it works, leaks in thread pools, inheritance |
| 31 | `synchronizers` | P1 | `CountDownLatch`, `CyclicBarrier`, `Semaphore`, `Phaser` |
| 32 | `fork-join` | P1 | Work stealing, `RecursiveTask`, relationship to parallel streams and `CompletableFuture` |

## Phase 5 — Modern concurrency (Project Loom)

Now a standard interview topic, and it needs Phase 4 to make sense.

| # | Topic | Priority | Covers |
|---|---|---|---|
| 33 | `virtual-threads` | P0 | Mounting and carriers, what blocking does, pinning (and the `synchronized` fix in 24), why not to pool them, limiting concurrency, CPU-bound limits |
| 34 | `scoped-values` | P1 | Final in 25, why they suit virtual threads better than `ThreadLocal` |
| 35 | `structured-concurrency` | P1 | **Still preview in 25** (needs `--enable-preview`), task scopes, cancellation, API has changed between releases |

## Phase 6 — JVM internals

| # | Topic | Priority | Covers |
|---|---|---|---|
| 36 | `jvm-memory-areas` | P0 | Heap, stacks, metaspace, code cache, direct memory, and which `OutOfMemoryError` each produces |
| 37 | `class-loading` | P0 | Load/link/init, delegation, classloader hierarchy, classloader leaks |
| 38 | `gc-fundamentals` | P0 | GC roots, reachability, generational hypothesis, mark/sweep/copy/compact, barriers, stop-the-world |
| 39 | `gc-collectors` | P0 | Serial, Parallel, G1, ZGC (generational only since 24), Shenandoah (generational mode in 25), how to choose |
| 40 | `jit-compilation` | P1 | Interpreter to C1 to C2, inlining, escape analysis, deoptimization, warm-up |
| 41 | `reference-types` | P1 | Soft, weak, phantom, `Cleaner`, why finalizers are deprecated |
| 42 | `object-layout` | P1 | Headers, compressed oops, alignment, compact object headers (25) |
| 43 | `bytecode-basics` | P2 | Reading `javap -c`, how to use it to settle "what does this actually compile to" |
| 44 | `startup-and-aot` | P2 | Class data sharing, AOT cache, why startup and warm-up are hard |

## Phase 7 — Production diagnostics

What separates someone who knows the JVM from someone who has operated it. Most of these work
best as labs.

| # | Topic | Priority | Covers |
|---|---|---|---|
| 45 | `oom-and-memory-leaks` | P0 | Leak patterns, GC problem vs application design problem, heap dumps, reading them in Eclipse MAT |
| 46 | `thread-dump-analysis` | P0 | `jcmd`/`jstack`, diagnosing high CPU, blocked pools and deadlocks |
| 47 | `gc-logs-and-tuning` | P0 | `-Xlog:gc*`, reading pause and occupancy trends, heap sizing, container awareness, when not to tune |
| 48 | `jfr-and-profiling` | P1 | Java Flight Recorder, JDK Mission Control, `async-profiler`, reading flame graphs |
| 49 | `benchmarking-with-jmh` | P1 | Why hand-rolled benchmarks lie, dead code elimination, warm-up |

## Phase 8 — Platform APIs

| # | Topic | Priority | Covers |
|---|---|---|---|
| 50 | `reflection-and-proxies` | P1 | Reflection, annotations and retention, dynamic proxies, `MethodHandle`: the mechanisms frameworks are built on |
| 51 | `io-and-nio` | P1 | Streams vs channels and buffers, direct buffers, memory mapping, selectors, `Path`/`Files` |
| 52 | `serialization` | P1 | `serialVersionUID`, compatibility, security risks, how records differ |
| 53 | `date-and-time` | P1 | `Instant` vs `LocalDateTime` vs `ZonedDateTime`, time zone bugs, legacy `Date` traps |
| 54 | `modules-jpms` | P2 | Module descriptors, strong encapsulation, why `--add-opens` exists |
| 55 | `foreign-function-memory` | P2 | Calling native code and off-heap memory (final in 22), where it replaces JNI |

## Verified on the installed JDK (25.0.2, 2026-11-03)

- **Final, ran without flags:** scoped values, stream gatherers, record patterns, unnamed `_`,
  sequenced collections, virtual threads.
- **Preview:** `StructuredTaskScope` fails to compile without `--enable-preview`.
- **Removed:** `-XX:+UseBiasedLocking` is rejected, and `-XX:-ZGenerational` is ignored.
- **Accepted:** `-XX:+UseCompactObjectHeaders`, and Shenandoah's generational mode.

Newer JDKs than 25 exist. Features can change status, so the mentor checks before teaching them.

## Sources

See [sources.md](sources.md).
