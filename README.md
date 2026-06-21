# Competitive Programming C++ Setup (macOS)

One-shot installer for **Homebrew GCC** + `<bits/stdc++.h>` + precompiled headers + debug pretty-printer.

---

## Quick start

```bash
# 1. Install Homebrew GCC if you haven't already
brew install gcc          # installs g++-16 (or latest)

# 2. Run the installer (from this directory)
bash install.sh

# 3. Start a new problem
cp template.cpp sol.cpp   # copy the starter

# 4. Edit, compile, run
cpc sol.cpp               # debug build (ASan + UBSan + dbg() enabled)
cprun sol.cpp             # compile + run in one shot
./sol                     # run again without recompiling

# 5. Submit
cpc -r sol.cpp            # release build (no sanitizers, no debug overhead)
./sol                     # verify output matches expected
```

---

## Why Homebrew GCC instead of Apple clang?

| Feature | Apple clang (`/usr/bin/g++`) | Homebrew GCC (`g++-16`) |
|---|---|---|
| `<bits/stdc++.h>` | ❌ not included | ✅ ships with GCC |
| `__int128` | partial | ✅ full support |
| `__builtin_popcount` / `__builtin_clz` | partial | ✅ |
| Policy-based data structures `<ext/pb_ds/…>` | ❌ | ✅ |
| GNU `__attribute__((optimize(…)))` | ❌ | ✅ |
| Matches Codeforces G++20 judge | ❌ | ✅ |

---

## Commands

### `cpc` — compile

```
cpc sol.cpp              # debug build (default)
cpc -r sol.cpp           # release / submit build
cpc --submit sol.cpp     # same as -r
cpc -h                   # help
```

### `cprun` — compile + run

```
cprun sol.cpp            # debug build, auto-reads in.txt if it exists
cprun -r sol.cpp         # release build + run
```

**Tip:** Create `in.txt` in your problem directory. `cprun` feeds it automatically in debug mode — no more copy-pasting sample input.

---

## Debug flags (default build)

