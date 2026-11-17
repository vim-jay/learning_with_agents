# JVM memory areas

Revision notes. Output verified on JDK 25.0.2 (macOS arm64, 8 GB RAM), 2026-11-03.

**Core idea:** `-Xmx` limits the Java heap, not the process. Each area holds data with a
different lifetime, has its own limit and fails in its own way. Identify the area before
choosing a fix.

## Learning path

Read top to bottom: each step builds on the one before. Steps 1, 2, 4, 6, 7 (first half) and
10 were added on 2026-11-06 from follow-up questions, with their output re-run on the same JDK.

| Step | Section | What you get |
|---|---|---|
| 1 | HotSpot: the JVM you are running | Spec vs implementation, HotSpot's parts, which JVM you have |
| 2 | A JVM's life: start, run, stop | One JVM per `java` command, startup order, what ends a JVM, finding running JVMs |
| 3 | The map, then One method call | The memory areas and what lives in each |
| 4 | Method area vs Metaspace | The spec's term vs HotSpot's implementation, and PermGen |
| 5 | What frees each area | How long each area's contents live |
| 6 | Code cache | Where JIT output lives and what happens when it fills. Invalidation is in `jit-compilation.md` |
| 7 | Using a direct buffer, then Direct buffers | How to use one, why it skips a copy, what it costs the heap |
| 8 | When each area runs out | Which error message points to which area |
| 9 | Reserved, committed, RSS | The three numbers memory tools report |
| 10 | Seeing memory stats: NMT, jcmd, jstat | Which tool to reach for, and how to read `jstat` |
| 11 | Traps | Mistakes experienced developers still make |
| - | Diagnose | Command cheat sheet |

## HotSpot: the JVM you are running

**Spec vs implementation.** The JVM specification (JVMS) is the rulebook. HotSpot is the JVM
in OpenJDK, so Oracle JDK, Temurin, Corretto and this Homebrew build all run it. OpenJ9 is
another implementation of the same spec.

**A native library.** The `java` launcher loads `lib/server/libjvm.dylib`. It's written in
C++: the library embeds 428 `src/hotspot/...cpp` source paths.

**The name.** It interprets bytecode first, profiles it, and JIT-compiles only the hot spots.
That's where warm-up comes from.

**Its parts:** a class loader, an interpreter, two JIT compilers (C1, C2), garbage collectors
(G1, ZGC, ...) and a runtime (threads, locks, deoptimization). Several show up as threads. An
idle `Hello` JVM ran 18, including:

```
 JIT compilers        C1 CompilerThread0, C2 CompilerThread0
 Garbage collector    G1 Main Marker, G1 Conc#0, G1 Refine#0, G1 Service, GC Thread#0
 VM operations        VM Thread, VM Periodic Task Thread
 Your code            main  (the interpreter and class loading run on your own threads)
```

**Which JVM am I running?**

```
$ java -version
openjdk version "25.0.2" 2026-01-20
OpenJDK Runtime Environment Homebrew (build 25.0.2)
OpenJDK 64-Bit Server VM Homebrew (build 25.0.2, mixed mode, sharing)
```

- The last line is the VM. It doesn't say "HotSpot": `OpenJDK 64-Bit Server VM` is HotSpot's
  name here, and `java -XshowSettings:properties -version` reports it as `java.vm.name`.
- `mixed mode` means the interpreter plus the JIT (`-Xint` prints `interpreted mode`).
- `sharing` means the class data sharing archive `lib/server/classes.jsa` is in use (see
  `startup-and-aot`).

**HotSpot vocabulary.** `-XX:` flags, Metaspace, C1/C2 and compressed oops are HotSpot terms,
not spec terms, so in an interview say "in HotSpot, ...". `java -XX:+PrintFlagsFinal -version`
lists every flag and its value.

## A JVM's life: start, run, stop

**One `java` command is one process with one JVM.** There's no shared background JVM: two runs
of `Hello` were two JVMs with their own pids. IDEs and build tools (the VS Code Java extension,
the Gradle daemon) run JVMs of their own. `javac` is a separate, short-lived program.

**Startup happens before your code runs:**

