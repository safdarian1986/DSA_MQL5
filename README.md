# DSA-MQL5 Native

DSA-MQL5 Native is a pure MQL5, non-trading MetaTrader 5 custom indicator for chart-based time-series analysis, forecasting visualization, uncertainty bands, validation diagnostics, and event rendering.

## Current Readiness

- Compiled and executable locally in MetaTrader 5.
- Current production binary: `DSA_MQL5_Native.ex5`.
- Current source entrypoint: `DSA_MQL5_Native.mq5`.
- Authoritative Catalog documents are stored in `Catalog/`.
- Validation harnesses and tester configuration files are stored in `Validation/`.
- Selection Data multi-channel modes preserve independent O/H/L/C, H/L, and O/C channels internally.
- The P0 Fast Path runs before historical/adaptive background slices on every eligible tick.
- Closed-bar history revision coverage now uses per-bar fingerprints plus a bounded background audit.

The current implementation is not marked Full Catalog Complete yet. The owner has clarified that `Deep Learning = Multi-Scale Sequence Expert` means a lightweight, causal, MQL5-native multi-scale sequence expert, not a conventional online-trained neural network. That owner-resolved Deep/Hybrid roadmap is still being implemented.

## Validation Evidence

Latest local MetaEditor evidence is retained in `compile-evidence-20260813-165613-*.log`; each retained compile log reports `0 errors, 0 warnings`.

Latest local Strategy Tester evidence is summarized in:

- `Validation/IMPLEMENTATION_REPORT.md`
- `Validation/CATALOG_SPECIFICATION_AUDIT.md`
- `Validation/COMPLETION_AUDIT.md`

GitHub Actions validates repository structure, hygiene, source constraints, official input count, required Catalog/validation files, and retained compile-log evidence. It does not fake MQL5 compilation on GitHub runners.

## Non-Scope

This indicator does not execute trades, place orders, manage positions, call external APIs, require Python, load external DLLs, or claim profitability or predictive superiority.
