# DSA-MQL5 Native

DSA-MQL5 Native is a pure MQL5, non-trading MetaTrader 5 custom indicator for chart-based time-series analysis, forecasting visualization, uncertainty bands, validation diagnostics, and event rendering.

## Current Readiness

- Compiled and executable locally in MetaTrader 5.
- Current production binary: `DSA_MQL5_Native.ex5`.
- Current source entrypoint: `DSA_MQL5_Native.mq5`.
- Authoritative Catalog documents are stored in `Catalog/`.
- Validation harnesses and tester configuration files are stored in `Validation/`.

The current implementation is not marked Full Catalog Complete because the Catalog names `Deep Learning = Multi-Scale Sequence Expert` and `Hybrid = Statistical + Ridge + Multi-Scale Ensemble` without enough implementable detail to define a unique native-MQL5 sequence architecture.

## Validation Evidence

Latest local MetaEditor evidence is retained in `compile-goal2-20260813-133756-*.log`; each retained compile log reports `0 errors, 0 warnings`.

Latest local Strategy Tester evidence is summarized in:

- `Validation/IMPLEMENTATION_REPORT.md`
- `Validation/CATALOG_SPECIFICATION_AUDIT.md`
- `Validation/COMPLETION_AUDIT.md`

GitHub Actions validates repository structure, hygiene, source constraints, official input count, required Catalog/validation files, and retained compile-log evidence. It does not fake MQL5 compilation on GitHub runners.

## Non-Scope

This indicator does not execute trades, place orders, manage positions, call external APIs, require Python, load external DLLs, or claim profitability or predictive superiority.
