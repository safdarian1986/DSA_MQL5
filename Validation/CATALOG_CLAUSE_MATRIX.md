# DSA-MQL5 Clause-Level Catalog Matrix

## Basis

- Catalog: `Catalog/DSA_MQL5_EN.docx`, freshly extracted from OOXML.
- Scientific reference: `Catalog/DataSience-en.docx`, treated as upstream objective, not a literal heavyweight implementation mandate.
- Owner decision: Deep Learning and Hybrid are no longer permanent specification gaps. They must be implemented as lightweight, causal, MQL5-native multi-scale sequence behavior without conventional online neural training.
- Current stage: independent Selection Data channels, Fast Path priority guard, Analysis Timeframe primary target path, retained-output candidate rebuild, complete practical feature families, Kalman state contract, adaptive AR-Ridge, per-expert evidence approval, full event taxonomy/finality, full visual market-structure objects, stress diagnostics, station source-owner traceability, and tick-safe finalization guard implemented and validated.

## DataScience Crosswalk

| DataSience-en objective | DSA-MQL5 equivalent | Current status | Evidence / gap |
| --- | --- | --- | --- |
| Data ingestion | MT5 market data, OHLCV/spread, selected symbol/timeframe | PASS | independent selection channels plus Analysis Timeframe primary snapshots and state lifecycle harnesses are covered. |
| Quality assessment | data quality score, gap/time penalties, anomaly inputs | PASS | OHLCV quality, spread/volume/time-gap penalties, robust-z anomaly events, and stress diagnostics are covered. |
| Pattern discovery | trend, volatility, ACF/PACF, cycle, structure, regime | PASS | Feature-regime harness covers volatility context, CUSUM pressure, structure, and regime validity. |
| Feature engineering | causal feature snapshot, selected channel contract, feature reliability, and sequence signatures | PASS | price/return/candle/trend/volatility/volume/memory/cycle/time/MTF/reliability fields are covered by feature and sequence harnesses. |
| Statistical models | Naive/Drift, Holt, Kalman, conformal | PASS | model-detail harness proof covers Holt/Kalman state, conformal radius, drift, and safe fallback. |
| Machine Learning | Adaptive AR-Ridge plus feature engine | PASS | bounded AR-Ridge, adaptive lag/feature/time/horizon weighting, adaptive lambda approval, and ML mode are covered. |
| Deep Learning objective | lightweight native Multi-Scale Sequence Expert | PASS | `DSA_SequenceExpertForecast`, `DSA_SequenceExpertHarness`, `deep_mode=true`. |
| Ensemble and scenarios | per-expert evidence ensemble, Hybrid, future objects | PASS | OOS/stability/maturity/coverage/shock/latency evidence, expert approval, Hybrid sequence contribution, forecast cone, scenario boundaries, and chart-object semantic tests are covered. |
| Uncertainty | conformal bands and future uncertainty geometry | PASS | regime-conditioned conformal radius, coverage metrics, horizon growth, and future cone objects are covered. |
| Backtesting and validation | prequential walk-forward plus Strategy Tester harnesses | PASS | Rolling MAE/RMSE, directional accuracy, coverage rate, and harness suite are present. |
| Monitoring/retraining | drift, safe mode, evidence-driven recalibration | PASS | Trigger coalescing, sliced adaptation, candidate approval/rejection, and tuning commit trace are covered by feature-regime harness. |
| Dashboard | graphical chart renderer | MQL5-FEASIBLE SUBSTITUTE | Uses chart buffers and objects instead of a textual dashboard. |

## DSA_MQL5_EN Clause Matrix

