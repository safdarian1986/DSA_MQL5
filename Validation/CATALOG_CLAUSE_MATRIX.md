# DSA-MQL5 Clause-Level Catalog Matrix

## Basis

- Catalog: `Catalog/DSA_MQL5_EN.docx`, freshly extracted from OOXML.
- Scientific reference: `Catalog/DataSience-en.docx`, treated as upstream objective, not a literal heavyweight implementation mandate.
- Owner decision: Deep Learning and Hybrid are no longer permanent specification gaps. They must be implemented as lightweight, causal, MQL5-native multi-scale sequence behavior without conventional online neural training.
- Current stage: independent Selection Data channels, Fast Path priority guard, Analysis Timeframe primary target path, New Analysis Bar commit sequencing, retained-output candidate rebuild, feature/regime scoring, lightweight native sequence expert, stress diagnostics, and station traceability implemented and validated.

## DataScience Crosswalk

| DataSience-en objective | DSA-MQL5 equivalent | Current status | Evidence / gap |
| --- | --- | --- | --- |
| Data ingestion | MT5 market data, OHLCV/spread, selected symbol/timeframe | PARTIAL | Analysis Timeframe can now feed the primary target path; full analysis-bar state lifecycle remains pending. |
| Quality assessment | data quality score, gap/time penalties, anomaly inputs | PARTIAL | `DSA_DataQualityScore`; broader cleaning dimensions remain incomplete. |
| Pattern discovery | trend, volatility, ACF/PACF, cycle, structure, regime | PASS | Feature-regime harness covers volatility context, CUSUM pressure, structure, and regime validity. |
| Feature engineering | causal feature snapshot, selected channel contract, and sequence signatures | PARTIAL | Selection Data, feature context, and sequence expert inputs are covered; broader cleaning/adaptive weighting remains incomplete. |
| Statistical models | Naive/Drift, Holt, Kalman, conformal | PARTIAL | Present but some state/uncertainty details remain simplified. |
| Machine Learning | Adaptive AR-Ridge plus feature engine | PARTIAL | Bounded Ridge exists; adaptive feature/lag/time weighting needs expansion. |
| Deep Learning objective | lightweight native Multi-Scale Sequence Expert | PASS | `DSA_SequenceExpertForecast`, `DSA_SequenceExpertHarness`, `deep_mode=true`. |
| Ensemble and scenarios | adaptive ensemble, Hybrid, future objects | PARTIAL | Hybrid sequence contribution exists; broader scenario semantics and shock-aware future tests remain incomplete. |
| Uncertainty | conformal bands and future uncertainty geometry | PARTIAL | Regime-conditioned conformal exists; calibration metrics need stronger evidence. |
| Backtesting and validation | prequential walk-forward plus Strategy Tester harnesses | PASS | Rolling MAE/RMSE, directional accuracy, coverage rate, and harness suite are present. |
| Monitoring/retraining | drift, safe mode, evidence-driven recalibration | PASS | Trigger coalescing, sliced adaptation, candidate approval/rejection, and tuning commit trace are covered by feature-regime harness. |
| Dashboard | graphical chart renderer | MQL5-FEASIBLE SUBSTITUTE | Uses chart buffers and objects instead of a textual dashboard. |

## DSA_MQL5_EN Clause Matrix

