#!/usr/bin/env bash
# install.sh — Competitive Programming C++ setup for macOS (Homebrew GCC)
#
# Usage:
#   bash install.sh                    global install  → /opt/homebrew/bin/
#   bash install.sh --prefix ~/.local  user install    → ~/.local/bin/
#   bash install.sh --local            per-project     → ./bin/  (current dir)
#   bash install.sh --uninstall        remove global install + ~/.config/cp
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── ANSI ─────────────────────────────────────────────────────────────────
RED="\033[0;31m"; GRN="\033[0;32m"; YEL="\033[0;33m"
CYN="\033[0;36m"; BOLD="\033[1m"; RST="\033[0m"
ok()   { echo -e "${GRN}✓${RST} $*"; }
info() { echo -e "${CYN}→${RST} $*"; }
warn() { echo -e "${YEL}!${RST} $*"; }
die()  { echo -e "${RED}✗ ERROR:${RST} $*" >&2; exit 1; }

# ── Homebrew prefix (/opt/homebrew on Apple Silicon, /usr/local on Intel) ──
brew_prefix() {
    local p=""
    if command -v brew >/dev/null 2>&1; then
        p="$(brew --prefix 2>/dev/null)" || p=""
    fi
    if [[ -z "$p" ]]; then
        local cand
        for cand in /opt/homebrew /usr/local; do
            [[ -x "${cand}/bin/brew" ]] && { echo "$cand"; return 0; }
        done
    fi
    [[ -n "$p" ]] || return 1
    echo "$p"
}

# ── parse top-level flags ─────────────────────────────────────────────────
BREW_PREFIX="$(brew_prefix 2>/dev/null || echo /opt/homebrew)"
BREW_BIN="${BREW_PREFIX}/bin"
LOCAL_INSTALL=0
UNINSTALL=0
INSTALL_PREFIX=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --uninstall) UNINSTALL=1; shift ;;
        --prefix)
            [[ -z "${2:-}" ]] && die "--prefix requires a path (e.g. --prefix ~/.local)"
            INSTALL_PREFIX="$(eval echo "$2")"   # expand ~ if present
            shift 2
            ;;
        --local)
            LOCAL_INSTALL=1
            INSTALL_PREFIX="$(pwd)/bin"
            shift
            ;;
        *)
            die "unknown option '$1'  (usage: bash install.sh [--prefix DIR | --local | --uninstall])"
            ;;
    esac
done

if (( UNINSTALL )); then
    info "Uninstalling cpc / cprun / cpnew / setup-cpp …"
    if [[ -n "$INSTALL_PREFIX" ]]; then
        targets=("$INSTALL_PREFIX")
    else
        targets=("/opt/homebrew/bin" "/usr/local/bin")
    fi
    for t in "${targets[@]}"; do
        for tool in cpc cprun cpnew setup-cpp; do
            rm -f "${t}/${tool}" 2>/dev/null || true
        done
    done
    rm -rf "${HOME}/.config/cp"
    ok "Uninstalled."
    exit 0
fi

INSTALL_PREFIX="${INSTALL_PREFIX:-${BREW_BIN}}"

echo -e "${BOLD}══════════════════════════════════════════════════════${RST}"
echo -e "${BOLD}  CP C++ Setup — Homebrew GCC + bits/stdc++.h + PCH  ${RST}"
echo -e "${BOLD}══════════════════════════════════════════════════════${RST}"
echo -e "  Install prefix: ${BOLD}${INSTALL_PREFIX}${RST}"
echo ""

# ── 1. Detect Homebrew GCC ────────────────────────────────────────────────
info "Detecting Homebrew GCC …"

GXX=""
HIGHEST=0
for bin in "${BREW_BIN}"/g++-*; do
    [[ -x "$bin" ]] || continue
    ver="${bin##*g++-}"
    [[ "$ver" =~ ^[0-9]+$ ]] || continue
    if (( ver > HIGHEST )); then
        HIGHEST=$ver
        GXX="$bin"
    fi
done

if [[ -z "$GXX" ]]; then
    die "No Homebrew GCC found in ${BREW_BIN}.\n  Fix: brew install gcc"
fi
GXX_CMD="$(basename "$GXX")"
ok "Found: ${GXX}  ($("$GXX" --version | head -1))"

# ── 2. C++ standard ───────────────────────────────────────────────────────
CP_STD="c++20"
info "C++ standard: ${CP_STD}"