```
 $ java -cp out Hello
 1  launcher     the `java` program parses options and loads lib/server/libjvm
 2  Create VM    18.5 ms here. -Xlog:startuptime shows its phases: Genesis,
                 Interpreter generation, Start VMThread, Initialize java.lang
                 classes, Initialize module system. 401 JDK classes were loaded
                 before Hello. A bad option fails here, before any of your code:
                   Error occurred during initialization of VM
                   Too small maximum heap                    (from -Xmx1k)
 3  your class   Hello is loaded and initialized: its static blocks run
 4  main(args)   your code starts
```

Real output, with a print in a static block and another in `main`:

```
1. static block of Hello runs (class initialized)
2. main() starts, pid=22412
```

**What ends a JVM** (each case run with a shutdown hook registered):

| How it ends | Shutdown hooks | Exit code seen |
|---|---|---|
| The last non-daemon thread finishes | run | 0 |
| `System.exit(0)` | run | 0 |
| `kill <pid>` (SIGTERM) | run | 143 |
| `Runtime.getRuntime().halt(0)` | skipped | 0 |
| `kill -9 <pid>` (SIGKILL), which is also what a container OOM kill sends | skipped | 137 |

A JVM crash also ends it without running hooks (not tested here).

**Returning from `main` doesn't end the JVM** while a non-daemon thread is alive. Here is the
same program with a worker thread that sleeps 3 s:

```
 worker is non-daemon (the default)     worker.setDaemon(true) before start()
 main returned                          main returned
 worker finished after 3 s              shutdown hook ran
 shutdown hook ran                      (exited after 0 s: the worker was abandoned)
 (exited after 3 s)
```

That's why a server keeps running after `main` returns: its non-daemon threads keep the JVM
alive. Calling `setDaemon` after `start()` throws `IllegalThreadStateException`.

**Seeing which JVMs are running:**

```
$ jps -l                                  $ jcmd
22485 Hello                               22485 Hello 20000
22487 Hello                               22487 Hello 20000
22492 jdk.jcmd/sun.tools.jps.Jps          22495 jdk.jcmd/sun.tools.jcmd.JCmd
```

Both lists are filtered to the test JVMs, and each tool lists itself because it's a JVM too.
`ps aux | grep java` shows every Java process, from any user.

- `jps` and `jcmd`'s list come from `$TMPDIR/hsperfdata_<user>/<pid>` files, so they show only
  your own user's JVMs.
- A JVM started with `-XX:-UsePerfData` writes no such file. It was missing from both lists and
  `jstat` failed with `Could not attach to 22489`, but `jcmd 22489 VM.version` still worked.

## The map

```
 JVM PROCESS: the OS and the container charge for every page touched here
┌─────────────────────────────────────────────────────────────────────────┐
│ JAVA HEAP   limit: -Xmx                                          shared │
│   objects and arrays, including all their fields                        │
│   Class mirrors (Order.class), which hold static fields                 │
│   interned String objects                                               │
├───────────────────────────── native memory ─────────────────────────────┤
│ METASPACE   limit: -XX:MaxMetaspaceSize                          shared │
│   class metadata, bytecode, constant pools                              │
│   └ Compressed Class Space   limit: -XX:CompressedClassSpaceSize        │
│ CODE CACHE   limit: -XX:ReservedCodeCacheSize                    shared │
│   machine code produced by the JIT                                      │
│ DIRECT BUFFERS   limit: -XX:MaxDirectMemorySize                  shared │
│   ByteBuffer.allocateDirect                                             │
│ THREAD STACKS   limit: -Xss                              one per thread │
│   one frame per active call; Java and native frames share the stack     │
│ EVERYTHING ELSE   no overall cap                                 shared │
│   GC bookkeeping, JIT compiler memory, symbol table, native libraries   │
└─────────────────────────────────────────────────────────────────────────┘
```

## One method call

```java
class Order {
    static int count = 7;
    int qty = 3;

    static void place() {
        int n = 5;
        Order o = new Order();
    }
}
```

