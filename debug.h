// debug.h — competitive programming pretty-printer
// Active only when compiled with -DLOCAL (stripped to nothing on judges).
// Include AFTER <bits/stdc++.h>. Requires C++20 (template lambdas).
#pragma once

#ifdef LOCAL

#include <bits/stdc++.h>
#include <unistd.h>   // STDERR_FILENO, isatty

namespace dbg_detail {

// ── ANSI colours ──────────────────────────────────────────────────────────
inline bool use_color() {
    static bool v = (isatty(STDERR_FILENO) != 0);
    return v;
}
inline const char* col(const char* c) { return use_color() ? c : ""; }

inline constexpr const char* RED  = "\033[31m";
inline constexpr const char* GRN  = "\033[32m";
inline constexpr const char* YEL  = "\033[33m";
inline constexpr const char* CYN  = "\033[36m";
inline constexpr const char* MAG  = "\033[35m";
inline constexpr const char* BOLD = "\033[1m";
inline constexpr const char* RST  = "\033[0m";

// ── Type traits ───────────────────────────────────────────────────────────
template<class T> struct is_pair_t    : std::false_type {};
template<class A, class B>
struct is_pair_t<std::pair<A,B>>      : std::true_type  {};

template<class T> struct is_tuple_t   : std::false_type {};
template<class... Ts>
struct is_tuple_t<std::tuple<Ts...>>  : std::true_type  {};

template<class T, class = void> struct is_iterable : std::false_type {};
template<class T>
struct is_iterable<T, std::void_t<
    decltype(std::begin(std::declval<const T&>())),
    decltype(std::end(std::declval<const T&>()))>> : std::true_type {};
// strings should print as "hello", not as a char sequence
template<> struct is_iterable<std::string>        : std::false_type {};
template<> struct is_iterable<const std::string>  : std::false_type {};

// Maps have ::mapped_type; plain sets do not
template<class T, class = void> struct is_map_like : std::false_type {};
template<class T>
struct is_map_like<T, std::void_t<typename T::mapped_type>> : std::true_type {};

// Stack / queue / priority_queue — detected by partial specialisation
template<class T> struct is_stack_t   : std::false_type {};
template<class T, class C>
struct is_stack_t<std::stack<T,C>>    : std::true_type  {};

template<class T> struct is_queue_t   : std::false_type {};
template<class T, class C>
struct is_queue_t<std::queue<T,C>>    : std::true_type  {};

template<class T> struct is_pqueue_t  : std::false_type {};
template<class T, class C, class Cmp>
struct is_pqueue_t<std::priority_queue<T,C,Cmp>> : std::true_type {};

// ── Forward declare the single print function (needed for recursion) ──────
template<class T> void print(std::ostream& os, const T& v);

// ── Tuple helper (needs index_sequence, defined before print body) ────────
template<class Tup, std::size_t... Is>
void print_tuple_impl(std::ostream& os, const Tup& t, std::index_sequence<Is...>) {
    os << col(CYN) << "(" << col(RST);
    bool first = true;
    auto one = [&](const auto& x) {
        if (!first) os << col(CYN) << ", " << col(RST);
        first = false;
        print(os, x);        // recursive — resolved at instantiation time
    };
    (one(std::get<Is>(t)), ...);
    os << col(CYN) << ")" << col(RST);
}

// ── Single print function — all dispatching via if constexpr ─────────────
// Having ONE template function avoids overload-resolution ambiguity.
template<class T>
void print(std::ostream& os, const T& v) {

    // --- pair ------------------------------------------------------------
    if constexpr (is_pair_t<T>::value) {
        os << col(CYN) << "(" << col(RST);
        print(os, v.first);
        os << col(CYN) << ", " << col(RST);
        print(os, v.second);
        os << col(CYN) << ")" << col(RST);

    // --- tuple -----------------------------------------------------------
    } else if constexpr (is_tuple_t<T>::value) {
        print_tuple_impl(os, v, std::make_index_sequence<std::tuple_size_v<T>>{});

    // --- string (special-case before the iterable branch) ----------------
    } else if constexpr (std::is_same_v<std::remove_cv_t<T>, std::string>
                      || std::is_same_v<std::remove_cv_t<T>, const char*>
                      || std::is_convertible_v<T, std::string_view>) {
        os << col(MAG) << '"' << v << '"' << col(RST);

    // --- stack (copy-drain front → back) ---------------------------------
    } else if constexpr (is_stack_t<T>::value) {
        auto s = v;   // copy by value
        std::vector<typename T::value_type> tmp;
        while (!s.empty()) { tmp.push_back(s.top()); s.pop(); }
        std::reverse(tmp.begin(), tmp.end());
        print(os, tmp);

    // --- queue (copy-drain) ----------------------------------------------
    } else if constexpr (is_queue_t<T>::value) {
        auto q = v;
        std::vector<typename T::value_type> tmp;
        while (!q.empty()) { tmp.push_back(q.front()); q.pop(); }
        print(os, tmp);

    // --- priority_queue (copy-drain) -------------------------------------
    } else if constexpr (is_pqueue_t<T>::value) {
        auto pq = v;
        std::vector<typename T::value_type> tmp;
        while (!pq.empty()) { tmp.push_back(pq.top()); pq.pop(); }
        print(os, tmp);

    // --- generic iterable: vector, array, deque, set, map, … ------------
    } else if constexpr (is_iterable<T>::value) {
        if constexpr (is_map_like<T>::value) {
            // map / multimap / unordered_map → {k: v, …}
            os << col(YEL) << "{" << col(RST);
            bool first = true;
            for (const auto& [k, val] : v) {
                if (!first) os << col(YEL) << ", " << col(RST);
                first = false;
                print(os, k);
                os << col(YEL) << ": " << col(RST);
                print(os, val);
            }
            os << col(YEL) << "}" << col(RST);
        } else {
            // sequence / set / multiset → [a, b, c]
            os << col(GRN) << "[" << col(RST);
            bool first = true;
            for (const auto& x : v) {
                if (!first) os << col(GRN) << ", " << col(RST);
                first = false;
                print(os, x);
            }
            os << col(GRN) << "]" << col(RST);
        }

    // --- bool ------------------------------------------------------------
    } else if constexpr (std::is_same_v<std::remove_cv_t<T>, bool>) {
        os << (v ? col(GRN) : col(RED)) << (v ? "true" : "false") << col(RST);

    // --- char ------------------------------------------------------------
    } else if constexpr (std::is_same_v<std::remove_cv_t<T>, char>) {
        os << col(MAG) << "'" << v << "'" << col(RST);

    // --- scalar fallback (int, long, double, __int128, …) ----------------
    } else {
        os << col(BOLD) << v << col(RST);
    }
}

// ── name-splitting: "a, b, vec" → ["a", "b", "vec"] ─────────────────────
inline std::vector<std::string> split_names(const char* raw) {
    std::vector<std::string> names;
    int depth = 0;
    std::string cur;
    for (const char* p = raw; *p; ++p) {
        char c = *p;
        if (c == '(' || c == '[' || c == '<' || c == '{') { ++depth; cur += c; }
        else if (c == ')' || c == ']' || c == '>' || c == '}') { --depth; cur += c; }
        else if (c == ',' && depth == 0) {
            auto b = cur.find_first_not_of(" \t");
            auto e = cur.find_last_not_of(" \t");
            names.push_back(b == std::string::npos ? "" : cur.substr(b, e - b + 1));
            cur.clear();
        } else {
            cur += c;
        }
    }
    auto b = cur.find_first_not_of(" \t");
    auto e = cur.find_last_not_of(" \t");
    names.push_back(b == std::string::npos ? "" : cur.substr(b, e - b + 1));
    return names;
}

} // namespace dbg_detail

