# Security

What GHBot guarantees about security today, how, and which tests check it. Update it when one of these changes.

## Sign-in

There is only development sign-in for now, so a name is the account: anyone who knows a name can get a token for it. That's fine for a development build only; production sign-in is still to be decided (decision 5). To keep it from running anywhere else, the backend refuses to start unless `ENVIRONMENT` is exactly `development` (`test_dev_auth_refuses_other_environments`, `test_dev_auth_requires_an_explicit_environment`), and the signing key must be at least 32 bytes (`test_dev_auth_rejects_a_31_character_secret`). `POST /dev/token` gives an HS256 token that lasts 15 minutes (`test_dev_token_is_signed_and_short_lived`).

Every protected route gets the user through `CurrentUser`, which verifies the token. A missing, expired, wrongly signed or malformed token gets the same 401 on every protected route, including `alg: none`, HS512, and tokens without `sub`, `iat` or `exp`, and no user row is created (`test_invalid_credentials_get_the_same_401`).

## Each user sees only their own data

Routes take the user from the token, never from the request. Profile reads and writes use that user's id, and targets are calculated from that user's saved profile, so ids sent in the body change nothing (`test_profiles_are_private_to_each_user`, `test_profile_owner_cannot_be_changed_by_body_ids`). The API sends no CORS headers, so other websites can't call it from a browser (`test_api_does_not_enable_cors`).

## Health data stays out of logs

Profiles hold health data. The database engine hides bound parameters in its errors and logs, so a failed insert doesn't log the values (`test_failed_profile_insert_does_not_log_health_values`). Bad input gets a 422 instead of a 500: ranges and the age limit are checked before saving, and NaN, Infinity and lone surrogates come back as text in the 422 (`test_non_finite_number_gives_422`, `test_lone_surrogate_in_token_subject_returns_422`).

## The phone

The app stores the sign-in name and, once the user accepts the age warning, a flag for it. It never stores a token; it gets a new one at each start (decision 17). Every request goes to the configured backend, and the token goes only in the `Authorization` header, never in a URL or body. The widget tests "only the name is stored and tokens stay in backend headers" and "a 79-year-old sees it after onboarding, then the targets" check this.

Release builds refuse to start unless the backend address begins with `https://` and has a host, so tokens and health data never go over plain HTTP. Debug and profile builds allow plain HTTP for the local backend (decision 11). The test "release builds require an HTTPS backend address" checks this.

## Not covered yet

- PostgreSQL can put a rejected row's values in its own constraint error message. Before adding a CHECK or NOT NULL constraint on health data, handle `DBAPIError` by logging only the error type and SQL (decision 8).
- Development names are not private credentials. Production sign-in, account recovery and session storage need their own design and review.
- Android backup stays on while development names are used. Revisit it when real sign-in replaces them.
- Hosting, certificates, production logging and access to the servers wait until deployment is planned (decision 6).
