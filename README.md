# DSA-MQL5 Native

DSA-MQL5 Native is a pure MQL5, non-trading MetaTrader 5 custom indicator for chart-based time-series analysis, forecasting visualization, uncertainty bands, validation diagnostics, event rendering, stress diagnostics, and Catalog station traceability.

## Readiness

Status: `PRODUCTION READY` for the Pure-MQL5 DSA Catalog contract.

- Production source: `DSA_MQL5_Native.mq5`
- Production binary: `DSA_MQL5_Native.ex5`
- Catalog sources: `Catalog/DSA_MQL5_EN.docx`, `Catalog/DataSience-en.docx`
- Final compile evidence: `compile-evidence-20260813-224845-*.log`
- Final runtime evidence: `Validation/final-runtime-regression-20260813-224845.json`

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
- Feature Engine covers price, returns, candle geometry, trend, volatility, volume, memory, cycle, time, MTF, and reliability evidence.
- Model Bank exposes Kalman level/slope/strength/innovation/residual/uncertainty/forecast and evidence-approved adaptive expert weights.
- Adaptive AR-Ridge exposes adaptive lag, feature, time, and horizon weights through bounded native candidates.
- Deep mode uses the owner-approved lightweight native sequence expert.
- Hybrid mode blends Statistical, Ridge, and the native sequence family through the adaptive evidence ensemble.
- Stress diagnostics are bounded and deferred.
- Event taxonomy covers Trend Change, Regime Change, Shock, Anomaly, Breakout, Up Pressure, Down Pressure, and Signal End with historical finality metadata.
- Full visual detail renders forecast cone, scenario bands, support/resistance, congestion, regime, and event markers.
- Station traceability is covered by the 50-station manifest with actual implementation owners and harness proof.

## Evidence

See:

- `Validation/CATALOG_CLAUSE_MATRIX.md`
- `Validation/CATALOG_SPECIFICATION_AUDIT.md`
- `Validation/IMPLEMENTATION_REPORT.md`
- `Validation/COMPLETION_AUDIT.md`

## Residual Limits

The indicator does not claim profitability or universal statistical superiority. Heavyweight generic DataScience techniques are represented by MQL5-feasible native substitutes where required by the final Catalog architecture. Real volume is reported only when available through the platform data path; otherwise tick volume remains the causal volume source. History revision detection is bounded and progressive for tick safety, with candidate commits guarded against stale closed-bar fingerprints and high-load finalization deferral.
