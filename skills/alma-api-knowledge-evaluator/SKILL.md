---
name: alma-api-knowledge-evaluator
description: Evaluate Alma API skills for factual accuracy, implementation alignment, and usefulness on realistic tasks using official documentation and controlled Sandbox evidence. Initial evaluation method; conclusions require traceable evidence.
---

# Alma API Knowledge Evaluator

Evaluate a selected Alma domain skill or an explicitly bounded set of claims.
This is a cross-domain review method, not a substitute for domain expertise or
permission to run all API operations. The method itself is an initial draft;
record its limitations and improve it when an evaluation exposes a failure.

## Scope the review

Identify the target skill revision, domain, user goal, existing evidence, installed
toolkit version and permitted resources. Review domain-specific project instructions
and tests. Preserve their existing authorization and private-data boundaries.
Use [the evaluation protocol](references/evaluation-protocol.md) for a full review.

Keep three tracks separate:
1. **Knowledge accuracy:** compare each material assertion with official API/schema
   and product-workflow documentation, then relevant Sandbox observations.
2. **Implementation alignment:** inspect what the actual installed wrapper/project
   sends, parses and considers success; mocks alone do not prove remote behavior.
3. **Agent usefulness:** give realistic tasks to an agent using the target skill,
   inspect its choices/explanations and score observable outcomes.

## Establish evidence rather than agreement

Extract testable claims, especially overloaded terms, absolute prerequisites,
parameter syntax, response paths, transition effects and error diagnoses. Check
existing project/toolkit work before creating a new test. Use the official reference
as the contract source and actual Sandbox tests as scoped observations. Preserve
conflicts rather than treating either historical prose or one response as universal.

Use documented/untested, Sandbox-confirmed within tested scope, contradicted or
unresolved verdicts. Mark a source-code observation as such. Tie every conclusion to
source/version and expected/actual evidence; do not call an entire skill validated
because a few claims, format checks or code tests passed.

## Run proportionate tests

Start with static review and bounded Sandbox reads. For a live test record method,
path template, parameter names, fixture preconditions, expected/actual states and
tested scope without exposing secrets or private records. Live writes need an
already-authorized bounded Sandbox fixture/action; a review request is not blanket
authorization for all mutations. If prerequisites are missing, record the claim as
untested and describe the needed test rather than inventing a pass or probing production.

For behavioral tests use realistic raw artifacts, an isolated workspace and only
the permissions required. Keep the expected answer/rubric out of the test agent's
prompt. Distinguish independent scenario evaluation, automatic discovery and actual
end-to-end use in each vendor client. Report unavailable clients honestly.

## Return and preserve the review

Report findings by consequence with claim/task IDs, supporting evidence, coverage
and limits. Separate domain corrections, toolkit/consumer bugs and skill-routing or
instruction failures. Propose the smallest relevant correction and retain a useful
regression or scenario when it catches a real failure. Update a conclusion only
after the supporting check, and keep unresolved claims visible.

Store reusable domain knowledge in the domain skill, generic evaluation mechanics
here, and campaign-specific selection/approval rules in the project. Keep private
fixtures/results ignored; version redacted evidence, code and test scenarios in the
owning repository. Do not silently refresh installed skills or broaden runtime policy
as part of merely evaluating them.