# ── 3. Locate bits/stdc++.h shipped with this GCC ────────────────────────
info "Locating bits/stdc++.h …"
STDC_H="$(echo '#include <bits/stdc++.h>' \
    | "$GXX" -std="$CP_STD" -E -x c++ - 2>/dev/null \
    | grep -m1 'stdc++\.h' \
    | sed 's/^# [0-9]* "//;s/".*//')" || true

if [[ -z "$STDC_H" ]] || [[ ! -f "$STDC_H" ]]; then
    die "Could not locate bits/stdc++.h — Homebrew GCC installation may be incomplete."
fi
ok "bits/stdc++.h → ${STDC_H}"

# ── 4. Create ~/.config/cp directory layout ───────────────────────────────
CP_DIR="${HOME}/.config/cp"
info "Setting up ${CP_DIR} …"
mkdir -p "${CP_DIR}/include"
mkdir -p "${CP_DIR}/pch-debug/bits"
mkdir -p "${CP_DIR}/pch-release/bits"

# ── 5. Install debug.h ────────────────────────────────────────────────────
DEBUG_H="${SCRIPT_DIR}/debug.h"
[[ -f "$DEBUG_H" ]] || die "debug.h not found in ${SCRIPT_DIR} — run from the repo directory."
cp "$DEBUG_H" "${CP_DIR}/include/debug.h"
ok "debug.h → ${CP_DIR}/include/debug.h  (globally accessible via #include \"debug.h\")"

# ── 6. Install template.cpp ───────────────────────────────────────────────
TMPL="${SCRIPT_DIR}/template.cpp"
[[ -f "$TMPL" ]] || die "template.cpp not found in ${SCRIPT_DIR}."
cp "$TMPL" "${CP_DIR}/template.cpp"
ok "template.cpp → ${CP_DIR}/template.cpp  (used by cpnew)"

# ── 7. Precompile stdc++.h (debug) ───────────────────────────────────────
info "Precompiling stdc++.h [debug] …"
cp "$STDC_H" "${CP_DIR}/pch-debug/bits/stdc++.h"
"$GXX" \
    -std="$CP_STD" -O2 \
    -Wall -Wextra -Wshadow -Wconversion \
    -D_GLIBCXX_DEBUG -DLOCAL -g \
    -fsanitize=address,undefined \
    -fno-sanitize-recover=all \
    -I"${CP_DIR}/include" \
    -x c++-header \
    "${CP_DIR}/pch-debug/bits/stdc++.h" \
    -o "${CP_DIR}/pch-debug/bits/stdc++.h.gch"
ok "PCH [debug]   → ${CP_DIR}/pch-debug/bits/stdc++.h.gch"

# ── 8. Precompile stdc++.h (release) ─────────────────────────────────────
info "Precompiling stdc++.h [release] …"
cp "$STDC_H" "${CP_DIR}/pch-release/bits/stdc++.h"
"$GXX" \
    -std="$CP_STD" -O2 \
    -Wall -Wextra -Wshadow -Wconversion \
    -I"${CP_DIR}/include" \
    -x c++-header \
    "${CP_DIR}/pch-release/bits/stdc++.h" \
    -o "${CP_DIR}/pch-release/bits/stdc++.h.gch"
ok "PCH [release] → ${CP_DIR}/pch-release/bits/stdc++.h.gch"

# ── 9. Write global config ────────────────────────────────────────────────
cat > "${CP_DIR}/cp.conf" <<EOF
# Written by install.sh — re-run to refresh after brew upgrade gcc
CP_GXX="${GXX}"
CP_STD="${CP_STD}"
CP_DIR="${CP_DIR}"
EOF
ok "Config → ${CP_DIR}/cp.conf"

# ── 10. Install cpc / cprun / cpnew ──────────────────────────────────────
info "Installing tools → ${INSTALL_PREFIX}/ …"
mkdir -p "$INSTALL_PREFIX"
for tool in cpc cprun cpnew setup-cpp; do
    SRC="${SCRIPT_DIR}/${tool}"
    [[ -f "$SRC" ]] || die "${tool} not found in ${SCRIPT_DIR}"
    cp "$SRC" "${INSTALL_PREFIX}/${tool}"
    chmod +x "${INSTALL_PREFIX}/${tool}"
    ok "  ${INSTALL_PREFIX}/${tool}"
done

