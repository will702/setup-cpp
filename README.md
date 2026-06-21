# setup-cpp

One-command C++ competitive programming setup for macOS — Homebrew GCC, `<bits/stdc++.h>`, precompiled headers, ASan/UBSan debug builds, a pretty-printer for all STL containers, and auto-configured VS Code IntelliSense + CPH.

---

## Quick start

```bash
# 1. Install Homebrew GCC if you haven't already
brew install gcc          # installs g++-16 (or latest)

# 2. Run the installer (one time, or after brew upgrade gcc)
bash install.sh

# 3. Start a new problem — from any directory, forever
cpnew                     # → sol.cpp  (ready to code)
cprun sol.cpp             # compile (debug) + run
cpc -r sol.cpp            # release/submit build
```

---

## Install modes

```bash
bash install.sh                    # global  → /opt/homebrew/bin/  (default)
bash install.sh --prefix ~/.local  # user    → ~/.local/bin/
bash install.sh --local            # project → ./bin/  in current dir
bash install.sh --uninstall        # remove everything
```

After `brew upgrade gcc`: re-run `bash install.sh` to rebuild precompiled headers for the new version.

---

## Commands

### `cpnew` — create problem files from template

```bash
cpnew                    # sol.cpp in current directory
cpnew foo                # foo.cpp
cpnew A B C D E          # A.cpp … E.cpp  (contest mode)
cpnew --contest          # same as above, A–E by default
cpnew --contest A-G      # A.cpp through G.cpp
cpnew --dir round        # mkdir round/ with sol.cpp + in.txt + .vscode/
cpnew --dir round A B C  # mkdir round/ with A.cpp B.cpp C.cpp + in.txt files
cpnew -f sol             # overwrite existing sol.cpp
```

`debug.h` and `template.cpp` are stored globally at `~/.config/cp/` — **you never need to copy either file**. `#include "debug.h"` works from any directory when compiled with `cpc`.

### `cpc` — compile

```bash
cpc sol.cpp              # debug build (default)
cpc -r sol.cpp           # release / submit build
cpc --submit sol.cpp     # same as -r
cpc -h                   # help
```

### `cprun` — compile + run

```bash
cprun sol.cpp            # debug build + run  (auto-reads in.txt if present)
cprun -r sol.cpp         # release build + run
```

**Tip:** `cprun` feeds `in.txt` automatically in debug mode. Create it once per problem with sample input.

---

## Why Homebrew GCC instead of Apple clang?

| Feature | Apple clang (`/usr/bin/g++`) | Homebrew GCC (`g++-16`) |
|---|---|---|
| `<bits/stdc++.h>` | ❌ | ✅ ships with GCC |
| `__int128` | partial | ✅ |
| Policy-based trees `<ext/pb_ds/…>` | ❌ | ✅ |
| `__builtin_popcount` / `__builtin_clz` | partial | ✅ |
| Matches Codeforces G++20 judge | ❌ | ✅ |

---

## Debug flags (default `cpc` build)

| Flag | What it does |
|---|---|
| `-O2` | Fast enough for local testing |
| `-Wall -Wextra -Wshadow -Wconversion` | Catch shadowed vars, narrowing, common mistakes |
| `-DLOCAL` | Activates `dbg()` in debug.h |
| `-D_GLIBCXX_DEBUG` | Bounds-checks `vector[]`, iterator validity |
| `-fsanitize=address,undefined` | Catches overflows, bad pointers, UB |
| `-fno-sanitize-recover=all` | Abort on first error |
| `-g` | Readable sanitizer stack traces |

Release build (`cpc -r`): `-std=c++20 -O2 -Wall -Wextra -Wshadow -Wconversion` — no overhead, matches judge.

---

## `debug.h` — pretty-printing

Include after `<bits/stdc++.h>`. All macros compile to **nothing** without `-DLOCAL` — safe to leave in submissions.

