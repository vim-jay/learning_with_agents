I've parked your `jvm-memory-areas` check, unanswered, under "Parked understanding checks" in [progress/progress.md](progress/progress.md). Say "resume the memory areas check" whenever you want to answer it.

**Phase 1 order, one topic at a time:** `object-contracts` (now), `strings-and-immutability`, `generics-deep-dive`, `exceptions`, `initialization-and-nested-types`, `record-patterns`.

You're also skipping the Phase 0 check-up quizzes. That's fine here: this topic builds on overriding `equals()` and overload vs override, which your notes say you've studied.

All output below is real, from JDK 25.0.2.

# Object contracts

## 1. Why it exists

Overriding `equals()` is the easy part, and you've done it. `HashMap`, `HashSet`, `TreeMap` and every sort call `equals`, `hashCode` and `compareTo`, and they trust rules they never check. Break a rule and nothing throws: entries go missing, duplicates appear, and sets leak.

## 2. How it works

**The rules (contracts), from the `Object` and `Comparable` Javadoc:**

| Method | Rules |
|---|---|
| `equals` | Reflexive, symmetric, transitive, consistent; `x.equals(null)` is `false` |
| `hashCode` | Equal objects must give equal hash codes. It must stay stable while the fields `equals` uses don't change. Unequal objects may collide: slower, not wrong. It may differ between runs |
| `compareTo` | The sign flips when you swap the arguments; it's transitive; 0 means "same position relative to everything else". Strongly recommended: 0 exactly when `equals` is true |

**How a hash lookup uses them** (`HashMap.getNode` in the JDK 25 source):

```
 set.contains(key)          (HashSet is a HashMap underneath)
   │
   ▼
 h     = key.hashCode()       your method
 hash  = h ^ (h >>> 16)       mixes the high bits into the low bits
 index = hash & (n - 1)       n = table length, a power of two
   │
   ▼
 table[index] ──► Node{hash, key, value} ──► Node{...} ──► null
                  for each node in the bucket:
                  1. node.hash == hash ?     stored at put(); a cheap int compare
                  2. same key ?              == first, then equals()  (your method)
```

Two details drive everything below:
- **The hash is stored once.** It's computed at `put` and kept in the node, and nothing re-checks it later.
- **The stored hash is compared before `equals`.** If the hashes differ, your `equals` never runs.

**Which collections call which method:**

| Collection | Uses | Ignores |
|---|---|---|
| `HashMap`, `HashSet` | `hashCode`, then `equals` | `compareTo` |
| `TreeMap`, `TreeSet`, sorting | `compareTo` or the `Comparator` | `equals`, `hashCode` |
| `ArrayList.contains`, `indexOf`, `remove(Object)` | `equals` | `hashCode` |
| `IdentityHashMap` | `==` and the identity hash | `equals`, `hashCode` |

## 3. Code: four ways to break it

```java
import java.math.BigDecimal;
import java.util.*;

public class Contracts {
    // 1. equals overridden, hashCode not
    static final class NoHash {
        final int id;
        NoHash(int id) { this.id = id; }
        @Override public boolean equals(Object o) { return o instanceof NoHash n && id == n.id; }
    }

    // 2. equals overloaded instead of overridden
    static final class Overloaded {
        final int id;
        Overloaded(int id) { this.id = id; }
        public boolean equals(Overloaded o) { return o != null && id == o.id; }
        @Override public int hashCode() { return id; }
    }

    // 3. hashCode depends on a field that changes
    static final class Key {
        int id;
        Key(int id) { this.id = id; }
        @Override public boolean equals(Object o) { return o instanceof Key k && id == k.id; }
        @Override public int hashCode() { return id; }
    }

    public static void main(String[] args) {
        Set<NoHash> set1 = new HashSet<>(List.of(new NoHash(1), new NoHash(1)));
        System.out.println("1. size=" + set1.size() + " contains(new NoHash(1))=" + set1.contains(new NoHash(1)));

        Overloaded x = new Overloaded(1), y = new Overloaded(1);
        Object yAsObject = y;
        System.out.println("2. x.equals(y)=" + x.equals(y) + " x.equals(yAsObject)=" + x.equals(yAsObject)
                + " List.of(x).contains(y)=" + List.of(x).contains(y));

        Key k = new Key(1);
        Set<Key> set3 = new HashSet<>();
        set3.add(k);
        k.id = 2;
        System.out.println("3. contains(k)=" + set3.contains(k) + " remove(k)=" + set3.remove(k)
                + " size=" + set3.size() + " iterator sees id=" + set3.iterator().next().id);

        BigDecimal a = new BigDecimal("1.0"), b = new BigDecimal("1.00");
        System.out.println("4. equals=" + a.equals(b) + " compareTo=" + a.compareTo(b)
                + " HashSet size=" + new HashSet<>(List.of(a, b)).size()
                + " TreeSet size=" + new TreeSet<>(List.of(a, b)).size());
    }
}
```

