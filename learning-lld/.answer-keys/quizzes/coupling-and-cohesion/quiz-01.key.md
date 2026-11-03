# Answer Key — quiz-01 — coupling-and-cohesion

Created 2026-10-27, before learner answered. Do not show before submission.

**Scoring:** `[E]`=5, `[M]`=10, `[H]`=20. Max = 3×5 + 4×10 + 2×20 = **95**.
Partial = half. `score_pct = earned / 95`. Pass ≥ 70% → +20 XP bonus.

Style: design-judgement questions only (learner preference, 2026-10-27).

Traps aimed at active pitfalls:
- `encapsulation-as-getters-setters` → Q3
- `logic-outside-owning-object` → Q5, Q6
- `inheritance-for-reuse-not-polymorphism` → Q4, Q9

---

## Q1 [E] — UserService cohesion
- must_include: low cohesion: methods are grouped by the noun "user", not by one responsibility or reason to change. `generateMonthlySalesReport` clearly doesn't belong; `hashPassword`, `sendWelcomeEmail` and `resizeAvatar` are separate concerns. A sensible split names the classes, e.g. `UserRegistrationService` (keeps `registerUser`, orchestrates), `PasswordHasher`, `WelcomeEmailSender`/`EmailService`, `AvatarProcessor`/`ImageResizer`, `SalesReportGenerator`.
- disqualifiers: says the class is cohesive because "everything is about users".
- partial: spots the sales report but keeps everything else together with no reason given; or splits it without naming the criterion (reason to change / single responsibility).

## Q2 [E] — new vs injected repository
- must_include: (A), the version that calls `new MySqlOrderRepository()`, is more tightly coupled, because it is bound to a concrete class *and* its construction. Concrete pain: it can't be unit tested without a real MySQL (no fake/mock), and switching storage means editing `OrderService`. (B) depends on an abstraction and receives it from outside.
- disqualifiers: picks (B) as more coupled.
- partial: right choice with a vague reason ("B is more flexible") and no concrete pain point.

## Q3 [E] — Order exposes its list (TRAP: encapsulation-as-getters-setters)
- must_include: returning the mutable internal list couples every caller to `Order`'s internal representation, and lets callers break invariants (adding items after the order is PAID, skipping total recalculation or max-item limits). The field being private doesn't help. Fix: `addItem(...)` / `removeItem(...)` on `Order` with guards; the getter returns an unmodifiable view or copy (`List.copyOf` / `Collections.unmodifiableList`).
- disqualifiers: says it's fine because the field is private / there's a getter.
- partial: suggests only returning an unmodifiable list with no `addItem`/`removeItem` (callers can no longer do their job); or adds methods but leaves the mutable list exposed.

