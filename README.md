# setup-cpp

> Competitive programming C++ toolchain for macOS — Homebrew GCC, `bits/stdc++.h`, precompiled headers, sanitizers, and a full-featured debug pretty-printer. Works from any directory after a one-time install.

---

## Install

### Via Homebrew (recommended)

```bash
brew tap will702/setup-cpp https://github.com/will702/setup-cpp
brew install setup-cpp
setup-cpp init
```

### From source

```bash
git clone https://github.com/will702/setup-cpp.git
cd setup-cpp
bash install.sh          # global → Homebrew bin/ (/opt/homebrew/bin on Apple Silicon, /usr/local/bin on Intel)
```

Other install targets:

```bash
bash install.sh --prefix ~/.local   # user   → ~/.local/bin/
bash install.sh --local             # project → ./bin/
bash install.sh --uninstall         # remove everything
```

> **After `brew upgrade gcc`:** run `setup-cpp update` (Homebrew) or `bash install.sh` (source) to rebuild precompiled headers.

---

## Daily workflow

```bash
# New problem
cpnew                     # → sol.cpp  (full template, ready to code)

# Edit sol.cpp …

# Compile and run (debug mode)
cprun sol.cpp             # compile + run; auto-feeds in.txt if present

# Submit
cpc -r sol.cpp            # release build — no sanitizers, no debug overhead
```

---

## Commands

### `cpnew` — stamp problem files from template

```bash
cpnew                     # sol.cpp
cpnew foo                 # foo.cpp
cpnew A B C D E           # A.cpp … E.cpp
cpnew --contest           # A.cpp … E.cpp  (Codeforces default)
cpnew --contest A-G       # A.cpp … G.cpp
cpnew --dir round         # mkdir round/ → sol.cpp + in.txt + .vscode/
cpnew --dir round A B C   # mkdir round/ → A.cpp B.cpp C.cpp + in.txt
cpnew -f sol              # overwrite existing sol.cpp
```

`debug.h` and `template.cpp` live at `~/.config/cp/` after install — **you never need to copy them**. `#include "debug.h"` resolves from any directory when compiled with `cpc`.

### `cpc` — compile

```bash
cpc sol.cpp               # debug build (default)
cpc -r sol.cpp            # release / submit build
cpc -h                    # full flag reference
```

**Debug build flags:** `-std=c++20 -O2 -Wall -Wextra -Wshadow -Wconversion -D_GLIBCXX_DEBUG -DLOCAL -g -fsanitize=address,undefined -fno-sanitize-recover=all`

**Release build flags:** `-std=c++20 -O2 -Wall -Wextra -Wshadow -Wconversion`

### `cprun` — compile + run

```bash
cprun sol.cpp             # debug build + run
cprun -r sol.cpp          # release build + run
```

Drop sample input in `in.txt` — `cprun` feeds it automatically in debug mode.

### `setup-cpp` — manage the installation

```bash
setup-cpp init            # first-time setup (or after brew install)
setup-cpp update          # rebuild PCH after brew upgrade gcc
setup-cpp doctor          # check all components are wired up
setup-cpp uninstall       # remove ~/.config/cp/
setup-cpp -h              # help
```

---

## `debug.h` — pretty-printer for all STL types

Include it after `<bits/stdc++.h>`. All macros expand to **nothing** without `-DLOCAL`, so they are safe to leave in submitted code.

```cpp
#include <bits/stdc++.h>
#include "debug.h"
```

### `dbg(expr, ...)` — print any variable with source location

```
[sol.cpp:12] n = 5  v = [(1, 2), (3, 4)]  m = {"a": [1, 2], "b": [3]}
             bs = "1010"  vb = [true, false, true]
```

<details>
<summary>All supported types</summary>

| Type | Output format |
|---|---|
| `int`, `long long`, `double`, `__int128` | `42` |
| `bool` | `true` / `false` (green / red in TTY) |
| `char` | `'x'` |
| `string` | `"hello"` |
| `pair<A, B>` | `(a, b)` |
| `tuple<...>` (any arity) | `(a, b, c)` |
| `vector`, `array`, `deque`, `list`, `set`, `multiset` | `[a, b, c]` |
| `map`, `multimap`, `unordered_map` | `{k: v, k: v}` |
| `stack`, `queue`, `priority_queue` | `[a, b, c]` (copy-drained) |
| `bitset<N>` | `"01101"` |
| `vector<bool>` | `[true, false]` (proxy reference handled) |
| Nested — `map<int, vector<pair<int,int>>>` | fully recursive |

</details>

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

---

## Per-project config (`.cpcrc`)

Place a `.cpcrc` in any contest or problem directory to override compiler settings for that tree:

```bash
# .cpcrc
CP_STD="c++17"                # override standard (default: c++20)
EXTRA_FLAGS="-DONLINE_JUDGE"  # append to every build
```

`cpc` walks up the directory tree and applies the nearest `.cpcrc` automatically.

---

## VS Code + CPH

`setup-cpp init` configures both automatically:

- **IntelliSense** — no more red squiggle under `#include <bits/stdc++.h>`. Copy the generated config into any workspace:
  ```bash
  cpnew --dir round      # copies .vscode/ automatically
  # or manually:
  mkdir -p .vscode && cp ~/.vscode-cp/c_cpp_properties.json .vscode/
  ```
- **CPH** (Competitive Programming Helper) — pre-configured to use your Homebrew `g++` (auto-detected at `setup-cpp init`) with debug flags. Install the extension:
  ```bash
  code --install-extension DivyanshuAgrawal.competitive-programming-helper
  ```

---

## Why Homebrew GCC over Apple clang

Apple's `g++` is clang in disguise. Homebrew GCC is real GCC, which is what all major online judges use.

| | Apple clang | Homebrew GCC |
|---|:---:|:---:|
| `<bits/stdc++.h>` | ✗ | ✓ |
| `__int128` | partial | ✓ |
| `<ext/pb_ds/…>` policy trees | ✗ | ✓ |
| `__builtin_popcount` / `__builtin_clz` | partial | ✓ |
| Matches Codeforces G++20 judge | ✗ | ✓ |

---

## Precompiled headers

`bits/stdc++.h` is precompiled twice — once with debug flags, once with release flags — into `~/.config/cp/pch-*/bits/stdc++.h.gch`. GCC picks up the matching `.gch` automatically, making `#include <bits/stdc++.h>` near-instant. If flags ever mismatch, GCC silently falls back to a normal parse with no build failure.

---

## Codeforces judge compatibility

| Judge | How to match locally |
|---|---|
| GNU G++17 | `CP_STD="c++17"` in `.cpcrc` |
| GNU G++20 | default ✅ |
| GNU G++23 | `CP_STD="c++23"` in `.cpcrc`, then `setup-cpp update` |

---

## Policy-based data structures

Available because you're compiling with real GCC:

```cpp
#include <ext/pb_ds/assoc_container.hpp>
#include <ext/pb_ds/tree_policy.hpp>
using namespace __gnu_pbds;

using ordered_set = tree<int, null_type, less<int>,
                         rb_tree_tag, tree_order_statistics_node_update>;

ordered_set s = {1, 3, 5};
s.find_by_order(1);   // iterator to 3  (0-indexed rank)
s.order_of_key(4);    // 2  (elements strictly less than 4)
```

---

## Uninstall

```bash
setup-cpp uninstall           # removes ~/.config/cp/
brew uninstall setup-cpp      # removes binaries (if installed via Homebrew)
```
