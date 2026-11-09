# M1 security review

M1 uses development sign-in only. The app refuses to start outside the
`development` environment. A name identifies a user; anyone who knows that
name can obtain a token for that account. Production authentication remains a
separate decision.

Protected routes verify short-lived HS256 tokens and use the token's subject
to find the caller's user row. Profile reads and writes use that row's ID, and
targets are calculated from the caller's saved profile. The client cannot
select an owner in a request body. The phone stores the development subject
and, after acknowledgement, an age-warning flag; it does not store tokens.
Tokens travel in authorization headers to the configured backend address.

The backend hides SQL bound parameters in errors and logs. Profile inputs are
validated before saving, and the 422 handler echoes non-finite numbers as
JSON-safe strings.

## Not covered yet

- PostgreSQL can include a rejected row's values in its own constraint error
  message. Before adding a CHECK or NOT NULL constraint on health data, handle
  `DBAPIError` by logging only the error type and SQL, as decision 8 requires.
- Development names are not private credentials. Production sign-in, account
  recovery, and session storage need their own design and review.
- Android backup remains enabled while development names are used. Revisit it
  when real sign-in replaces them.
- Hosting, transport certificates, production logging, and operational access
  controls are deferred until deployment is planned.

The security requirements and evidence for this review are in the private
`docs/reviews/m1/` notes. Backend and mobile README checks run before the
review branch is handed over.
