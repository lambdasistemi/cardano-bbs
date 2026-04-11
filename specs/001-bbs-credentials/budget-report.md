# Budget Report

Date: 2026-04-11

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
| 1 | 1 | 2,192,593 | 3,524,919,934 | Pass |
| 5 | 2 | 7,108,242 | 7,164,664,334 | Pass |
| 10 | 4 | 17,391,788 | 14,175,952,361 | Fail |

## Interpretation

- The current verifier is acceptable for small and medium credentials.
- The current verifier exceeds the 10B CPU transaction budget at 10 attributes.
- This means FR-007 and SC-006 are not currently satisfied.

## Likely Cost Drivers

- repeated G1 decompression / compression during transcript reconstruction
- per-message scalar multiplication as attribute count grows
- the final pairing check on top of transcript work

## Immediate Follow-Up

1. Reduce point decompression / recompression churn inside [verify.ak](/code/cardano-bbs-verify/onchain/lib/bbs/verify.ak).
2. Re-measure after any verifier refactor before extending selective disclosure further.
3. Keep signed-header support blocked behind another measurement pass, because the 10-attribute case already fails.
