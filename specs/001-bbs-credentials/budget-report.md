# Budget Report

Date: 2026-04-12

## Method

Measurements were taken from `aiken check` execution units on real verifier acceptance tests in [onchain/lib/bbs/budget.ak](/code/cardano-bbs-verify/onchain/lib/bbs/budget.ak).

Current verifier assumptions:

- no signed header is carried on-chain yet
- generated budget cases therefore use `header = ""`
- the nonce is still bound to the presentation header / transaction context
- the verifier includes:
  - disclosure-shape checks
  - transcript challenge recomputation
  - the core pairing equation

## Results

| Attributes | Disclosed | Memory ExUnits | CPU ExUnits | Status vs 10B CPU budget |
| --- | ---: | ---: | ---: | --- |
| 1 | 1 | 1,826,482 | 2,805,715,072 | Pass |
| 5 | 2 | 3,613,325 | 4,311,717,538 | Pass |
| 10 | 4 | 6,093,611 | 6,268,412,930 | Pass |

## Interpretation

- The current verifier now fits within the 10B CPU transaction budget for the measured 1, 5, and 10 attribute cases.
- This satisfies the current FR-007 and SC-006 budget target for the no-header proof flow.
- Compared to the previous measured version, CPU improved by roughly:
  - 5.2% at 1 attribute
  - 29.9% at 5 attributes
  - 50.2% at 10 attributes
- The main win came from generating the BBS message generator list once per proof verification instead of rebuilding it repeatedly during transcript reconstruction.

## Likely Cost Drivers

- transcript reconstruction and per-message scalar multiplication as attribute count grows
- generator derivation if it is recomputed inside inner verifier loops
- the final pairing check on top of transcript work

## Immediate Follow-Up

1. Re-measure after adding signed-header support, because the current measurements still assume `header = ""`.
2. Re-run the budget suite when selective disclosure logic changes, because partial-disclosure handling can still shift verifier cost.
3. Keep the [RoundTripSpec.hs](/code/cardano-bbs-verify/offchain/test/Integration/RoundTripSpec.hs) integration fixture aligned with any future signed-header or redeemer-shape changes.
