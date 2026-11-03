# JVM memory areas

Revision notes. Output verified on JDK 25.0.2 (macOS arm64, 8 GB RAM), 2026-11-03.

**Core idea:** `-Xmx` limits the Java heap, not the process. Each area holds data with a
different lifetime, has its own limit and fails in its own way. Identify the area before
choosing a fix.

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

## What frees each area

| Area | Freed when |
|---|---|
| Stack frame | The method returns or throws, with no GC involved |
| Heap object | GC finds it unreachable |
| Metaspace | Its class loader becomes unreachable and GC unloads its classes |
| Code cache | The compiled method is unloaded, or flushed under pressure |
| Direct buffer | GC finds the buffer object unreachable and its `Cleaner` runs |

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
