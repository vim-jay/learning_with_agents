# Object contracts

Revision notes. Output verified on JDK 25.0.2 (macOS arm64), 2026-11-06.

**Core idea:** collections never look at your fields. They call `equals`, `hashCode` and
`compareTo`, and they trust the contracts. Break one and nothing throws: entries go missing,
duplicates appear, and sets quietly leak.

## The contracts

| Method | Rules |
|---|---|
| `equals` | Reflexive, symmetric, transitive, consistent; `x.equals(null)` is `false` |
| `hashCode` | Equal objects give equal hash codes. Stable while the fields used by `equals` don't change. Unequal objects may collide (slower, not wrong). May differ between runs |
| `compareTo` | Sign flips when the arguments swap; transitive; 0 means the same position relative to every other element. Strongly recommended: 0 exactly when `equals` is `true` |

## How HashMap uses them

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

- The hash is computed once, at `put`, and stored in the node.
- A lookup compares the stored hash before it ever calls `equals`.

## Who calls what

| Collection | Uses | Ignores |
|---|---|---|
| `HashMap`, `HashSet` | `hashCode`, then `equals` | `compareTo` |
| `TreeMap`, `TreeSet`, sorting | `compareTo` or the `Comparator` | `equals`, `hashCode` |
| `ArrayList.contains`, `indexOf`, `remove(Object)` | `equals` | `hashCode` |
| `IdentityHashMap` | `==` and the identity hash | `equals`, `hashCode` |

## Writing them

```java
final class Money {
    private final long cents;
    private final String currency;

    Money(long cents, String currency) {
        this.cents = cents;
        this.currency = Objects.requireNonNull(currency);
    }

    @Override public boolean equals(Object o) {
        return o instanceof Money m && cents == m.cents && currency.equals(m.currency);
    }

    @Override public int hashCode() {
        return 31 * Long.hashCode(cents) + currency.hashCode();
    }
}
```

- For a value type, `record Money(long cents, String currency) {}` generates the same pair from
  all components.
- Always add `@Override`: on `equals(Money)` the compiler says "method does not override or
  implement a method from a supertype".
- Use the same fields in `equals` and `hashCode`, and keep them immutable.
- Compare with `Integer.compare`, `Long.compare` or `Comparator.comparing...`, never by
  subtraction.

## Traps

- **Equal objects, no `hashCode`:** a `HashSet` kept both copies, and `contains` returned
  `false`.
- **An overloaded `equals(Overloaded)`:** `x.equals(y)` was `true` when the static type was
  `Overloaded`, but `false` through `Object`, and collections only call `equals(Object)`.
- **A key mutated after `add`:** `contains` returned `false`, `remove` returned `false`,
  `size` stayed 1, and the iterator still saw it. Long-lived sets leak this way.
- **`BigDecimal` 1.0 vs 1.00:** `equals` compares value and scale, `compareTo` only value. A
  `HashSet` kept 2 and a `TreeSet` kept 1.
- **Records compare array components by reference** (`Objects.equals`): two records holding
  equal arrays were not equal.
- **`==` on boxed numbers:** `127 == 127` was `true` and `128 == 128` was `false`.
  `-XX:AutoBoxCacheMax=1000` flipped the second to `true`.
- **Subtraction comparators overflow:** `(p, q) -> p - q` sorted `[2000000000, -2000000000, 0]`.
- **Inconsistent comparators fail only sometimes:** `(int) (p - q)` on doubles sorted 100
  elements wrongly without an error, and threw `Comparison method violates its general
  contract!` from 1000 elements up.
- **`URL.equals` and `URL.hashCode` resolve host names:** they block on DNS, and `localhost`
  equalled `127.0.0.1`. Use `URI` for keys.

## Watch out

No open weak entries for this topic yet.