| # | Catalog clause | Status | Current evidence | Next required action |
| --- | --- | --- | --- | --- |
| 1 | Final System Architecture | PARTIAL | Core modules exist | Complete Closed/Live state and atomic commit. |
| 2 | MT5 Tool Definition | EXACT PASS | non-trading indicator, static scan | Keep invariant. |
| 3 | Exact User Input Contract | EXACT PASS | 10 `input` declarations | Keep invariant. |
| 4 | Tick-Safe Update Contract | PARTIAL | live path now precedes historical/adaptive background slices | Complete Closed/Live state and candidate commit. |
| 5 | Anti-Freeze and Anti-Lock Contract | PASS | bounded work budget, P0-before-P8 source guard, and stress-station harness runtime proof | Broaden duration datasets only if final regression exposes risk. |
| 6 | Adaptive Runtime Budget | PASS | latency EWMA, load budget, and runtime-cost model-score penalty covered by feature-regime harness | Add wider stress-duration datasets. |
| 7 | Runtime Priority | PARTIAL | `OnCalculate` prepares rebuild cheaply, then runs P0 before P8 slices | Complete Analysis Bar and lower-priority queue semantics. |
| 8 | Runtime Busy Guard | PARTIAL | `runtime_busy`, single active flags | Strengthen single-flight commit behavior. |
| 9 | Trigger Coalescing | PASS | reason mask merge plus history-revision harness `revision_trigger=true` | Broaden non-history trigger lifecycle tests. |
| 10 | Selection Data Contract | EXACT PASS | `DSASelectionChannels`, selection harness | Keep independent channels. |
| 11 | Auxiliary Central Series | EXACT PASS | OHLC average, median, OC midpoint | Keep as auxiliary, not replacement. |
| 12 | Candle 0 Contract | PARTIAL | live `DSA_ProcessLivePath` derives provisional `DSALiveState` from committed `DSAClosedState` | Add broader live component coverage tests. |
| 13 | ClosedState and LiveState | PASS | `Core/StateRegistry.mqh`, `DSA_StateIsolationHarness`, live state starts from valid closed state and is replaced each tick | Keep state isolation invariant. |
| 14 | Full History Range | EXACT PASS | adversarial `deep_bars=8437` | Keep full source coverage. |
| 15 | Progressive Historical Build | PASS | sliced historical build with retained-output candidate buffers and history-revision harness stale-candidate rejection | Broaden single-flight stress proof. |
| 16 | Model Maturity | PASS | feature maturity plus sequence confidence/maturity gates validated by `DSA_SequenceExpertHarness` | Broaden dataset coverage. |
| 17 | Adaptive Historical Weight | PARTIAL | Ridge time decay | Broaden evidence-based time weighting. |
| 18 | Fixed Market Parameters | PARTIAL | some adaptive scales | Classify and adapt market-behavior constants. |
| 19 | Model Bank | PASS | Naive/Drift, Holt, Kalman, AR-Ridge, sequence expert, ensemble, conformal, drift, and Safe Mode all present | Broaden calibration evidence. |
| 20 | Naive / Drift | EXACT PASS | `model.naive`, `model.drift` | Keep causal. |
| 21 | Adaptive Holt | PARTIAL | adaptive alpha/beta | Validate OOS-driven smoothing behavior. |
| 22 | Kalman Local Linear Trend | PARTIAL | level/slope/innovation approximation | Expose uncertainty/residual state more completely. |
| 23 | Adaptive AR-Ridge | PARTIAL | bounded 5D Ridge | Add adaptive lag/feature/time weight evidence. |
| 24 | Adaptive Volatility Engine | PASS | EW plus channel/range, MAD, Parkinson-style range, and vol-of-vol evidence | Broaden market dataset coverage. |
| 25 | Regime Engine | PASS | six regimes with CUSUM pressure, residual/disagreement, structure, vol-of-vol, and volume-shock evidence | Broaden market dataset coverage. |
| 26 | Model Mode | PASS | all six attach; Deep prioritizes sequence and Hybrid blends Statistical/Ridge/sequence | Keep mode contracts covered. |
| 27 | Feature Engine | PARTIAL | many causal features | Complete required families and tests. |
| 28 | Multi-Timeframe Leakage Guard | EXACT PASS | MTF causality harness and primary Analysis Timeframe harness | Keep closed higher-TF candles causal. |
| 29 | Main Formula Catalog | PARTIAL | formulas exist in modules | Complete missing formulas and traceability. |
| 30 | Main Algorithm Catalog | PASS | model, sequence, adaptation, approval, stress, and station algorithms exist with targeted harness proof | Keep matrix aligned during final closure. |
| 31 | 10-Phase System Map | PASS | station manifest validates all 50 station definitions with trace fields and harness proof | Keep manifest aligned with execution responsibilities. |
| 32 | Station 00 Runtime Foundation | PARTIAL | runtime scheduler state | Complete context/state registry semantics. |
| 33 | Phase 1 | PARTIAL | input/data contract plus analysis-rate primary snapshot | Complete analysis-bar state lifecycle. |
| 34 | Phase 2 | PARTIAL | quality score | cleaning/outlier dimensions incomplete. |
| 35 | Phase 3 | PASS | feature-regime harness covers causal channel, volatility, structure, and validation context | Keep sequence-specific features under Phase 6. |
| 36 | Phase 4 | PARTIAL | ACF/PACF/cycle/structure | reliability and reranking incomplete. |
| 37 | Phase 5 | PASS | volatility ensemble and regime context now covered by `DSA_FeatureRegimeHarness` | Broaden market dataset coverage. |
| 38 | Phase 6 | PASS | model bank includes classical, Ridge, sequence, Hybrid, conformal, drift, and Safe Mode behavior | Broaden adaptive weight calibration datasets. |
| 39 | Phase 7 | PARTIAL | forecast objects | scenario semantics need stronger proof. |
| 40 | Phase 8 | PASS | rolling OOS metrics plus adaptive candidate approval/rejection are covered by feature-regime harness | Broaden calibration datasets in final regression. |
| 41 | Phase 9 | PARTIAL | event engine basics | event taxonomy/finality proof incomplete. |
| 42 | Phase 10 | PARTIAL | buffers/objects/runtime plus station traceability proof | visual detail vocabulary incomplete. |
| 43 | Fast Path Every Tick | EXACT PASS | P0 `DSA_ProcessLivePath` runs before historical slices and adaptive jobs; CI guards call order | Keep invariant. |
| 44 | Medium Path New Analysis Bar | PASS | `DSA_ShouldRunMediumPath`, `DSA_IsAnalysisCommitHostBar`, Analysis Timeframe harness `commit_samples=30`, `hold_samples=90` | Keep analysis-boundary invariant. |
| 45 | Slow Path Evidence-Driven | PASS | retained-output rebuild candidates, stale rejection, stress-triggered recalibration, and adaptive approval/rejection are covered | Keep heavy work sliced. |
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
| 59 | Adaptive Band | PASS | bands use volatility, conformal radius, vol-of-vol, and volume-shock scaling | Broaden coverage datasets. |
| 60 | Prequential Walk-Forward | PARTIAL | previous forecast error | Add stored multi-metric OOS evidence. |
| 61 | Model Disagreement | PASS | disagreement includes statistical/Ridge spread plus sequence-family spread when active | Broaden OOS calibration datasets. |
| 62 | Regime-Conditioned Conformal | PARTIAL | regime residual selection | Strengthen coverage evidence. |
| 63 | Metrics | PASS | absolute error, squared error, rolling MAE/RMSE, directional accuracy, and coverage rate | Broaden reporting outputs. |
| 64 | Model Score | PASS | error, disagreement, quality, rolling validation, volatility stress, and runtime-cost penalty | Broaden OOS calibration datasets. |
| 65 | Drift | PARTIAL | drift score exists | Add distribution/structure triggers. |
| 66 | Safe Mode | PARTIAL | market safe gating | Validate mode transitions. |
| 67 | Computational Safe Mode | PASS | runtime load gates optional work and stress diagnostics defer heavy work under high load | Keep Fast Path free of diagnostic full scans. |
| 68 | Event Engine | PARTIAL | up/down/aux events | Add full supported event taxonomy. |
| 69 | Historical Event Finality | PARTIAL | anti-repaint harness covers outputs | Add event-specific finality test. |
| 70 | Live Events | PARTIAL | Candle0 provisional events | Isolate from historical commit. |
| 71 | Historical Analysis | PASS | display-state harness proves historical plots hide while calculation buffers stay active | Keep invariant. |
| 72 | Forecast Display | EXACT PASS | display-state harness proves forecast objects hide while forecast buffers stay active | Keep invariant. |
| 73 | Event Display | EXACT PASS | display-state harness proves event markers hide while core buffers stay active | Keep invariant. |
| 74 | Visual Detail | PARTIAL | detail input and load gating | Complete detail-priority behavior. |
| 75 | Adaptive Parameter Engine | PASS | sliced interval/ridge candidates now require evidence-based approval before tuning commit and reject insufficient evidence | Keep feature reranking as future refinement unless mandatory final gap remains. |
| 76 | Feature Reliability | PASS | feature instability combines ACF/PACF, cycle, MTF, volatility, and validation metric risk | Broaden historical reliability summaries. |
| 77 | Shock Handling | PARTIAL | shock regime and wider intervals | Add shock-specific fallback proof. |
| 78 | Anomaly Handling | PARTIAL | robust z / quality penalties | Add anomaly semantics and event link. |
| 79 | Model Approval | PASS | adaptive job records approval/rejection, reason mask, approved/rejected score, and avoids tuning-version changes on rejected candidates | Keep approval causal and bounded. |
| 80 | Stress Diagnostics | PASS | `DSA_ComputeStressDiagnosticsSlice`, `DSA_ProcessStressDiagnostics`, and `DSA_StressStationHarness` prove bounded diagnostics, load deferral, and recalibration request behavior | Broaden duration datasets in final regression if needed. |
| 81 | Internal Output Structure | PARTIAL | buffers and snapshots | Add traceable state/output mapping. |
| 82 | Code Architecture | PARTIAL | consolidated modules | Add real state components only where behavior needs them. |
| 83 | Standard Station Contract | PASS | manifest covers required state, validity, error state, output, mutation permission, dependencies, validation tag, priority, cost, live/closed flags, deferral, slicing, and heavy-task semantics for all 50 stations | Keep compact manifest; no artificial station classes required. |
| 84 | State Mutation | PARTIAL | explicit ClosedState/LiveState snapshots exist, but some model internals still use shared buffers | Broaden mutation-permission enforcement. |
| 85 | Normal Tick Contract | PARTIAL | P0 live path derives LiveState from ClosedState before rendering | Add broader live component tests. |
| 86 | New-Bar Tick Contract | PARTIAL | New Analysis Bar detection commits ClosedState before live processing | Add mature forecast resolution/online-state tests. |
| 87 | Heavy Trigger Contract | PARTIAL | reason mask and slices | Add candidate job lifecycle. |
| 88 | History Revision Contract | PASS | `DSA_HistoryRevisionHarness` proves bar/history fingerprint change, revision trigger, and completed-build restart | Keep bounded-sweep latency invariant. |
| 89 | Stale Result Protection | PASS | `DSA_HistoryRevisionHarness` proves sampled and unsampled stale candidates are rejected before commit | Broaden stale adaptive-job proof. |
| 90 | Ready-for-Production Contract | MISSING | current audit not complete | Requires zero mandatory PARTIAL/MISMATCH/MISSING. |

## Current Highest-Risk Work Queue

1. Event taxonomy, visual vocabulary, and broader calibration datasets.
2. Adaptive approval/rejection lifecycle and broader trigger tests.
3. Remaining partial data-quality, model-state, and live-event contracts.
