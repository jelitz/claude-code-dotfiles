#!/usr/bin/env bash
#
# release-notes.sh — RELEASE-NOTES.md 에서 한 버전의 절 본문만 뽑아 stdout 으로 낸다.
# 제목 줄("## vX (날짜)")은 빼고, 다음 "## " 제목 직전까지를 낸다.
# GitHub Actions 릴리스 워크플로가 Release 본문으로 쓴다.
#
# 사용: bash scripts/release-notes.sh v2026.10.11
#
set -euo pipefail

tag="${1:?usage: release-notes.sh <tag>}"
notes="$(cd "$(dirname "$0")/.." && pwd)/RELEASE-NOTES.md"

body="$(awk -v tag="$tag" '
  { sub(/\r$/, "") }
  /^## / { if (found) exit; if ($2 == tag) { found = 1; next } }
  found { print }
' "$notes" | sed -e '/./,$!d')"

if [ -z "${body//[[:space:]]/}" ]; then
  echo "error: RELEASE-NOTES.md 에 '## $tag' 절이 없거나 비어 있습니다" >&2
  exit 1
fi

printf '%s\n' "$body"