```cpp
#include <bits/stdc++.h>
#include "debug.h"   // no path prefix needed — globally accessible via cpc
```

### `dbg(expr [, expr …])`

```cpp
int n = 5;
vector<pair<int,int>> v = {{1,2},{3,4}};
map<string,vector<int>> m = {{"a",{1,2}},{"b",{3}}};
bitset<4> bs("1010");
vector<bool> vb = {true, false, true};

dbg(n, v, m, bs, vb);
// [sol.cpp:9] n = 5  v = [(1, 2), (3, 4)]  m = {"a": [1, 2], "b": [3]}
//             bs = "1010"  vb = [true, false, true]
```

Supported types (including **nested**):

| Type | Output |
|---|---|
| `int`, `ll`, `double`, `__int128`… | `42` |
| `bool` | `true` / `false` (green/red in TTY) |
| `char` | `'x'` |
| `string` | `"hello"` |
| `pair<A,B>` | `(a, b)` |
| `tuple<…>` (any arity) | `(a, b, c)` |
| `vector`, `array`, `deque`, `list`, `set` | `[a, b, c]` |
| `map`, `unordered_map` | `{k: v, k: v}` |
| `stack`, `queue`, `priority_queue` | `[a, b, c]` (copy-drained) |
| `bitset<N>` | `"01101"` |
| `vector<bool>` | `[true, false]` (proxy-ref handled correctly) |
| Nested e.g. `map<int,vector<pair<int,int>>>` | fully recursive |

### `dbg_arr(arr, n)` — indexed 1-D array

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

---

## Per-project configuration (`.cpcrc`)

Drop a `.cpcrc` in any problem or contest folder to override compile settings for that directory tree:

```bash
# .cpcrc
CP_STD="c++17"               # use c++17 for this contest
EXTRA_FLAGS="-DONLINE_JUDGE" # extra define for every build
```

`cpc` walks up the directory tree and picks up the nearest `.cpcrc` automatically.

---

## Precompiled headers

`install.sh` precompiles `bits/stdc++.h` twice (separate debug and release flag sets) into `~/.config/cp/pch-*/bits/stdc++.h.gch`. GCC recognises the PCH automatically, making `#include <bits/stdc++.h>` near-instant. If the PCH flags ever mismatch, GCC silently falls back to a normal parse — no build failure.

---

## VS Code setup

After `install.sh`, `c_cpp_properties.json` is generated at `~/.vscode-cp/`. Copy it into any workspace to eliminate the red squiggle under `#include <bits/stdc++.h>`:

```bash
cpnew --dir myround      # does this automatically
# or manually:
mkdir -p .vscode && cp ~/.vscode-cp/c_cpp_properties.json .vscode/
```

**CPH extension** (Competitive Programming Helper) is auto-configured to use `g++-16` with all debug flags:

```bash
code --install-extension DivyanshuAgrawal.competitive-programming-helper
```

---

## Policy-based data structures (GCC only)

```cpp
#include <ext/pb_ds/assoc_container.hpp>
#include <ext/pb_ds/tree_policy.hpp>
using namespace __gnu_pbds;
using ordered_set = tree<int,null_type,less<int>,rb_tree_tag,
                         tree_order_statistics_node_update>;

ordered_set os;
os.insert(1); os.insert(3); os.insert(5);
os.find_by_order(1);   // iterator to 3 (0-indexed rank)
os.order_of_key(4);    // 2  (count of elements < 4)
```

---

## Codeforces judge compatibility

| Judge | Local equivalent |
|---|---|
| GNU G++17 | `CP_STD="c++17"` in `.cpcrc` |
| GNU G++20 | default ✅ |
| GNU G++23 | `CP_STD="c++23"` in `.cpcrc`, re-run `install.sh` |

---

## Uninstall

```bash
bash install.sh --uninstall
# removes /opt/homebrew/bin/{cpc,cprun,cpnew} and ~/.config/cp/
```