```
 THREAD STACK               HEAP                    METASPACE (native)
┌────────────────────┐    ┌─────────────────┐     ┌─────────────────────┐
│ frame: place()     │    │ Order object    │     │ Order metadata      │
│   n = 5            │    │   qty = 3       │────►│   field layout      │
│   o ───────────────┼───►│                 │     │   constant pool     │
├────────────────────┤    └─────────────────┘     │   bytecode of       │
│ frame: main()      │    ┌─────────────────┐     │     place()         │
│   args             │    │ Order.class     │◄───►│                     │
└────────────────────┘    │ (Class mirror)  │     └─────────────────────┘
                          │   count = 7     │
                          └─────────────────┘
```

- Three `int`s, three locations. Location depends on what owns the value, not on its type.
- A frame is a local variable array, an operand stack and a reference to the class's constant
  pool. `javac` fixes both sizes: `javap -v` shows `stack=2, locals=3`.
- Spec vs HotSpot: "method area" is the JVMS term, Metaspace is HotSpot's implementation.
  PermGen is gone since Java 8 (JEP 122).

## Method area vs Metaspace

```
 HEAP                                METASPACE (HotSpot's method area)
┌───────────────┐                    ┌────────────────────────────┐
│ Order object  │──┐                 │ Order class data           │
│   qty = 3     │  │  class pointer  │   field layout             │
└───────────────┘  ├────────────────►│   methods and bytecode     │
┌───────────────┐  │                 │   run-time constant pool   │
│ Order object  │──┘                 └────────────────────────────┘
│   qty = 9     │                      one copy per loaded class,
└───────────────┘                      shared by all its objects
```

Each object holds only its own field values. Methods are never copied into objects; every
`Order` points to the one copy of its class data.

- **Method area** is the spec's name for per-class data shared by all threads: the run-time
  constant pool, field and method data, and the code of methods and constructors. The spec
  calls it "logically part of the heap" but leaves its location, and whether it is garbage
  collected, to the implementation.
- **HotSpot's implementation has changed.** Up to Java 7 it was PermGen, a fixed-size region set
  by `-XX:MaxPermSize` that failed with `OutOfMemoryError: PermGen space`. Since Java 8 it has
  been Metaspace, in native memory and uncapped by default (JEP 122). On 25,
  `-XX:MaxPermSize=64m` stops the JVM with `Unrecognized VM option 'MaxPermSize=64m'`.
- **JIT machine code is not in Metaspace.** It goes in the code cache (step 6).
- **Say it like this:** "The method area is the spec's abstraction. HotSpot implements it with
  Metaspace, which replaced PermGen in Java 8." The two terms are not synonyms.
- Older articles put things in the method area that HotSpot has since moved. Check the map for
  where they live today.

## What frees each area

| Area | Freed when |
|---|---|
| Stack frame | The method returns or throws, with no GC involved |
| Heap object | GC finds it unreachable |
| Metaspace | Its class loader becomes unreachable and GC unloads its classes |
| Code cache | The compiled method is unloaded, or flushed under pressure |
| Direct buffer | GC finds the buffer object unreachable and its `Cleaner` runs |

## Code cache

The code cache holds machine code from the JIT, plus code the JVM generates for itself (the
interpreter and stubs). It's native memory, not heap. The default is 240 MiB
(`-XX:ReservedCodeCacheSize`), split into three heaps: non-nmethods (JVM code), profiled and
non-profiled (JEP 197, Java 9).

```
 Hot.java
    │ javac
    ▼
 Hot.class
    │ class loading
    ▼
 bytecode in METASPACE ──── first calls: the INTERPRETER runs it and collects a profile
    │ called often ("hot")
    ▼
 JIT: C1 first (tier 3, keeps profiling), then C2 (tier 4, optimized using the profile)
    │
    ▼
 machine code in the CODE CACHE ──── later calls jump straight here
```

The bytecode stays in Metaspace because compiled code can be thrown away, and the method then
falls back to the interpreter. How that happens is in `jit-compilation.md`.

Watch it happen:

```java
public class Hot {
    static int add(int a, int b) { return a + b; }

    public static void main(String[] args) {
        long sum = 0;
        for (int i = 0; i < 1_000_000; i++) sum = add((int) sum, i) & 0xFFFF;
        System.out.println("sum=" + sum);
    }
}
```

