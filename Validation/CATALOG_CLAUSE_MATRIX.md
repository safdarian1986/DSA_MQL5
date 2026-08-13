# DSA-MQL5 Clause-Level Catalog Matrix

## Basis

- Catalog: `Catalog/DSA_MQL5_EN.docx`, freshly extracted from OOXML.
- Scientific reference: `Catalog/DataSience-en.docx`, treated as upstream objective, not a literal heavyweight implementation mandate.
- Owner decision: Deep Learning and Hybrid are no longer permanent specification gaps. They must be implemented as lightweight, causal, MQL5-native multi-scale sequence behavior without conventional online neural training.
- Current stage: independent Selection Data channels, Fast Path priority guard, Analysis Timeframe primary target path, New Analysis Bar commit sequencing, and retained-output candidate rebuild implemented and validated.

## DataScience Crosswalk

| DataSience-en objective | DSA-MQL5 equivalent | Current status | Evidence / gap |
| --- | --- | --- | --- |
| Data ingestion | MT5 market data, OHLCV/spread, selected symbol/timeframe | PARTIAL | Analysis Timeframe can now feed the primary target path; full analysis-bar state lifecycle remains pending. |
| Quality assessment | data quality score, gap/time penalties, anomaly inputs | PARTIAL | `DSA_DataQualityScore`; broader cleaning dimensions remain incomplete. |
| Pattern discovery | trend, volatility, ACF/PACF, cycle, structure, regime | PARTIAL | Implemented in feature/model layers, but several evidence families are simplified. |
| Feature engineering | causal feature snapshot and selected channel contract | PARTIAL | Selection Data is now exact; full feature family matrix remains incomplete. |
| Statistical models | Naive/Drift, Holt, Kalman, conformal | PARTIAL | Present but some state/uncertainty details remain simplified. |
| Machine Learning | Adaptive AR-Ridge plus feature engine | PARTIAL | Bounded Ridge exists; adaptive feature/lag/time weighting needs expansion. |
| Deep Learning objective | lightweight native Multi-Scale Sequence Expert | MISSING | Owner-resolved design direction exists; implementation pending. |
| Ensemble and scenarios | adaptive ensemble, Hybrid, future objects | PARTIAL | Classical ensemble exists; true Hybrid sequence contribution pending. |
| Uncertainty | conformal bands and future uncertainty geometry | PARTIAL | Regime-conditioned conformal exists; calibration metrics need stronger evidence. |
| Backtesting and validation | prequential walk-forward plus Strategy Tester harnesses | PARTIAL | Harness suite exists; metrics coverage is incomplete. |
| Monitoring/retraining | drift, safe mode, evidence-driven recalibration | PARTIAL | Trigger/coalescing and sliced adaptation exist; approval/state commit incomplete. |
| Dashboard | graphical chart renderer | MQL5-FEASIBLE SUBSTITUTE | Uses chart buffers and objects instead of a textual dashboard. |

## DSA_MQL5_EN Clause Matrix