| Flag | What it does |
|---|---|
| `-O2` | Fast enough for local testing |
| `-Wall -Wextra -Wshadow -Wconversion` | Catch common mistakes (shadowed vars, narrowing) |
| `-DLOCAL` | Activates `dbg()` in debug.h |
| `-D_GLIBCXX_DEBUG` | Bounds-checks `vector[]`, `string[]`, iterator validity |
| `-fsanitize=address` | Detects heap/stack buffer overflows, use-after-free |
| `-fsanitize=undefined` | Catches signed overflow, null dereference, bad shifts |
| `-fno-sanitize-recover=all` | Abort immediately on first error (don't continue) |
| `-g` | Debug symbols (readable sanitizer stack traces) |

## Release flags (`cpc -r`)

```
-std=c++20 -O2 -Wall -Wextra -Wshadow -Wconversion
```

No sanitizers, no `LOCAL`, no `_GLIBCXX_DEBUG` — exactly what a judge runs.

---

## `debug.h` — pretty-printing data structures

Include it **after** `<bits/stdc++.h>`:

```cpp
#include <bits/stdc++.h>
#include "debug.h"
```

### `dbg(expr [, expr …])` — print values with source location

```cpp
int n = 5;
vector<pair<int,int>> v = {{1,2},{3,4}};
map<int,vector<int>> m = {{0,{10,20}},{1,{30}}};
dbg(n);          // [sol.cpp:12] n = 5
dbg(v, m);       // [sol.cpp:13] v = [(1, 2), (3, 4)]  m = {0: [10, 20], 1: [30]}
```

Supported types (including **nested**):

| Type | Output format |
|---|---|
| `int`, `ll`, `double`, … | `42` |
| `bool` | `true` / `false` (green/red in TTY) |
| `char` | `'x'` |
| `string` | `"hello"` |
| `pair<A,B>` | `(a, b)` |
| `tuple<…>` | `(a, b, c)` |
| `vector`, `array`, `deque`, `list` | `[a, b, c]` |
| `set`, `multiset` | `[a, b, c]` |
| `map`, `multimap` | `{k: v, k: v}` |
| `stack`, `queue`, `priority_queue` | `[a, b, c]` (copied) |
| Nested e.g. `vector<pair<int,int>>` | `[(1, 2), (3, 4)]` |

### `dbg_arr(arr, n)` — 1-D array with index labels

```cpp
int a[] = {10, 20, 30};
dbg_arr(a, 3);
// [sol.cpp:5] a = [0:10, 1:20, 2:30]
```

### `dbg_grid(grid, rows, cols)` — 2-D grid

```cpp
vector<vector<int>> g = {{1,2,3},{4,5,6}};
dbg_grid(g, 2, 3);
// [sol.cpp:8] g (2x3):
//   1 2 3
//   4 5 6
```

### Zero overhead on judges

`dbg`, `dbg_arr`, and `dbg_grid` expand to **nothing** without `-DLOCAL`. You can leave them in your submission safely — they add zero code.

---

## Precompiled headers (PCH)

`install.sh` pre-compiles `bits/stdc++.h` twice (debug flags / release flags) into `~/.config/cp/pch-*/bits/stdc++.h.gch`. GCC recognises the PCH automatically when you `-I ~/.config/cp/pch-<mode>`, giving you **instant** `#include <bits/stdc++.h>` instead of re-parsing thousands of lines each time.

> **After `brew upgrade gcc`:** re-run `bash install.sh` to rebuild the PCH for the new version. If you forget, GCC silently falls back to a normal parse — no breakage, just slower first compile.

---

## Codeforces / judge compatibility

| Judge setting | Flags equivalent |
|---|---|
| GNU G++17 | `cpc` with `CP_STD=c++17` in `~/.config/cp/cp.conf` |
| GNU G++20 | default (`c++20`) ✅ |
| GNU G++23 | change `CP_STD=c++23` in `~/.config/cp/cp.conf`, re-run `install.sh` |

---

## Policy-based data structures (ordered set with `order_of_key` / `find_by_order`)

Available because you're using GCC:

```cpp
#include <bits/stdc++.h>
#include <ext/pb_ds/assoc_container.hpp>
#include <ext/pb_ds/tree_policy.hpp>
using namespace __gnu_pbds;
using ordered_set = tree<int,null_type,less<int>,rb_tree_tag,tree_order_statistics_node_update>;

ordered_set os;
os.insert(1); os.insert(3); os.insert(5);
os.find_by_order(1);   // iterator to 3 (0-indexed)
os.order_of_key(4);    // 2  (elements strictly less than 4)
```

---

## VS Code integration (optional)

Create `.vscode/tasks.json` in your problem folder:

```json
{
    "version": "2.0.0",
    "tasks": [
        {
            "label": "CP: Debug Build",
            "type": "shell",
            "command": "cpc ${file}",
            "group": { "kind": "build", "isDefault": true },
            "presentation": { "reveal": "always" }
        },
        {
            "label": "CP: Run",
            "type": "shell",
            "command": "cprun ${file}",
            "group": "test",
            "presentation": { "reveal": "always" }
        },
        {
            "label": "CP: Release Build",
            "type": "shell",
            "command": "cpc -r ${file}",
            "group": "build",
            "presentation": { "reveal": "always" }
        }
    ]
}
```

Then press `⌘+Shift+B` (Build) to run `cpc` on the current file.

---

## Uninstall

```bash
bash install.sh --uninstall
```

Removes `/opt/homebrew/bin/cpc`, `/opt/homebrew/bin/cprun`, and `~/.config/cp/`.

---

## Directory layout

```
competitive_gcc_setup/
├── install.sh       ← run this once (and after brew upgrade gcc)
├── cpc              ← compile helper (copied to /opt/homebrew/bin/)
├── cprun            ← compile+run helper (copied to /opt/homebrew/bin/)
├── debug.h          ← pretty-printer (copied to ~/.config/cp/include/)
├── template.cpp     ← your starting point for every problem
└── README.md        ← this file

~/.config/cp/        ← runtime assets (created by install.sh)
├── cp.conf          ← compiler + path config
├── include/
│   └── debug.h
├── pch-debug/bits/
│   ├── stdc++.h
│   └── stdc++.h.gch   ← precompiled header (debug flags)
└── pch-release/bits/
    ├── stdc++.h
    └── stdc++.h.gch   ← precompiled header (release flags)
```
# setup-cpp