```
$ java -XX:+PrintCompilation Hot | grep 'Hot::add'
21    8       3       Hot::add (4 bytes)
22    9       4       Hot::add (4 bytes)
22    8       3       Hot::add (4 bytes)   made not entrant: not used
```

- The columns are ms since start, compile id, tier, method and bytecode size. `add` was
  compiled by C1 at 21 ms and by C2 at 22 ms, and then the C1 version was retired.
- Tier 4 is C2: with `-XX:TieredStopAtLevel=3` the JVM started no C2 compiler thread. With
  `-Xint` there were no compiles at all.
- A `%` in a line (for example `Hot::main @ 4`) marks OSR: a loop switched to compiled code
  while it was running.
- On a live JVM, `Compiler.codecache` (see Diagnose) shows the three heaps.

**When it fills, there's no `OutOfMemoryError`.** New hot methods stay interpreted, and the JVM
removes compiled code to make room and runs extra GCs. Eventually it prints `CodeCache is full.
Compiler has been disabled.` It looks like a slow app with healthy heap graphs. In the lesson,
a `javac` loop took 296 ms per run with the default cache and 2607 ms with a 3 MiB cache, with
no exception.

## Using a direct buffer

A direct buffer is a small heap object that holds the address of a block of native memory.
The class isn't public, so you can't name it:

```
Named.java:1: error: DirectByteBuffer is not public in java.nio; cannot be accessed from outside package
```

Create one with `ByteBuffer.allocateDirect` and use it like any `ByteBuffer`:

```java
import java.lang.management.*;
import java.nio.ByteBuffer;
import java.nio.channels.FileChannel;
import java.nio.file.*;
import static java.nio.file.StandardOpenOption.*;

public class DirectDemo {
    static void pool(String when) {
        for (BufferPoolMXBean p : ManagementFactory.getPlatformMXBeans(BufferPoolMXBean.class))
            if (p.getName().equals("direct"))
                System.out.println(when + ": direct pool count=" + p.getCount() + " bytes=" + p.getMemoryUsed());
    }
    public static void main(String[] args) throws Exception {
        pool("before");
        ByteBuffer buf = ByteBuffer.allocateDirect(1024);
        pool("after allocateDirect(1024)");
        System.out.println(buf.getClass().getName() + " isDirect=" + buf.isDirect() + " hasArray=" + buf.hasArray());
        buf.put("hello".getBytes());
        System.out.println("position=" + buf.position() + " limit=" + buf.limit());
        buf.flip();
        System.out.println("after flip position=" + buf.position() + " limit=" + buf.limit());
        Path f = Path.of("out.txt");
        try (FileChannel ch = FileChannel.open(f, CREATE, WRITE, TRUNCATE_EXISTING)) {
            System.out.println("bytes written=" + ch.write(buf));
        }
        System.out.println("file=" + Files.readString(f));
        try { buf.array(); } catch (UnsupportedOperationException e) { System.out.println("array() -> " + e); }
    }
}
```

```
before: direct pool count=0 bytes=0
after allocateDirect(1024): direct pool count=1 bytes=1024
java.nio.DirectByteBuffer isDirect=true hasArray=false
position=5 limit=1024
after flip position=0 limit=5
bytes written=5
file=hello
array() -> java.lang.UnsupportedOperationException
```

**Under the hood** (from the JDK 25 source):

```
 allocateDirect(n)    check -XX:MaxDirectMemorySize, allocate n native bytes, zero them,
                      and wrap the address in a DirectByteBuffer
 put(b) / get()       bounds check (position < limit), then a raw write or read
                      at address + index
 channel.write(buf)   passes (address + position, remaining) straight to the OS write()
```

**Why a heap buffer costs an extra copy:**

```
 heap buffer     byte[] on the heap ──copy──► temporary native buffer ──► OS write()
 direct buffer   native block ──────────────────────────────────────────► OS write()
```

The OS needs an address that won't move during the call, and GC can move heap arrays. So NIO
first copies a heap buffer into a temporary native buffer (`IOUtil.write`). This isn't
"zero-copy", because the kernel still copies. That term usually means `FileChannel.transferTo`.

