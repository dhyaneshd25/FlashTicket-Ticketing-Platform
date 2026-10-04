# FlashTicket

High-Throughput Event Ticketing & Flash Sale Platform — a **modular monolith**
built with Java 17, Spring Boot 3, Redis (Redisson), Apache Kafka, PostgreSQL,
and a server-rendered **JSP** frontend.

See `flashticket-architecture.md` (shared earlier) for the full design
rationale. This README covers getting the code running on your machine.

---

## 1. Prerequisites

Install these before anything else:

| Tool | Version | Check with |
|---|---|---|
| Java (JDK) | 17 or newer | `java -version` |
| Maven | 3.9+ | `mvn -version` |
| Docker + Docker Compose | recent | `docker --version` / `docker compose version` |

You do **not** need to install Postgres, Redis, or Kafka locally — Docker
Compose runs all three for you.

---

## 2. Project layout

```
flashticket/
├── pom.xml                          # Maven build (WAR packaging — needed for JSP)
├── docker-compose.yml                # Postgres + Redis + Kafka + Zookeeper + Kafka UI
├── src/main/java/com/flashticket/
│   ├── FlashTicketApplication.java
│   ├── config/                      # Redis, Kafka topics, Security, MVC/JSP wiring
│   ├── common/                      # Base entity, exception handling
│   ├── inventory/                   # Redis-backed flash-sale reservation engine
│   ├── order/                       # Order lifecycle + Transactional Outbox
│   ├── payment/                     # Payment gateway stub + circuit breaker
│   ├── notification/                # Notification stub
│   ├── ratelimit/                   # Redis Lua sliding-window rate limiter
│   ├── idempotency/                 # Redis-backed idempotent consumer guard
│   └── web/                         # MVC controllers that render the JSP pages
├── src/main/resources/
│   ├── application.yml
│   ├── scripts/sliding_window_rate_limiter.lua
│   ├── db/seed.sql                  # sample event to buy tickets against
│   └── static/{css,js}
└── src/main/webapp/WEB-INF/jsp/     # JSP frontend views
```

---

## 3. First-time setup

**Step 1 — Start the infrastructure (Postgres, Redis, Kafka):**

You can start the services either via the local Windows scripts or via Docker:

*Option A — Local Windows (Recommended, zero virtualization overhead):*
```cmd
start-dev-environment.bat
```
*(To stop services later, run `stop-dev-environment.bat`)*

*Option B — Docker Compose (Requires Intel VT-x enabled in BIOS and WSL2):*
```bash
cd flashticket
docker compose up -d
```
All services should show `healthy` or `running`.

**Step 2 — Install dependencies and build:**

```bash
mvn clean install
```

This downloads all dependencies (Spring Boot, Redisson, spring-kafka,
Resilience4j, JSTL, etc.) and compiles the project into `target/flashticket.war`.

**Step 3 — Run the application:**

```bash
mvn spring-boot:run
```

The app starts on **http://localhost:8080**. On first boot, Hibernate
(`ddl-auto: update`) creates the tables automatically — you don't need to run
any migration tool.

**Step 4 — Seed a sample show to buy tickets against:**

Run the helper script:
```cmd
seed-show.bat
```
Or via Docker:
```bash
docker exec -i flashticket-postgres psql -U flashticket -d flashticket < src/main/resources/db/seed.sql
```

(Or run that SQL file with any Postgres client pointed at
`postgresql://flashticket:flashticket@localhost:5432/flashticket`.)

**Step 5 — Restart the app** so the new show gets seeded into Redis's
availability counter:

```bash
# Ctrl+C the running process, then:
mvn spring-boot:run
```

**Step 6 — Open the frontend:**

Visit **http://localhost:8080/** — you should see the seeded show listed.
Click "View & Buy" to open the seat-purchase page and click **Buy Now**. This:

1. Calls `POST /api/orders` (rate-limited, gated by a Redis atomic decrement).
2. Redirects to `/orders/{id}/status`, which polls `GET /api/orders/{id}`
   every second until the async Kafka pipeline (Order → Outbox relay →
   Inventory/Payment consumers) marks it `CONFIRMED`.

---

## 4. Useful URLs while running

| URL | What it is |
|---|---|
| http://localhost:8080/ | JSP frontend — show listing |
| http://localhost:8080/api/shows | REST: list shows (JSON) |
| http://localhost:8080/actuator/health | Health check |
| http://localhost:8080/actuator/prometheus | Metrics (Prometheus format) |
| http://localhost:8081 | Kafka UI — inspect `orders.v1` / `payments.v1` / `notifications.v1` topics |

---

## 5. Running the test suite

```bash
mvn test
```

Integration tests use **Testcontainers**, which will spin up throwaway
Postgres/Kafka containers automatically (Docker must be running for these to
pass — no need to have `docker compose up` running separately for tests).

---

## 6. Common issues

- **Docker Desktop fails to start ("Virtual Machine Platform not enabled" / WSL error):**
  Docker on Windows requires hardware virtualization (Intel VT-x / AMD-V) to be
  enabled in your computer's BIOS/UEFI settings. If hardware virtualization is disabled,
  use the provided `start-dev-environment.bat` script to run Postgres, Redis, and Kafka
  natively on Windows without needing Docker or a virtual machine.
- **JSPs return 404 or don't reflect changes:** JSP compilation happens via
  the embedded Jasper compiler at request time when
  `server.servlet.jsp.init-parameters.development=true` (already set in
  `application.yml`), so edits under `src/main/webapp` should appear on
  refresh without a restart when running via `mvn spring-boot:run`.
- **`mvn spring-boot:run` complains about missing Tomcat/Jasper classes:**
  make sure you didn't change the `packaging` in `pom.xml` away from `war` —
  JSP support depends on it.
- **Orders stay `PENDING_PAYMENT` forever:** check `docker compose logs kafka`
  and confirm the app logs show `OutboxRelayPublisher` dispatching events; if
  Kafka isn't reachable, the Outbox rows will sit as `PENDING`/`FAILED` and
  retry automatically once Kafka is back up.

---

## 7. What's stubbed vs. production-ready

This is a working scaffold, not a finished product. Treat these as the next
things to build out:

- **Auth:** JWT validation isn't wired into a real login flow yet — the
  frontend uses a demo `userId` stored in `localStorage`. Add a real
  `/api/auth/login` issuing JWTs, and read the user from
  `SecurityContextHolder` in `OrderController` instead of trusting the
  request body.
- **Payment gateway:** `PaymentService.chargeCustomer()` is a stub that
  always succeeds. Swap in a real client (Stripe, Razorpay, etc.).
- **Outbox relay:** currently a polling publisher (`@Scheduled` every
  500ms). For higher volume, replace with **Debezium** via Kafka Connect
  reading Postgres's WAL, as described in the architecture doc.
- **Seat-level selection:** `InventoryService.reserveSpecificSeat()` exists
  for assigned-seating shows but isn't wired into the frontend yet — the
  current UI only does "any N seats" via the atomic counter path.
