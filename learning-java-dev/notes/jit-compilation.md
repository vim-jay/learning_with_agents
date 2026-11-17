# JIT compilation

Seed notes. This topic hasn't been taught yet (`jit-compilation` is still `not-started`). They
cover code cache invalidation, built from follow-up questions after the `jvm-memory-areas`
lesson. Tiers and `-XX:+PrintCompilation` basics are in `jvm-memory-areas.md` (Code cache).
Output verified on JDK 25.0.2 (macOS arm64), 2026-11-06.

**Core idea:** compiled code is built on bets taken from the profile, such as "only `Square`
ever reaches this call". When a bet stops holding, that compiled version is retired and the
method runs interpreted until it is recompiled. Behaviour never changes; only speed does.

## When compiled code stops being valid

There's no TTL or LRU eviction as in an ordinary cache. Compiled code is invalidated when it
no longer applies:

| Trigger | Example | `-XX:+PrintCompilation` shows |
|---|---|---|
| A speculation fails | C2 assumed only `Square` reaches `s.area()`, then a `Circle` arrives | `made not entrant: uncommon trap` |
| A class load breaks an assumption, such as "only one implementor" | `Circle` is loaded | `made not entrant: marked for deoptimization` (fits this cause, but the log doesn't name it) |
| A better version is ready | C2's version replaces C1's | `made not entrant: not used` |
| A compiled loop (OSR) is replaced by a higher tier | | `made not entrant: OSR invalidation of lower level` |
| A class is unloaded, or an agent redefines it | Not reproduced here | |
| Space is needed for hotter code | The 3 MiB code cache run in the `jvm-memory-areas` lesson | GC log: `(CodeCache GC Threshold)` |

## The four steps

```
 compiled version in use
   │  an assumption breaks, or a better version is ready
   ▼
 1 made not entrant   new calls go to the interpreter or to a newer version
   ▼
 2 deoptimize         frames still running the old code are rebuilt as
                      interpreter frames and carry on there (only if needed)
   ▼
 3 recompile          if the method is still hot, under a new compile id
   ▼
 4 free               the memory is reclaimed later, once nothing can use it
                      (driven by GC since JDK 20)
```

## Demo

```java
public class Deopt {
    interface Shape { int area(); }
    static class Square implements Shape { public int area() { return 4; } }
    static class Circle implements Shape { public int area() { return 3; } }

    static int total(Shape s) { return s.area() + 1; }

    static long loop(Shape s, int n) {
        long sum = 0;
        for (int i = 0; i < n; i++) sum += total(s);
        return sum;
    }

    public static void main(String[] args) throws Exception {
        System.out.println("PHASE 1: only Square, 2M calls");
        System.out.println(loop(new Square(), 2_000_000));
        Thread.sleep(500);
        System.out.println("PHASE 2: load Circle and call it");
        System.out.println(loop(new Circle(), 2_000_000));
        Thread.sleep(500);
        System.out.println("END");
    }
}
```

```
$ java -XX:+PrintCompilation Deopt        (trimmed to the Deopt lines)
PHASE 1: only Square, 2M calls
24   13       3       Deopt::total (9 bytes)
24   14       4       Deopt::total (9 bytes)
24   13       3       Deopt::total (9 bytes)   made not entrant: not used
26   15 %     3       Deopt::loop @ 5 (27 bytes)
26   16       3       Deopt::loop (27 bytes)
26   17 %     4       Deopt::loop @ 5 (27 bytes)
27   15 %     3       Deopt::loop @ 5 (27 bytes)   made not entrant: OSR invalidation of lower level
27   17 %     4       Deopt::loop @ 5 (27 bytes)   made not entrant: uncommon trap
PHASE 2: load Circle and call it
535   16       3       Deopt::loop (27 bytes)   made not entrant: marked for deoptimization
535   14       4       Deopt::total (9 bytes)   made not entrant: uncommon trap
536   20       4       Deopt::total (9 bytes)
```

A separate run with `-Xlog:deoptimization=debug` names each trap (trimmed):

```
[0.057s][debug][deoptimization] cid=  17 osr level=4 Deopt.loop(LDeopt$Shape;I)J trap_bci=8 osr_bci=5 unstable_if reinterpret ...
[0.566s][debug][deoptimization] cid=  14     level=4 Deopt.total(LDeopt$Shape;)I trap_bci=1 class_check maybe_recompile ...
```

`javap -c` shows that `trap_bci=1` in `total` is `invokeinterface Shape.area`, and `trap_bci=8`
in `loop` is `if_icmpge`, the loop's exit test.

Reading it:

- **Phase 1:** `total` is compiled by C1 (id 13), then by C2 (id 14), and the C1 version is
  retired as "not used". The C2 OSR version of the loop (id 17) had never seen the loop exit,
  so it left that path out. When the loop finally ended, it trapped (`unstable_if` at the exit
  test).
- **Phase 2:** a `Circle` reaches C2's `total` and the type check fails (`class_check`). The
  trapping frame carries on in the interpreter. The trap fired several times (4 log lines for
  `cid=14`) before id 14 was retired, and `total` was recompiled as id 20.
- `loop` id 16 is "marked for deoptimization". That fits the class-load trigger, but the log
  doesn't prove the cause.
- The log shows code being retired, not memory being freed.
- The reasons were the same in two runs.

## Older articles

JDK-8290025 ("Remove the Sweeper", JDK 20) removed the separate sweeper thread and the "zombie"
method state, and GC now unloads dead code. Articles that mention "made zombie" or a sweeper
thread describe older JDKs. On 25 there were no "zombie" lines, and an idle JVM's thread list
had no sweeper thread. Flags named after sweeping still exist (`SweeperThreshold`,
`StartAggressiveSweepingAt`), so don't judge by flag names.

## In production

- Expect latency blips after warm-up when a rare path or a new class shows up.
- Repeated deoptimize-and-recompile cycles are a real performance problem.
- Spot them with `-XX:+PrintCompilation` or the JFR event `jdk.Deoptimization`.

## Watch out

No open weak entries. This topic hasn't been taught or tested yet.
