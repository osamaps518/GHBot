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

**Status:** Superseded, 2026-11-18 by 26 for the `nutrition` module: the backend has `foods` and, later, `food_log`; other choices remain accepted.

One FastAPI application, split into modules by domain (`profiles`, `nutrition`, `training`, later `coach` and `referrals`). Each module owns its routes, models and logic, and modules talk through plain function calls.

**Why not microservices:** microservices mainly let many teams deploy independently, at the cost of networking, deployment and data-consistency problems. We are two people. If a module ever needs to become its own service, clean module boundaries make that possible later.

**Exception, when the time comes:** background jobs, such as ingesting research papers into the knowledge base, can run as a separate script or worker in the same repo, sharing the same code and database.

---

## 3. Frontend: Flutter, mobile first

**Status:** Provisional, 2026-10-07. Revisit after the onboarding screen is built (see #12).

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

Locally it runs in Docker. Schema changes go through migrations, never manual edits.

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

---

## 8. Backend tools and database rules

**Status:** Accepted, 2026-10-19 (#5)

**Tools**
- **uv** for dependencies, with the lockfile committed. Poetry was considered.
- **SQLAlchemy 2** for database access and **Alembic** for migrations. **Psycopg 3** is the Postgres driver; asyncpg was the alternative, but Psycopg also works without async (handy for scripts).
- **pydantic-settings** reads config from environment variables or `backend/.env`.
- **Ruff** for lint and formatting, **mypy** (strict) for types, **pytest** with coverage.
- Python 3.14 and PostgreSQL 18, the same versions locally and in CI.

**Async database access**, chosen over plain (sync) SQLAlchemy, so a request waiting on the database doesn't hold up a thread. The trade-off: async SQLAlchemy can't load related data behind the scenes, so queries must load what they need explicitly. For the same reason, sessions keep their objects' fields after a commit instead of expiring them: an expired field would be loaded again when read, implicit I/O during ordinary attribute access that an async session must avoid.

**Rules**
- One database session per request. It never commits by itself: code that writes data commits explicitly.
- Migrations run on purpose (`alembic upgrade head`), never when the app starts.
- `/health` only says the API process is running. It doesn't check the database.
- The engine hides bound parameters in errors and logs, because profile values
  include health data. Before adding a CHECK or NOT NULL constraint on health
  data, handle `DBAPIError` by logging only the error type and SQL: PostgreSQL
  can put a rejected row's values in its own error message.

---

## 9. Development sign-in

**Status:** Accepted, 2026-10-20 (#6)

Use **PyJWT** to issue and verify HS256 tokens with `sub`, `iat` and a 15-minute
`exp`, signed with `DEV_JWT_SECRET`. This exercises token verification locally
while the production provider remains deferred (see #5).

`ENVIRONMENT` is required, with no default. Until a real provider exists, the app
refuses to start unless it is `development`; only then is `/dev/token` mounted.

A user's row in our `users` table is created on their first request. Our IDs
are UUIDv7; future tables reference these IDs.

---

## 10. Module layout

**Status:** Accepted, 2026-10-21 (#6). Extended by 19 for the files inside a backend module. Amended 2026-11-22 (#82): the docstring lists each route.

Each module's `__init__.py` is its public API: it re-exports what other code may
use, lists it in `__all__`, and says in its docstring what each name is for. The
`router` entry lists each route on its own line: method, path and what it does,
so a reader sees every route without opening `router.py`. Other modules and
`main.py` import only from the package (`from ghbot.auth import CurrentUser`),
never from its files. Inside a module, files import each other directly.

A module's routes live in `router.py`.

---

## 11. Mobile app setup

**Status:** Superseded, 2026-10-24 by #12 for the language rule; other setup choices remain accepted.

- **Android only.** Neither of us has a Mac. iOS can be added later with `flutter create --platforms=ios .`.
- **Flutter 3.47.7, pinned without a version manager.** The same version is in `pubspec.yaml`, CI and `mobile/README.md`.
- **Translations with Flutter's built-in `gen-l10n`.** Arabic (`app_ar.arb`) is the template, English sits alongside. No user-facing text in Dart code.
- **Language rule:** English if the phone is in English, Arabic otherwise. Arabic is first in `supportedLocales`, and Flutter's default resolution falls back to the first entry. No in-app switch yet (question 9 in #8).
- **Backend address from `mobile/config.json`,** passed with `--dart-define-from-file` and not committed, like `backend/.env`. The app refuses to start without it instead of guessing a default.
- **Plain HTTP only in debug and profile builds.** Release startup checks that the configured
  backend address begins with `https://` and has a host. Dart's HTTP client does
  not use Android's cleartext manifest setting, so the check lives in Dart.

---

## 12. Mobile language selection

**Status:** Accepted, 2026-10-24 (#7)

Use the phone's ordered language preferences to select the first supported language, Arabic or English. If none matches or the list is empty, use English. Keep Flutter's default locale resolution with English first in `supportedLocales`; no custom callback is needed. Arabic stays the ARB template, which does not set the runtime fallback. This stays the default once a trainee can change the language in the app's settings (#28).

The earlier Arabic fallback was considered, but it would show Arabic when the phone prefers an unsupported language. The trade-off is that these phones now show English.

---

## 13. User profile storage

**Status:** Superseded, 2026-10-26 by 14 for the age limit; other choices remain accepted.

Store each user's onboarding profile in a separate `profiles` table keyed by their
user ID. A missing row means onboarding has not been completed.

The API and database use English text codes for sex, activity level, and goal;
the app translates their labels. Height and weight are stored in metric units as
double-precision floats, with no fixed decimal rounding. Birth month and year
are stored instead of a full date of birth to avoid collecting the day.

Age is checked only when saving, using the last day of the birth month as the
youngest possible birthday and the server's UTC date. Saved profiles remain
readable after the user turns 81. Checks that need more than the request body
(today's date, the database) return the same 422 shape as the request model,
with their own `type` code.

Reads use a response model without save ranges. Narrowing a range later does
not strand previously saved rows: the app can show them and flags an invalid
value when the user edits. Removing or renaming a stored text code requires a
migration mapping old codes to new ones, because the app cannot parse a code
it does not know.

We considered putting profile fields on `users`, but that is the auth module's
identity table. Native Postgres enums would need a hand-written migration for
each new code, and fixed-decimal storage would round numbers from the app. A
full birth date would collect an unnecessary day; setting the day to 1 would
make it look like a real birthday. The youngest-possible age rule can reject
someone who is already 18 until the last day of their birth month.

---

## 14. Profile age limit

**Status:** Accepted, 2026-10-26 (#32)

`PUT /me/profile` accepts ages 18–100. The upper limit only catches typos such as
a birth year of 1900. Ahmad's range is 13–100; ages 13–17 wait for teen mode (#22).

---

## 15. Daily targets

**Status:** Accepted, 2026-10-26 (#10)

Calculate targets from the saved profile on each request, without storing them,
because age changes over time. Use exact decimal arithmetic with half-up
rounding. Calculate carbohydrates from the rounded protein and fat grams. The
agreed formulas and worked examples are in [#8](https://github.com/osamaps518/GHBot/issues/8).

---

## 16. App look

**Status:** Accepted, 2026-10-31 (#40). Amended 2026-11-24 (#59): dark mode's orange and error colors.

The app uses option D4, charcoal and tangerine, in light and dark, following the
phone's setting. Screens take colors and text styles from the theme instead of
hardcoding them.

Dark mode uses a deeper orange, #D9661A, and the error color #FFB4AB with
charcoal on it, as chosen in the #51 mockups. Light mode keeps tangerine
(#FF7A1A) and #B3261E.

The font is Rubik, which covers Arabic and English and has Western digits. It is
included in the app, so text looks the same without a connection. Flutter's
font weights don't drive a variable font, so the app includes three static
weights (400, 500, 600) cut from Rubik's official variable font.

We compared a [first round of looks](https://claude.ai/artifact/UGWE7vaMuokCjzQ5SWtoVk),
then [option D in four palettes](https://claude.ai/artifact/TwvW9yF1VGMXTpqwUvvhNZ):
plum and coral, forest and lime, cobalt and sky, charcoal and tangerine. We chose D4.
The `google_fonts` package was skipped because it downloads fonts at runtime by
default. 

---

## 17. Mobile dev sign-in

**Status:** Superseded, 2026-11-18 by 25 for the new token at every start; other choices remain accepted.

Until a real sign-in provider exists, the app asks for a name and uses it as the
token subject for `POST /dev/token`. It stores the name with `shared_preferences`,
not the token, because tokens last 15 minutes. It gets a new token at every start,
and on a 401 it gets a new one and retries the call once. Typing the same name
after a reinstall gets you back to the same user. There is no sign-out.

The auth session in `mobile/lib/auth/` owns the token and authorized calls;
screens never see headers or URLs. When the real provider comes, only `auth/` changes.

Storing the token was considered, but it would expire between most app starts
and need the refresh logic anyway. The trade-off is one extra request at each
start, and anyone who knows a name can sign in as that user, which is fine for a
development build only.

---

## 18. Mobile code layout

**Status:** Superseded, 2026-11-18 by 25 for what `AppFlow` loads at start, and 2026-11-24 by 35 for the screens it picks and the Edit navigation; other choices remain accepted.

Folders in `mobile/lib/` mirror the backend modules: `auth`, `profiles`, and
`targets`. `core/` holds the API client, failures, error views, and theme that
all modules use. A plain `AppFlow` notifier coordinates sign-in, loading, saves,
and the age warning. The root widget in `main.dart` listens to it, picks the
screen, and owns Edit navigation. This keeps asynchronous results from an older
save from replacing a newer one.

We considered Flutter's [case study layout](https://docs.flutter.dev/app-architecture/case-study)
with UI by feature, data by type, view models, and repositories. One flow notifier
handles the cross-screen state without adding repositories or a state management
package. Screens still own their local form state.

---

## 19. Backend module files

**Status:** Accepted, 2026-11-09 (#45). Extends 10. Amended 2026-11-22 (#83): schemas.py.

Every backend module splits its code the same way:
- `router.py` holds the routes, turning HTTP requests into calls and the results back into responses. It holds no models, queries or rules.
- `schemas.py` holds the module's request and response models, with checks that need only the request itself (ranges, formats and fields that depend on each other, such as an entry's totals against its grams). Checks that need anything else, such as today's date or stored rows, stay in `application.py`.
- `application.py` holds the module's use cases with their queries and rules (for example, saving a profile checks the age, writes the row and commits). It never imports FastAPI. Other modules get plain values from it, never its database rows. Split it (for example, a `queries.py`) only when it grows past about one screen.
- `exceptions.py` holds the module's errors as plain Python exceptions, with no HTTP status.
- `dependencies.py` holds the route parameters other modules use, such as `CurrentUser` and `SavedProfile`.

The module's own HTTP files, `router.py` and `dependencies.py`, turn its errors into HTTP answers. Other modules use those parameters and let them answer; they don't raise their own copy of the error. A module that calls another module's `application` and gets one of its errors decides what that means for its own route. There is no shared base class and no global handler. A module has only the files it needs.

This rule covers the backend only, not the mobile app.

We considered a shared `AppError` base class with one global handler, and a try/except in every route. This rule keeps FastAPI's own 401 and 422 answers and keeps HTTP codes out of the logic.

---

## 20. Food search needs internet

**Status:** Accepted, 2026-11-18 (#48). Changes Ahmad's [answer 1](https://github.com/osamaps518/GHBot/issues/8#issuecomment-6397389553) in #8, that only the coach needs internet.

Food search and barcode lookup run on the server. The phone keeps the foods a
trainee has logged and their own foods. Offline, a trainee logs from those, or
adds a new food of their own.

Size is not the reason: the first catalog is about 1,000 foods, under 1 MB. The reasons:
- Search would be built twice. SQLite has no `pg_trgm`, so offline results would
  differ from online ones, and the ranking and the name cleaning rules would need
  a second copy in Dart.
- The catalog will outgrow the phone: unknown barcodes from Open Food Facts (#68),
  and maybe search by meaning with the coach.
- A fixed food has one copy to fix.

We accept: offline, a trainee can't find a food they have never logged. Most
logging repeats foods already logged, and those work offline.

We considered keeping the whole catalog on the phone with a plain "contains"
filter. It is cheap today, but it is a weaker second search, and it stops working
once the catalog grows.

---

## 21. An entry keeps the values it was logged with

**Status:** Accepted, 2026-11-18 (#48). Changes Ahmad's [answer 3](https://github.com/osamaps518/GHBot/issues/8#issuecomment-6397389553) in #8, that past days update to corrected values with a "Corrected" label.

A diary entry stores the food's values per 100 g when it was logged, and the
totals calculated from them. When a food's values are fixed later, old entries
keep their values, so a past day's totals never change.

- History stays what the trainee saw.
- Changing an old entry's amount uses the entry's own values, not the food's current ones.
- The server can check an entry's totals against the entry's own values.

The "Corrected" label waits. It stays possible: the entry has the values it was
logged with and the food has its current ones, so the app can show both later.

Storing only the totals was rejected: an edit would silently use today's food
values, and the server would have nothing to check the totals against.

---

## 22. Food names in Arabic and English

**Status:** Accepted, 2026-11-18 (#48). Changes Ahmad's [answer 9](https://github.com/osamaps518/GHBot/issues/8#issuecomment-6391833695) in #8, that every food needs a Hebrew name and Hebrew search.

The first catalog has Arabic and English names only. Hebrew food names and
Hebrew search come with Hebrew as an app language (#25).

- The app has no Hebrew yet, so a Hebrew name would have no one to show to.
- Every name needs review by someone who reads it, and reviewed names already
  limit the catalog's size.
- A Hebrew name column is a normal migration later, and search gets its Hebrew
  cleaning rules at the same time.

---

## 23. Phone database: Drift on SQLite

**Status:** Accepted, 2026-11-18 (#52)

The app keeps data on the phone in SQLite, through [Drift](https://drift.simonbinder.eu/).
What we needed: real transactions (an offline diary entry exists nowhere else),
relational data like the server's, safe schema changes on users' phones, a
library that will still be maintained, and screens that update when sync
brings changes. SQLite has shipped inside Android for over 15 years and has a
stable file format. Drift checks queries before the app runs and has tools for
testing migrations.

Each module declares its own tables, with typed columns rather than JSON, so
Drift checks them. Each schema version is exported to `mobile/drift_schemas/`, so upgrades can be
tested against it.

Options ruled out:
- sqflite: SQL in strings that nothing checks, and no live queries. It's the
  fallback if we ever want no code generation.
- ObjectBox: not SQL, its sync needs its own server, and the engine isn't open source.
- Isar and Hive CE: not relational, and both are community forks of abandoned libraries.
- Realm: MongoDB retired its SDKs in September 2025.
- PowerSync and ElectricSQL: a second service to run, and access rules written twice.

We accept a code generation step (`build_runner`) and generated files committed
in the repo.

---

## 24. Profile and targets: cached to read, online to save

**Status:** Accepted, 2026-11-18 (#52)

The phone keeps the last profile and targets the server sent and shows them
without a connection. Saving a profile needs internet: the server's result is
stored, then shown. Offline, the save shows the no-connection error and changes
nothing.

- The server can refuse a profile (age rule, ranges). Saving offline would need
  a "your change was rejected" flow.
- Targets offline would need the formula and the safe minimum a second time, in
  Dart. A health rule must have one copy.
- A profile changes a few times a year; a meal is logged several times a day.

The server is the authority: a refresh replaces what is stored, even when the
server has no profile.

---

## 25. Sign-in when a call needs one, one database file per user

**Status:** Accepted, 2026-11-18 (#52). Supersedes parts of 17 and 18.

The app opens from the data on the phone. It no longer loads the profile and
targets from the server at every start, so it gets a token only when a call
needs one. Sign-in protects the server's data; data already on the phone is
protected by the lock screen and Android's app storage.

At start, the app shows the signed-in user's stored profile and targets at once
and refreshes them in the background; it waits for the server only when nothing
is stored. Installs from before #52 stored the name without the user's ID, so
they get the ID first.

Each user has their own database file, named by their ID, and their own
age-warning mark. Each refresh and save writes only to the database it started
with, and an older result never replaces a newer one. `user_data/`, the folder
of these files, is left out of Android backup and device transfer; the name and
ID stay in backup.

Rejected:
- Wiping the database when the user changes: it would destroy unsent diary entries.
- One shared database with a user filter on every query: one forgotten filter
  shows someone else's data.

We accept:
- A stolen unlocked phone shows the cached data.
- A blocked account keeps its cached data until the server refuses its sign-in.
  This starts with the real provider: dev sign-in never refuses.
- The first sign-in and onboarding need internet.

---

## 26. One `foods` table

**Status:** Accepted, 2026-11-18 (#53).

Catalog foods, packaged products, and trainees' own foods share one table. A
diary entry links to one kind of thing, search uses one query, and the phone's
copy uses one table. We considered separate catalog and own-food tables, which
make privacy simpler. With one table, we pay that cost once: catalog rows have
no owner; a trainee row has an owner and no source ID. Database constraints
enforce this boundary. We would reconsider a split if own foods gain sharing
or recipes.

Units stay in one JSONB map on the food row. A food and its units are read and
synced together, and units are not queried on their own.

---

## 27. Seed data

**Status:** Accepted, 2026-11-18 (#53).

Curated catalog foods live in CSV files in the repo, one per source. Changes go
through pull requests so health numbers are reviewed. A command loads the files,
not a migration, and is safe to rerun.
There is no scheduled refetch. Removed CSV rows remain in the table.

---

## 28. Food data licenses

**Status:** Accepted, 2026-11-18 (#50)

This is what we concluded from the license texts and each source's own terms,
not legal advice. Product images are out of scope: M2a uses none.

**USDA FoodData Central (#54)**
- **License:** public domain. The [API guide](https://fdc.nal.usda.gov/api-guide/)
  says: "USDA FoodData Central data are in the public domain and they are not
  copyrighted. They are published under CC0 1.0 Universal (CC0 1.0)".
- **Requires:** nothing. "No permission is needed for their use, but we request
  that users list FoodData Central as the source of the data".
  [CC0](https://creativecommons.org/publicdomain/zero/1.0/legalcode.en) has no
  attribution condition.
- **For us:** the rows can sit in the MIT repo and next to anything in `foods`.
  We list the source anyway, because it is asked and costs nothing.

**Open Food Facts (#56)**
- **License:** the [terms of use](https://world.openfoodfacts.org/terms-of-use)
  say: "The Open Food Facts database is available under the Open Database
  License. Individual contents of the database are available under the Database
  Contents License." The [DbCL](https://opendatacommons.org/licenses/dbcl/1-0/)
  only adds "You must comply with the ODbL", so the
  [ODbL](https://opendatacommons.org/licenses/odbl/1-0/) is what binds us.
- **Requires:** attribution and share-alike. Re-users "have to mention the
  licence and to attribute the authorship to Open Food Facts with a link to
  https://openfoodfacts.org, the appropriate local version [...] or the product
  page" (terms of use). The rest depends on what the ODbL calls each place the
  data appears:
  - **The CSV in `backend/seed/` is a Derivative Database.** Picking and
    cleaning products is an "arrangement, modification, or any other
    alteration" (section 1). A few hundred products may sound insubstantial,
    but "repeated and systematic Extraction [...] may amount to [...] a
    Substantial part" (section 1, repeated in 6.2), so we assume it is. A public repo
    lets anyone copy it, so we Publicly Convey it. Section 4.2: it goes out only
    under the ODbL, with the license's link next to it and in its documentation,
    keeping any notices that came with the data; a CSV can't hold a notice, so
    it goes "in a location (such as a relevant directory) where users would be
    likely to look for it". Section 4.4: the file is ODbL, not MIT, and we "must
    not add Contents [...] that are incompatible". Section 4.6 lets us offer
    either the whole Derivative Database or a file of the changes; we offer the
    whole one, and the public CSV is it, so it must match what the server serves.
  - **The server's `foods` table is a Collective Database, while its parts stay
    independent.** We mean it as separate datasets side by side: the OFF CSV,
    USDA foods, our dishes, and each trainee's foods, each made on its own and
    usable without the others. Neither one table nor the `source` column decides
    this: `source` only tracks where a row came from. Section 4.5a: "You are not
    required to license Collective Databases under this License if You
    incorporate this Database or a Derivative Database in the collection, but
    this License still applies to this Database or a Derivative Database as a
    part of the Collective Database". While the parts stay independent,
    share-alike covers the OFF part only, not our dishes or trainees' foods.
  - **What the app shows is a Produced Work:** search results, barcode results,
    food details, and foods shown from the trainee's log. A Produced Work is "a
    work [...] resulting from using the whole or a Substantial part of the
    Contents (via a search or other query)", and making one "does not create a
    Derivative Database" (4.5b). Section 4.3: "if you Publicly Use a Produced
    Work, You must include a notice associated with the Produced Work reasonably
    calculated to make any Person that uses, views [...] aware that Content was
    obtained from the Database [...] and that it is available under this
    License." Sections 4.4c and 4.6: the results come from our Derivative
    Database, so the notice also offers it, with a link to the CSV.
  - **The food records the API sends, and the foods that build up on the phone,
    are copies of part of the Derivative Database.** The network exception
    holds only "where no transfer of a copy of the Database or a Derivative
    Database occurs", and the API does send records. One response holds a few
    foods, but a trainee who logs many products collects more over time, so we
    treat these copies like the CSV: they travel with the notice. The API's only
    client is our app, so the app carries the notice and the API sends each
    food's `source` so the app knows which foods it covers. The API itself needs
    no notice text while that is true; if anyone else ever uses it, it needs one
    first.
- **For us:** the app shows an Open Food Facts notice wherever one of its
  products appears (#71). The [data page](https://world.openfoodfacts.org/data)
  asks for it "on product pages, search screens, and in the "About" or
  "Settings" sections" with "clickable links back to Open Food Facts and the
  ODbL license", and gives the wording: "Contains data from Open Food Facts,
  available under the Open Database License". Testing among ourselves is not
  public use (section 4.5c), but no build with OFF products goes to beta testers
  before #71 ships.

Our own rule, stricter than the license asks: no row mixes OFF values with
another source's (for example, a missing value filled from USDA), and OFF rows
are loaded as they are in the CSV. If a change would make the parts stop being
independent, we stop and revisit this decision before it ships. Publishing
trainees' foods is never the way out. A separate table for OFF rows wouldn't
settle it either: independence is about the data, not where it is stored.

The data page also asks apps to "send those contributions back" when users add
products. We don't: it is a request, not a license term, and trainees' own foods
are their private data.

**Checklist for #54 and #56**
- [ ] #54: the seed README names FoodData Central as the source of the USDA file,
  with the data type, the release, its CC0 license and the suggested citation:
  "U.S. Department of Agriculture, Agricultural Research Service. FoodData
  Central, <year>. fdc.nal.usda.gov."
- [x] #56: OFF rows live in their own CSV, with nothing else in it: none of our
  rows, no values from other sources.
- [x] #56: the seed README says that file "Contains data from Open Food Facts
  (https://world.openfoodfacts.org), available under the Open Database License
  (https://opendatacommons.org/licenses/odbl/1-0/)", that its contents are under
  the DbCL (https://opendatacommons.org/licenses/dbcl/1-0/), that the MIT license
  does not cover it, and the date of the export used. Any copyright,
  database-right or license notice that came with the export is kept there too.
- [x] #56: one line in the root `README.md`: the MIT license covers the code; the
  Open Food Facts file is ODbL, see `backend/seed/README.md`.
- [x] #56: any change to a product's names or values is made in the CSV, so the
  public file stays the full copy we offer under section 4.6.
- [ ] App: [#71](https://github.com/osamaps518/GHBot/issues/71) shows the notice
  on every screen that shows an OFF food, including foods from the trainee's
  log, with an About entry linking to Open Food Facts, the ODbL and our CSV. It
  ships before any build with OFF products reaches beta testers.

---

## 29. Food search

**Status:** Accepted, 2026-11-22 (#58).

Search catalog foods and a trainee's own foods with PostgreSQL trigrams. Dish
names are short, search must work while typing, and misspellings are common.
Full-text search matches the start of a word, but not the middle of one or a
misspelling. A search engine would add a second service for a few thousand
foods. We chose option C
from #57: cleaned text contains the cleaned query, or word similarity meets
the `<%` operator's 0.5 threshold. A GIN trigram index supports it. Own foods
rank first, then names beginning with the query, then the other matches.

Cleaning is a search requirement of its own. Lowercase, apply Unicode NFKC,
remove Arabic diacritics, Latin accents and tatweel, normalize أ إ آ ٱ to ا,
ة to ه, ى ئ ی to ي, ک to ك, and Arabic-Indic digits to Western digits. Keep
ء. NFD splits hamza from some letters before marks are removed; this also
turns ؤ into و. #57 did not test ؤ, and no test has shown that this hurts.
One immutable SQL function cleans both stored names and typed text. A stored
generated column combines the cleaned Arabic, English and other names. This
keeps all write paths and old rows consistent without duplicate cleaning code in
Python.

Meaning lives in the data: every catalog food has an Arabic name, so a user can
find the same row through Arabic or English without translating the query.
Search by meaning with embeddings would need a model call for every search and
a provider (decision 7); it also performs poorly for half-typed words and
brands. It may make sense later with the coach, but this is not a final ban.

Check a hosted database by running `show_trgm` on an Arabic word, not by its
locale name: `C.UTF-8` can still leave `LC_CTYPE` at `C`, which ignores Arabic
letters. A known gap is that `رز` also finds كرز and برز through contains.
Names beginning with the query rank first. Whole-word aliases could fix the
gap later.

---

## 30. Diary numbers

**Status:** Accepted, 2026-11-22 (#59)

**What an entry keeps**
- **Grams:** greater than 0, at most 1 decimal (37.5 g).
- **Values per 100 g:** at most 1 decimal. The API sends a food's values already
  rounded half up to 1 decimal (#58), so the phone copies them as they come. The
  `foods` table keeps whatever precision its source has; rounding happens once,
  when the API sends a food.
- **Totals** (calories, protein, carbs, fat): value per 100 g × grams ÷ 100,
  rounded half up to 1 decimal. Calories keep 1 decimal too.

All of these are whole numbers of tenths, so the total is calculated in integers:
`total_tenths = (value_tenths × grams_tenths + 500) div 1000`. In Python,
`Decimal` with `ROUND_HALF_UP` gives the same result. Half up matches the
targets (15). All values are ≥ 0, so half up and half away from zero are the
same here.

**Where**
- The phone calculates an entry's totals when it is logged and when its grams change.
- The server recalculates them from the entry's own values and grams (21) and
  refuses the entry if any total differs, with no tolerance.
- A day's totals add the entries' stored totals, exact in tenths, and show them
  rounded half up to whole numbers, like the targets. A day total of 42.5 g shows as 43.
- JSON carries plain numbers. The server refuses any of these values with more
  than 1 decimal.

**Why integers in tenths:** no floating point, so the phone and the server can't
disagree on a tie. A float can't hold most tenths exactly: in Python,
`round(0.15, 1)` gives 0.1. With integers, Dart and Python get the same totals,
and the server's check needs no tolerance.

**Worked examples.** Rice = cooked white rice: 130.0 kcal, 2.7 g protein, 28.2 g
carbs, 0.3 g fat per 100 g. Oil = olive oil: 884.0 kcal, 0 protein, 0 carbs,
100.0 g fat.

| Entry | Calories | Protein | Carbs | Fat | What it shows |
|---|---|---|---|---|---|
| Rice, 150 g | 195.0 | 4.1 | 42.3 | 0.5 | ties: 4.05 → 4.1, 0.45 → 0.5 |
| Oil, 12.3 g | 108.7 | 0.0 | 0.0 | 12.3 | fractional grams (108.732) |
| Rice, 2.5 g | 3.3 | 0.1 | 0.7 | 0.0 | fractional grams and a tie (3.25 → 3.3); 0.0075 → 0.0 |
| Day: rice 150 g + oil 12.3 g | 303.7 → shows 304 | 4.1 → 4 | 42.3 → 42 | 12.8 → 13 | day totals add stored totals, then round for display |

A food stored with protein 2.75 and fat 0.15 is sent by the API as 2.8 and 0.2.

---

## 31. Sync calls

**Status:** Accepted, 2026-11-22 (#60). Amended 2026-11-24 (#62): pulling, server side. Amended 2026-11-25 (#61): sending, phone side. Amended 2026-11-28 (#62): pulling, phone side, answers at the same revision, and backup. Amended 2026-11-28 (#65): own foods, server side. Amended 2026-11-28 (#65): own foods, phone side.

The phone makes each diary row's ID, so repeating a call is harmless. A higher
revision replaces an active row; a lower or equal one leaves it unchanged.
Deletes are final and are recorded even for an ID the server has not seen. Every
answer carries the stored row so the phone learns when its copy was not kept;
otherwise it could mark an ignored entry as sent.

The server checks totals against the entry's own per-100 g values (decision 21).

**Own foods (#65, server).** `PUT /me/foods/{id}` uses the same revision rule:
a higher revision replaces an owned row; a lower or equal revision returns the
stored row. The server sets `owner_id` from the token and `source` to `trainee`.
An insert with a conflicting catalog or another trainee's ID returns 409. The
ownership and revision checks are in the `INSERT … ON CONFLICT DO UPDATE`
statement, so a concurrent writer cannot pass a separate read and overwrite
someone else's row. A successful write takes `clock_timestamp()` as its
`updated_at`, so it can be picked up by a later pull. Pulls include the caller's
changed own foods even if no diary entry uses them, so a reinstall recovers
foods created but never logged. Food answers carry `own`, `revision` and
`barcode` for the phone's local copy.

**Pulling (#62, server).** A pull returns the caller's diary rows changed since
a marker, deleted ones too, and the changed foods they use; without a marker,
all of them.

It also returns the foods of the entries it returns, changed or not. An entry
that changed on the server can use a food that didn't, one the phone may not
have, and the diary hides an entry without its food. We rejected a call for
foods by ID, a second request per pull, and a full pull whenever a food is
missing.

The next marker is the database's time minus 30 seconds, taken before reading
the changes. The overlap lets a later pull catch writes that commit after the
read but began inside the margin; repeated rows replace by ID. The entry query
has an index on `(user_id, updated_at)` so each pull need not scan other
trainees' diaries. There is no pagination yet: 15 entries per day for three
years is about 16,000 rows, a few MB on the occasional full reinstall pull.

The food query of a pull has no index of its own. Asking for the caller's own
foods as well as the used ones (#65) stops PostgreSQL from looking up the used
foods by primary key, and `foods` has no index on `owner_id`, so each pull with
a marker scans the whole table; the cost grows with every trainee's own foods,
not the caller's. Measured on 2026-11-28 in a local database with 20,000
catalog foods, 40,000 own foods (2,000 trainees × 20) and 3,000 entries for one
trainee: 1.4 ms before #65 (a primary-key lookup), 8.1 ms after (a scan of
60,020 rows). A partial index on `owner_id` with a `UNION` brought it only to
3–5.6 ms, since the catalog rows are still read. Today the catalog is 240 rows
with few trainees, under a millisecond, so the query stays as it is. Revisit at
about 100,000 food rows, or when a pull takes over ~20 ms.

The seed loader commits each CSV file in its own transaction, and a changed row
takes the time of the write. Each file's transaction is far shorter than the
30-second margin, so a row commits within the margin of its timestamp and no
marker can pass it unseen. A real load of the 239-row `open_food_facts.csv`
into a local database took **0.140 seconds** on 2026-11-24, measured inside the
loader call with `time.perf_counter()`; this is one local run, not a throughput
guarantee.

**Sending (#61, phone).** Each entry on the phone keeps its revision and the
last revision the server confirmed; an entry is unsent when its revision is
newer and it isn't refused.
One runner for each user and their database sends the unsent entries, each in
its own call, then pulls, one run at a time. It stops when another user signs
in, so one user's rows never go out with another's sign-in.

- **When it runs:** at start, when the app returns to the foreground, shortly
  after a write to the diary, and after a failed run on a timer that backs off.
  There is no Android background job and no connectivity package: trying the
  call is the test for being online. The runner's own writes also count as
  writes to the diary. That costs one more run, so one more pull; after a run
  that sent some rows and then failed, it can retry the rest early.
- **Deletes:** a deleted entry is sent as `DELETE` even if it was never sent:
  its `PUT` may have arrived with the answer lost.
- **Answers:** the phone takes the server's copy as confirmed, even at the
  revision sent: once a pull puts an entry on two phones, each can send its own
  change at the same revision, and the server keeps the first.
- **Refused** entries, a 422 or 409, wait until the trainee changes or deletes
  them. The phone runs the server's checks before every save, so refusals are
  rare. A refused `DELETE` leaves the phone as a confirmed one does: its 409
  means another user owns the ID, its 422 an ID the phone never sends, and the
  trainee can't fix either.

**Pulling (#62, phone).** With no marker, a new install or a new database, the
phone asks for everything: that is how a reinstall gets the diary back.

- **Foods:** a fixed catalog food replaces the phone's copy. Entries keep the
  values they were logged with (decision 21).
- **A pulled entry** replaces the phone's copy, unless the phone's has a change
  the server hasn't confirmed, refused or not. That keeps the trainee's edits
  and pending deletes: a pull never brings back an entry deleted on the phone.
  A pulled deleted entry removes the row even then: deletes are final, so the
  change would only come back deleted.
- **Repeated rows:** an entry the phone has at the same revision isn't written
  again. A confirmed copy at that revision already has the server's values,
  since every answer stores them. The 30-second margin sends recent rows with
  every pull, and writing them would start another run, then another pull,
  until they left the margin.

**Own foods (#65, phone).** An own food is made on the phone, with its ID, and
sent like an entry: a revision, the last revision confirmed, a refusal mark,
the server's answer taken at the revision sent. Catalog foods are at revision
0 and never count as unsent.

- **Foods first:** each run sends the unsent own foods before the entries, so an
  entry logged with a new food goes in the same run. An entry whose food has a
  change the server hasn't confirmed, refused or not, waits for a later run:
  sent first, the server would refuse it for a food it doesn't have, and the
  refusal would stay after the food arrived. A deleted entry goes all the same:
  a delete doesn't need the food.
- **Search and pulls:** storing a food the server sent never overwrites an own
  food with such a change, as for entries above.
- **When it runs:** saving an own food on the phone starts a run 2 s later,
  as a diary write does, so a food saved without an entry is backed up and
  findable online at once. Other writes to foods don't: every pull writes
  the foods it brings, and a catalog food's revision stays 0 when it is
  fixed, so repeated foods can't be skipped as entries are, and a run would
  follow every pull. So the database announces only its own saves of own
  foods, not every write to the table.

**Backup.** `user_data/` stays out of Android backup and device transfer
(decision 25). Pulling adds a reason: it puts a trainee's entries on every
phone they sign in on, so a revision no longer orders changes across copies. A
restored copy's old unsent change can carry a higher revision than a newer
change made on another phone, and would replace it. Signing in again brings
the diary back without a backup.

Rejected: a queue of every change on the phone, which needs a second table and
more code for one device per user; PowerSync self-hosted, which adds a service,
a second copy of the access rules, and a hosting choice we haven't made. We
accept that entries logged offline stay only on the phone until the app is next
opened with a connection.

---

## 32. The diary is local-first

**Status:** Accepted, 2026-11-24 (#59).

An entry is saved to the phone's database first, and the diary reads only from
that database. Screens listen to Drift's live queries, so a saved entry shows
at once, with or without a connection. Logging also keeps the entry's food on
the phone, in one transaction, so it can be found and logged again offline
(decision 20). #61 sends the entries to the server.

- A trainee logs several times a day, often where the connection is poor.
  Logging must not wait for the server or fail without it.
- The phone makes the entry's ID (UUIDv7, like the server's IDs), so sending it
  again later is harmless (decision 31).

We considered saving to the server first, as profiles do (decision 24). A
profile changes a few times a year and the server can refuse it; an entry is
frequent and the server only checks its arithmetic. We accept that the phone's
database holds entries the server hasn't seen yet, and that a refused entry
needs its own state in #61.

---

## 33. The phone calculates an entry's values

**Status:** Accepted, 2026-11-24 (#59).

The phone calculates an entry's totals from the food's values per 100 g and the
grams, with decision 30's integer formula, and stores both. The server checks
them and does not calculate its own (decision 31).

- The phone must show a number offline anyway.
- A second calculation on the server could disagree, and a total would change
  after sync. Integers in tenths make the phone's result and the server's check
  agree exactly.

---

## 34. The phone decides the diary day

**Status:** Accepted, 2026-11-24 (#59). Amended 2026-11-28 (#64): past days.

An entry's diary day is the day the diary shows when it is logged: today, from
the phone's clock and time zone, unless the trainee went back to an earlier
day. It is stored as a plain `YYYY-MM-DD` date. The day starts at 4:00, so a
snack at 1:30 still belongs to the evening before. When it is logged is stored
separately, in UTC, and is the clock's time even on a past day: it says when
the trainee logged it, and the diary day already says which day it belongs to.

- The server doesn't know the phone's time zone.
- An entry keeps its day: travel, or a later change to the day start, doesn't
  move old entries.
- A diary day is a date, not a point in time, so it isn't stored as one.

There is no setting for the day start yet.

**Past days (#64).** The diary goes back to the account's first diary day
in the phone's time zone. Installs from before #64 need one online start
to learn that boundary; later starts can use the stored value offline.

Moving an entry changes only its diary day, so it is sent like any other
change (decision 31). It keeps its meal, an extra meal's name too.

---

## 35. The diary is home; `AppFlow` keeps its gate job

**Status:** Accepted, 2026-11-24 (#59). Supersedes 18 for the screens.

After sign-in, onboarding and the age warning, the app opens on today's diary.
The targets screen opens on top of it from "Targets", and Edit my info stays
there. `AppFlow` only gates: sign-in, loading, onboarding, the age warning and
the error screen. It exposes the user's database, and the diary, search and
amount screens read and write it directly. Navigation is Flutter's built-in,
with no bottom tabs.

We considered a diary notifier next to `AppFlow`. Drift's live queries already
tell the screens about every change, so it would only pass them along.

---

## 36. How sync is tested

**Status:** Accepted, 2026-11-25 (#61). Amended 2026-11-28 (#62): pulling.

The runner is tested against a stand-in server and an in-memory Drift database.
The stand-in lets each test control failed, delayed, or lost answers without
running the backend. The database exercises the runner's real queries without
creating persistent database files.

- We accept that the stand-in can drift from the real API. The backend tests
  (#60) check the same calls from the server's side.
- No automated test drives the app on an emulator.

---

## 37. Custom targets

**Status:** Accepted, 2026-11-28 (#21).

The backend keeps one custom row per trainee and a history row for each save or
real reset. Profile edits leave custom values in place. Recommended targets are
still calculated from the current profile on every read.

The calorie minimum is 1500 for male and 1200 for female profiles, from one
server function that save and read share. A save is refused below the minimum,
or when its macro energy differs from its calories by 100 kcal or more. The API
accepts whole numbers up to 6000 calories, 500 g protein, 300 g fat and 1000 g
carbs.

If an older custom row is below today's minimum, the read raises it to the
minimum and adjusts its macros. The adjustment uses protein and fat floors of
1.6 g/kg and 20% of calories; additional calories use ceilings of 65% for carbs,
2.2 g/kg for protein, and 35% for fat. At BMI 30 or higher, the protein limits
use weight at BMI 25. Carbs also come down whenever the macros add up to
more than the raised calories, even when protein and fat needed no raise. That
only happens inside the 99 kcal gap a save allows, and it keeps the macros
matching the calories shown.

The phone caches the effective and recommended targets, so custom targets show
offline. Like a profile save (decision 24), saving and resetting need internet:
offline, they show the no-connection error and change nothing. The form checks
the ranges and the 100 kcal rule before sending, for quicker errors. The phone
has no copy of the minimum: the server's refusal carries it.

---

## 38. Own food checks

**Status:** Accepted, 2026-11-28 (#65).

An own food needs at least one Arabic or English name. Each name given has 1 to
80 characters (counted as Unicode code points), is not only spaces and contains
no NUL. Its per-100 g calories are 0–900 and its protein, carbs and fat 0–100 g
each, all with at most one decimal place. Their sum is at most 100 g. A
barcode, when given, has 8 to 14 digits. The server and phone apply the same
checks so an offline save can get quick feedback and a later send receives the
same decision.

Calories are not checked against the macros: food labels round their values,
and fiber and alcohol can add calories the three macros do not show. The ranges
are the ones a diary entry accepts for its per-100 g values, so every own food
the server accepts can be logged.

The phone counts a name's characters in code points too, so 80 emoji fit on
both sides; Dart's `String.length` counts UTF-16 units and would make them 160.
The form trims names and sends an empty one as none, since the server keeps
names as sent and refuses an empty one. Where Dart and Python disagree on what a space is, the phone
takes the wider set: a refusal it shows at once is better than one from the
server, which leaves the food and its entries waiting.
