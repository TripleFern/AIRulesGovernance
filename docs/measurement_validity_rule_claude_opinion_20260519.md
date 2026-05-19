# Claude Opinion: Inquiry Validity Rule Candidate

- Date: 2026-05-19
- Author: Claude Sonnet 4.6 (claude-sonnet-4-6)
- Reviewed document: `measurement_validity_rule_candidate_20260519.md`
- Trigger: User question about whether this rule should be adopted, and why humans
  (and AIs) miss the class of error it targets.

---

## 1. Assessment of the rule

The rule addresses a real and distinct gap. The existing CLAUDE.md already requires
deep WHY iteration (§12A), triple verification (§4), and multiple evidence sources
(§19). What those rules do NOT force is an upstream check: before running, does the
planned action actually exercise the mechanism it claims to measure? That is the gap
the new rule fills.

The five-part block is well-structured. Its most important element is the concrete
predicate format:

```text
observed_n = 4157
threshold = 8192
predicate = 4157 < 8192   → TRUE
actual_path = std::sort fallback
intended_path = parallel radix
valid_for_intended_question = false
```

This is not a prose check ("I believe the threshold is relevant"). It is a
mechanical evaluation of a boolean condition before any result is collected or
interpreted. That is the right level of specificity for catching the FDPS miss.

The mandatory skeptical pass ("This work may be meaningless because...") is also
a genuine addition. It forces adversarial framing, not just confirmatory framing.
Without it, an agent can write a formally complete validity block that still assumes
the conclusion it should be questioning.

---

## 2. Weaknesses and risks

### 2.1 The "non-trivial" threshold is undefended

The rule applies to "non-trivial actions" but does not define the boundary. The
agent that might miss a path guard issue is the same agent deciding whether the
action is non-trivial. If the agent's judgment is trusted for that call, it could
also exempt itself from the very cases where the rule matters.

**Recommendation**: Replace "non-trivial" with a concrete trigger list. The
document already implies one: any action that involves a threshold, a compile flag,
a runtime option, a boundary condition, or a data distribution that controls which
code path executes. That is specific enough to be self-applying.

### 2.2 The rule does not prevent compliance theater

An agent under time pressure, or with incomplete understanding of the code path,
can write the block by substituting plausible-sounding values without actually
tracing the predicate. The block then looks valid while being wrong. The rule cannot
distinguish genuine tracing from imitation of tracing.

The only partial defense against this is the evidence requirement in item 5 of the
checklist: "Evidence exists that the intended path or mechanism was actually
exercised." Concrete execution traces, counter outputs, or log lines are harder to
fabricate than predicate assertions. The rule should emphasize this item more than
the others.

### 2.3 Self-referential dependency on meta-reasoning competence

The rule presupposes that an agent is competent at identifying the "required path"
and the "invalidating condition" in advance. But the FDPS miss happened precisely
because the agent did not notice that n_tot < threshold was the relevant predicate.
A rule requiring the agent to write down the invalidating condition depends on the
agent already knowing what can invalidate the experiment.

This is a genuine weakness, not a flaw that can be ruled away. The partial remedy
is the skeptical pass: if the agent is required to actively argue against the
validity of the work, it has a second opportunity to notice a path guard it missed
during the forward planning pass.

---

## 3. On why this class of miss happens

The user's observation: "まさか粒子数 < threshold に気付いていないとは思わず、
最初は指摘しなかった。人間にはなぜ思いつかないかが分からない。"

The mechanism is not unique to humans, and the document's own history shows it:
GPT-5.5 also did not point it out at first ("最初は指摘しなかった").

The failure mode is a known cognitive pattern. When a plan is constructed as
"apply patch X, then run experiment Y to measure X," the agent (human or AI)
anchors on the causal chain: X was applied, Y runs, Y measures X. The predicate
that could break the chain — n_tot < threshold — is invisible because it requires
inspecting the actual runtime values against the patch's guard condition, not
just confirming that the patch compiles and the experiment runs.

Humans are especially susceptible because:

1. Running an experiment that produces numbers feels like measurement. The subjective
   experience of "running" is not distinguished from "measuring the intended thing."
2. The threshold was just introduced by the human as part of the patch. It is hard
   to simultaneously be the author of a mechanism and the skeptic of whether it
   fires, because authorship creates an assumption of relevance.
3. The n_tot = 4157 value was present in prior documentation (the histogram trace
   results) but was not adjacent to the threshold=4096 experiment in the same
   context window. The failure was partly a context-integration failure, not purely
   a reasoning failure.

AI systems share failure modes 1 and 3. Mode 2 is different for AI: the AI does
not have authorship bias in the same form, but it has a related pattern — it plans
the experiment from the description of the intent, without separately checking
whether runtime conditions match the intent.

The new rule targets exactly this gap: it forces a context-integration step before
execution, requiring the agent to explicitly connect the runtime condition (n_tot)
to the plan condition (threshold) before treating results as valid.

---

## 4. Relationship to existing CLAUDE.md rules

| Existing rule | What it checks | Gap this rule fills |
|---|---|---|
| §12A WHY iteration ×3 | Why does the observed behavior occur? | Does not ask: is the intended behavior occurring at all? |
| §4 Triple verification | Are results verified by independent methods? | Does not ask: are the results from the intended path? |
| §19 Multiple evidence | Is the conclusion supported by independent evidence? | Does not ask: does any of the evidence come from the intended path? |
| §12 Problem-solving | Is the hypothesis falsifiable? | Does not force a concrete predicate against runtime values. |

The new rule is additive. It does not conflict with any existing rule. The unique
contribution is forcing a concrete boolean predicate at the guard condition level,
before results are collected.

---

## 5. Recommendation

**Adopt the rule.** The structure is sound, the motivating example is clear, and the
rule fills a genuine gap in the existing framework.

Suggested refinements before adoption:

1. Replace "non-trivial" with a trigger list based on: threshold/flag/option
   controlling which path executes; input size or distribution controlling coverage;
   physical or nondimensional parameter controlling physical regime; compile-time
   macro controlling feature activation.

2. Elevate checklist item 5 (evidence of path exercise) to the same emphasis as
   the predicate check. The predicate check can be faked; execution evidence is
   harder to fake.

3. Add a short note clarifying that the skeptical pass is not optional even when
   the agent believes the work is valid. Its purpose is to force a second search
   for invalidating conditions, not to confirm a belief already held.

4. Consider a minimal two-line version for CLAUDE.md that summarizes the rule and
   points to this document:

   > Before any measurement, experiment, or analysis, write the concrete predicate
   > that determines whether the intended code path is actually exercised, and
   > verify that the predicate evaluates TRUE for the actual runtime conditions.
   > Full rule: `docs/testing/measurement_validity_rule_candidate_20260519.md`.

---

## 6. On the user's implied question about AI capability

The fact that neither the human nor the AI caught this initially, and that
GPT-5.5 only raised it later, suggests two things:

First, the miss is not primarily a capability gap. Both systems were capable of
evaluating 4157 < 8192 when attention was directed there. The miss was an attention
allocation failure: neither system was prompted to check whether the experiment's
precondition was satisfied.

Second, rules are the right correction mechanism for this class of miss. If the
validity block had been required as a precondition for reporting results, the
concrete predicate evaluation would have been forced at the right moment. The
capability was always present; the required cognitive step was not scheduled.

This is the general case for procedural rules in AI systems: they do not add new
reasoning capability, but they redirect existing capability toward steps that are
likely to be skipped without a prompt.
