# 🔥 DAILY NON-NEGOTIABLE CHECKLIST (EVERY DAY)

### 🧠 Mental Warm-Up (30 min)

* ☐ Read **10–20 pages** of Rust Book / Rustonomicon / RFC
* ☐ Write **1 paragraph** explaining a concept *from memory*
* ☐ Predict compiler errors before compiling

---

### 💻 Code Session 1 — Core Work (3–4 hrs)

* ☐ Implement today’s feature **without tutorials**
* ☐ Compile with:

  * `cargo clippy -- -W clippy::pedantic`
  * `cargo fmt`
* ☐ Fix **all warnings**
* ☐ Write at least **1 test**

---

### 🧪 Failure Engineering (1 hr)

* ☐ Intentionally break ownership or lifetimes
* ☐ Observe compiler messages
* ☐ Fix without `.clone()` unless justified
* ☐ Write comment explaining *why it works*

---

### 🔍 Source Code Reading (1–2 hrs)

* ☐ Read **1 Rust crate or std module**
* ☐ Identify:

  * unsafe blocks
  * invariants
  * performance tricks
* ☐ Rewrite **1 function** from scratch

---

### 🧠 Code Session 2 — Real-World Task (3 hrs)

* ☐ Work on weekly project task
* ☐ Add logging / tracing
* ☐ Consider failure modes
* ☐ Write TODOs like a senior engineer

---

### 🔐 Security & Performance Pass (45 min)

* ☐ Look for:

  * panics
  * unchecked indexing
  * allocations
* ☐ Ask: *Could this be exploited?*
* ☐ Benchmark at least one function

---

### 📓 End-of-Day Review (30 min)

* ☐ Write:

  * What I learned
  * What confused me
  * What I broke
* ☐ Note one concept to revisit tomorrow

---

# 📅 WEEK-BY-WEEK DAILY CHECKLISTS

---

## 🧠 WEEK 1 — OWNERSHIP & BASICS

### DAILY EXTRA

* ☐ Rewrite examples **without references**
* ☐ Replace `clone()` with borrowing
* ☐ Draw memory layout on paper

### DAILY TASK ROTATION

| Day | Task                       |
| --- | -------------------------- |
| 1   | Ownership & move semantics |
| 2   | Borrowing rules            |
| 3   | Lifetimes                  |
| 4   | Structs & enums            |
| 5   | Pattern matching           |
| 6   | Error handling             |
| 7   | Mini project refactor      |

---

## ⚙️ WEEK 2 — UNSAFE & MEMORY

### DAILY EXTRA

* ☐ Write **one unsafe block**
* ☐ Document invariants
* ☐ Run under sanitizer if possible

### DAILY TASK ROTATION

| Day | Task                     |
| --- | ------------------------ |
| 8   | Raw pointers             |
| 9   | Manual allocation        |
| 10  | `MaybeUninit`            |
| 11  | `Pin` & self-referential |
| 12  | `Send` / `Sync`          |
| 13  | Buffer pools             |
| 14  | Memory audit             |

---

## 🌐 WEEK 3 — ASYNC & CONCURRENCY

### DAILY EXTRA

* ☐ Explain future state machines
* ☐ Inspect `.await` desugaring

### DAILY TASK ROTATION

| Day | Task               |
| --- | ------------------ |
| 15  | Async basics       |
| 16  | Tokio runtime      |
| 17  | TCP server         |
| 18  | Backpressure       |
| 19  | Atomics            |
| 20  | Lock-free patterns |
| 21  | Load testing       |

---

## 🖥 WEEK 4 — BACKEND ENGINEERING

### DAILY EXTRA

* ☐ Log everything
* ☐ Add metrics
* ☐ Think about API versioning

### DAILY TASK ROTATION

| Day | Task               |
| --- | ------------------ |
| 22  | REST API           |
| 23  | Auth               |
| 24  | Database           |
| 25  | Caching            |
| 26  | Observability      |
| 27  | Failure simulation |
| 28  | Hardening          |

---

## 🔌 WEEK 5 — EMBEDDED & IOT

### DAILY EXTRA

* ☐ Avoid heap
* ☐ Measure memory usage

### DAILY TASK ROTATION

| Day | Task               |
| --- | ------------------ |
| 29  | `no_std`           |
| 30  | HAL                |
| 31  | Interrupts         |
| 32  | Drivers            |
| 33  | Protocols          |
| 34  | Gateway            |
| 35  | Power optimization |

---

## 🔐 WEEK 6 — SECURITY

### DAILY EXTRA

* ☐ Threat model the code
* ☐ Search for CVEs related to used crates

### DAILY TASK ROTATION

| Day | Task               |
| --- | ------------------ |
| 36  | Fuzzing            |
| 37  | Parsers            |
| 38  | Crypto             |
| 39  | Timing attacks     |
| 40  | Key storage        |
| 41  | Exploit simulation |
| 42  | Patch & report     |

---

## 🚀 WEEK 7 — PERFORMANCE & OS

### DAILY EXTRA

* ☐ Profile with flamegraphs
* ☐ Reduce allocations

### DAILY TASK ROTATION

| Day | Task       |
| --- | ---------- |
| 43  | Syscalls   |
| 44  | mmap       |
| 45  | SIMD       |
| 46  | Cache      |
| 47  | Allocators |
| 48  | eBPF       |
| 49  | Benchmarks |

---

## 🧪 WEEK 8 — ARCHITECT & SENIOR MINDSET

### DAILY EXTRA

* ☐ Write public docs
* ☐ Think long-term maintenance

### DAILY TASK ROTATION

| Day | Task            |
| --- | --------------- |
| 50  | API design      |
| 51  | Stability       |
| 52  | RFC reading     |
| 53  | Crate packaging |
| 54  | Docs            |
| 55  | Refactor        |
| 56  | Final polish    |

---

# 🧨 Hot Recap! Done.