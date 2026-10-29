---
name: gcloud-login
description: Logs gcloud in with the user's own Google account from this cloud session, which has no browser, for the gcloud CLI and Application Default Credentials (ADC), and revokes it after. Use for "log in to gcloud" or `gcloud auth login`, gcloud's 401s and permission errors, "Your default credentials were not found", and cleaning up gcloud after the work.
---

# Log in to gcloud without a browser

The login is the user's own account's, ADC included (`--update-adc`), so it carries the account's permissions, raised ones too while the user holds them.

The script is `scripts/gcloud-login.sh`, in this skill's directory.

## Log in

1. Run `status`. When the gcloud CLI has an account and ADC is valid, you're done.
2. Run `start`, and write the URL it prints in full in your reply's text: a command's output doesn't always reach the user's screen (the Claude app folds it), so a URL only in the output hasn't been given. The user opens it in their own browser, logs in, and pastes the verification code it shows into this chat. With the URL, tell them the rules under [The verification code](#the-verification-code).
3. Run `finish '<code>'`, which ends with `status`'s output.

The login waits for its code in files, which the VM keeps when it pauses while the user logs in, so `finish` works after the pause too.
Until `finish` succeeds, `start` prints the same URL again.

## The verification code

The page that shows the code warns that it's a credential, like a password, to share with no one: given to a login someone else started, it completes that login with your account.
Pasting into this chat the code of the URL this session's `start` printed isn't that:

- PKCE (`code_challenge_method=S256`) binds the code to the code verifier `start` keeps on the VM, so it can't be exchanged without it.
- The code works once and expires shortly (RFC 6749, 4.1.2), so once `finish` has exchanged it, the copy left in the chat's history is useless.

The rules:

- Open only a URL this session's `start` printed, and paste the code of no login URL from anywhere else.
- Paste the code only into the chat of the session that printed its URL, and `finish` at once. After a failure or a long wait, drop the code: the user opens the URL again for a new one.

## Once logged in

- Keep tokens out of the output: neither `print-access-token`'s output nor the whole of `env`.
- Use `gcloud storage` for Cloud Storage: `gsutil` is untried with this login.

## The placeholder `CLOUDSDK_AUTH_ACCESS_TOKEN`

A cloud session's VM sets `CLOUDSDK_AUTH_ACCESS_TOKEN` to a placeholder, which gcloud prefers to the account it's logged in to, and which only unsetting it removes; the cloud environment's setup script unsets it in `~/.bashrc`.
When `status` reports it set anyway, run these with `env -u CLOUDSDK_AUTH_ACCESS_TOKEN`:

- `gcloud`
- `bq`
- `docker-credential-gcloud`, Docker's credential helper for Artifact Registry
- Scripts that call `gcloud`

What uses ADC, such as Google's client libraries, ignores it.
With it set, `gcloud auth print-access-token` succeeds without a login, so check the login with `status`.

## When done

Run `revoke` once the work is done, and before the user raises their permissions: a login left in place keeps its token on the VM until Google's session control expires it, and carries the raised permissions while the user holds them.

`revoke` revokes ADC first, and with it the gcloud CLI's login, which holds the same token, so gcloud then warns that the account is `already inactive (previously revoked?)`: that's expected.
It's done when it ends with `No credentials of the gcloud CLI or ADC are left`, and fails otherwise.