# For --local installs, remind user to add bin/ to PATH if needed
if [[ $LOCAL_INSTALL -eq 1 ]]; then
    echo ""
    warn "Per-project install: tools are in ${INSTALL_PREFIX}/"
    warn "Run them as  ./bin/cpc  or add to PATH:"
    warn "  export PATH=\"\$(pwd)/bin:\$PATH\""
fi

# For --prefix installs outside Homebrew, check if prefix is on PATH
if [[ $LOCAL_INSTALL -eq 0 ]] && [[ "$INSTALL_PREFIX" != "$BREW_BIN" ]]; then
    if ! echo "$PATH" | tr ':' '\n' | grep -qx "$INSTALL_PREFIX"; then
        warn "${INSTALL_PREFIX} is not on your PATH."
        warn "Add to ~/.zshrc:  export PATH=\"${INSTALL_PREFIX}:\$PATH\""
    fi
fi

# ── 11. VS Code + CPH configuration ──────────────────────────────────────
echo ""
info "Configuring VS Code + CPH …"

GCC_INCS=()
while IFS= read -r line; do
    GCC_INCS+=("$line")
done < <(
    "$GXX" -std="$CP_STD" -E -x c++ -v /dev/null 2>&1 \
    | awk '/#include <\.\.\.>/{p=1;next} /End of search/{p=0} p{gsub(/^ +/,""); print}' \
    | grep -v '(framework'
)

INC_LINES=()
INC_LINES+=("                \"\${workspaceFolder}/**\"")
INC_LINES+=("                \"\${HOME}/.config/cp/include\"")
for inc in "${GCC_INCS[@]}"; do
    if [[ -d "$inc" ]] && [[ "$inc" != *Frameworks* ]]; then
        norm="$(cd "$inc" 2>/dev/null && pwd)" && inc="$norm"
        INC_LINES+=("                \"${inc}\"")
    fi
