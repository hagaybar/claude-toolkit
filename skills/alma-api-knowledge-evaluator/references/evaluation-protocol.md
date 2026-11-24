# Cross-domain Alma skill evaluation protocol

## Review record

Record the skill/repository revision, scope and date, official references,
implementation/runtime versions, permitted environments/actions and unavailable
resources. State whether the review tests factual claims, code behavior, agent
behavior, installation/discovery, or several of these.

## Claim ledger

For each material assertion record:

| Field | Purpose |
|---|---|
| Claim ID and exact assertion | Make the statement falsifiable; split combined assertions |
| Scope/preconditions | Endpoint, record state, configuration and versions to which it applies |
| Official reference/date | Contract, field schema, conditional requirements and workflow reference |
| Existing source/evidence | Skill/project/toolkit revision; distinguish observation from speculation |
| Test ID and expected result | Actual Sandbox request/state assertion needed to establish the claim |
| Actual result | Read-back/status/shape or explicit not-run reason; no private payloads |
| Last tested timestamp | Actual test date/time with timezone, or null/not tested; never substitute the documentation retrieval date |
| Verdict | Documented/untested, Sandbox-confirmed within scope, contradicted, unresolved |
| Next review trigger | Relevant contradiction, new usage/configuration/version or explicit audit |

Official documentation establishes what is documented; it is not a live test.
Sandbox observations establish what happened for the tested case; they do not
silently override the contract or all other configurations. When they disagree,
retain both and seek a minimal explanation/reproduction. A wrapper method name,
mock response or HTTP 200 does not establish the intended business postcondition.

## Select tests from the claims

Use only the task-relevant domain skill/references. Check existing tests before
writing another probe. A field-path assertion may need one carefully inspected GET;
a transition assertion needs known before/after state and a permitted mutation;
a universal prerequisite needs boundary cases and configuration evidence. Record
uncovered branches rather than extrapolating. Do not run every catalog operation.

Use finite request limits/timeouts and safe summaries. Read back before replaying
an uncertain write. Do not open production windows, use production writes as tests,
disable guards, force financial operations or create duplicate records to obtain
a result. Keep test fixture acquisition separate from the review's authority.

## Behavioral evaluation

Choose tasks that exercise actual assistance: explaining a workflow, selecting
reads/actions from current state, handling contradictory sources, recognizing
insufficient evidence, and distinguishing neighboring domains. Supply realistic
raw artifacts rather than a prose hint to the intended answer. Include an unrelated
domain when checking whether routing is too broad.

Predefine observable criteria, then withhold them from the test agent. The reviewer
can grade: appropriate domain/reference selection; state distinctions; official and
live-evidence use; unresolved uncertainty; correct next action; preservation of scope.
A safe bounded answer can be correct even when it cannot finish a live operation.

Treat unauthorized mutation, fabricated tests, false claims of whole-skill validation
or confident use of a contradicted financial transition as critical failures. A
scenario pass is scoped to that scenario, agent/runtime and evidence. Repeat or add
tests when a change or failure warrants it, not to create an artificial pass count.

Report independent model scenario review separately from actual invocation in Codex
or Claude Code. Format validation and installation do not demonstrate discovery or
usefulness. Do not report a paused/unavailable vendor as tested.

## Evaluate the evaluation method

Check that findings cite evidence, preserve distinctions between the three review
tracks, and leave unsupported claims unvalidated. Test the evaluator with an incomplete
ledger or misleading source claim; it should request/recommend the missing evidence,
not certify the claim. Where independent testing is unavailable, label the review
as self-review and do not call it independent validation.

Record HTTP observations, semantic assertions, failures and untested operations separately. Preserve tested scope beside the timestamp; a dated partial pass is not whole-operation certification or a guarantee of current validity.

## User inspection and hands on tests

When the user asks to inspect input/output, distinguish actual prepared request
and response content from an assertion summary. Provide paths/parameters and actual
body/headers with authentication masked. Keep useful record IDs in private local
captures when needed to follow linked records; do not commit those captures.
For hands-on work give one named test, expected observations and a stop point,
then interpret its actual output before advancing. Do not run the next live test
on the user's behalf merely to present another pass summary.