```
1. size=2 contains(new NoHash(1))=false
2. x.equals(y)=true x.equals(yAsObject)=false List.of(x).contains(y)=false
3. contains(k)=false remove(k)=false size=1 iterator sees id=2
4. equals=false compareTo=0 HashSet size=2 TreeSet size=1
```

1. **No `hashCode`:** each object keeps `Object`'s identity hash, so the two equal objects get different hashes and `equals` is never called. The set keeps both.
2. **Overloaded `equals`:** `equals(Overloaded)` overloads `equals(Object)` instead of overriding it. As your overload-vs-override notes say, the compiler picks it only when the static type is `Overloaded`. Collections call `equals(Object)`, which is still `Object`'s identity check. Adding `@Override` turns the bug into a compile error: `method does not override or implement a method from a supertype`.
3. **Mutated key:** the node still holds hash 1, while `contains(k)` computes hash 2 and looks somewhere else. The entry can't be found or removed, but iteration still sees it. A long-lived set that does this leaks.
4. **`BigDecimal`:** `equals` compares value and scale (1.0 vs 1.00), while `compareTo` compares value only. `HashSet` uses `equals` and keeps both; `TreeSet` uses `compareTo` and keeps one. The `Comparable` Javadoc names `BigDecimal` as the known exception.

## 4. Trade-offs

**`instanceof` or `getClass()` in `equals`?**
- **`instanceof`:** a subclass instance can equal a parent instance, so subclasses and proxies stay substitutable. But once a subclass adds a field to `equals`, symmetry or transitivity breaks.
- **`getClass() == o.getClass()`:** stays symmetric across a hierarchy, but a subclass instance never equals a parent instance, even when it adds no state.
- **The way out is needing neither:** make value classes `final` or use records, and add state by composition instead of subclassing. That's the same argument as your fragile-base-class notes.

**What goes into `equals`?**
- **A value object:** every field that defines the value, kept immutable so it's safe as a key.
- **An object with an identity:** a stable id only.
- Any field that can change while the object sits in a set or map is a bug waiting to happen.

**Cost vs quality of `hashCode`:**
- `Objects.hash(a, b, c)` is short, but it allocates a varargs array and boxes primitives on every call. A hand-written `31 * h + ...` doesn't.
- Immutable classes can compute the hash once and cache it, as `String` does (`private int hash`).
- A constant `hashCode` is legal, but it puts every key in one bucket.

**Ordering that disagrees with `equals`** (like `BigDecimal`) is allowed, but sorted and hashed collections then disagree. If you do it, choose the collection on purpose and document it.

## 5. Traps

- **Records compare array components by reference.** A record's `equals` uses `Objects.equals` for each component, so `record Bytes(byte[] data) {}` with two equal arrays gives:
  ```
  record with array: equals false, Arrays.equals true
  ```
