## 🧠 WEEK 1 — OWNERSHIP & BASICS (EXAM SET)

### 🧩 Task 1.1 — Ownership Transfer Simulator

**Problem:**
You are given a sequence of operations describing variable creation, moves, borrows, and drops.

Implement a program that:

* Tracks ownership of heap objects
* Detects invalid access

**Input**

```
CREATE a
MOVE a b
BORROW b
DROP b
ACCESS b
```

**Output**

```
OK
OK
OK
OK
ERROR: use after move
```

**Constraints**

* Max operations: 100,000
* No garbage collection allowed

**Tests**

* Ownership rules
* Use-after-move
* Borrow validity

---

### 🧩 Task 1.2 — Lifetime Verifier

**Problem:**
Given scopes and references, determine if each reference is valid.

**Input**

```
SCOPE_START
  VAR x
  REF r x
SCOPE_END
USE r
```

**Output**

```
INVALID
```

**Tests**

* Lifetime tracking
* Scope-based invalidation

---

### 🧩 Task 1.3 — Error Propagation Engine

**Problem:**
Implement a function chain where errors propagate automatically.

**Requirements**

* No `unwrap()`
* Use `Result<T, E>`
* Use `?`

---

## ⚙️ WEEK 2 — MEMORY & UNSAFE (EXAM SET)

### 🧩 Task 2.1 — Custom Vector

**Problem:**
Implement `MyVec<T>` with:

* `push`
* `pop`
* `len`

**Constraints**

* No `Vec<T>`
* Use `alloc`
* No memory leaks

**Hidden Tests**

* Double drop
* Uninitialized memory
* Alignment

---

### 🧩 Task 2.2 — Fixed Buffer Pool

**Problem:**
Design a pool of N buffers.

**API**

```rust
fn alloc() -> Option<&mut [u8]>
fn free(buf: *mut u8)
```

**Constraints**

* Thread-safe
* No heap allocation after init

---

## 🌐 WEEK 3 — ASYNC & CONCURRENCY (EXAM SET)

### 🧩 Task 3.1 — Async Echo Server

**Problem:**
Write an async TCP server that echoes messages.

**Constraints**

* Must support 10,000 concurrent clients
* Timeout idle clients

---

### 🧩 Task 3.2 — Lock-Free Counter

**Problem:**
Implement a counter incremented by multiple threads.

**Constraints**

* No `Mutex`
* Use atomics only

---

## 🖥 WEEK 4 — BACKEND SYSTEMS (EXAM SET)

### 🧩 Task 4.1 — REST API Challenge

**Problem:**
Implement an API with endpoints:

```
POST /login
GET /data
```

**Requirements**

* JWT auth
* Rate limiting
* Structured logs

---

### 🧩 Task 4.2 — Binary Protocol Parser

**Problem:**
Parse packets:

```
| LEN (2 bytes) | TYPE (1 byte) | PAYLOAD |
```

**Reject**

* Malformed packets
* Overflow

---

## 🔌 WEEK 5 — IOT & EMBEDDED (EXAM SET)

### 🧩 Task 5.1 — no_std Sensor Driver

**Problem:**
Implement a temperature sensor driver.

**Constraints**

* `no_std`
* Interrupt-driven
* Fixed memory

---

### 🧩 Task 5.2 — Gateway Simulator

**Problem:**
Relay sensor data to server.

**Constraints**

* Retry on failure
* Offline buffering

---

## 🔐 WEEK 6 — CYBERSECURITY (EXAM SET)

### 🧩 Task 6.1 — Binary Fuzzer Target

**Problem:**
Write a binary parser that **will be fuzzed**.

**Goal**

* Survive 1M random inputs
* No panics

---

### 🧩 Task 6.2 — Secure Vault

**Problem:**
Store secrets in memory.

**Requirements**

* Constant-time comparison
* Zeroization on drop

---

## 🚀 WEEK 7 — PERFORMANCE & OS (EXAM SET)

### 🧩 Task 7.1 — mmap Log Scanner

**Problem:**
Scan huge log files for patterns.

**Constraints**

* No full file read
* Zero-copy

---

### 🧩 Task 7.2 — Custom Allocator

**Problem:**
Implement region allocator.

**Benchmark**

* Must outperform system allocator for small objects

---