**Who uses them:** your code, and libraries such as Netty, whose buffer pools are a common real
source of native memory. NIO itself uses them for its temporary buffers (see Traps), and JNI code
reads their address with `GetDirectBufferAddress`. An idle JVM starts with none: the demo's
`direct` pool read `count=0 bytes=0` before the first allocation.

**Choosing:** use direct buffers when they're long-lived, reused and I/O-heavy. Use heap buffers
when they're short-lived or the data is processed in Java: `array()` works only on heap buffers.

## Direct buffers

```
 HEAP                                 NATIVE
┌─────────────────────────┐         ┌──────────────┐
│ DirectByteBuffer   64 B │ address │              │
│ Cleaner            40 B │────────►│ 1 MiB block  │
│ Deallocator        32 B │         │              │
└─────────────────────────┘         └──────────────┘
  136 bytes on the heap               freed only after GC collects
                                      the buffer and its Cleaner runs
```

- 1 MiB of native memory adds 136 bytes to the heap, so the heap feels no pressure.
- When a reservation fails, `Bits.reserveMemory` calls `System.gc()`, retries with backoff,
  then throws.

## When each area runs out

| Exhausted | Limit (default) | You get | Dump flag | Exit flag |
|---|---|---|---|---|
| Heap | `-Xmx` (25% of RAM) | `Java heap space` | dumps | exits |
| Heap, thrashing (Parallel GC) | 98% of time in GC, under 2% recovered | `GC overhead limit exceeded` | dumps | exits |
| One array too big | VM limit, any heap size | `Requested array size exceeds VM limit` | dumps | exits |
| Metaspace | `-XX:MaxMetaspaceSize` (unlimited) | `Metaspace` | dumps | exits |
| Class pointer space | `-XX:CompressedClassSpaceSize` (1 GiB) | `Compressed class space` | dumps | exits |
| Direct buffers | `-XX:MaxDirectMemorySize` (max heap size) | `Cannot reserve N bytes of direct buffer memory` | **no** | **no** |
| Thread count | OS limits | `unable to create native thread` | **no** | **no** |
| Stack depth | `-Xss` (2 MiB here, 1 MiB on Linux x64) | `StackOverflowError`, not an OOM | n/a | n/a |
| Code cache | `-XX:ReservedCodeCacheSize` (240 MiB) | No exception: a warning and a slow JVM | n/a | n/a |
| Container limit | Kernel, via cgroup | SIGKILL, exit 137, no Java error | never runs | never runs |
| Native `malloc` | OS | JVM aborts with a fatal error log (docs, not reproduced) | n/a | n/a |

Dump flag is `-XX:+HeapDumpOnOutOfMemoryError`. Exit flag is `-XX:+ExitOnOutOfMemoryError`.

## Reserved, committed, RSS

- **Reserved:** address space set aside, nearly free.
- **Committed:** memory the JVM asked the OS to back.
- **RSS:** pages physically in RAM. This is what monitoring shows.
- Measured: `-Xmx128m` process, RSS 300 MiB. 521 threads reserved 1042 MB of stack and
  committed 39 MB. Direct buffers appear under NMT's `Other`.

## Seeing memory stats: NMT, jcmd, jstat

When you need every area at once, use NMT. It must be switched on at startup, and its commands
are in the Diagnose table. Without NMT, use `jcmd` and `jstat`, after finding the pid with
`jps -l` or `jcmd`.

```
 jcmd <pid> <command>                    jstat -gcutil <pid> 1000
 one-off report, or an action            live meter, one line per interval
 attaches to the JVM                     reads the JVM's perf counters
 can act: GC.run, GC.heap_dump           read-only
 53 commands here: jcmd <pid> help       GC and memory-pool numbers only
```

Both are JDK tools that work on a running JVM on the same machine, as the same user, with no
restart. A trimmed runtime may not have them: `jlink --add-modules java.base` produced a `bin/`
with only `java` and `keytool`. Adding the `jdk.jcmd` module brought `jcmd`, `jinfo`, `jmap`,
`jps`, `jstack` and `jstat`.

**Useful jcmd commands:** `jcmd` on its own lists JVMs. Then `jcmd <pid> help`, `GC.heap_info`,
`Thread.print`, `VM.flags` and `GC.heap_dump <file>`. Two commands act on the JVM:

