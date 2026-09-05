# Bot Management (reCAPTCHA Enterprise token depth)

## What this covers

This lab's rules-redirect.tf already demonstrates the basic
GOOGLE_RECAPTCHA redirect action, challenging suspicious traffic. This
doc covers the deeper reCAPTCHA Enterprise integration beyond that basic
redirect, session tokens and action tokens, which let a legitimate client
prove it already passed a challenge without being re-challenged on every
request.

## Session tokens vs action tokens

- Session tokens are issued after a client passes an initial challenge
  and are valid for a period of time across multiple requests, reducing
  repeated friction for legitimate users
- Action tokens are tied to a specific action, such as a login attempt or
  a transfer, and are validated per-action rather than per-session,
  useful for high-value actions like the transfer endpoint this lab
  already rate-limits

## Why this lab only demos the basic redirect, not tokens

Session and action tokens require reCAPTCHA Enterprise to be integrated
directly into the frontend application, JavaScript embedded in the login
and transfer pages, generating a token client-side that Cloud Armor then
validates. vuln-bank was not built with this integration, and adding it
would mean modifying the pinned vuln-bank submodule itself, which this
repo deliberately avoids, see vulnerable-app/NOTES.md on why the
submodule stays pinned and unmodified.

## How you would add this in a real application

1. Create a reCAPTCHA Enterprise key scoped to your domain
2. Embed the reCAPTCHA Enterprise JavaScript snippet in the relevant
   frontend pages (login, transfer)
3. Generate a token client-side on the relevant action
4. Configure Cloud Armor to validate that token via a header the
   frontend attaches to the request
5. Cloud Armor allows, challenges, or denies based on the token's risk
   score

## Relationship to Cloud Armor Enterprise

Note this is a separate product subscription, reCAPTCHA Enterprise, from
Cloud Armor Enterprise itself, see standard-vs-enterprise.md for that
distinction, both are referenced together here because they compose in
the redirect action.
