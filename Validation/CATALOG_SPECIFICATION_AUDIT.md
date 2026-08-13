# DSA-MQL5 Catalog Specification Audit

## Source Inventory

- `Catalog/DSA_MQL5_EN.docx`: primary DSA-MQL5 implementation Catalog.
- `Catalog/DataSience-en.docx`: general time-series and data-science roadmap.
- Fresh OOXML extraction covered document paragraphs and tables. No prior completion report was used as a source of truth.

## Authoritative Requirements Model

- Non-trading MT5 custom indicator named `DSA_MQL5_Native.mq5`.
- Pure MQL5 implementation using active MT5 terminal market data only.
- No Python, DLL, WebRequest, external API, external model server, order execution, position management, Stop Loss, or Take Profit behavior.
- Exactly 10 official inputs and no user-configurable update interval.
- Full available history from oldest available candle through Candle 0 must participate in the computational chain.
- Candle 0 is live and provisional; closed historical bars and events must remain final.
- Higher-timeframe features must use only candles finalized by the host historical time.
- Runtime must preserve Fast / Medium / Slow separation, budget heavy work, coalesce triggers, and avoid full refits on ordinary ticks.
- Model bank requires Naive/Drift, Adaptive Holt, Kalman, Adaptive AR-Ridge, Adaptive Ensemble, Conformal uncertainty, Prequential Walk-Forward validation, Drift, Safe Mode, and graphical rendering.
- Future objects require forecast path, lower/upper path, forecast rectangle/cone geometry, and scenario boundaries.

## Specification Gaps

- `Deep Learning = Multi-Scale Sequence Expert` is named but not specified with sufficient architecture, equations, training/inference behavior, state contract, or MQL5 station mapping.
- `Hybrid = Statistical + Ridge + Multi-Scale Ensemble` inherits the same undefined Multi-Scale component.
- The general DataScience document lists LSTM/TCN/Attention formulas at roadmap level, but does not define a Catalog-compliant DSA-MQL5 neural implementation.

## Current Traceability Summary

| Area | Status | Evidence |
| --- | --- | --- |
| Pure MQL5 non-trading indicator | PASS | `DSA_MQL5_Native.mq5`, static dependency scan |
| Exactly 10 official inputs | PASS | `DSA_MQL5_Native.mq5` input section |
| No update interval input | PASS | Static scan; no timer input |
| Full-history progressive build | PASS | `DSA_ProcessHistoricalSlice`, adversarial harness `deep_bars=8437` |
| Candle 0 live path | PASS | `DSA_ProcessLivePath`, tester every-tick calculation |
| Closed historical anti-repaint | PASS | adversarial harness captured closed bar and compared after future bars |
| MTF leakage guard | PASS | `Data/MTFAlignment.mqh`, MTF harness `samples=234` |
| Naive / Holt / Kalman | PASS | `Models/ModelBank.mqh` |
| AR-Ridge | PASS | causal bounded ridge solve; Fast Path holds prior ridge state |
| Adaptive ensemble | PASS | mode and maturity weights in `DSA_ComputeModels` |
| Prequential validation | PASS | previous forecast resolved against newly available target |
| Conformal uncertainty | PASS | causal residual pools with regime preference |
| Drift and market safe mode | PASS | model drift, disagreement, quality, shock gating |
| Computational safe-mode behavior | PASS | runtime load gates heavy jobs and reduces visual horizon |
| Future object semantics | PASS | semantic chart harness validates types, anchors, bounds, scenarios |
| All official Model Mode values attach | PASS | `DSA_ModelModeHarness`, all six modes true |
| Deep Learning implementation | SPECIFICATION GAP | undefined Multi-Scale Sequence Expert; neural approximation removed |
| Hybrid Multi-Scale component | SPECIFICATION GAP | undefined Multi-Scale Ensemble; statistical/ridge subset remains |
| Arbitrary unsampled history revision detection | PARTIAL | sparse history fingerprint, progressive rebuild on detected revision |
| Predictive accuracy / profitability | NOT APPLICABLE | explicitly outside scope |

## Fresh Evidence

- Final compile: `compile-goal2-20260813-133756-final.log`, `0 errors, 0 warnings`.
- Harness compiles: `compile-goal2-20260813-133756-*-harness.log`, all `0 errors, 0 warnings`.
- Latest Strategy Tester run window: `2026-08-13 13:39-13:41` in `C:\Users\ariapars\AppData\Roaming\MetaQuotes\Terminal\D0E8209F77C8CF37AD8BF550E51FF075\Tester\logs\20260813.log`.
- Adversarial full-history and anti-repaint runtime: `OnTester result 1`, `failures=0`, `deep_bars=8437`.
- MTF causality runtime: `OnTester result 1`, `failures=0`, `samples=234`.
- Future object semantic runtime: `OnTester result 1`, `failures=0`, `count=121`.
- Model mode runtime: `OnTester result 1`, all six official modes true.

## Audit Conclusion

Most implementable Catalog requirements now have static and runtime evidence. The project must not be marked production-ready while Deep Learning / Multi-Scale behavior remains undefined by the Catalog.
