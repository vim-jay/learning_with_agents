# Quiz 01 — Coupling & Cohesion

**Topic:** `coupling-and-cohesion` · **Questions:** 9 · **Pass:** 70%
**Difficulty:** `[E]` easy · `[M]` medium · `[H]` hard

Rules
- Write your answer under each `> **Your answer:**` marker.
- These are design questions: your **reasoning and redesign** are graded, not keywords.
- When a question asks for a redesign, class names + method signatures are enough.
- When done, say **"grade my quiz"**.

---

### Q1 `[E]` — Rate the cohesion

```java
class UserService {
    User registerUser(SignupRequest req) { ... }
    String hashPassword(String raw) { ... }
    void sendWelcomeEmail(User u) { ... }
    byte[] resizeAvatar(byte[] image, int w, int h) { ... }
    Report generateMonthlySalesReport(YearMonth m) { ... }
}
```

Is this class cohesive? Split it, name the resulting classes, and state the criterion
you used to decide what goes together.

> **Your answer:**

---

### Q2 `[E]` — Which is more coupled?

```java
// (A)
class OrderService {
    private final MySqlOrderRepository repo = new MySqlOrderRepository();
}

// (B)
class OrderService {
    private final OrderRepository repo;
    OrderService(OrderRepository repo) { this.repo = repo; }
}
```

Which one is more tightly coupled? Name **two concrete pains** it causes in real work.

> **Your answer:**

---

### Q3 `[E]` — Hidden coupling

```java
class Order {
    private List<LineItem> items = new ArrayList<>();
    private Status status;
    public List<LineItem> getItems() { return items; }
}

// in 6 different services:
order.getItems().add(new LineItem(sku, qty, price));
order.getItems().removeIf(i -> i.qty() == 0);
```

The field is private. How does this design still couple callers to `Order`, and what can
go wrong? Show the corrected API.

> **Your answer:**

---

### Q4 `[M]` — Spot the coupling

```java
class NotificationSender {
    // channel: 1 = email, 2 = sms, 3 = push
    void send(User u, String msg, int channel) {
        switch (channel) {
            case 1 -> { /* SMTP stuff */ }
            case 2 -> { /* Twilio stuff */ }
            case 3 -> { /* FCM stuff */ }
        }
    }
}

// caller
sender.send(user, "Your OTP is 4821", 2);
```

What kind of coupling is this, and why does it hurt? Redesign it (types + signatures).
What happens in your design when WhatsApp is added?

> **Your answer:**

---

### Q5 `[M]` — Count the dependencies

```java
class InvoicePrinter {
    String print(Invoice inv) {
        double subtotal = 0;
        for (LineItem li : inv.getItems())
            subtotal += li.getPrice() * li.getQty();
        double tax = subtotal * inv.getCustomer().getAddress().getState().getTaxRate();
        return format(inv.getId(), subtotal, tax, subtotal + tax);
    }
}
```

1. How many types does `InvoicePrinter` depend on? How many does it *need*?
2. Name the smell.
3. Move the logic: show which method lands in which class, and what `print()` looks like after.

> **Your answer:**

---

### Q6 `[M]` — "We decoupled it"

A teammate "improves" a `ShoppingCart` by splitting it into:

```java
class ShoppingCart        { List<Item> getItems(); void setItems(List<Item> i); /* data only */ }
class CartTotalCalculator { Money total(ShoppingCart c); }
class CartDiscountApplier { void apply(ShoppingCart c, Coupon k); }
class CartValidator       { boolean isValid(ShoppingCart c); }
```

They say: "Each class now has a single responsibility, so it's more cohesive and less
coupled." Do you agree? Back it up, and state when splitting a class *is* the right call.

> **Your answer:**

---

### Q7 `[M]` — The protocol

```java
Connection c = new Connection();
c.setHost("db.internal");
c.init();
c.authenticate(user, pass);
ResultSet r = c.query("SELECT ...");
```

This code appears in ~20 places. What coupling exists between callers and `Connection`?
What fails, and how? Redesign so callers *can't* get it wrong.

> **Your answer:**

---

### Q8 `[H]` — Design critique

```java
class RideService {
    private final PaymentService payments;
    private final DriverService drivers;
    private final NotificationService notifications;
    private final AnalyticsService analytics;
    private final LoyaltyService loyalty;
    private final ReceiptService receipts;

    void completeRide(Ride ride) {
        ride.markCompleted();
        payments.charge(ride.rider(), ride.fare());
        drivers.promptForRating(ride);
        notifications.sendRideSummary(ride);
        analytics.track("ride_completed", ride);
        loyalty.addPoints(ride.rider(), ride.fare());
        receipts.email(ride);
    }
}
```

Every new feature adds one more dependency and one more line here. Last week, analytics
being down caused rides to fail to complete.

1. Name the problem in coupling/cohesion terms.
2. Redesign. Which calls should stay direct, and which shouldn't? Why?
3. What does your redesign cost? Be specific.

> **Your answer:**

---

### Q9 `[H]` — The base class everyone extends

```java
abstract class BaseRepository {
    protected Connection conn;
    protected Logger log = LoggerFactory.getLogger(getClass());
    protected <T> T withRetry(Supplier<T> op) { /* 3 attempts, 100ms backoff */ }
    protected void audit(String action) { /* writes audit row */ }
}

class UserRepository  extends BaseRepository { ... }
class OrderRepository extends BaseRepository { ... }
// ... 14 repositories in total
```

Two requests arrive:
- (a) `OrderRepository` needs 5 retries with exponential backoff; everyone else stays the same.
- (b) The company switches logging libraries.

1. What coupling does this hierarchy create, and how do (a) and (b) expose it?
2. Redesign so both requests touch as little code as possible. Show the types.
3. When *would* a shared base class be acceptable here?

> **Your answer:**
