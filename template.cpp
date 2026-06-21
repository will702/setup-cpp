// Competitive Programming Template — C++20
// Compile (debug):  cpc sol.cpp
// Compile (submit): cpc -r sol.cpp   OR   cpc --submit sol.cpp
// Run:              cprun sol.cpp
#include <bits/stdc++.h>
#include "debug.h"   // dbg() expands to nothing when not compiled with -DLOCAL

using namespace std;

// ── Types ──────────────────────────────────────────────────────────────────
using ll  = long long;
using ull = unsigned long long;
using ld  = long double;
using pii = pair<int,int>;
using pll = pair<ll,ll>;
using vi  = vector<int>;
using vll = vector<ll>;
using vvi = vector<vi>;

// ── Constants ─────────────────────────────────────────────────────────────
const int  INF  = 0x3f3f3f3f;          // ~1e9
const ll   LINF = 0x3f3f3f3f3f3f3f3fLL; // ~4.6e18
const int  MOD  = 1e9 + 7;
const int  MOD2 = 998244353;
const ld   PI   = acos((ld)-1);

// ── Macros ────────────────────────────────────────────────────────────────
#define all(x)    (x).begin(), (x).end()
#define rall(x)   (x).rbegin(), (x).rend()
#define sz(x)     (int)(x).size()
#define pb        push_back
#define eb        emplace_back
#define ff        first
#define ss        second

// rep(i, a, b)  → i in [a, b)
#define rep(i, a, b)  for (int i = (a); i < (b); ++i)
// per(i, a, b)  → i in (b, a] (reverse)
#define per(i, a, b)  for (int i = (a) - 1; i >= (b); --i)
// FOR(i, n)     → i in [0, n)
#define FOR(i, n)     rep(i, 0, n)

// ── Math utilities ────────────────────────────────────────────────────────
template<class T> T gcd(T a, T b) { return b ? gcd(b, a % b) : a; }
template<class T> T lcm(T a, T b) { return a / gcd(a, b) * b; }
template<class T> T pw(T b, ll e, T m) {   // fast modpow
    T r = 1; b %= m;
    for (; e; e >>= 1, b = b * b % m) if (e & 1) r = r * b % m;
    return r;
}
template<class T> bool ckmax(T& a, const T& b) { return b > a ? (a=b,1) : 0; }
template<class T> bool ckmin(T& a, const T& b) { return b < a ? (a=b,1) : 0; }

// ── I/O helpers ───────────────────────────────────────────────────────────
// Read a whole vector:  vi a(n); read(a);
template<class T>
void read(vector<T>& v) { for (auto& x : v) cin >> x; }
// Print container on one line:  println(v);
template<class T>
void println(const T& v) {
    bool f = true;
    for (const auto& x : v) { cout << (f ? "" : " ") << x; f = false; }
    cout << "\n";
}

// ── Main solve ────────────────────────────────────────────────────────────
void solve() {
    // ── read input ─────────────────────────────────────────────────────
    int n;
    cin >> n;

    // ── debug example — remove before submit ───────────────────────────
    vector<pair<int,int>> v;
    FOR(i, n) v.pb({i, i * i});
    dbg(n, v);                         // prints: n = 3  v = [(0, 0), (1, 1), (2, 4)]

    map<int, vector<int>> m;
    FOR(i, n) m[i % 2].pb(i);
    dbg(m);                            // prints: m = {0: [0, 2], 1: [1]}

    // ── your solution here ─────────────────────────────────────────────
    cout << 0 << "\n";
}

int main() {
    ios_base::sync_with_stdio(false);
    cin.tie(nullptr);

    int t = 1;
    // cin >> t;      // uncomment for multi-test
    while (t--) solve();

    return 0;
}
