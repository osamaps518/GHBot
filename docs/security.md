# Security

What GHBot guarantees about security today, how, and which tests check it. Update it when one of these changes.

## Sign-in

There is only development sign-in for now, so a name is the account: anyone who knows a name can get a token for it. That's fine for a development build only; production sign-in is still to be decided (decision 5). To keep it from running anywhere else, the backend refuses to start unless `ENVIRONMENT` is exactly `development` (`test_dev_auth_refuses_other_environments`, `test_dev_auth_requires_an_explicit_environment`), and the signing key must be at least 32 bytes (`test_dev_auth_rejects_a_31_character_secret`). `POST /dev/token` gives an HS256 token that lasts 15 minutes (`test_dev_token_is_signed_and_short_lived`).

Every protected route gets the user through `CurrentUser`, which verifies the token. A missing, expired, wrongly signed or malformed token gets the same 401 on every protected route, including `alg: none`, HS512, and tokens without `sub`, `iat` or `exp`, and no user row is created (`test_invalid_credentials_get_the_same_401`).

## Each user sees only their own data

Routes take the user from the token, never from the request. Profile reads and writes use that user's id, and targets are calculated from that user's saved profile, so ids sent in the body change nothing (`test_profiles_are_private_to_each_user`, `test_profile_owner_cannot_be_changed_by_body_ids`). The API sends no CORS headers, so other websites can't call it from a browser (`test_api_does_not_enable_cors`).

Own foods are private. Every trainee food read uses `visible_foods`, which
selects catalog rows plus only that trainee's own rows. Search takes the user
from the token (`test_search_keeps_other_trainees_food_private`,
`test_visible_foods_include_catalog_and_only_the_users_own`).

Diary entries are private to each trainee. The owner comes from the token, and
the ownership check and write are one database statement, so another trainee
cannot replace or delete an entry (`test_other_trainee_cannot_replace_or_delete_entry`).
An entry cannot refer to another trainee's own food
(`test_other_trainees_own_food_cannot_be_logged`).
The diary pull returns only the caller's entries and their visible used foods,
including tombstones (`test_pull_never_returns_other_trainees_own_foods`,
`test_pull_returns_deleted_entry_and_excludes_other_trainee`).

## Health data stays out of logs

Profiles hold health data. The database engine hides bound parameters in its errors and logs, so a failed insert doesn't log the values (`test_failed_profile_insert_does_not_log_health_values`). Bad input gets a 422 instead of a 500: ranges and the age limit are checked before saving, and NaN, Infinity and lone surrogates come back as text in the 422 (`test_non_finite_number_gives_422`, `test_lone_surrogate_in_token_subject_returns_422`).

Diary entry values stay out of logs when a database constraint rejects a write:
the handler records only the error type and SQL statement
(`test_failed_write_keeps_entry_values_out_of_logs`).

## The phone

The app stores the sign-in name, the user's ID from `GET /me`, and, once a user accepts the age warning, a mark for that user. It never stores a token; it gets one when a call needs it (decision 25). Every request goes to the configured backend, and the token goes only in the `Authorization` header, never in a URL or body. The widget tests "only the name and ID are stored and tokens stay in backend headers", "a 79-year-old sees it after onboarding, then the targets" and "shows once for each user on the phone" check this.

Each user's profile and targets are kept in their own database file, `user_data/<userId>.sqlite` in the app's private storage, so a second user on the phone sees none of the first's data (decision 25). The widget test "two users on one phone each keep only their own data" checks this. `user_data/` is left out of Android backup and device transfer (`data_extraction_rules.xml` for Android 12 and higher, `full_backup_content.xml` for Android 11 and lower).

Release builds refuse to start unless the backend address begins with `https://` and has a host, so tokens and health data never go over plain HTTP. Debug and profile builds allow plain HTTP for the local backend (decision 11). The test "release builds require an HTTPS backend address" checks this.

## Not covered yet

- PostgreSQL can put a rejected row's values in its own constraint error message. Before adding a CHECK or NOT NULL constraint on health data, handle `DBAPIError` by logging only the error type and SQL (decision 8).
- Development names are not private credentials. Production sign-in, account recovery and session storage need their own design and review.
- Android backup still includes the name and ID while development names are used. Revisit it when real sign-in replaces them.
- Hosting, certificates, production logging and access to the servers wait until deployment is planned (decision 6).