- `GC.heap_dump`: its help says "Impact: High: Depends on Java heap size and content. Request a
  full GC unless the '-all' option is specified." It pauses the app, so be careful in production.
- `GC.run` runs a full GC: `FGC` went from 0 to 1.

**Reading jstat.** This is a busy JVM (a `javac` loop, G1):

```
$ jstat -gcutil <pid> 1000
  S0     S1     E      O      M     CCS    YGC     YGCT     FGC    FGCT     CGC    CGCT       GCT
     -  75.00  25.86  74.00  98.95  97.81     35     0.265     0     0.000     4     0.010     0.275
     -  70.22  94.37  70.24  99.08  97.81     45     0.335     0     0.000     6     0.013     0.348
```

| Columns | Meaning |
|---|---|
| `S0` `S1` `E` `O` | % used of survivor 0, survivor 1, Eden and Old (generations are in `gc-fundamentals`) |
| `M` `CCS` | % used of Metaspace and of compressed class space |
| `YGC` `YGCT` | Young GCs: count and total seconds |
| `FGC` `FGCT` | Full GCs: count and total seconds |
| `CGC` `CGCT` | Pauses from concurrent cycles: count and seconds. With G1 that's Remark plus Cleanup, two per cycle. The `jstat` docs don't define these two columns |
| `GCT` | All GC time, in seconds |

- **Percentages are of current (committed) capacity, not the max.** `M` at 99% above was 13079
  of 13184 KB committed (`MU` and `MC` from `jstat -gc`), with Metaspace uncapped. That's
  normal, not a warning.
- **`-` means the capacity is 0.** G1 had no S0 region at that moment. On an idle JVM, `M` and
  `CCS` showed `-` until the first GC; after `jcmd GC.run` they read 62.06 and 19.60.
- **An `O` that keeps rising after each old-generation collection** means live data is growing.
  If it never levels off, suspect a leak.

## Traps

- "Primitives live on the stack": only local ones. Fields live inside their object.
- "1000 threads = 1000 x `-Xss` of RAM": 1000 threads at `-Xss2m` reserved 2036 MB and
  committed 50 MB.
- An OOM's stack trace names whoever asked last, not who holds the memory, and only that
  thread gets the error. The JVM keeps running.
- Stack depth is not a stable number. Identical `-Xss2m` runs reached 49424 and 123560;
  `-Xint` reached 20592.
- Virtual thread stacks live on the heap when unmounted. 20,000 parked ones held 58 MB of
  `jdk.internal.vm.StackChunk` on 34 OS threads.
- `MetaspaceSize` is the first GC trigger, not the initial size or the cap.
- A captured local is copied to the heap (`int arg$1` on the lambda object), which is why it
  must be effectively final.
- Non-escaping objects may never be allocated: 0 vs 24 bytes per `new` with escape analysis
  on vs off. See `jit-compilation`.
- Writing a heap `ByteBuffer` to a channel holds a per-thread temporary native buffer that
  `MaxDirectMemorySize` and the `direct` pool both miss. A 64 MiB write showed `direct` 0
  bytes and NMT `Other` 64 MB. `-Djdk.nio.maxCachedBufferSize` caps what gets cached.
- Loaders, not classes, keep Metaspace alive. Keeping loaders: OOM at 5260 classes under a
  32 MiB cap. Dropping them: 40,000 classes through the same cap.

## Diagnose

| Question | Command |
|---|---|
| Memory by area | Start with `-XX:NativeMemoryTracking=summary`, then `jcmd <pid> VM.native_memory summary` |
| What grew | `jcmd <pid> VM.native_memory baseline`, later `summary.diff` |
| Heap and objects | `jcmd <pid> GC.heap_info`, `jcmd <pid> GC.class_histogram` |
| Metaspace | `jcmd <pid> VM.metaspace` |
| Code cache | `jcmd <pid> Compiler.codecache` |
| Direct buffers | `BufferPoolMXBean` named `direct` (misses temporary NIO buffers) |

NMT cannot be switched on after startup, costs 5-10% according to the docs, and does not track
non-JVM native code.

## Watch out

No open weak entries for this topic yet.
