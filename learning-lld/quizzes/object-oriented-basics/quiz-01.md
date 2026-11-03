# Quiz 01 — OOP Basics

**Topic:** `object-oriented-basics` · **Questions:** 10 · **Pass:** 70%
**Difficulty:** `[E]` easy · `[M]` medium · `[H]` hard

Rules
- Write your answer under each `> **Your answer:**` marker (use as many lines as you need).
- Where a question asks **why**, the reasoning is graded, not just the choice.
- For "what does this print" questions: answer **without running the code**. Predicting
  dispatch is the skill being tested.
- When done, say **"grade my quiz"**.

---

### Q1 `[E]` — Concept MCQ

Which statement best describes **encapsulation**? Pick one and explain **why** the
other options fall short.

- (a) Every field is `private`.
- (b) An object controls how its state can change, so its invariants can't be broken from outside.
- (c) Callers depend on an interface instead of a concrete class.
- (d) Every field has a getter and a setter.

> **Your answer:** Option B: Thats the core of encapsulation, with private fields and accessing them using getters and setters object will have full control over its state. Every other option doesn't or completely doesn't explain about encapsulation

---

### Q2 `[E]` — Abstract class or interface?

`Order`, `User`, and `Invoice` are unrelated classes (each already extends a different
base class). All three must support `String toAuditLog()`.

Should `Auditable` be an **abstract class** or an **interface**? Give the deciding reason.

> **Your answer:** Abstract class will have shared state and partial implementation; Interface is capability contract. Providing each class with `String toAuditLog()`, is just providing capability to each class, to audit. So interface is correct

---

### Q3 `[E]` — Spot the violation

```java
public class Wallet {
    private double balance;

    public double getBalance() { return balance; }
    public void setBalance(double balance) { this.balance = balance; }
}
```

The field is private. What is still wrong with this design? Show the corrected API
(signatures + the key guard logic are enough).

> **Your answer:** It doesn't violates anything

--- 

### Q4 `[H]` — Predict the output

```java
class Payment {}
class CardPayment extends Payment {}

class Processor {
    void process(Payment p)     { System.out.println("Processor-Payment"); }
    void process(CardPayment p) { System.out.println("Processor-Card"); }
}

class FraudCheckingProcessor extends Processor {
    @Override void process(Payment p)     { System.out.println("Fraud-Payment"); }
    @Override void process(CardPayment p) { System.out.println("Fraud-Card"); }
}

Processor proc = new FraudCheckingProcessor();
Payment pay = new CardPayment();
proc.process(pay);
```

What is printed? Explain **both** decisions the JVM/compiler makes to arrive there.

> **Your answer:** 
> 1. `Fraud-Payment`
> 2. `process()` from `FraudCheckingProcessor` will be called because application resolves this a runtime; Deciding between `process(Payment p)` vs `process(CardPayment p)` will happen compile time: Thats the core of polymorphism

---

### Q5 `[M]` — Predict the output

```java
class Base {
    String name = "base";
    String getName() { return name; }
}

class Derived extends Base {
    String name = "derived";
    @Override String getName() { return name; }
}

Base b = new Derived();
System.out.println(b.name + " " + b.getName());
```

What is printed, and why?

> **Your answer:** `base derived` - variables will be fetched based variable type but methods will be tied with object. Though b is of type `Base` it contains object of `Derived`, method of `Derived` is being invoked

---

### Q6 `[H]` — Critique this design

A teammate wants a set that counts how many elements were ever added to it:

```java
class CountingSet<E> extends HashSet<E> {
    int addCount = 0;

    @Override public boolean add(E e) {
        addCount++;
        return super.add(e);
    }

    @Override public boolean addAll(Collection<? extends E> c) {
        addCount += c.size();
        return super.addAll(c);
    }
}

CountingSet<String> s = new CountingSet<>();
s.addAll(List.of("a", "b", "c"));
System.out.println(s.addCount);
```

1. What does it print, and why?
2. What is the underlying design problem (name it)?
3. How would you redesign it so it's robust regardless of how `HashSet` is implemented?

> **Your answer:**

---

### Q7 `[M]` — Which concept fits?

In a parking-lot system, this pattern appears in `ParkingService`, `FeeCalculator`, and
`SpotAllocator`:

```java
switch (vehicle.getType()) {
    case "BIKE":  /* ... */ break;
    case "CAR":   /* ... */ break;
    case "TRUCK": /* ... */ break;
}
```

1. Which OOP pillar removes this, and how? Sketch the types (signatures only).
2. What concretely improves when the business adds `ELECTRIC_CAR`?

> **Your answer:**
>1. Polymorphism
>2. No much of code change required; Design resolves it at runtime

---

### Q8 `[M]` — When is it overkill?

A teammate replaces a simple address DTO with this:

```java
abstract class Address {
    private String line1, city, zip;
    // getters + setters for each field
    abstract String country();
}
class IndianAddress extends Address { String country() { return "IN"; } }
class USAddress     extends Address { String country() { return "US"; } }
class UKAddress     extends Address { String country() { return "UK"; } }
// ... one subclass per country
```

The subclasses contain nothing else. The object is only used to carry data between the
API layer and the database. Is this hierarchy justified? What would you use instead, and
what is the general rule for when a subclass is warranted?

> **Your answer:** `country()` was just capability; Creating each type of each country is over kill. If application has to store ~170 countries, ~170 classes should have been created. Rather I would incline with creating an single `Address` which is composed with `Country` with String: String can be easily created: Data is data which can be anything

---

### Q9 `[M]` — Spot the violation

```java
class Account {
    protected double balance;
    void deposit(double amt)  { /* ... */ }
    void withdraw(double amt) { /* ... */ }
}

class FixedDepositAccount extends Account {
    @Override void withdraw(double amt) {
        throw new UnsupportedOperationException("FD is locked until maturity");
    }
}

// elsewhere, a monthly job:
for (Account a : allAccounts) {
    a.withdraw(MAINTENANCE_FEE);
}
```

What is wrong with the hierarchy (not just "it throws")? How would you restructure it?

> **Your answer:** `withdraw()` should be method of `Account` 'cause, `FixedDepositAccount` doesn't support it. Moreover, it fails LSP. Rather we have to extract this method into a interface(`Iwithdrawable`) and make which ever subclass of Accounts would need it

---

### Q10 `[M]` — Refactor

```java
// in CheckoutService
if (cart.getTotal() <= cart.getUser().getWallet().getBalance()) {
    cart.getUser().getWallet().setBalance(
        cart.getUser().getWallet().getBalance() - cart.getTotal());
    cart.setStatus("PAID");
}
```

1. Name the smell(s).
2. Rewrite it so behaviour lives with the data it uses. Show where each piece of logic
   moves to.

> **Your answer:** Redundancy usage: `cart.getUser().getWallet()` is being used multiple times

```java
var wallet = cart.getWallet();

if (cart.getTotal() <= wallet.getBalance()) {
    wallet.setBalance(
        wallet.getBalance() - cart.getTotal());
    cart.setStatus("PAID");
}
```