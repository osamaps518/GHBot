# Decisions

One place for every technical decision on GHbot and the reasoning behind it.
Each entry records what we chose, what else we considered, and what we accept as a trade-off.
When a decision changes, mark the old one as **Superseded** and add a new entry instead of editing history.

Status values: **Accepted**, **Provisional** (we'll revisit after a set point), **Deferred** (not decided yet, on purpose), **Superseded**.

---

## 1. Backend: Python + FastAPI

**Status:** Accepted, 2026-10-07

**Options considered:** Python/FastAPI, Go, Java/Spring Boot, C#/ASP.NET Core

**Why FastAPI**
- **Speed isn't the deciding factor at our scale.** In raw benchmarks ([TechEmpower](https://www.techempower.com/benchmarks/)), Go, ASP.NET Core and Java frameworks are faster than FastAPI. But our app spends its time waiting on the database and, later, on LLM calls, not on CPU work in our own code, so the language overhead is a few milliseconds per request. If we ever get slow, the fix will be queries and indexes, not the language.
- **The hardest future feature is AI and data work.** The evidence-based coach (retrieval, embeddings, the evaluation question set) and the food database (cleaning USDA and Open Food Facts data) are where Python has the strongest libraries.


## 2. Architecture: modular monolith

**Status:** Accepted, 2026-10-07

One FastAPI application, split into modules by domain (`profiles`, `nutrition`, `training`, later `coach` and `referrals`). Each module owns its routes, models and logic, and modules talk through plain function calls.

**Why not microservices:** microservices mainly let many teams deploy independently, at the cost of networking, deployment and data-consistency problems. We are two people. If a module ever needs to become its own service, clean module boundaries make that possible later.

**Exception, when the time comes:** background jobs, such as ingesting research papers into the knowledge base, can run as a separate script or worker in the same repo, sharing the same code and database.

---

## 3. Frontend: Flutter, mobile first

**Status:** Provisional, 2026-10-07. Revisit after the onboarding screen is built (see `plans/setup.md`).

**Options considered:** Flutter, React Native (Expo), mobile-first React web app

**Why mobile first**
- People log meals and workouts every day, often at the gym. That favours a real app: on the home screen, with reliable notifications, and later camera and barcode scanning.
- The beta testers will use phones, so we'd rather hit mobile-specific problems early than in month 4.
- The backend is the same whichever frontend we pick, so this choice only affects the UI layer.

**Why Flutter over React Native**
- **Arabic / right-to-left support is built in.** 
- **It comes with a full widget set** (Material and Cupertino). Neither of us cares much about UI work, so not having to choose and assemble a component library is a real advantage.
- "TypeScript across the whole stack" doesn't apply to us, because the backend is Python either way.

**What we accept**
- Neither of us has used Dart or Flutter, so the first weeks are slower.
- If we add a web frontend later, it will be a separate codebase. 

**What might come next**
- **A web frontend in React (TypeScript)** for gym owners (referrals, subscribers, earnings) and, later, trainers. These people use a laptop, and React is stronger for web than Flutter web. It would talk to the same FastAPI backend.

---

## 4. Database: PostgreSQL

**Status:** Accepted, 2026-10-07 (hosting provider deferred, see #6)

- Our data is relational (users → profiles, meals, workouts → sets) and benefits from constraints and transactions.
- Every host supports it, so it doesn't lock us in.
- The `pgvector` extension can store embeddings for the future coach, so we may not need a separate vector database.

Locally it runs in Docker. Schema changes go through migrations (see `plans/setup.md`), never manual edits.

---

## 5. Authentication: real auth from day one, behind one interface

**Status:** Accepted (approach), 2026-10-07. Provider: Deferred.
**How**
- Every route gets the user from a single FastAPI dependency, `get_current_user`, which verifies a token through an `AuthProvider` interface. Routes never know which provider is in use.
- We keep our **own `users` table with our own ID**. The provider's user ID is stored in a separate `auth_subject` column. All other tables reference our ID, so switching providers means updating one column, not migrating every table.
- We won't write our own password or session handling. In production a provider handles that (candidates: Supabase Auth, Firebase Auth, Clerk, Auth0).

---

## 6. Hosting and deployment

**Status:** Deferred, 2026-10-07

We decide once the first main feature works end to end, then deploy it right away instead of waiting for "done". 

Candidates to compare when the time comes: Supabase, Neon, Railway, Render, Fly.io, or a cheap VPS running Docker Compose. Criteria: monthly cost at beta scale, whether free tiers pause or sleep, backups, and how hard it is to move away.

---

## 7. AI coach / LLM

**Status:** Deferred, 2026-10-07

Not needed for the first version (basic CRUD). We decide when we build the coach. Current direction to revisit then: retrieval over a vetted research library, a model-agnostic wrapper so providers can be swapped, and choosing the model by running our own evaluation question set against candidates.