## Q4 [M] — int channel flag (TRAP: inheritance-for-reuse)
- must_include: control coupling: the caller passes a flag that steers the callee's internal flow, so the caller has to know the callee's internal branches and every new channel edits `send()` (and the magic ints). Redesign: a `Notifier` interface `send(User, Message)` with `EmailNotifier`, `SmsNotifier` and `PushNotifier`, chosen via polymorphism. The caller holds a `Notifier` (or a list of them / a map keyed by user preference).
- disqualifiers: just replaces the int with an enum and keeps the switch (that's still control coupling); or proposes an abstract `BaseNotifier` "to reuse code" without giving behavioural polymorphism as the reason.
- partial: names the problem correctly but the redesign is vague; or gives a good redesign without naming or explaining the coupling.

## Q5 [M] — InvoicePrinter feature envy (TRAP: logic-outside-owning-object)
- must_include: `InvoicePrinter` depends on `Invoice`, `LineItem`, `Customer`, `Address` and `State` (5 types). It only needs `Invoice`. Subtotal goes to `Invoice.subtotal()` (built on `LineItem.total()`); tax goes to `Invoice.tax()` (Invoice asks its customer/address for the rate, or a `TaxPolicy` is injected). After the refactor the printer calls `inv.subtotal()`, `inv.tax()` and `inv.total()`, so it depends on `Invoice` only. Should name feature envy / Law of Demeter / tell-don't-ask.
- disqualifiers: keeps the calculation in the printer and only extracts local variables / private helper methods inside the printer.
- partial: moves the subtotal but leaves the tax chain in the printer; or counts the dependencies right but the refactor is unclear.

## Q6 [M] — Over-split ShoppingCart (TRAP: logic-outside-owning-object)
- must_include: not an improvement. It splits data from behaviour (anemic model): four classes that each depend on the cart's internals through getters means *more* coupling and *lower* cohesion. A change to how items are stored now ripples into 4 classes, and the cart can't protect its own invariants. The rule: split by reason to change and keep data together with the behaviour that changes with it. A legitimately separate piece is e.g. discount rules that change independently (a `DiscountPolicy` the cart *uses*), not "everything the cart does".
- disqualifiers: says it's better because "each class has a single responsibility" / smaller classes.
- partial: says it's worse but explains only one of coupling or cohesion; or gives no rule for when splitting *is* right.

## Q7 [M] — Temporal coupling
- must_include: temporal coupling (sequential/protocol coupling): callers must know the hidden required call order. Failure mode: a forgotten or reordered call (`query` before `authenticate`) fails at runtime, possibly with a confusing error, and every caller duplicates the protocol. Redesign: make invalid states impossible to represent. E.g. a factory/constructor `Connection.open(host, credentials)` that returns a ready, authenticated connection, or a builder whose `build()` returns a usable object. At minimum, fail fast with a clear state check.
- disqualifiers: "just document the order".
- partial: only proposes runtime state checks inside each method (better than nothing, but the coupling is still there); or a good redesign without naming the problem.

## Q8 [H] — RideService fan-out
- must_include:
  1. Problem: high efferent coupling / fan-out. `RideService` changes for reasons unrelated to rides (loyalty, analytics, notification changes), so cohesion is low. A failure in a side effect (analytics down) can fail ride completion.
  2. Distinguish the core from side effects: payment (and probably the ride state change) must stay a direct, synchronous call whose outcome matters to completion. Notifications, analytics, loyalty and rating prompts are reactions, so publish a `RideCompleted` event (observer / event bus / domain events) and let them subscribe.
  3. Cost: indirection (harder to trace "what happens when a ride completes"), ordering not guaranteed, error handling and retries move to subscribers, eventual consistency, harder debugging.
- disqualifiers: puts payment behind fire-and-forget events with no consideration of failure; or says "inject all 6 as interfaces" is the whole fix (that reduces concrete coupling but not fan-out or the reasons to change).
- partial: two of the three sub-parts correct.

## Q9 [H] — BaseRepository (TRAP: inheritance-for-reuse)
- must_include:
  1. Inheritance is the tightest form of coupling: all 14 subclasses depend on the base's protected fields and implementation, and the base can't change without risking all of them. Here it's used for code reuse, not substitutability; nobody uses `BaseRepository` polymorphically.
  2. With the change requests: a different retry policy for `OrderRepository` alone means overriding/hacking around the base, or adding flags to it (control coupling). Swapping the logging library edits the base and recompiles/retests 14 classes.
  3. Redesign: composition. Inject collaborators (`RetryPolicy`, `Logger`, `ConnectionProvider`/`DataSource`) into each repository; `OrderRepository` gets a different `RetryPolicy` instance and nothing else changes.
  4. When a base class is acceptable: a small, stable, abstract base that defines a real substitutable contract or a template method with an invariant algorithm, without exposing mutable protected state.
- disqualifiers: fix = add a `boolean useCustomRetry` (or similar) to the base; or says inheritance is fine because "it avoids duplication".
- partial: right diagnosis and composition fix but no point 4; or says "use composition" with no concrete collaborators.
