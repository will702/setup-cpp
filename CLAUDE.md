# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

A self-contained macOS toolchain for competitive programming in C++. It wraps Homebrew GCC (`g++-NN`) to provide `bits/stdc++.h`, precompiled headers, sanitizers, and a debug pretty-printer — none of which work with the default Apple clang.

After running `bash install.sh`, three commands become available globally: `cpc`, `cprun`, `cpnew`.

## Runtime layout (created by install.sh, not in repo)

```
~/.config/cp/
  cp.conf              # CP_GXX, CP_STD, CP_DIR — sourced by cpc/cprun/cpnew
  template.cpp         # copy of repo template.cpp, used by cpnew
  include/debug.h      # copy of repo debug.h, always on -I path
  pch-debug/bits/      # stdc++.h + stdc++.h.gch (debug flags)
  pch-release/bits/    # stdc++.h + stdc++.h.gch (release flags)
~/.vscode-cp/
  c_cpp_properties.json  # IntelliSense config (cpnew --dir copies this)
```

## Key invariant: PCH flag matching

`install.sh` precompiles `stdc++.h` with the **exact same flags** that `cpc` later uses at compile time. If flags in `cpc` are changed (e.g. adding `-march=native`), the PCH steps in `install.sh` must be updated to match, or GCC will silently fall back to a slower full parse. The debug and release PCH are separate because their flag sets differ.

## Compiler detection

`install.sh` and `cpc`/`cprun`/`cpnew` all resolve the compiler at runtime by scanning `/opt/homebrew/bin/g++-*` and picking the highest numeric suffix. The result is written to `~/.config/cp/cp.conf` as `CP_GXX`. This means the repo contains no hardcoded version number — `g++-16` today, `g++-17` after `brew upgrade gcc`.

## Config layering in `cpc`

`cpc` sources `~/.config/cp/cp.conf` first, then walks up the directory tree looking for a `.cpcrc` file. `.cpcrc` can override `CP_STD` or add `EXTRA_FLAGS`. This is the intended per-project customisation point — not editing `cpc` itself.

## `debug.h` architecture

- Single `print(ostream&, const T&)` template using `if constexpr` dispatch — intentionally one function, not overloads. This avoids overload-resolution ambiguity when `_GLIBCXX_DEBUG` renames containers to `std::__debug::vector` etc.
- Special cases ordered: pair → tuple → string → bitset → `vector<bool>` (proxy-ref) → stack/queue/pqueue → generic iterable → bool → char → scalar.
- `vector<bool>` is detected via `has_proxy_ref<T>` (checks `value_type == bool && !is_reference_v<reference>`), not by name, so it catches `__debug::vector<bool>` too.
- `dbg(...)` uses a C++20 template lambda to turn `__VA_ARGS__` into a real parameter pack for the fold expression. This requires `-std=c++20` or later.
- All macros expand to `do {} while(0)` when `LOCAL` is not defined — safe to leave `dbg()` calls in submitted code.

## Install modes

| Command | Installs to | Use case |
|---|---|---|
| `bash install.sh` | `/opt/homebrew/bin/` | default, already on PATH |
| `bash install.sh --prefix ~/.local` | `~/.local/bin/` | avoid writing to Homebrew |
| `bash install.sh --local` | `./bin/` | per-project, shared repo |
| `bash install.sh --uninstall` | removes global + `~/.config/cp` | clean slate |

## Updating the setup

After `brew upgrade gcc`: re-run `bash install.sh` from this directory. This re-detects the new `g++-NN`, copies the new `bits/stdc++.h`, rebuilds both PCH files, and reinstalls the tools.

After editing `debug.h` or `template.cpp` in this repo: re-run `bash install.sh` to push changes to `~/.config/cp/`.

## Testing changes

There is no test suite. Validate by running the self-test baked into `install.sh`:

```bash
bash install.sh   # runs self-test at the end automatically
```

Or manually:

```bash
cpnew && cpc sol.cpp && ./sol          # debug build from fresh template
cpc -r sol.cpp && ./sol                # release build
```

To test `debug.h` type coverage (pair, map, bitset, vector<bool>, nested containers):

```bash
# from any directory — debug.h is globally accessible, no copying needed
cat > /tmp/t.cpp << 'EOF'
#include <bits/stdc++.h>
#include "debug.h"
using namespace std;
int main() {
    vector<pair<int,int>> v={{1,2}}; map<int,int> m={{3,4}};
    bitset<4> bs("1010"); vector<bool> vb={true,false};
    dbg(v, m, bs, vb);
}
EOF
cpc /tmp/t.cpp && /tmp/t
```
