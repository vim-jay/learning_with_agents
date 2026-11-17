# Vijaysurya Mandala

+91-9493111857 · mandalavijaysurya2@gmail.com · [linkedin.com/in/mandalavijaysurya](https://linkedin.com/in/mandalavijaysurya) · Hyderabad, India

---

## Professional Summary

Software Engineer with 4 years of experience in backend development and data integration. Builds reactive Java 21 and Spring WebFlux microservices, and owns end-to-end Postgres replication with Oracle GoldenGate for CQRS read models. Started out building DB2-to-Oracle data pipelines, with hands-on experience in Kafka, GitHub Actions, and a PCF-to-GCP migration using Terraform.

## Core Competencies

| Area | Skills |
|---|---|
| **Languages & Frameworks** | Java, Spring Boot, Spring WebFlux |
| **Architecture** | Microservices, CQRS |
| **Data** | PostgreSQL, Data Replication & CDC, Oracle GoldenGate, Kafka |
| **Cloud & DevOps** | GCP, Terraform |

---

## Work Experience

### Senior Software Engineer — Persistent Systems
*Sep 2025 – Present · Hyderabad, India*

- Owned end-to-end **Oracle GoldenGate replication** (Postgres-to-Postgres) powering the CQRS read model, delivering near real-time sync from setup through production rollout, and independently resolving **10+ replication issues** along the way.
- Built a **reactive Java 21 / Spring WebFlux read API** serving account transfer instructions to user-facing workflows, orchestrating **5 downstream services** and a complex multi-join view while keeping service-side **p95 ≤ 5 seconds**.
- Implemented **cursor-based pagination** across two **1M+ row** data stores queried in parallel, including a 25-join legacy view, with graceful degradation: if one store timed out, results from the other were still returned with an updated cursor instead of failing the request.
- Ported undocumented **mainframe business logic** to a Java microservice, using AI-assisted analysis to reconstruct **5 missing business rules** and resolve **30+ related defects**, including critical integration regressions, before launch.
- Designed the separation between transformation logic and the reactive stream layer, letting business rules be unit-tested independently of reactive infrastructure.
- Stabilized a flaky **GitHub Actions and PCF** deployment pipeline, restoring reliable releases for the team.
- Contributing to the ongoing **PCF-to-GCP migration**, working with Terraform and GitHub Actions to move services onto GCP infrastructure.

### Career Transition & Upskilling
*2022 – 2025*

- Scaler programme and **Master of Computer Science**, covering DSA, low- and high-level system design, and data engineering.

### Software Engineer — Cognizant
*Dec 2019 – Jul 2022 · Hyderabad, India*

- Developed **40+ SSIS (DTSX) packages** for daily batch pipelines loading data from DB2 into Oracle, rebuilding them for a platform upgrade and mapping stored procedure output to the Oracle schemas.
- Reverse-engineered and documented the stored procedure logic behind these pipelines, which became the team's reference for the data transformations.

---

## Projects

### The Leaky Cauldron — Scalable E-Commerce Platform
*Spring Boot · PostgreSQL · Elasticsearch · Kafka · Redis · Stripe · OAuth 2.0 · AWS*

- Designed the platform around **CQRS**, with writes going to Postgres and product search reads served from Elasticsearch, keeping search fast without loading the transactional database.
- Implemented the **Transactional Outbox pattern** with a Spring `@Scheduled` relay to sync the write and read stores reliably, avoiding the dual-write problem.
- Built **6 Spring Boot microservices** covering users, product catalogue and payments, with Stripe and OAuth 2.0 for secure checkout.
- Added an **event-driven notification service** on Kafka and **Redis caching** for frequently read product data, reducing load on the primary database; deployed on AWS Elastic Beanstalk.