done
INC_JSON=""
for i in "${!INC_LINES[@]}"; do
    if (( i < ${#INC_LINES[@]} - 1 )); then
        INC_JSON+="${INC_LINES[$i]},"$'\n'
    else
        INC_JSON+="${INC_LINES[$i]}"
    fi
done

VSCODE_DIR="${HOME}/.vscode-cp"
mkdir -p "$VSCODE_DIR"
ARCH_MODE="linux-gcc-arm64"
if [[ "$(uname -m)" == "x86_64" ]]; then ARCH_MODE="linux-gcc-x64"; fi
cat > "${VSCODE_DIR}/c_cpp_properties.json" <<JSONEOF
{
    "configurations": [
        {
            "name": "Mac (Homebrew GCC)",
            "includePath": [
${INC_JSON}
            ],
            "defines": [
                "LOCAL",
                "_GLIBCXX_DEBUG"
            ],
            "compilerPath": "${GXX}",
            "cppStandard": "${CP_STD}",
            "intelliSenseMode": "${ARCH_MODE}",
            "compilerArgs": [
                "-std=${CP_STD}",
                "-Wall",
                "-Wextra"
            ]
        }
    ],
    "version": 4
}
JSONEOF
ok "c_cpp_properties.json → ${VSCODE_DIR}/c_cpp_properties.json"

VSCODE_SETTINGS="${HOME}/Library/Application Support/Code/User/settings.json"
# settings.json is JSONC (comments + trailing commas are legal) — plain
# json.load() chokes on it, so strip comments before parsing. Parse failure
# must never abort the install. Missing file → created.
if command -v python3 >/dev/null 2>&1; then
    CPH_COMMAND="${GXX_CMD}"
    CPH_ARGS="-std=${CP_STD} -O2 -Wall -Wextra -Wshadow -DLOCAL -I${CP_DIR}/include -I${CP_DIR}/pch-debug -D_GLIBCXX_DEBUG -g -fsanitize=address,undefined -fno-sanitize-recover=all"
    if python3 - "$VSCODE_SETTINGS" "$CPH_COMMAND" "$CPH_ARGS" <<'PYEOF'
import json, os, sys

path, cmd, args = sys.argv[1], sys.argv[2], sys.argv[3]

def load_jsonc(path):
    """Parse JSON with // and /* */ comments and trailing commas allowed.
    Returns (dict, had_comments). Raises on genuinely malformed input."""
    if not os.path.exists(path) or os.path.getsize(path) == 0:
        return {}, False
    with open(path) as f:
        text = f.read()
    out = []
    had_comments = False
    i, n = 0, len(text)
    in_str = False
    while i < n:
        c = text[i]
        if in_str:
            out.append(c)
            if c == "\\" and i + 1 < n:
                out.append(text[i + 1])
                i += 1
            elif c == '"':
                in_str = False
            i += 1
            continue
        if c == '"':
            in_str = True
            out.append(c)
            i += 1
            continue
        if text[i:i+2] == "//":
            had_comments = True
            while i < n and text[i] != "\n":
                i += 1
            continue
        if text[i:i+2] == "/*":
            had_comments = True
            i += 2
            while i < n and text[i:i+2] != "*/":
                i += 1
            i = min(i + 2, n)
            continue
        if c == ",":
            # trailing comma: only whitespace/comments before } or ] → drop it
            j = i + 1
            while j < n:
                if text[j] in " \t\r\n":
                    j += 1
                elif text[j:j+2] == "//":
                    while j < n and text[j] != "\n":
                        j += 1
                elif text[j:j+2] == "/*":
                    j += 2
                    while j < n and text[j:j+2] != "*/":
                        j += 1
                    j = min(j + 2, n)
                else:
                    break
            if j < n and text[j] in "}]":
                i += 1
                continue
        out.append(c)
        i += 1
    stripped = "".join(out)
    if not stripped.strip():
        return {}, had_comments
    return json.loads(stripped), had_comments

cfg, had_comments = load_jsonc(path)
cfg["cph.language.cpp.Command"] = cmd
cfg["cph.language.cpp.Args"]    = args
d = os.path.dirname(path)
if d:
    os.makedirs(d, exist_ok=True)
with open(path, "w") as f:
    json.dump(cfg, f, indent=4)
    f.write("\n")
if had_comments:
    sys.stderr.write("       note: comments in settings.json were removed when rewriting it\n")
PYEOF
    then
        ok "CPH → VS Code User settings.json  (command=${CPH_COMMAND})"
    else
        warn "Could not update VS Code settings.json — set CPH manually:"
        warn "  \"cph.language.cpp.Command\": \"${GXX_CMD}\""
    fi
else
    warn "python3 not found — set CPH manually: cph.language.cpp.Command = ${GXX_CMD}"
fi

# ── 12. Self-test ─────────────────────────────────────────────────────────
echo ""
info "Running self-test …"
TMPDIR_TEST="$(mktemp -d)"
trap 'rm -rf "$TMPDIR_TEST"' EXIT

cat > "${TMPDIR_TEST}/test.cpp" <<'CPPEOF'
#include <bits/stdc++.h>
#include "debug.h"
using namespace std;
int main() {
    vector<pair<int,int>> v = {{1,2},{3,4}};
    map<int,int> m = {{5,6},{7,8}};
    dbg(v, m);
    cout << "OK\n";
}
CPPEOF

pushd "$TMPDIR_TEST" > /dev/null
if "${INSTALL_PREFIX}/cpc" test.cpp; then
    OUTPUT=$(./test 2>/dev/null)
    if [[ "$OUTPUT" == "OK" ]]; then
        ok "Self-test passed"
    else
        warn "Unexpected output: '${OUTPUT}'"
    fi
else
    warn "Self-test compile failed — see compiler output above"
fi
popd > /dev/null

# ── Done ──────────────────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}${GRN}══ Setup complete! ══${RST}"
echo ""
echo -e "  ${BOLD}New problem:${RST}       cpnew              → sol.cpp"
echo -e "  ${BOLD}New contest:${RST}       cpnew A B C D E    → A.cpp … E.cpp"
echo -e "  ${BOLD}New workspace:${RST}     cpnew --dir round  → round/ with .vscode/"
echo ""
echo -e "  ${BOLD}Compile (debug):${RST}   cpc sol.cpp"
echo -e "  ${BOLD}Compile (submit):${RST}  cpc -r sol.cpp"
echo -e "  ${BOLD}Compile + run:${RST}     cprun sol.cpp"
echo ""
echo -e "  ${YEL}Note:${RST} #include \"debug.h\" works from ANY directory — never copy it."
echo -e "  ${YEL}Tip:${RST}  re-run this script after 'brew upgrade gcc' to rebuild PCH."
echo ""
echo -e "${BOLD}Install modes:${RST}"
echo -e "  Homebrew:         brew tap will702/setup-cpp https://github.com/will702/setup-cpp"
echo -e "                    brew install setup-cpp && setup-cpp init"
echo -e "  Global (default): bash install.sh"
echo -e "  User:             bash install.sh --prefix ~/.local"
echo -e "  Per-project:      bash install.sh --local  (installs to ./bin/)"
echo ""
