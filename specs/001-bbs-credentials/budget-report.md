# Budget Report

Date: 2026-04-12

## Method

Measurements were taken from `aiken check` execution units on real verifier acceptance tests in [onchain/lib/bbs/budget.ak](/code/cardano-bbs-verify/onchain/lib/bbs/budget.ak).

Current verifier assumptions:

- signed-header support exists in the verifier and in datum serialization
- the generated budget cases in this report still use `header = ""`
- the nonce is still bound to the presentation header / transaction context
- the verifier includes:
  - disclosure-shape checks
  - transcript challenge recomputation
  - the core pairing equation

## Results

| Attributes | Disclosed | Memory ExUnits | CPU ExUnits | Status vs 10B CPU budget |
| --- | ---: | ---: | ---: | --- |
| 1 | 1 | 1,828,884 | 2,806,522,370 | Pass |
| 5 | 2 | 3,615,727 | 4,312,524,836 | Pass |
| 10 | 4 | 6,096,013 | 6,269,220,228 | Pass |

## Interpretation

- The current verifier now fits within the 10B CPU transaction budget for the measured 1, 5, and 10 attribute cases.
- This satisfies the current FR-007 and SC-006 budget target for the currently measured empty-header proof flow.
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

1. Re-measure with non-empty signed headers, because the current measurements still assume `header = ""`.
2. Build the first submitted-transaction integration slice through `cardano-node-clients`.
3. Keep the [RoundTripSpec.hs](/code/cardano-bbs-verify/offchain/test/Integration/RoundTripSpec.hs) integration fixture aligned with any future redeemer-shape changes.