| # | Catalog clause | Status | Current evidence | Next required action |
| --- | --- | --- | --- | --- |
| 1 | Final System Architecture | PARTIAL | Core modules exist | Complete Closed/Live state and atomic commit. |
| 2 | MT5 Tool Definition | EXACT PASS | non-trading indicator, static scan | Keep invariant. |
| 3 | Exact User Input Contract | EXACT PASS | 10 `input` declarations | Keep invariant. |
| 4 | Tick-Safe Update Contract | PARTIAL | live path now precedes historical/adaptive background slices | Complete Closed/Live state and candidate commit. |
| 5 | Anti-Freeze and Anti-Lock Contract | PARTIAL | bounded work budget plus P0-before-P8 source guard | Add stronger runtime stress proof. |
| 6 | Adaptive Runtime Budget | PARTIAL | latency EWMA and load budget | Include broader runtime cost in model score. |
| 7 | Runtime Priority | PARTIAL | `OnCalculate` prepares rebuild cheaply, then runs P0 before P8 slices | Complete Analysis Bar and lower-priority queue semantics. |
| 8 | Runtime Busy Guard | PARTIAL | `runtime_busy`, single active flags | Strengthen single-flight commit behavior. |
| 9 | Trigger Coalescing | PASS | reason mask merge plus history-revision harness `revision_trigger=true` | Broaden non-history trigger lifecycle tests. |
| 10 | Selection Data Contract | EXACT PASS | `DSASelectionChannels`, selection harness | Keep independent channels. |
| 11 | Auxiliary Central Series | EXACT PASS | OHLC average, median, OC midpoint | Keep as auxiliary, not replacement. |
| 12 | Candle 0 Contract | PARTIAL | live `DSA_ProcessLivePath` derives provisional `DSALiveState` from committed `DSAClosedState` | Add broader live component coverage tests. |
| 13 | ClosedState and LiveState | PASS | `Core/StateRegistry.mqh`, `DSA_StateIsolationHarness`, live state starts from valid closed state and is replaced each tick | Keep state isolation invariant. |
| 14 | Full History Range | EXACT PASS | adversarial `deep_bars=8437` | Keep full source coverage. |
| 15 | Progressive Historical Build | PASS | sliced historical build with retained-output candidate buffers and history-revision harness stale-candidate rejection | Broaden single-flight stress proof. |
| 16 | Model Maturity | PARTIAL | maturity-based weights | Add sequence maturity and residual maturity gates. |
| 17 | Adaptive Historical Weight | PARTIAL | Ridge time decay | Broaden evidence-based time weighting. |
| 18 | Fixed Market Parameters | PARTIAL | some adaptive scales | Classify and adapt market-behavior constants. |
| 19 | Model Bank | PARTIAL | classical models present | Add sequence expert and stronger state contracts. |
| 20 | Naive / Drift | EXACT PASS | `model.naive`, `model.drift` | Keep causal. |
| 21 | Adaptive Holt | PARTIAL | adaptive alpha/beta | Validate OOS-driven smoothing behavior. |
| 22 | Kalman Local Linear Trend | PARTIAL | level/slope/innovation approximation | Expose uncertainty/residual state more completely. |
| 23 | Adaptive AR-Ridge | PARTIAL | bounded 5D Ridge | Add adaptive lag/feature/time weight evidence. |
| 24 | Adaptive Volatility Engine | PARTIAL | EW plus channel/range evidence | Add MAD, Parkinson, vol-of-vol ensemble. |
| 25 | Regime Engine | PARTIAL | six regimes returned | Add CUSUM, residual, structure, volume shock evidence. |
| 26 | Model Mode | PARTIAL | all six attach | Deep/Hybrid semantics incomplete. |
| 27 | Feature Engine | PARTIAL | many causal features | Complete required families and tests. |
| 28 | Multi-Timeframe Leakage Guard | EXACT PASS | MTF causality harness and primary Analysis Timeframe harness | Keep closed higher-TF candles causal. |
| 29 | Main Formula Catalog | PARTIAL | formulas exist in modules | Complete missing formulas and traceability. |
| 30 | Main Algorithm Catalog | PARTIAL | algorithms exist in modules | Complete sequence/adaptation/approval algorithms. |
| 31 | 10-Phase System Map | PARTIAL | station manifest exists | Bind stations to actual execution evidence. |
| 32 | Station 00 Runtime Foundation | PARTIAL | runtime scheduler state | Complete context/state registry semantics. |
| 33 | Phase 1 | PARTIAL | input/data contract plus analysis-rate primary snapshot | Complete analysis-bar state lifecycle. |
| 34 | Phase 2 | PARTIAL | quality score | cleaning/outlier dimensions incomplete. |
| 35 | Phase 3 | PARTIAL | features implemented | feature family expansion pending. |
| 36 | Phase 4 | PARTIAL | ACF/PACF/cycle/structure | reliability and reranking incomplete. |
| 37 | Phase 5 | PARTIAL | volatility/regime | volatility ensemble and regime evidence incomplete. |
| 38 | Phase 6 | PARTIAL | model bank | sequence expert and adaptive weights incomplete. |
| 39 | Phase 7 | PARTIAL | forecast objects | scenario semantics need stronger proof. |
| 40 | Phase 8 | PARTIAL | OOS/conformal basics | metrics and approval incomplete. |
| 41 | Phase 9 | PARTIAL | event engine basics | event taxonomy/finality proof incomplete. |
| 42 | Phase 10 | PARTIAL | buffers/objects/runtime | station traceability and visual detail incomplete. |
| 43 | Fast Path Every Tick | EXACT PASS | P0 `DSA_ProcessLivePath` runs before historical slices and adaptive jobs; CI guards call order | Keep invariant. |
| 44 | Medium Path New Analysis Bar | PASS | `DSA_ShouldRunMediumPath`, `DSA_IsAnalysisCommitHostBar`, Analysis Timeframe harness `commit_samples=30`, `hold_samples=90` | Keep analysis-boundary invariant. |
| 45 | Slow Path Evidence-Driven | PARTIAL | adaptive/rebuild triggers and retained-output candidate buffers | Complete candidate lifecycle evidence. |
| 46 | Slow Work Slicing | PARTIAL | budgeted slices can run against candidate buffers | Add stronger single-flight/candidate proof. |
| 47 | Full Historical Pass | EXACT PASS | adversarial full-history harness | Keep invariant. |
| 48 | Atomic State Commit | PASS | retained-output rebuilds process into candidate buffers; `DSA_FingerprintBufferMatchesCurrent` rejects stale sampled/unsampled candidates before commit | Broaden adaptive candidate approval evidence. |
| 49 | Input Fingerprint | PARTIAL | computational fingerprint exists | Separate display-only inputs from analytical state. |
| 50 | Input Changes | PARTIAL | input change triggers rebuild | Avoid unnecessary rebuild for display-only changes. |
| 51 | Graphical Output Contract | PARTIAL | 10 buffers and future objects | Complete graphical vocabulary proof. |
| 52 | Market Structure Layer | PARTIAL | structure_position and events | Add support/resistance/congestion evidence. |
| 53 | Historical Event Layer | PARTIAL | event buffers | Expand event taxonomy and finality tests. |
| 54 | Future Layer | PARTIAL | forecast paths/objects | Add scenario and shock-aware tests. |
| 55 | Visual Language | PARTIAL | graphical-only output | Verify no forbidden textual dashboard. |
| 56 | Historical Buffers | EXACT PASS | 10 plot buffers | Keep invariant. |
| 57 | Future Objects | PARTIAL | semantic chart harness | Broaden object semantics. |
| 58 | Forecast Rectangle | EXACT PASS | chart-object semantic harness | Keep invariant. |
| 59 | Adaptive Band | PARTIAL | bands exist | Tie band width to volatility/conformal evidence. |
| 60 | Prequential Walk-Forward | PARTIAL | previous forecast error | Add stored multi-metric OOS evidence. |
| 61 | Model Disagreement | PARTIAL | disagreement score | Include sequence/ridge/stat family disagreement. |
| 62 | Regime-Conditioned Conformal | PARTIAL | regime residual selection | Strengthen coverage evidence. |
| 63 | Metrics | PARTIAL | absolute error and coverage | Add RMSE, DA, MAE summaries. |
| 64 | Model Score | PARTIAL | error/disagreement/quality | Add latency/runtime cost. |
| 65 | Drift | PARTIAL | drift score exists | Add distribution/structure triggers. |
| 66 | Safe Mode | PARTIAL | market safe gating | Validate mode transitions. |
| 67 | Computational Safe Mode | PARTIAL | runtime load gates optional work | Separate computational safe state. |
| 68 | Event Engine | PARTIAL | up/down/aux events | Add full supported event taxonomy. |
| 69 | Historical Event Finality | PARTIAL | anti-repaint harness covers outputs | Add event-specific finality test. |
| 70 | Live Events | PARTIAL | Candle0 provisional events | Isolate from historical commit. |
| 71 | Historical Analysis | PASS | display-state harness proves historical plots hide while calculation buffers stay active | Keep invariant. |
| 72 | Forecast Display | EXACT PASS | display-state harness proves forecast objects hide while forecast buffers stay active | Keep invariant. |
| 73 | Event Display | EXACT PASS | display-state harness proves event markers hide while core buffers stay active | Keep invariant. |
| 74 | Visual Detail | PARTIAL | detail input and load gating | Complete detail-priority behavior. |
| 75 | Adaptive Parameter Engine | PARTIAL | sliced scale candidates | Complete approval and feature reranking. |
| 76 | Feature Reliability | PARTIAL | quality and diagnostics | Add feature reliability records. |
| 77 | Shock Handling | PARTIAL | shock regime and wider intervals | Add shock-specific fallback proof. |
| 78 | Anomaly Handling | PARTIAL | robust z / quality penalties | Add anomaly semantics and event link. |
| 79 | Model Approval | PARTIAL | adaptive job updates scales | Add candidate approval/rejection state. |
| 80 | Stress Diagnostics | MISSING | no dedicated low-priority diagnostics | Implement lightweight deferred diagnostics. |
| 81 | Internal Output Structure | PARTIAL | buffers and snapshots | Add traceable state/output mapping. |
| 82 | Code Architecture | PARTIAL | consolidated modules | Add real state components only where behavior needs them. |
| 83 | Standard Station Contract | PARTIAL | station manifest metadata | Link station fields to execution/tests. |
| 84 | State Mutation | PARTIAL | explicit ClosedState/LiveState snapshots exist, but some model internals still use shared buffers | Broaden mutation-permission enforcement. |
| 85 | Normal Tick Contract | PARTIAL | P0 live path derives LiveState from ClosedState before rendering | Add broader live component tests. |
| 86 | New-Bar Tick Contract | PARTIAL | New Analysis Bar detection commits ClosedState before live processing | Add mature forecast resolution/online-state tests. |
| 87 | Heavy Trigger Contract | PARTIAL | reason mask and slices | Add candidate job lifecycle. |
| 88 | History Revision Contract | PASS | `DSA_HistoryRevisionHarness` proves bar/history fingerprint change, revision trigger, and completed-build restart | Keep bounded-sweep latency invariant. |
| 89 | Stale Result Protection | PASS | `DSA_HistoryRevisionHarness` proves sampled and unsampled stale candidates are rejected before commit | Broaden stale adaptive-job proof. |
| 90 | Ready-for-Production Contract | MISSING | current audit not complete | Requires zero mandatory PARTIAL/MISMATCH/MISSING. |

## Current Highest-Risk Work Queue

1. Full feature, volatility, regime, adaptive weights, latency-aware score.
2. Lightweight Multi-Scale Sequence Expert and true Hybrid ensemble.
3. Stress diagnostics and station traceability.
