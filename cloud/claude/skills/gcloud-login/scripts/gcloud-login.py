#!/usr/bin/env python3
"""Logs gcloud in with the user's own account in a Claude Code cloud session, which has no browser.

  gcloud-login.py start          Starts the login and prints the URL for the user to open
  gcloud-login.py finish <code>  Finishes it with the verification code the browser shows
  gcloud-login.py status         Shows the login, and the variables in the way of it
  gcloud-login.py revoke         Revokes the gcloud CLI's credentials and ADC
"""

# The VM can pause while the user logs in, which ends its processes and keeps its files, so the login waits in files:
# start keeps the PKCE code verifier, and finish exchanges the code with it, as `gcloud auth login --no-launch-browser
# --update-adc` would, then hands the refresh token to gcloud and writes ADC. No token is printed.

import base64
import hashlib
import json
import os
import secrets
import shutil
import subprocess
import sys
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path

STATE_DIR = Path.home() / ".local/state/gcloud-login"
VERIFIER = STATE_DIR / "verifier"
URL_FILE = STATE_DIR / "url"
CONFIG_DIR = Path(os.environ.get("CLOUDSDK_CONFIG") or Path.home() / ".config/gcloud")
ADC_FILE = CONFIG_DIR / "application_default_credentials.json"

# What gcloud's login URL asks for besides its client and PKCE challenge (tests/gcloud-login.bats compares the two)
REDIRECT_URI = "https://sdk.cloud.google.com/authcode.html"
SCOPES = [
    "openid",
    "https://www.googleapis.com/auth/userinfo.email",
    "https://www.googleapis.com/auth/cloud-platform",
    "https://www.googleapis.com/auth/appengine.admin",
    "https://www.googleapis.com/auth/sqlservice.login",
    "https://www.googleapis.com/auth/compute",
    "https://www.googleapis.com/auth/accounts.reauth",
]

# gcloud prefers a cloud session's placeholder token to the account it's logged in to: status reports whether the
# session still has it
PLACEHOLDER = bool(os.environ.pop("CLOUDSDK_AUTH_ACCESS_TOKEN", ""))


def base64url(data):
    return base64.urlsafe_b64encode(data).rstrip(b"=").decode()


# What gcloud prints; gcloud's failure fails the script
def gcloud(*args):
    return subprocess.run(["gcloud", *args], stdout=subprocess.PIPE, text=True, check=True).stdout.strip()


def start():
    if URL_FILE.exists():
        print("A login is already waiting for its code. Write this URL in full in your reply's text for the user:")
        print(URL_FILE.read_text())
        return

    verifier = base64url(secrets.token_bytes(48))
    params = {
        "response_type": "code",
        "client_id": gcloud("config", "get", "auth/client_id"),
        "redirect_uri": REDIRECT_URI,
        "scope": " ".join(SCOPES),
        "prompt": "consent",
        "token_usage": "remote",
        "access_type": "offline",
        "code_challenge": base64url(hashlib.sha256(verifier.encode()).digest()),
        "code_challenge_method": "S256",
    }
    url = gcloud("config", "get", "auth/auth_host") + "?" + urllib.parse.urlencode(params, quote_via=urllib.parse.quote)

    STATE_DIR.mkdir(mode=0o700, parents=True, exist_ok=True)
    VERIFIER.write_text(verifier)
    URL_FILE.write_text(url)
    print(
        "Write this URL in full in your reply's text for the user, and take the verification code shown after they"
        " log in:"
    )
    print(url)


# Google's answer to the code's exchange, which holds the tokens when it takes the code
def exchange(code, client_id, client_secret):
    form = {
        "grant_type": "authorization_code",
        "code": code,
        "code_verifier": VERIFIER.read_text(),
        "redirect_uri": REDIRECT_URI,
        "client_id": client_id,
        "client_secret": client_secret,
    }
    request = urllib.request.Request(gcloud("config", "get", "auth/token_host"), urllib.parse.urlencode(form).encode())
    try:
        with urllib.request.urlopen(request) as response:
            return json.load(response)
    except urllib.error.HTTPError as error:
        # Google refuses a code with its reason in JSON; any other answer isn't Google's
        try:
            return json.load(error)
        except ValueError:
            raise error from None