## 🧪 WEEK 8 — ARCHITECTURE (EXAM SET)

### 🧩 Task 8.1 — Public Crate Design

**Problem:**
Design a crate API.

**Evaluation**

* API ergonomics
* Safety
* Documentation

---

---

# 🧨 FINAL PROJECTS — RECRUITMENT-LEVEL CHALLENGES

---

## 🔥 FINAL PROJECT 1 — SECURE IOT RUNTIME (15 DAYS)

### Problem Statement

Build a **secure runtime** connecting simulated embedded devices to a backend.

### Required Modules

1. Device agent (`no_std`)
2. Secure handshake
3. Binary protocol
4. OTA updates
5. Fault recovery

### Automated Tests

* Packet replay attack
* Memory exhaustion
* Network partition

---

## 🧠 FINAL PROJECT 2 — SECURITY RESEARCH PLATFORM (15 DAYS)

### Problem Statement

Build a system that analyzes binary protocols for vulnerabilities.

### Required Features

1. Packet capture
2. Parser
3. Fuzzer
4. Crash analyzer
5. Report generator

### Evaluation

* Memory safety
* Throughput
* Exploit detection quality

---

---
# 🧨 LAST PROJECT  — HIGH-PERFORMANCE DISTRIBUTED BACKEND CORE

**Duration:** 15 Days
**Difficulty:** Staff / Principal-level backend engineer
**Language:** Rust only

---

## 🧩 PROBLEM STATEMENT

Design and implement a **distributed, fault-tolerant backend core** that provides a **strongly-consistent data service** over unreliable networks.

You are building the **core storage & coordination layer** for a modern backend platform.

---

## 🧱 SYSTEM REQUIREMENTS

### 1️⃣ Core API (Mandatory)

Implement a TCP-based binary protocol exposing:

```
PUT key value
GET key
DELETE key
CAS key expected_value new_value
```

**Properties**

* Linearizable consistency
* Idempotent requests
* Deterministic behavior

---

### 2️⃣ CLUSTER MODEL

* 3–7 nodes
* One leader at a time
* Leader election required
* Log replication required
* Automatic failover

⚠️ You **may not** use existing consensus crates (no Raft crates).

---

### 3️⃣ CONSISTENCY & STORAGE

* Append-only log
* In-memory state machine
* Snapshotting
* Crash recovery
* fsync correctness

---

### 4️⃣ PERFORMANCE TARGETS

| Metric             | Target         |
| ------------------ | -------------- |
| Throughput         | ≥ 100k ops/sec |
| P99 Latency        | < 10ms         |
| Concurrent Clients | ≥ 20k          |

---

### 5️⃣ SECURITY REQUIREMENTS

* Encrypted node-to-node communication
* Replay-attack prevention
* Authentication tokens
* Memory zeroization for secrets

---

### 6️⃣ FAULT INJECTION TESTS

Your system **must survive**:

* Leader crash
* Network partition
* Disk full
* Clock skew
* Duplicate packets
* Out-of-order messages

---

## 🧪 AUTOMATED TEST CASES (EXAM-STYLE)

### Test 1 — Linearizability

```
Client A: PUT x=1
Client B: GET x
Expected: 1
```

---

### Test 2 — Leader Failover

```
Leader dies during PUT
New leader elected
GET returns correct value
```

---

### Test 3 — Log Corruption

* Partial write on crash
* Recovery without data loss

---

### Test 4 — Replay Attack

* Re-send old packets
* Must be rejected

---

### Test 5 — Throughput Stress

* 20k clients
* Random operations
* No memory growth

---

## 🧠 EVALUATION CRITERIA (HOW YOU ARE JUDGED)

### Rust Mastery

* Minimal `unsafe`
* Documented invariants
* No memory leaks
* Correct lifetimes

### Backend Engineering

* Correct failure handling
* Observability
* Graceful degradation

### Systems Thinking

* Clear trade-offs
* Consistency guarantees explained
* Performance tuning justified

---

## 🛠️ HARD CONSTRAINTS

* No garbage collection
* No global mutable state
* No `unwrap()` in production paths
* No blocking calls in async contexts
* No consensus crates

---

## 📦 REQUIRED DELIVERABLES

1. Source code
2. Design document (architecture + tradeoffs)
3. Fault injection report
4. Benchmarks
5. Security analysis