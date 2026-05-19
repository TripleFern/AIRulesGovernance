# Inquiry Validity Rule Candidate

- Date: 2026-05-19
- Status: RULE_CANDIDATE
- Trigger: FDPS sort threshold/thread-cap measurement missed that observed particle count was below the radix threshold

## Background

The existing rule files already require deep verification, multiple WHY
iterations, and concrete code-path tracing. They do not explicitly force a
pre-work check that the planned action, test, analysis, or implementation
actually answers the intended question.

The FDPS sort experiment showed the gap: a thread-cap measurement was initially
treated as a radix-thread measurement even though the observed particle count
was below the `std::sort` fallback threshold. The run therefore measured a
different path from the intended one.

This is not only a benchmarking problem. It is a general scientific and
engineering failure mode: doing a technically correct operation that answers a
different question from the one that matters.

## Candidate Rule Text

Before running or interpreting any non-trivial action, the agent MUST write a
short inquiry-validity block. This applies to benchmarks, profiler experiments,
smoke tests, performance comparisons, bug fixes, refactors, simulations,
static analyses, documentation conclusions, and design decisions.

The block must answer:

```text
Question:
  What decision or claim is this work supposed to support?

Required path:
  What mechanism, branch, algorithm, state transition, assumption, or data path
  must be exercised or examined for the work to answer that question?

Path guard:
  Which concrete values or conditions decide whether that required path is
  actually relevant? Examples: n, threshold, compile flags, runtime options,
  input size, process count, thread count, boundary condition, initial state,
  data distribution, physical regime, API contract, ownership/lifetime rule.

Invalidating condition:
  Under what condition would this work become meaningless, misleading, or answer
  a different question?

Evidence to collect:
  What output, trace, counter, log line, or source-level fact will prove after
  the run that the required path was actually exercised?
```

The agent MUST explicitly compare the guard values before treating the result
as valid. For thresholded code, this means writing the actual predicate and
concrete values, for example:

```text
observed_n = 4157
threshold = 8192
predicate = observed_n < threshold
actual_path = std::sort fallback
intended_path = parallel radix
valid_for_intended_question = false
```

If `valid_for_intended_question` is false, the agent MUST stop and redesign the
work instead of collecting or interpreting results.

## Required Skeptical Pass

Before execution or conclusion, the agent MUST also write one counter-argument:

```text
This work may be meaningless or misleading because ...
```

The counter-argument must name at least one concrete mechanism that could make
the work answer the wrong question. Examples:

- input size below threshold;
- compile flag not actually enabled;
- runtime option ignored by the library;
- benchmark or model uses a synthetic payload that does not represent production data
  movement;
- process/thread count differs from the intended path;
- result could be dominated by setup, allocation, logging, or I/O instead of
  the target algorithm.
- bug fix changes a symptom path but not the failing mechanism;
- refactor preserves one call path but breaks another ownership or lifetime
  path;
- simulation is in a different physical regime from the claim;
- proof or derivation assumes a condition that is not true in the target case;
- documentation conclusion is based on old or non-authoritative evidence;
- comparison uses non-equivalent inputs, units, precision, compiler flags, or
  boundary conditions.

## Minimal Checklist

For any non-trivial scientific or engineering work, do not report a conclusion
until all of these are true:

1. The intended question is written.
2. The actual mechanism/path/assumption being exercised is identified.
3. The branch predicate, boundary condition, or concrete guard values are
   written.
4. The invalidating condition is written.
5. Evidence exists that the intended path or mechanism was actually exercised.
6. At least one alternative explanation or failure mode was considered.

## General Examples

### Benchmark Example

```text
Question:
  Is algorithm A faster than algorithm B for the production-relevant path?

Invalidating condition:
  If the input size triggers a fallback path, the benchmark is not measuring A.
```

### Bug-Fix Example

```text
Question:
  Does this patch fix the cause of the crash?

Invalidating condition:
  If the test only avoids the crashing input but does not exercise the original
  ownership/lifetime path, the patch may only hide the symptom.
```

### Refactor Example

```text
Question:
  Does this refactor preserve behavior?

Invalidating condition:
  If only the common call path is tested, but an uncommon caller relies on a
  side effect or aliasing behavior, the refactor evidence is incomplete.
```

### Scientific/Simulation Example

```text
Question:
  Does this result support the stated physical interpretation?

Invalidating condition:
  If the run is in a different resolution, time regime, boundary condition, or
  nondimensional parameter range, it may not support the claim.
```

### Documentation/Research Example

```text
Question:
  Is this status summary current and decision-relevant?

Invalidating condition:
  If it relies on stale notes, old logs, or secondary summaries instead of the
  active source of truth, it may answer a historical question rather than the
  current one.
```

## Why This Would Have Caught The Miss

The failed FDPS thread-cap sweep would have required this block:

```text
Question:
  Does limiting radix OpenMP threads improve FDPS radix sort performance?

Required path:
  RadixSort::lsdSort parallel radix region.

Path guard:
  n_tot must not fall into the std::sort threshold fallback.

Concrete values:
  observed particles = 4157
  threshold = 8192
  predicate = 4157 < 8192

Invalidating condition:
  If n_tot < threshold, thread-cap changes do not measure the radix region.

Result:
  invalid for the intended question.
```

That would have stopped the measurement before interpreting fallback timings as
radix-thread timings.