def finish(code):
    if not VERIFIER.exists():
        sys.exit("No login is waiting for its code: start one")

    client_id = gcloud("config", "get", "auth/client_id")
    client_secret = gcloud("config", "get", "auth/client_secret")
    tokens = exchange(code, client_id, client_secret)
    if "refresh_token" not in tokens:
        reason = ": ".join(tokens[key] for key in ("error", "error_description") if tokens.get(key))
        sys.exit(f"Google didn't take the code: {reason}\nThe user can open the same URL again for a new code")

    claims = tokens["id_token"].split(".")[1]
    account = json.loads(base64.urlsafe_b64decode(claims + "=" * (-len(claims) % 4)))["email"]
    # gcloud takes the token from its input when the command line leaves it out, and refreshes it before keeping it
    activated = subprocess.run(
        ["gcloud", "auth", "activate-refresh-token", account],
        input=tokens["refresh_token"] + "\n",
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
    )
    if activated.returncode:
        sys.exit(f"gcloud didn't take the login: {activated.stdout.strip()}")

    adc = {
        "type": "authorized_user",
        "account": "",
        "client_id": client_id,
        "client_secret": client_secret,
        "refresh_token": tokens["refresh_token"],
        "universe_domain": "googleapis.com",
    }
    with open(os.open(ADC_FILE, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o600), "w") as f:
        json.dump(adc, f, indent=2, sort_keys=True)
        f.write("\n")

    shutil.rmtree(STATE_DIR)
    status()


def status():
    account = subprocess.run(
        ["gcloud", "auth", "list", "--filter=status:ACTIVE", "--format=value(account)"],
        stdout=subprocess.PIPE,
        stderr=subprocess.DEVNULL,
        text=True,
    ).stdout.strip()
    print(f"gcloud CLI's account: {account or '(none)'}")

    adc = subprocess.run(
        ["gcloud", "auth", "application-default", "print-access-token"],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )
    print(f"ADC: {'invalid' if adc.returncode else 'valid'}")

    if PLACEHOLDER:
        print(
            "CLOUDSDK_AUTH_ACCESS_TOKEN is set: run gcloud and the tools that call it with"
            " env -u CLOUDSDK_AUTH_ACCESS_TOKEN (SKILL.md)"
        )


def revoke():
    # ADC holds the gcloud CLI's refresh token. Revoked after the CLI's, ADC's revoke gets invalid_token from the server
    # and fails without deleting its file, so ADC goes first. The CLI's revoke then takes invalid_token as already
    # revoked, warns "already inactive" and deletes the credentials.
    subprocess.run(["gcloud", "auth", "application-default", "revoke", "--quiet"])
    subprocess.run(["gcloud", "auth", "revoke", "--all", "--quiet"])
    status()

    remaining = []
    accounts = subprocess.run(
        ["gcloud", "auth", "list", "--format=value(account)"],
        stdout=subprocess.PIPE,
        stderr=subprocess.DEVNULL,
        text=True,
    ).stdout.strip()
    if accounts:
        remaining.append("the gcloud CLI's credentials")
    if ADC_FILE.exists():
        remaining.append(f"ADC's file {ADC_FILE}")
    if remaining:
        sys.exit(f"Left unrevoked: {' '.join(remaining)}")
    print("No credentials of the gcloud CLI or ADC are left")


# Each line goes out as it's printed, in its order with gcloud's output and the errors on stderr
sys.stdout.reconfigure(line_buffering=True)

match sys.argv[1:]:
    case ["start"]:
        start()
    case ["finish", code]:
        finish(code)
    case ["status"]:
        status()
    case ["revoke"]:
        revoke()
    case _:
        sys.exit(__doc__.strip())
