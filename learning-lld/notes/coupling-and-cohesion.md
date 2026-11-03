# Coupling & Cohesion

Updated 2026-10-27 · roadmap #2

**Core.** Keep the blast radius of a change small. *Cohesion*: things that change together live together (one job per class: same data, same reason to change). *Coupling*: how much A must know about B, which is how likely a change to B forces a change to A. Logic in the wrong class hurts both at once. Strong coupling *inside* one class is just cohesion.

## Heuristics
- Coupling hurts when it is **strong, far and volatile**. Strength, weakest to strongest: interface method < concrete class < fields < invariants or call order < internal algorithm. Depend on stable things freely. Put volatile ones (vendors, DB, formats, clock, changing rules) behind something you own.
- **Tell, don't ask.** Each rule lives with the data it reads. Callers should know verbs, not fields.
- A **public setter or leaked mutable collection** makes every caller co-own your invariant. Expose guarded operations instead.
- **Split by data, not by verb.** Extract a cluster of fields *plus* the methods that use them. Splitting into `XData` + `XCalculator` + `XValidator` lowers cohesion and forces getters and setters.
- **Hidden coupling costs more than visible coupling:** `Map<String,Object>`, magic ints and strings, string event names, reflection, shared tables. Deleting an import doesn't decouple anything.
- Don't merge look-alike code that changes for different reasons. DRY means one home per *rule*.
- Checks: count the files a likely change touches · count the mocks needed to unit-test one method · draw a field-usage grid (disjoint blocks = hidden classes) · a name that needs And/Manager/Utils/Helper means things were grouped by accident.

## Coupling forms (tightest first) and the lever for each
| Form | Lever |
|---|---|
| Inheritance (child depends on parent's self-calls) | compose + delegate |
| Representation (setters, leaked mutable state, feature envy) | guarded operations, read-only views |
| Shared mutable state (statics, stateful singletons, shared table) | one owner |
| Control (a flag picks the callee's branch) | one method/type per behaviour |
| Temporal (required call order) | factory returns a ready object |
| Runtime (A fails when B is down) | keep sync only what the operation needs |
| Concrete (`new Vendor()` inside) | interface you own, injected (DIP) |
| Stamp (whole object passed for one field) | pass the value or a narrow interface |
| Data (exactly what's needed) | healthy |

## Shines / overkill / degrades
- **Shines:** rules that change often, vendor/DB/IO/clock boundaries, code several people touch, unit tests.
- **Overkill:** wrapping stable pure things, interfaces with one implementation and no need for a seam, scripts, events for steps that must succeed together.
- **Degrades:** indirection, implicit flow, more classes, runtime errors instead of compile errors, over-splitting (which brings back shotgun surgery).

## Commonly confused with
- **SRP:** cohesion as a rule (one reason to change). Cohesion measures; SRP says where to cut.
- **Encapsulation:** limits what others *can* couple to. A public setter turns it off.
- **DRY:** merging look-alike code adds coupling.
- **Law of Demeter:** one specific coupling rule: no `a.getB().getC()`.
- **DIP:** points dependencies at abstractions. It reduces coupling to concretions; it doesn't remove coupling.

## Snippet
```java
// ask: the caller knows 2 fields, the rule and the invariant
if (m.getActiveLoans() < 3 && m.getUnpaidFine() == 0) m.setActiveLoans(m.getActiveLoans() + 1);
// tell: the caller knows one verb; Member owns the data and the rule
member.borrow(book, today);
```

## Smells
Shotgun surgery (coupling) · divergent change (cohesion) · feature envy (both) · flag params · required call order · getter chains · tests that need 5 mocks · `Manager`/`Utils`/`Helper`.

## Watch out (your active pitfalls, from OOP quiz-01)
- `encapsulation-as-getters-setters`: a setter is a coupling contract, not a harmless write. `setActiveLoans(0)` is the same bug as `setBalance`.
- `logic-outside-owning-object`: feature envy is low cohesion plus high coupling. Fix it by moving the method.
- `inheritance-for-reuse-not-polymorphism`: inheritance is the tightest coupling Java has. Reuse alone never pays for it.
