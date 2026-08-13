# DSA-MQL5 Native

DSA-MQL5 Native is a pure MQL5, non-trading MetaTrader 5 custom indicator for chart-based time-series analysis, forecasting visualization, uncertainty bands, validation diagnostics, event rendering, stress diagnostics, and Catalog station traceability.

## Readiness

Status: `PRODUCTION READY` for the Pure-MQL5 DSA Catalog contract.

- Production source: `DSA_MQL5_Native.mq5`
- Production binary: `DSA_MQL5_Native.ex5`
- Catalog sources: `Catalog/DSA_MQL5_EN.docx`, `Catalog/DataSience-en.docx`
- Final compile evidence: `compile-evidence-20260813-215123-*.log`
- Final runtime evidence: `Validation/final-runtime-regression-20260813-215123.json`

The final compile pass covers the production indicator plus 14 validation harnesses. All 15 targets report `0 errors, 0 warnings`.

The final runtime regression covers 14 Strategy Tester configs and all report `OnTester result 1` with `failures=0`.

## Contract Summary

- Exactly 10 official inputs.
- No update-interval input and no timer dependency.
- No trading, order execution, position management, external API, Python, DLL import, or model-server dependency.
- Full available history participates through bounded, retained-output progressive builds.
- Normal tick processing keeps Fast Path work ahead of background rebuild, adaptive, diagnostic, and visual-heavy work.
- Analysis Timeframe is the primary causal feature path; higher-timeframe values use finalized source candles for closed host bars.
- ClosedState and LiveState are isolated; Candle0 remains provisional and closed historical output remains final.
- Deep mode uses the owner-approved lightweight native sequence expert.
- Hybrid mode blends Statistical, Ridge, and the native sequence family through the adaptive ensemble.
- Stress diagnostics are bounded and deferred.
- Station traceability is covered by the 50-station manifest and harness proof.

## Evidence

See:

- `Validation/CATALOG_CLAUSE_MATRIX.md`
- `Validation/CATALOG_SPECIFICATION_AUDIT.md`
- `Validation/IMPLEMENTATION_REPORT.md`
- `Validation/COMPLETION_AUDIT.md`

## Residual Limits

The indicator does not claim profitability or universal statistical superiority. Heavyweight generic DataScience techniques are represented by MQL5-feasible native substitutes where required by the final Catalog architecture. History revision detection is bounded and progressive for tick safety, with candidate commits guarded against stale closed-bar fingerprints.
