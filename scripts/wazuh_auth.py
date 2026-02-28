"""
wazuh_auth.py — Wazuh JWT Token Auto-Refresh Helper
Phase 4 — AI Agent component

The Wazuh REST API JWT token expires after 900 seconds.
This module refreshes it every 800 seconds to ensure uninterrupted agent operation.

Usage:
  from wazuh_auth import get_token
  token = get_token()  # always returns a valid token
"""

import time
import threading
import requests
import os
from dotenv import load_dotenv

load_dotenv()

WAZUH_HOST = os.getenv("WAZUH_HOST", "10.10.20.10")
WAZUH_PORT = os.getenv("WAZUH_PORT", "55000")
WAZUH_USER = os.getenv("WAZUH_USER", "wazuh-wui")
WAZUH_PASS = os.getenv("WAZUH_PASS", "")
VERIFY_SSL = os.getenv("WAZUH_VERIFY_SSL", "false").lower() != "true"

TOKEN_REFRESH_INTERVAL = 800  # seconds — before the 900s expiry

_token = None
_token_lock = threading.Lock()
_refresh_thread = None


def _fetch_token() -> str:
    """Fetch a fresh JWT token from the Wazuh API."""
    url = f"https://{WAZUH_HOST}:{WAZUH_PORT}/security/user/authenticate"
    response = requests.post(
        url,
        auth=(WAZUH_USER, WAZUH_PASS),
        verify=not VERIFY_SSL,
        timeout=10
    )
    response.raise_for_status()
    return response.json()["data"]["token"]


def _refresh_loop():
    """Background thread that refreshes the token every 800 seconds."""
    global _token
    while True:
        try:
            new_token = _fetch_token()
            with _token_lock:
                _token = new_token
            print(f"[wazuh_auth] Token refreshed successfully")
        except Exception as e:
            print(f"[wazuh_auth] Token refresh failed: {e}")
        time.sleep(TOKEN_REFRESH_INTERVAL)


def start_refresh_thread():
    """Start the background token refresh thread. Call once at startup."""
    global _refresh_thread
    if _refresh_thread is None or not _refresh_thread.is_alive():
        _refresh_thread = threading.Thread(target=_refresh_loop, daemon=True)
        _refresh_thread.start()


def get_token() -> str:
    """
    Get a valid JWT token. Fetches on first call, then returns cached value
    (background thread keeps it fresh). Thread-safe.
    """
    global _token
    with _token_lock:
        if _token is None:
            _token = _fetch_token()
            start_refresh_thread()
        return _token


if __name__ == "__main__":
    # Quick test
    print("Testing Wazuh token fetch...")
    token = get_token()
    print(f"Token obtained (first 20 chars): {token[:20]}...")
    print("Auto-refresh thread started. Ctrl+C to stop.")
    try:
        while True:
            time.sleep(60)
    except KeyboardInterrupt:
        print("Done.")
