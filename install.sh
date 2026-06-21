#!/usr/bin/env bash
# install.sh — Competitive Programming C++ setup for macOS (Homebrew GCC)
# Run once (or after brew upgrade gcc) to install cpc/cprun and build PCH.
# Usage: bash install.sh [--uninstall]
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

# ── uninstall ─────────────────────────────────────────────────────────────
if [[ "${1:-}" == "--uninstall" ]]; then
    info "Uninstalling cpc / cprun …"
    rm -f /opt/homebrew/bin/cpc /opt/homebrew/bin/cprun
    rm -rf "${HOME}/.config/cp"
    ok "Uninstalled."
    exit 0
fi

echo -e "${BOLD}══════════════════════════════════════════════════════${RST}"
echo -e "${BOLD}  CP C++ Setup — Homebrew GCC + bits/stdc++.h + PCH  ${RST}"
echo -e "${BOLD}══════════════════════════════════════════════════════${RST}"
echo ""

# ── 1. Detect Homebrew GCC ────────────────────────────────────────────────
info "Detecting Homebrew GCC …"

GXX=""
HIGHEST=0
for bin in /opt/homebrew/bin/g++-*; do
    [[ -x "$bin" ]] || continue
    ver="${bin##*g++-}"
    # only match numeric version suffixes
    [[ "$ver" =~ ^[0-9]+$ ]] || continue
    if (( ver > HIGHEST )); then
        HIGHEST=$ver
        GXX="$bin"
    fi
done

if [[ -z "$GXX" ]]; then
    die "No Homebrew GCC found in /opt/homebrew/bin.\n  Fix: brew install gcc"
fi
GXX_CMD="$(basename "$GXX")"   # e.g. g++-16
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
if [[ ! -f "$DEBUG_H" ]]; then
    die "debug.h not found in ${SCRIPT_DIR} — run from the repo directory."
fi
cp "$DEBUG_H" "${CP_DIR}/include/debug.h"
ok "Installed debug.h → ${CP_DIR}/include/debug.h"

# ── 6. Precompile stdc++.h (debug) ───────────────────────────────────────
info "Precompiling stdc++.h [debug] …"
cp "$STDC_H" "${CP_DIR}/pch-debug/bits/stdc++.h"
# Flags must match cpc debug exactly so GCC recognises the PCH
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

# ── 7. Precompile stdc++.h (release) ─────────────────────────────────────
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

# ── 8. Write config file ──────────────────────────────────────────────────
cat > "${CP_DIR}/cp.conf" <<EOF
# Written by install.sh — re-run to refresh after brew upgrade gcc
CP_GXX="${GXX}"
CP_STD="${CP_STD}"
CP_DIR="${CP_DIR}"
EOF
ok "Config written → ${CP_DIR}/cp.conf"

# ── 9. Install cpc / cprun ────────────────────────────────────────────────
info "Installing cpc and cprun → /opt/homebrew/bin/ …"
for tool in cpc cprun; do
    SRC="${SCRIPT_DIR}/${tool}"
    [[ -f "$SRC" ]] || die "${tool} not found in ${SCRIPT_DIR}"
    cp "$SRC" "/opt/homebrew/bin/${tool}"
    chmod +x "/opt/homebrew/bin/${tool}"
done
ok "Installed /opt/homebrew/bin/cpc"
ok "Installed /opt/homebrew/bin/cprun"

# ── 10. VS Code + CPH configuration ──────────────────────────────────────
echo ""
info "Configuring VS Code + CPH …"

# Get the real GCC C++ include paths for IntelliSense (bash 3.2 compatible)
GCC_INCS=()
while IFS= read -r line; do
    GCC_INCS+=("$line")
done < <(
    "$GXX" -std="$CP_STD" -E -x c++ -v /dev/null 2>&1 \
    | awk '/#include <\.\.\.>/{p=1;next} /End of search/{p=0} p{gsub(/^ +/,""); print}' \
    | grep -v '(framework'
)

