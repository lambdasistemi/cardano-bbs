# Budget Report

Date: 2026-04-14

## Method

Measurements were taken from `aiken check --json` execution units on real
verifier acceptance tests in
[onchain/lib/bbs/budget.ak](/code/cardano-bbs-verify/onchain/lib/bbs/budget.ak).

The checked-in baseline used by CI lives in
[budget-baseline.json](/code/cardano-bbs-verify/specs/001-bbs-credentials/budget-baseline.json)
and is enforced by
[check-budget-matrix.sh](/code/cardano-bbs-verify/scripts/check-budget-matrix.sh).

Current verifier assumptions:

- signed-header support exists in the verifier and in datum serialization
- the generated budget cases in this report still use `header = ""`
- the nonce is still bound to the presentation header / transaction context
- the verifier includes:
  - disclosure-shape checks
  - transcript challenge recomputation
  - the core pairing equation

## Results

| Total attributes | Disclosed | Memory ExUnits | CPU ExUnits | Status vs 10B CPU budget |
| --- | ---: | ---: | ---: | --- |
| 1 | 1 | 1,828,884 | 2,806,522,370 | Pass |
| 5 | 1 | 3,423,196 | 4,255,648,004 | Pass |
| 5 | 2 | 3,615,727 | 4,312,524,836 | Pass |
| 10 | 1 | 5,480,751 | 6,087,153,959 | Pass |
| 10 | 2 | 5,688,932 | 6,148,665,456 | Pass |
| 15 | 1 | 7,610,156 | 7,940,992,039 | Pass |
| 15 | 2 | 7,833,987 | 8,007,138,201 | Pass |

## Interpretation

- The verifier stays under the 10B CPU transaction budget for every measured
  case up to 15 total attributes.
- Hidden messages are not free. Holding disclosed count at 1 still grows CPU
  from `2.81B` at total 1 to `4.26B`, `6.09B`, and `7.94B` at totals 5, 10,
  and 15.
- Disclosing one extra attribute adds measurable cost at the same total size,
  but much less than adding five more total attributes:
  - total 5: `+56.9M` CPU, `+192,531` memory from 1 disclosed to 2 disclosed
  - total 10: `+61.5M` CPU, `+208,181` memory
  - total 15: `+66.1M` CPU, `+223,831` memory
- The current CI now compares these exact cases against the checked-in baseline
  so regressions in the current Aiken verifier fail the gate immediately.

## Likely Cost Drivers

- transcript reconstruction and per-message scalar multiplication as total
  attribute count grows
- separate loops over disclosed and undisclosed messages, which is why hidden
  messages still affect the verifier budget
- the final pairing check on top of transcript work

## Immediate Follow-Up

1. Re-measure with non-empty signed headers, because the current matrix still
   assumes `header = ""`.
2. Extend the matrix beyond 15 total attributes to find the practical cutoff
   for the current verifier.
3. Keep the
   [RoundTripSpec.hs](/code/cardano-bbs-verify/offchain/test/Integration/RoundTripSpec.hs)
   integration fixture aligned with any future redeemer-shape changes.
