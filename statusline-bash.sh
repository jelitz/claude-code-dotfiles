#!/usr/bin/env bash
# Claude Code statusLine (2 lines):
#   row 1 (identity): ⎇ branch │ ◈ model │ effort │ ⚖ advisor: <model>
#   row 2 (usage):    ctx bar% │ $cost │ 5h bar% ↻ left │ [7d bar%] │ vX.Y.Z

input=$(cat)

# read advisorModel from ~/.claude/settings.json (independent of stdin payload)
advisor=$(python -c "
import json, os
try:
    p = os.path.expanduser('~/.claude/settings.json')
    with open(p, 'r', encoding='utf-8') as f:
        s = json.load(f)
    v = s.get('advisorModel')
    print(v if v else '')
except Exception:
    print('')
" 2>/dev/null)

read_json=$(printf '%s' "$input" | python -c "
import json, sys, time
try:
    d = json.load(sys.stdin)
    cwd = (d.get('workspace') or {}).get('current_dir') or d.get('cwd') or ''
    model = (d.get('model') or {}).get('display_name') or ''
    version = d.get('version') or ''
    ctx = (d.get('context_window') or {}).get('used_percentage')
    cost = (d.get('cost') or {}).get('total_cost_usd')
    effort = (d.get('effort') or {}).get('level') or ''
    rl = d.get('rate_limits') or {}
    fh = (rl.get('five_hour') or {}).get('used_percentage')
    sd = (rl.get('seven_day') or {}).get('used_percentage')
    fh_resets = (rl.get('five_hour') or {}).get('resets_at')
    fh_left = ''
    if fh_resets:
        rem = int(fh_resets) - int(time.time())
        if rem > 0:
            h, m = divmod(rem // 60, 60)
            fh_left = f'{h}h{m:02d}m' if h else f'{m}m'
        else:
            fh_left = '0m'
    print(cwd)
    print(model)
    print('' if ctx is None else ctx)
    print('' if cost is None else f'{cost:.2f}')
    print(effort)
    print('' if fh is None else fh)
    print('' if sd is None else sd)
    print(fh_left)
    print(version)
except Exception:
    for _ in range(9):
        print()
" 2>/dev/null)

cwd=$(printf       '%s\n' "$read_json" | sed -n '1p')
model=$(printf     '%s\n' "$read_json" | sed -n '2p')
ctx_pct=$(printf   '%s\n' "$read_json" | sed -n '3p')
cost_usd=$(printf  '%s\n' "$read_json" | sed -n '4p')
effort=$(printf    '%s\n' "$read_json" | sed -n '5p')
five_hour=$(printf '%s\n' "$read_json" | sed -n '6p')
seven_day=$(printf '%s\n' "$read_json" | sed -n '7p')
fh_left=$(printf   '%s\n' "$read_json" | sed -n '8p')
version=$(printf   '%s\n' "$read_json" | sed -n '9p')

[ -z "$cwd" ] && cwd=$PWD

branch=$(git --no-optional-locks -C "$cwd" branch --show-current 2>/dev/null)

e=$'\033'
GREEN="${e}[32m"
MAGENTA="${e}[35m"
YELLOW="${e}[33m"
CYAN="${e}[36m"
BLUE="${e}[34m"
RED="${e}[31m"
DIM="${e}[2m"
RESET="${e}[0m"

# 8-char progress bar (█ filled, ░ empty)
bar() {
  local pct=${1%.*}
  pct=${pct:-0}
  [[ $pct -gt 100 ]] && pct=100
  local filled=$(( pct * 8 / 100 ))
  local empty=$(( 8 - filled ))
  local b=""
  for ((i=0; i<filled; i++)); do b+="█"; done
  for ((i=0; i<empty; i++)); do b+="░"; done
  printf '%s' "$b"
}

# green <50, yellow <80, red ≥80
pct_color() {
  local p=${1%.*}
  if [[ ${p:-0} -ge 80 ]]; then printf '%s' "$RED"
  elif [[ ${p:-0} -ge 50 ]]; then printf '%s' "$YELLOW"
  else printf '%s' "$GREEN"
  fi
}

# cost: dim <$1, yellow $1–$4, red ≥$5
cost_color() {
  local whole=${1%.*}
  if [[ ${whole:-0} -ge 5 ]]; then printf '%s' "$RED"
  elif [[ ${whole:-0} -ge 1 ]]; then printf '%s' "$YELLOW"
  else printf '%s' "$DIM"
  fi
}

# effort level → compact height glyph
effort_sym() {
  case "$1" in
    low)    printf '▁' ;;
    medium) printf '▄' ;;
    high)   printf '▇' ;;
    *)      printf '%s' "$1" ;;
  esac
}

# append with │ separator (one helper per row)
row1=""
row2=""
add1() { [ -n "$row1" ] && row1+=" ${DIM}│${RESET} "; row1+="$1"; }
add2() { [ -n "$row2" ] && row2+=" ${DIM}│${RESET} "; row2+="$1"; }

# === row 1: identity (branch / model / effort / advisor) ===

# ⎇ branch
[ -n "$branch" ] && add1 "${CYAN}⎇ ${branch}${RESET}"

# ◈ model  (strip leading "Claude ")
if [ -n "$model" ]; then
  short_model="${model#Claude }"
  add1 "${BLUE}◈ ${short_model}${RESET}"
fi

# effort as text
if [ -n "$effort" ]; then
  add1 "${MAGENTA}effort: ${effort}${RESET}"
fi

# ⚖ advisor model (from settings.json) — show "(unset)" when no value
if [ -n "$advisor" ]; then
  add1 "${YELLOW}⚖ advisor: ${advisor}${RESET}"
else
  add1 "${DIM}⚖ advisor: (unset)${RESET}"
fi

# === row 2: usage (ctx / cost / rate limits / version) ===

# ctx progress bar
if [ -n "$ctx_pct" ]; then
  col=$(pct_color "$ctx_pct")
  add2 "${DIM}ctx${RESET} ${col}$(bar "$ctx_pct") ${ctx_pct}%${RESET}"
fi

# $cost
if [ -n "$cost_usd" ]; then
  col=$(cost_color "$cost_usd")
  add2 "${col}\$${cost_usd}${RESET}"
fi

# 5h rate limit: bar + % + ↻ reset time
if [ -n "$five_hour" ]; then
  col=$(pct_color "$five_hour")
  fh_str="${DIM}5h${RESET} ${col}$(bar "$five_hour") ${five_hour}%${RESET}"
  [ -n "$fh_left" ] && fh_str+="${DIM} ↻ ${fh_left}${RESET}"
  add2 "$fh_str"
fi

# 7d rate limit: only when ≥ 10%
if [ -n "$seven_day" ]; then
  sd_val=${seven_day%.*}
  if [[ ${sd_val:-0} -ge 10 ]]; then
    col=$(pct_color "$seven_day")
    add2 "${DIM}7d${RESET} ${col}$(bar "$seven_day") ${seven_day}%${RESET}"
  fi
fi

# version (dim, no separator — appended at end of row 2)
[ -n "$version" ] && row2+="  ${DIM}v${version}${RESET}"

printf '%s\n' "$row1"
printf '%s\n' "$row2"