- **`==` on boxed numbers.** With `Integer a = 127, b = 127, c = 128, d = 128;`:
  ```
  boxed: a==b true, c==d false, c.equals(d) true
  ```
  Values from -128 to 127 are cached objects; beyond that, `==` compares two different objects. With `-XX:AutoBoxCacheMax=1000`, `c==d` printed `true`, so the answer can change with a JVM flag.
- **Subtraction comparators overflow.** 2,000,000,000 - (-2,000,000,000) wraps around to a negative number:
  ```
  sorted with p - q:          [2000000000, -2000000000, 0]
  sorted with Integer::compare: [-2000000000, 0, 2000000000]
  ```
- **A broken comparator fails only sometimes.** `(p, q) -> (int) (p - q)` on doubles truncates the difference. That makes 0.3 "equal" 0.9 and 0.9 "equal" 1.5, while 0.3 < 1.5, so it isn't transitive. On random prices (the 10,000 and 100,000 element runs also threw):
  ```
  100 elements: sorted without error, sorted? false
  1000 elements: java.lang.IllegalArgumentException: Comparison method violates its general contract!
  ```
  The sort throws only when it happens to notice, so this passes tests on small data and fails in production.
- **`URL.equals` and `URL.hashCode` resolve host names.** The JDK documents both as blocking operations. Comparing `http://localhost/` with `http://127.0.0.1/`:
  ```
  URL equals across host names: true, URI equals: false
  ```
  Never use `URL` as a map key; use `URI`.

## 6. Interview angle

"Two keys are equal but their `hashCode`s differ. If both happen to land in the same bucket, can `HashMap.get` still find the entry?"

Reciting the contract doesn't answer this. The deep answer is no. `getNode` compares the stored hash before calling `equals`. The spread step `h ^ (h >>> 16)` is reversible: the top 16 bits pass through unchanged, and the bottom 16 can be recovered from them. So two different `hashCode`s can never produce the same stored hash, and sharing a bucket doesn't help.

Notes are in [notes/object-contracts.md](notes/object-contracts.md).

---

## Your turn

Answer in your own words. "Yes, understood" doesn't count.

**1. Explain back.** What does `HashSet.contains` do with `hashCode()` and `equals()`, step by step? Why is "equal objects must have equal hash codes" a hard rule, while "unequal objects may share a hash code" is allowed?

**2. Predict, then explain.** What do the four lines print? Explain each one. Then change `Tag` so it's safe to use as a set element, and say why your change works.

```java
import java.util.*;

record Tag(String name, List<String> aliases) {}

public class Q1 {
    public static void main(String[] args) {
        List<String> aliases = new ArrayList<>(List.of("a"));
        Tag t = new Tag("x", aliases);
        Set<Tag> set = new HashSet<>();
        set.add(t);
        aliases.add("b");
        System.out.println(set.contains(t));
        System.out.println(set.contains(new Tag("x", List.of("a"))));
        System.out.println(set.contains(new Tag("x", List.of("a", "b"))));
        System.out.println(set.size());
    }
}
```

**3. Predict, then fix.** What do the four lines print, and why? Then fix the design so `equals` is symmetric, and say what your fix costs.

```java
import java.util.*;

class Point {
    final int x, y;
    Point(int x, int y) { this.x = x; this.y = y; }
    @Override public boolean equals(Object o) { return o instanceof Point p && x == p.x && y == p.y; }
    @Override public int hashCode() { return Objects.hash(x, y); }
}

class ColorPoint extends Point {
    final String color;
    ColorPoint(int x, int y, String color) { super(x, y); this.color = color; }
    @Override public boolean equals(Object o) {
        return o instanceof ColorPoint cp && super.equals(cp) && color.equals(cp.color);
    }
}

public class Q2 {
    public static void main(String[] args) {
        Point p = new Point(1, 2);
        Point cp = new ColorPoint(1, 2, "red");
        System.out.println(p.equals(cp));
        System.out.println(cp.equals(p));
        System.out.println(new ArrayList<>(List.of(cp)).contains(p));
        System.out.println(new ArrayList<>(List.of(p)).contains(cp));
    }
}
```