// ── Public macros ─────────────────────────────────────────────────────────

// dbg(expr [, expr …])
// Prints: [file:line] name1 = val1  name2 = val2
// C++20 template lambda gives us a real variadic pack from __VA_ARGS__.
#define dbg(...) \
    do { \
        auto _dbg_names = dbg_detail::split_names(#__VA_ARGS__); \
        std::size_t _dbg_i = 0; \
        std::cerr << dbg_detail::col(dbg_detail::RED) \
                  << dbg_detail::col(dbg_detail::BOLD) \
                  << "[" << __FILE__ << ":" << __LINE__ << "]" \
                  << dbg_detail::col(dbg_detail::RST) << " "; \
        [&]<class... _DbgTs>(const _DbgTs&... _dbg_vals) { \
            (( \
                std::cerr \
                    << dbg_detail::col(dbg_detail::CYN) \
                    << (_dbg_i < _dbg_names.size() ? _dbg_names[_dbg_i++] : "?") \
                    << dbg_detail::col(dbg_detail::RST) << " = ", \
                dbg_detail::print(std::cerr, _dbg_vals), \
                std::cerr << "  " \
            ), ...); \
        }(__VA_ARGS__); \
        std::cerr << "\n"; \
    } while(0)

// dbg_arr(arr, n) — 1-D array/vector with 0-based index labels
#define dbg_arr(arr, n) \
    do { \
        std::cerr << dbg_detail::col(dbg_detail::RED) \
                  << dbg_detail::col(dbg_detail::BOLD) \
                  << "[" << __FILE__ << ":" << __LINE__ << "] " \
                  << dbg_detail::col(dbg_detail::RST) \
                  << #arr << " = " \
                  << dbg_detail::col(dbg_detail::GRN) << "[" \
                  << dbg_detail::col(dbg_detail::RST); \
        for (int _k = 0; _k < (int)(n); ++_k) { \
            if (_k) std::cerr << dbg_detail::col(dbg_detail::GRN) << ", " \
                              << dbg_detail::col(dbg_detail::RST); \
            std::cerr << dbg_detail::col(dbg_detail::YEL) << _k \
                      << dbg_detail::col(dbg_detail::RST) << ":"; \
            dbg_detail::print(std::cerr, (arr)[_k]); \
        } \
        std::cerr << dbg_detail::col(dbg_detail::GRN) << "]\n" \
                  << dbg_detail::col(dbg_detail::RST); \
    } while(0)

// dbg_grid(grid, rows, cols) — 2-D grid (vector<vector<T>> or T[R][C])
#define dbg_grid(grid, rows, cols) \
    do { \
        std::cerr << dbg_detail::col(dbg_detail::RED) \
                  << dbg_detail::col(dbg_detail::BOLD) \
                  << "[" << __FILE__ << ":" << __LINE__ << "] " \
                  << dbg_detail::col(dbg_detail::RST) \
                  << #grid << " (" << (rows) << "x" << (cols) << "):\n"; \
        for (int _r = 0; _r < (int)(rows); ++_r) { \
            std::cerr << "  "; \
            for (int _c = 0; _c < (int)(cols); ++_c) { \
                if (_c) std::cerr << " "; \
                dbg_detail::print(std::cerr, (grid)[_r][_c]); \
            } \
            std::cerr << "\n"; \
        } \
    } while(0)

#else // !LOCAL  →  all macros compile to nothing

#define dbg(...)         do {} while(0)
#define dbg_arr(a,n)     do {} while(0)
#define dbg_grid(g,r,c)  do {} while(0)

#endif // LOCAL
