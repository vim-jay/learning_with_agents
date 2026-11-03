# Result — quiz-01 — object-oriented-basics

**Graded:** 2026-10-27 · **Score:** 32.5 / 105 = **31%** · **Verdict:** FAIL (pass = 70%)
**XP:** 32 (no pass bonus)

| Q | Diff | Verdict | Points |
|---|---|---|---|
| Q1 | E | Partial | 2.5 / 5 |
| Q2 | E | Full | 5 / 5 |
| Q3 | E | Zero (blank) | 0 / 5 |
| Q4 | H | Zero (blank) | 0 / 20 |
| Q5 | M | Full | 10 / 10 |
| Q6 | H | Zero (blank) | 0 / 20 |
| Q7 | M | Zero | 0 / 10 |
| Q8 | M | Partial | 5 / 10 |
| Q9 | M | Full | 10 / 10 |
| Q10 | M | Zero | 0 / 10 |

---

## Q1: Partial
(b) is correct, but your reasoning says encapsulation means private fields accessed through getters and setters. That is the misconception this question was testing. A public `setBalance` gives no protection at all, which is why (a) and (d) are wrong: they describe mechanisms, not the guarantee. (c) describes abstraction (programming to an interface). You didn't explain why any of the other options fall short.

## Q2: Full
You chose an interface because the method is a capability, not shared state, which is correct. The sharper deciding reason is that all three classes **already extend a base class** and Java allows only one superclass, so an abstract class isn't even possible here.

## Q3: Zero (blank)
Expected: the public setter lets any caller set any value (negative or arbitrary), so the private field protects nothing. The fix is to replace it with domain operations:
```java
public void deposit(double amt) { if (amt <= 0) throw new IllegalArgumentException(); balance += amt; }
public void withdraw(double amt) { if (amt <= 0 || amt > balance) throw new IllegalArgumentException(); balance -= amt; }
```

## Q4: Zero (blank)
Expected: prints `Fraud-Payment`. Java makes two separate decisions:
1. **Overload, chosen at compile time** from the declared type of the argument (`Payment`), so it picks `process(Payment)`.
2. **Override, chosen at runtime** from the actual type of the receiver (`FraudCheckingProcessor`), so it runs `FraudCheckingProcessor.process(Payment)`.

## Q5: Full
`base derived` is correct, with the right reasoning: field access uses the declared type (fields are hidden, not overridden), and the method call uses the runtime object. One thing to add: inside `Derived.getName()`, `name` refers to `Derived.name`.

## Q6: Zero (blank)
Expected:
1. It prints `6`. `HashSet.addAll` (inherited from `AbstractCollection`) calls `add()` for each element, and that is your overridden `add`, so each element is counted twice.
2. The design problem is the **fragile base class** problem: the subclass depends on how its superclass calls its own methods internally, so inheritance breaks encapsulation.
3. Redesign with **composition plus forwarding**: `class CountingSet<E> implements Set<E> { private final Set<E> inner; ... }`. Count in your own methods and delegate the rest to `inner`.

## Q7: Zero
"Inheritance + A / ResuaCode adheres to OCP" is unfinished, and it names the wrong pillar. What removes the switch is **polymorphism** (runtime dispatch). Inheritance is only the mechanism that enables it, and "reusing code" is not the benefit here. Expected sketch:
```java
abstract class Vehicle { abstract SpotSize requiredSpot(); abstract Money hourlyRate(); }
class Bike extends Vehicle {...}  class Car extends Vehicle {...}  class Truck extends Vehicle {...}
```
Adding ELECTRIC_CAR then means **one new class and no edits to the three services**, so there is no switch left that someone can forget to update.

## Q8: Partial
You correctly said it's overkill and proposed a single `Address` with a country value. Two problems:
- Saying "`country()` is a capability, use an interface" is wrong. It's a constant, so it belongs in data (a field or enum, ideally a `record` for a DTO), not in an interface.
- The general rule is missing: **subclass only when behaviour varies, not data** (and only when the subclass is truly substitutable).

## Q9: Full
You identified the LSP violation and restructured with a withdraw capability interface (`Withdrawable`), which is correct. ("should be method of Account" reads as a typo for "shouldn't".) To make it complete, also say the concrete failure: the monthly job, written against `Account`, crashes at runtime. After the fix, that job iterates only `Withdrawable` accounts.

## Q10: Zero
"Redundancy" is not the smell, and your rewrite still reads the balance and calls `setBalance` from outside `Wallet`. That matches the key's disqualifier: the logic hasn't moved. Also, `cart.getWallet()` doesn't exist in the original code.
- Smells: **feature envy / tell-don't-ask violation**, a **train wreck** (Law of Demeter), and Wallet's encapsulation broken by `setBalance`.
- Expected rewrite:
```java
class Wallet { boolean tryDebit(Money amt) { if (amt.gt(balance)) return false; balance = balance.minus(amt); return true; } }
class Cart   { void checkout(Wallet w) { if (!w.tryDebit(total())) throw new InsufficientFundsException(); status = Status.PAID; } }
// CheckoutService
cart.checkout(user.wallet());
```

---

## Pitfalls hit
- `encapsulation-as-getters-setters` (Q1, Q10)
- `logic-outside-owning-object` (Q10)
- `inheritance-for-reuse-not-polymorphism` (Q7)

## Next step
Retake with quiz-02 on object-oriented-basics, aimed at these three pitfalls. Before that, write Q3, Q4 and Q6 out yourself in an IDE without looking at this file, then run them.