# Build IntelliSense includePath JSON array
INC_LINES=()
INC_LINES+=("                \"\${workspaceFolder}/**\"")
INC_LINES+=("                \"\${HOME}/.config/cp/include\"")
for inc in "${GCC_INCS[@]}"; do
    # normalise away /../ chains; skip non-existent and framework dirs
    if [[ -d "$inc" ]] && [[ "$inc" != *Frameworks* ]]; then
        norm="$(cd "$inc" 2>/dev/null && pwd)" && inc="$norm"
        INC_LINES+=("                \"${inc}\"")
    fi
done
# join with comma+newline
INC_JSON=""
for i in "${!INC_LINES[@]}"; do
    if (( i < ${#INC_LINES[@]} - 1 )); then
        INC_JSON+="${INC_LINES[$i]},"$'\n'
    else
        INC_JSON+="${INC_LINES[$i]}"
    fi
done

# Write c_cpp_properties.json directly with real paths
VSCODE_DIR="${HOME}/.vscode-cp"
mkdir -p "$VSCODE_DIR"
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
            "intelliSenseMode": "linux-gcc-arm64",
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

# CPH global settings — patch VS Code User settings.json
VSCODE_SETTINGS="${HOME}/Library/Application Support/Code/User/settings.json"
if [[ -f "$VSCODE_SETTINGS" ]]; then
    # Build the CPH block
    CPH_COMMAND="${GXX_CMD}"
    CPH_ARGS="-std=${CP_STD} -O2 -Wall -Wextra -Wshadow -DLOCAL -I${CP_DIR}/include -I${CP_DIR}/pch-debug -D_GLIBCXX_DEBUG -g -fsanitize=address,undefined -fno-sanitize-recover=all"

    # Use Python (ships with macOS) to safely merge JSON
    python3 - "$VSCODE_SETTINGS" "$CPH_COMMAND" "$CPH_ARGS" <<'PYEOF'
import json, sys
path, cmd, args = sys.argv[1], sys.argv[2], sys.argv[3]
with open(path) as f:
    cfg = json.load(f)
cfg["cph.language.cpp.Command"] = cmd
cfg["cph.language.cpp.Args"]    = args
with open(path, "w") as f:
    json.dump(cfg, f, indent=4)
    f.write("\n")
PYEOF
    ok "CPH settings written → VS Code User settings.json"
    ok "  cph.language.cpp.Command = ${CPH_COMMAND}"
    ok "  cph.language.cpp.Args    = ${CPH_ARGS}"
else
    warn "VS Code settings.json not found — skipping CPH auto-config."
    warn "Manually set in VS Code: cph.language.cpp.Command = ${GXX_CMD}"
fi

# ── 11. Self-test ─────────────────────────────────────────────────────────
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
cpc test.cpp 2>&1
OUTPUT=$(./test 2>/dev/null)
if [[ "$OUTPUT" == "OK" ]]; then
    ok "Self-test passed (cout output: '${OUTPUT}')"
else
    warn "Unexpected output: '${OUTPUT}'"
fi
popd > /dev/null

# ── Done ──────────────────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}${GRN}══ Setup complete! ══${RST}"
echo ""
echo -e "  ${BOLD}Compile (debug):${RST}   cpc sol.cpp"
echo -e "  ${BOLD}Compile (submit):${RST}  cpc -r sol.cpp"
echo -e "  ${BOLD}Compile + run:${RST}     cprun sol.cpp"
echo -e "  ${BOLD}Template:${RST}          cp ${SCRIPT_DIR}/template.cpp sol.cpp"
echo ""
echo -e "  ${YEL}Tip:${RST} re-run this script after 'brew upgrade gcc' to rebuild PCH."
echo ""
echo -e "${BOLD}VS Code setup:${RST}"
echo -e "  1. Copy .vscode/c_cpp_properties.json into your problem workspace:"
echo -e "     mkdir -p <workspace>/.vscode"
echo -e "     cp ${VSCODE_DIR}/c_cpp_properties.json <workspace>/.vscode/"
echo -e "  2. CPH extension: already configured in VS Code User settings."
echo -e "     Install: code --install-extension DivyanshuAgrawal.competitive-programming-helper"
echo ""
