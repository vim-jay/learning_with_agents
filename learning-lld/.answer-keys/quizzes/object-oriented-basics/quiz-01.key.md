# Answer Key — quiz-01 — object-oriented-basics

Created 2026-10-26, before learner answered. Do not show before submission.

**Scoring:** each question is worth its XP weight: `[E]`=5, `[M]`=10, `[H]`=20.
Max = 3×5 + 5×10 + 2×20 = **105**. Partial = half. `score_pct = earned / 105`.
Pass ≥ 70% → +20 XP bonus.

Outputs for Q4/Q5/Q6 verified by running on OpenJDK 25.0.2.

Trap questions (common misconceptions, no active pitfalls yet):
Q1/Q3 (encapsulation = getters/setters), Q4 (overload resolved at runtime),
Q5 (fields are polymorphic), Q6 (inheritance for code reuse is safe).

---

## Q1 [E] — Answer: (b)
- must_include: chooses (b); says the point is protecting invariants / controlling how state changes; notes (a) or (d) are mechanisms that don't guarantee it (private + public setter = no protection).
- disqualifiers: picks (d); claims getters/setters for all fields *is* encapsulation.
- partial: picks (b) with weak or missing reasoning about why (a)/(d) fail; or picks (a) but explicitly argues invariants are the goal.
- note: (c) is program-to-interface / abstraction, not encapsulation.

## Q2 [E] — Answer: interface
- must_include: interface; reason = classes already extend other bases and Java has single class inheritance (or: it's a capability shared by unrelated types, no shared state).
- disqualifiers: abstract class.
- partial: interface with a vague reason ("interfaces are better") that doesn't mention single inheritance or capability for unrelated types.

## Q3 [E]
- must_include: public setter lets anyone set any value (negative, arbitrary) — invariant unprotected; replace setter with intention-revealing operations like `deposit(amt)` / `debit(amt)` with guards (amt > 0, sufficient balance).
- disqualifiers: says it's fine because field is private; "fix" that just adds validation inside `setBalance` while still allowing arbitrary absolute overwrite without justifying it (→ treat as partial, not disqualifier, if guard is reasonable).
- partial: identifies problem but fix is only `setBalance` with a `>= 0` check (still allows arbitrary jumps / bypasses domain operations).

## Q4 [H] — Answer: `Fraud-Payment`
- must_include: correct output `Fraud-Payment`; (1) overload chosen at compile time using the *static/declared* type of the argument (`Payment`) → signature `process(Payment)`; (2) override chosen at runtime using the *actual* type of the receiver (`FraudCheckingProcessor`).
- disqualifiers: any other output (`Fraud-Card`, `Processor-Card`, `Processor-Payment`).
- partial: correct output but explains only one of the two decisions, or explanation is muddled.

## Q5 [M] — Answer: `base derived`
- must_include: correct output; fields are not polymorphic — field access is resolved by the static type (`Base`) (field hiding), while the method is overridden and dispatched at runtime, and inside `Derived.getName()` `name` refers to `Derived.name`.
- disqualifiers: `derived derived`, `base base`, `derived base`.
- partial: correct output with reasoning that only says "fields vs methods differ" without static vs runtime resolution.

## Q6 [H] — Answer: prints `6`
- must_include:
  1. `6`, because `HashSet.addAll` (via `AbstractCollection.addAll`) calls `add()` for each element, which is the overridden `add` → counted twice.
  2. Fragile base class / inheritance breaks encapsulation — subclass depends on superclass's self-use implementation details.
  3. Composition/forwarding: a class that *has* a `Set<E>` (or implements `Set<E>` and delegates), counting in its own methods; then base class internals can't double count.
- disqualifiers: says `3`.
- partial: `6` + correct reason but no redesign; or redesign = "just remove the addAll override" with no recognition that this still depends on undocumented internals (that's partial at best). Two of three sub-parts correct = partial.

## Q7 [M]
- must_include: polymorphism (runtime dispatch) — via abstraction `Vehicle`/`Spot` with type-specific behaviour (e.g. `abstract class Vehicle { abstract SpotSize requiredSpot(); abstract Money hourlyRate(); }` with `Bike`, `Car`, `Truck`); adding ELECTRIC_CAR = one new class, no edits to the 3 services' switches; fewer places to forget/missed-case bugs.
- disqualifiers: answers "inheritance" alone with the code still switching on type; keeps switches and just adds a case.
- partial: names polymorphism but sketch is wrong/absent, or benefit stated vaguely ("more extensible") without the "one new class, zero switch edits" point.
- bonus credit (not required): notes that rates could also be data (config) rather than behaviour.

## Q8 [M] — Not justified
- must_include: subclasses differ only in data (a constant), not behaviour → use a field/enum (`country`) or a `record`; DTO is a data carrier → record/plain data; rule: subclass only when *behaviour* varies (and substitutability holds).
- disqualifiers: says the hierarchy is good because "it's more OO / extensible".
- partial: says it's overkill but doesn't state the "behaviour vs data" rule, or doesn't offer an alternative.
- note: if learner argues subclasses would be justified *if* country-specific validation/formatting behaviour existed — that's a good answer, full credit if the rest is present.

## Q9 [M]
- must_include: FixedDepositAccount is not substitutable for Account (is-a "except" → violates substitutability / LSP); callers using the base type break at runtime; restructure so withdraw isn't promised by the base type — e.g. `Account` (deposit, balance) + `Withdrawable` capability interface / separate `WithdrawableAccount` subtype, monthly job iterates only types that support it (or fee charged via a different operation).
- disqualifiers: fix = catch the exception in the loop / `instanceof` check in loop as the whole solution; says the design is fine.
- partial: identifies substitutability problem but fix is weak (instanceof filter), or good restructure without explaining why the original is wrong.

## Q10 [M]
- must_include: smells = feature envy / tell-don't-ask violation / train-wreck (Law of Demeter) and broken encapsulation of Wallet (setBalance); rewrite: `Wallet.debit(Money)` owns the sufficient-funds check and mutation; `Cart`/`Order` owns status transition (e.g. `cart.markPaid()` or `cart.checkout(wallet)`), CheckoutService just orchestrates (`if (wallet.tryDebit(total)) cart.markPaid();` or exception-based).
- disqualifiers: rewrite still reads balance and calls `setBalance` from outside Wallet.
- partial: names smell correctly but only partially moves logic (e.g. debit moved but status still set via setter string), or good rewrite but smell not named.
