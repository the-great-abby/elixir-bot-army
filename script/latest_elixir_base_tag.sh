#!/usr/bin/env sh
# Output latest hexpm/elixir tag for Elixir 1.17 + debian-bookworm (for Dockerfile FROM).
# Usage: script/latest_elixir_base_tag.sh
# Requires: curl. Optional: jq (for parsing; otherwise uses a pinned default).
# Docker Hub rate-limits unauthenticated requests; this is for occasional use.

set -e

# Pinned fallback when API is unavailable or jq is missing (update periodically)
DEFAULT_TAG="1.17.0-erlang-26.2.5.4-debian-bookworm-20260202"

if ! command -v curl >/dev/null 2>&1; then
  echo "$DEFAULT_TAG"
  exit 0
fi

API_URL="https://hub.docker.com/v2/namespaces/hexpm/repositories/elixir/tags?page_size=100&name=1.17"

if command -v jq >/dev/null 2>&1; then
  TAG=$(curl -sL "$API_URL" 2>/dev/null | jq -r '.results[].name' 2>/dev/null | grep -E '^1\.17[.-].*debian-bookworm' | sort -t- -k9 -nr 2>/dev/null | head -1)
  if [ -n "$TAG" ]; then
    echo "$TAG"
    exit 0
  fi
fi

echo "$DEFAULT_TAG"