| # | Catalog clause | Status | Current evidence | Next required action |
| --- | --- | --- | --- | --- |
| 1 | Final System Architecture | PASS | modules, input contract, scheduler, ClosedState/LiveState, retained candidate state, station manifest, and validation suite are aligned | Final docs must synchronize status. |
| 2 | MT5 Tool Definition | EXACT PASS | non-trading indicator, static scan | Keep invariant. |
| 3 | Exact User Input Contract | EXACT PASS | 10 `input` declarations | Keep invariant. |
| 4 | Tick-Safe Update Contract | PASS | P0 live path precedes bounded historical/adaptive/diagnostic slices and no timer/update input exists | Keep runtime budget invariant. |
| 5 | Anti-Freeze and Anti-Lock Contract | PASS | bounded work budget, P0-before-P8 source guard, and stress-station harness runtime proof | Broaden duration datasets only if final regression exposes risk. |
| 6 | Adaptive Runtime Budget | PASS | latency EWMA, load budget, and runtime-cost model-score penalty covered by feature-regime harness | Add wider stress-duration datasets. |
| 7 | Runtime Priority | PASS | OnCalculate order and harnesses cover build prep, Analysis Bar commit, P0 live, revision audit, adaptive job, and stress diagnostics | Keep lower-priority work bounded. |
| 8 | Runtime Busy Guard | PASS | runtime busy, single active rebuild/adaptive flags, version guards, and stale candidate rejection are covered | Keep no unbounded queue. |
| 9 | Trigger Coalescing | PASS | reason mask merge plus history-revision harness `revision_trigger=true` | Broaden non-history trigger lifecycle tests. |
| 10 | Selection Data Contract | EXACT PASS | `DSASelectionChannels`, selection harness | Keep independent channels. |
| 11 | Auxiliary Central Series | EXACT PASS | OHLC average, median, OC midpoint | Keep as auxiliary, not replacement. |
| 12 | Candle 0 Contract | PASS | live path derives provisional LiveState from ClosedState and chart/event harness validates live provisional flags | Keep Candle0 replaceable. |
| 13 | ClosedState and LiveState | PASS | `Core/StateRegistry.mqh`, `DSA_StateIsolationHarness`, live state starts from valid closed state and is replaced each tick | Keep state isolation invariant. |
| 14 | Full History Range | EXACT PASS | adversarial `deep_bars=8437` | Keep full source coverage. |
| 15 | Progressive Historical Build | PASS | sliced historical build with retained-output candidate buffers and history-revision harness stale-candidate rejection | Broaden single-flight stress proof. |
| 16 | Model Maturity | PASS | feature maturity plus per-expert approval gates and sequence confidence/maturity gates validated by `DSA_FeatureRegimeHarness` and `DSA_SequenceExpertHarness` | Broaden dataset coverage. |
| 17 | Adaptive Historical Weight | PASS | Ridge uses causal time decay, adaptive lag/feature/time/horizon weights, and adaptive lambda approval; sequence uses age decay | Keep bounded windows. |
| 18 | Fixed Market Parameters | PASS | market-behavior parameters are data-scaled through quality, volatility, maturity, runtime, and adaptive tuning | Structural numeric guards remain fixed. |
| 19 | Model Bank | PASS | Naive/Drift, Holt, Kalman, AR-Ridge, sequence expert, ensemble, conformal, drift, and Safe Mode all present | Broaden calibration evidence. |
| 20 | Naive / Drift | EXACT PASS | `model.naive`, `model.drift` | Keep causal. |
| 21 | Adaptive Holt | PASS | Holt level/trend adapt to quality and persistence with model-detail proof | Keep causal smoothing. |
| 22 | Kalman Local Linear Trend | PASS | level, slope, trend strength, innovation, residual, state uncertainty, and forecast are computed and validated | Keep causal state. |
| 23 | Adaptive AR-Ridge | PASS | bounded 5D Ridge exposes adaptive lag, feature weights, time weights, horizon weights, adaptive score, and adaptive lambda approval | Keep Fast Path inference-only. |
| 24 | Adaptive Volatility Engine | PASS | EW plus channel/range, MAD, Parkinson-style range, and vol-of-vol evidence | Broaden market dataset coverage. |
| 25 | Regime Engine | PASS | six regimes with CUSUM pressure, residual/disagreement, structure, vol-of-vol, and volume-shock evidence | Broaden market dataset coverage. |
| 26 | Model Mode | PASS | all six attach; Deep prioritizes sequence and Hybrid blends Statistical/Ridge/sequence | Keep mode contracts covered. |
| 27 | Feature Engine | PASS | price O/H/L/C/OHLC/HL/OC, returns, candle geometry, trend level/slope/acceleration/persistence/efficiency, EW/MAD/range/Parkinson/vol-of-vol, tick/relative volume, memory, cycle stability, time/session, MTF, and reliability evidence are implemented and tested | Keep features causal. |
| 28 | Multi-Timeframe Leakage Guard | EXACT PASS | MTF causality harness and primary Analysis Timeframe harness | Keep closed higher-TF candles causal. |
| 29 | Main Formula Catalog | PASS | formulas are represented in Data, Feature, Model, Validation, Adaptation, Event, Visual, and Station modules with harness proof | Final docs should summarize only. |
| 30 | Main Algorithm Catalog | PASS | model, sequence, adaptation, approval, stress, and station algorithms exist with targeted harness proof | Keep matrix aligned during final closure. |
| 31 | 10-Phase System Map | PASS | station manifest validates all 50 station definitions with trace fields and harness proof | Keep manifest aligned with execution responsibilities. |
| 32 | Station 00 Runtime Foundation | PASS | runtime scheduler, work budget, trigger coalescer, progressive builder, and station manifest are covered | Keep single-flight semantics. |
| 33 | Phase 1 | PASS | input/data contract plus analysis-rate primary snapshots and Analysis Timeframe commit/hold harness are covered | Keep MTF causal. |
| 34 | Phase 2 | PASS | quality score includes OHLCV validity, spread/volume, time-gap penalty, anomaly link, and stress diagnostics | Keep data cleaning lightweight. |
| 35 | Phase 3 | PASS | feature-regime harness covers causal channel, volatility, structure, and validation context | Keep sequence-specific features under Phase 6. |
| 36 | Phase 4 | PASS | ACF/PACF, adaptive memory proxies, cycle score, structure, and feature reliability feed models/adaptation | Keep sampled/bounded estimates. |
| 37 | Phase 5 | PASS | volatility ensemble and regime context now covered by `DSA_FeatureRegimeHarness` | Broaden market dataset coverage. |
| 38 | Phase 6 | PASS | model bank includes classical, Ridge, sequence, Hybrid, conformal, drift, and Safe Mode behavior | Broaden adaptive weight calibration datasets. |
| 39 | Phase 7 | PASS | forecast central/lower/upper path, scenario boundaries, and forecast rectangle are semantically validated by chart harness | Keep object count bounded. |
| 40 | Phase 8 | PASS | rolling OOS metrics plus adaptive candidate approval/rejection are covered by feature-regime harness | Broaden calibration datasets in final regression. |
| 41 | Phase 9 | PASS | event taxonomy covers Trend Change, Regime Change, Shock, Anomaly, Breakout, Up Pressure, Down Pressure, Signal End, and live/final identity flags with chart harness proof | Keep event buffers hidden only by display contract. |
| 42 | Phase 10 | PASS | buffers, future objects, visual detail scenario objects, market structure objects, runtime, and station traceability are covered | Keep final docs synchronized. |
| 43 | Fast Path Every Tick | EXACT PASS | P0 `DSA_ProcessLivePath` runs before historical slices and adaptive jobs; CI guards call order | Keep invariant. |
| 44 | Medium Path New Analysis Bar | PASS | `DSA_ShouldRunMediumPath`, `DSA_IsAnalysisCommitHostBar`, Analysis Timeframe harness `commit_samples=30`, `hold_samples=90` | Keep analysis-boundary invariant. |
| 45 | Slow Path Evidence-Driven | PASS | retained-output rebuild candidates, stale rejection, stress-triggered recalibration, and adaptive approval/rejection are covered | Keep heavy work sliced. |
| 46 | Slow Work Slicing | PASS | historical rebuild, history audit, adaptive job, and stress diagnostics are sliced and bounded | Keep Fast Path nonblocking. |
| 47 | Full Historical Pass | EXACT PASS | adversarial full-history harness | Keep invariant. |
| 48 | Atomic State Commit | PASS | retained-output rebuilds process into candidate buffers; stale sampled/unsampled candidates are rejected before commit and high-load candidate finalization is deferred | Keep commit validation outside overloaded Fast Path. |
| 49 | Input Fingerprint | PASS | computational fingerprint excludes display-only inputs; feature-regime harness proves display toggles do not rebuild analytical state | Keep renderer-only inputs separate. |
| 50 | Input Changes | PASS | computational input changes trigger rebuild while display-only toggles affect graphical output only | Keep fingerprint guard. |
| 51 | Graphical Output Contract | PASS | 10 buffers, forecast cone objects, scenario boundaries, rectangle, support/resistance, congestion, regime, and event-marker semantics are validated | Keep graphical-only output. |
| 52 | Market Structure Layer | PASS | support/resistance/congestion feature fields and full visual objects are covered by feature-regime and chart-object harnesses | Broaden datasets in final regression only if needed. |
| 53 | Historical Event Layer | PASS | closed bars set final, immutable, no-future-input event identity flags and the 8-event taxonomy is validated synthetically | Keep anti-repaint invariant. |
| 54 | Future Layer | PASS | forecast paths, cone bounds, scenario boundaries, stale-object cleanup, and rectangle geometry are validated | Keep horizon bounded by visual detail and runtime load. |
| 55 | Visual Language | PASS | output remains chart buffers and objects only; no dashboard/text output or trading behavior is introduced | Keep display toggles graphical-only. |
| 56 | Historical Buffers | EXACT PASS | 10 plot buffers | Keep invariant. |
| 57 | Future Objects | PASS | semantic chart harness validates object types, anchors, bounds, scenarios, rectangle, and stale cleanup | Keep object prefix cleanup. |
| 58 | Forecast Rectangle | EXACT PASS | chart-object semantic harness | Keep invariant. |
| 59 | Adaptive Band | PASS | bands use volatility, conformal radius, vol-of-vol, and volume-shock scaling | Broaden coverage datasets. |
| 60 | Prequential Walk-Forward | PASS | previous forecast resolution, rolling MAE/RMSE, directional accuracy, coverage rate, and model-score penalty are covered | Keep OOS semantics. |
| 61 | Model Disagreement | PASS | disagreement includes statistical/Ridge spread plus sequence-family spread when active | Broaden OOS calibration datasets. |
| 62 | Regime-Conditioned Conformal | PASS | regime-preferred residual radius plus all-regime fallback and coverage metrics are covered | Broaden final regression datasets only. |
| 63 | Metrics | PASS | absolute error, squared error, rolling MAE/RMSE, directional accuracy, and coverage rate | Broaden reporting outputs. |
| 64 | Model Score | PASS | error, disagreement, quality, rolling validation, volatility stress, and runtime-cost penalty | Broaden OOS calibration datasets. |
| 65 | Drift | PASS | forecast error, regime, quality, model disagreement, and event/stress paths expose drift behavior | Keep drift causal. |
| 66 | Safe Mode | PASS | explicit Safe Mode and market-triggered safe fallback suppress heavy experts and widen uncertainty; harness proof added | Keep fallback conservative. |
| 67 | Computational Safe Mode | PASS | runtime load gates optional work and stress diagnostics defer heavy work under high load | Keep Fast Path free of diagnostic full scans. |
| 68 | Event Engine | PASS | Trend Change, Regime Change, Shock, Anomaly, Breakout, Up Pressure, Down Pressure, Signal End plus strength/finality fields are implemented | Keep event detection causal. |
| 69 | Historical Event Finality | PASS | event snapshot marks closed bars final/immutable/no-future-input with deterministic identity and live Candle0 provisional; chart harness validates both states | Keep closed event buffers final. |
| 70 | Live Events | PASS | Candle0 events are explicitly provisional and rendered through live path without ClosedState mutation | Keep live events replaceable per tick. |
| 71 | Historical Analysis | PASS | display-state harness proves historical plots hide while calculation buffers stay active | Keep invariant. |
| 72 | Forecast Display | EXACT PASS | display-state harness proves forecast objects hide while forecast buffers stay active | Keep invariant. |
| 73 | Event Display | EXACT PASS | display-state harness proves event markers hide while core buffers stay active | Keep invariant. |
| 74 | Visual Detail | PASS | Full detail renders scenario boundaries, Basic/load-gated detail removes them and limits horizon | Keep Fast Path rendering bounded. |
| 75 | Adaptive Parameter Engine | PASS | sliced interval/ridge candidates now require evidence-based approval before tuning commit and reject insufficient evidence | Keep feature reranking as future refinement unless mandatory final gap remains. |
| 76 | Feature Reliability | PASS | causal correlation, ACF/PACF, ridge shrinkage, coefficient stability, and bounded permutation-degradation approximation are computed and consumed by adaptation/model approval | Broaden historical reliability summaries. |
| 77 | Shock Handling | PASS | shock regime maps to auxiliary shock event and wider uncertainty/scenario geometry is validated through chart objects | Broaden market datasets in final regression. |
| 78 | Anomaly Handling | PASS | robust-z anomaly maps to classified auxiliary event and participates in stress/safe diagnostics | Keep anomaly handling causal. |
| 79 | Model Approval | PASS | each expert has OOS/stability/maturity/coverage/shock/latency evidence and unapproved advanced experts receive zero or limited operational weight | Keep approval causal and bounded. |
| 80 | Stress Diagnostics | PASS | `DSA_ComputeStressDiagnosticsSlice`, `DSA_ProcessStressDiagnostics`, and `DSA_StressStationHarness` prove bounded diagnostics, load deferral, and recalibration request behavior | Broaden duration datasets in final regression if needed. |
| 81 | Internal Output Structure | PASS | buffers, calc buffers, ClosedState/LiveState frames, stress diagnostics, and station manifest map internal outputs | Final docs should synchronize. |
| 82 | Code Architecture | PASS | existing modules implement the Catalog components without artificial class inflation | Keep compact architecture. |
| 83 | Standard Station Contract | PASS | manifest covers required state, validity, error state, output, mutation permission, dependencies, validation tag, priority, cost, live/closed flags, deferral, slicing, heavy-task semantics, and actual source owner for all 50 stations | Keep compact manifest; no artificial station classes required. |
| 84 | State Mutation | PASS | ClosedState/LiveState, candidate buffers, mutation permissions in station manifest, and atomic commit guards are covered | Keep historical mutation closed-bar only. |
| 85 | Normal Tick Contract | PASS | P0 live path updates provisional LiveState and rendering without committing ClosedState | Keep no heavy work before live path. |
| 86 | New-Bar Tick Contract | PASS | New Analysis Bar commits ClosedState before live processing and hold behavior is covered | Keep analysis-boundary commit semantics. |
| 87 | Heavy Trigger Contract | PASS | rebuild/adaptive/diagnostic triggers coalesce, slice, version-guard, reject stale work, and avoid unbounded queues | Keep GitHub source guards. |
| 88 | History Revision Contract | PASS | `DSA_HistoryRevisionHarness` proves bar/history fingerprint change, revision trigger, and completed-build restart | Keep bounded-sweep latency invariant. |
| 89 | Stale Result Protection | PASS | `DSA_HistoryRevisionHarness` proves sampled and unsampled stale candidates are rejected before commit | Broaden stale adaptive-job proof. |
| 90 | Ready-for-Production Contract | PASS | final compile stamp `20260813-224845`, final runtime summary `Validation/final-runtime-regression-20260813-224845.json`, synchronized release documentation, and CI release gate | Keep release evidence attached to final commit. |

## Current Highest-Risk Work Queue

1. Final release commit and GitHub GREEN.
