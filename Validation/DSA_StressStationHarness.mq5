#property copyright "DSA-MQL5 Native"
#property version   "1.00"

#include "..\Adaptation\AdaptiveEngine.mqh"
#include "..\Stations\StationManifest.mqh"

bool HarnessDone = false;
int HarnessFailures = 0;
int HarnessChecks = 0;
bool StationManifestOk = false;
bool StationTraceOk = false;
bool StressDiagnosticsOk = false;
bool StressRecalibrationOk = false;
bool BoundedSliceOk = false;

void DSA_RecordFailure(const string message)
{
   ++HarnessFailures;
   Print("DSA stress-station harness failure: ",message," error=",GetLastError());
}

void DSA_FillStressBuffers(double &stress_buffer[],
                           double &safe_mode_buffer[],
                           double &model_score_buffer[],
                           double &disagreement_buffer[])
{
   const int total = 180;
   ArrayResize(stress_buffer,total);
   ArrayResize(safe_mode_buffer,total);
   ArrayResize(model_score_buffer,total);
   ArrayResize(disagreement_buffer,total);
   ArraySetAsSeries(stress_buffer,true);
   ArraySetAsSeries(safe_mode_buffer,true);
   ArraySetAsSeries(model_score_buffer,true);
   ArraySetAsSeries(disagreement_buffer,true);

   for(int shift = 0; shift < total; ++shift)
   {
      const bool stressed = (shift % 3 == 0 || shift < 18 || shift > total - 38);
      stress_buffer[shift] = (stressed ? 0.88 : 0.46 + 0.01 * (double)(shift % 7));
      safe_mode_buffer[shift] = (stressed ? 0.74 : 0.38);
      model_score_buffer[shift] = (stressed ? 42.0 : 71.0);
      disagreement_buffer[shift] = (stressed ? 0.72 : 0.34);
   }
}

void DSA_RunStressStationHarness()
{
   int station_count = 0;
   int heavy_count = 0;
   int sliced_count = 0;
   int priority_violations = 0;
   StationManifestOk = DSA_ValidateStationManifest(station_count,
                                                   heavy_count,
                                                   sliced_count,
                                                   priority_violations);
   if(!StationManifestOk)
      DSA_RecordFailure("station manifest contract validation failed");
   ++HarnessChecks;

   DSAStationDefinition scheduler;
   DSAStationDefinition commit;
   DSAStationDefinition candidate;
   DSAStationDefinition history;
   const bool trace_loaded = (DSA_GetStationDefinition(49,scheduler) &&
                              DSA_GetStationDefinition(50,commit) &&
                              DSA_GetStationDefinition(38,candidate) &&
                              DSA_GetStationDefinition(4,history));
   StationTraceOk = (trace_loaded &&
                     scheduler.runtime_priority == 0 &&
                     scheduler.cost_class == DSA_STATION_COST_LIGHT &&
                     scheduler.can_run_on_live_candle0 &&
                     commit.can_commit_historical_state &&
                     candidate.heavy_task &&
                     candidate.can_be_sliced &&
                     candidate.can_be_deferred &&
                     !candidate.can_run_on_live_candle0 &&
                     !candidate.can_commit_historical_state &&
                     history.heavy_task &&
                     history.requires_closed_bar &&
                     StringLen(scheduler.validation_tag) > 0 &&
                     StringLen(commit.mutation_permission) > 0 &&
                     StringLen(candidate.dependencies) > 0 &&
                     StringLen(history.required_state) > 0);
   if(!StationTraceOk)
      DSA_RecordFailure("station trace fields were incomplete for scheduler, commit, candidate, or history stations");
   ++HarnessChecks;

   double stress_buffer[];
   double safe_mode_buffer[];
   double model_score_buffer[];
   double disagreement_buffer[];
   DSA_FillStressBuffers(stress_buffer,safe_mode_buffer,model_score_buffer,disagreement_buffer);

   DSAStressDiagnosticSnapshot diagnostics;
   int next_cursor = -1;
   DSA_ComputeStressDiagnosticsSlice(ArraySize(stress_buffer),
                                     -1,
                                     32,
                                     1.20,
                                     stress_buffer,
                                     safe_mode_buffer,
                                     model_score_buffer,
                                     disagreement_buffer,
                                     diagnostics,
                                     next_cursor);
   StressDiagnosticsOk = (diagnostics.diagnostics_available &&
                          diagnostics.sampled_bars > 0 &&
                          diagnostics.processed_bars <= 32 &&
                          diagnostics.high_stress_bars > 0 &&
                          diagnostics.high_load_bars == diagnostics.sampled_bars &&
                          diagnostics.average_stress > 0.50 &&
                          diagnostics.defer_heavy_work &&
                          !diagnostics.request_recalibration &&
                          (diagnostics.reason_mask & DSA_REASON_MODEL_INSTABILITY) != 0);
   if(!StressDiagnosticsOk)
      DSA_RecordFailure("stress diagnostics did not defer heavy work under high load");
   ++HarnessChecks;

   DSAStressDiagnosticSnapshot recalibration_diagnostics;
   int recalibration_cursor = -1;
   DSA_ComputeStressDiagnosticsSlice(ArraySize(stress_buffer),
                                     -1,
                                     40,
                                     0.30,
                                     stress_buffer,
                                     safe_mode_buffer,
                                     model_score_buffer,
                                     disagreement_buffer,
                                     recalibration_diagnostics,
                                     recalibration_cursor);
   StressRecalibrationOk = (recalibration_diagnostics.diagnostics_available &&
                            recalibration_diagnostics.request_recalibration &&
                            !recalibration_diagnostics.defer_heavy_work &&
                            recalibration_diagnostics.stress_event &&
                            (recalibration_diagnostics.reason_mask & DSA_REASON_FORECAST_DEGRADATION) != 0 &&
                            (recalibration_diagnostics.reason_mask & DSA_REASON_LOW_CONFIDENCE) != 0);
   if(!StressRecalibrationOk)
      DSA_RecordFailure("stress diagnostics did not request recalibration under available runtime");
   ++HarnessChecks;

   DSAStressDiagnosticSnapshot bounded_diagnostics;
   int bounded_cursor = 17;
   int bounded_next = bounded_cursor;
   DSA_ComputeStressDiagnosticsSlice(ArraySize(stress_buffer),
                                     bounded_cursor,
                                     9,
                                     0.20,
                                     stress_buffer,
                                     safe_mode_buffer,
                                     model_score_buffer,
                                     disagreement_buffer,
                                     bounded_diagnostics,
                                     bounded_next);
   BoundedSliceOk = (bounded_diagnostics.diagnostics_available &&
                     bounded_diagnostics.processed_bars == 9 &&
                     bounded_next == bounded_cursor - 9);
   if(!BoundedSliceOk)
      DSA_RecordFailure("stress diagnostics slice was not bounded by cursor and budget");
   ++HarnessChecks;

   HarnessDone = true;
   Print("DSA stress-station harness completed. failures=",HarnessFailures,
         " checks=",HarnessChecks,
         " station_manifest=",StationManifestOk,
         " station_trace=",StationTraceOk,
         " stress_diagnostics=",StressDiagnosticsOk,
         " stress_recalibration=",StressRecalibrationOk,
         " bounded_slice=",BoundedSliceOk,
         " stations=",station_count,
         " heavy=",heavy_count,
         " sliced=",sliced_count,
         " sampled=",recalibration_diagnostics.sampled_bars,
         " average_stress=",recalibration_diagnostics.average_stress);
}

int OnInit()
{
   DSA_RunStressStationHarness();
   return (HarnessFailures == 0 ? INIT_SUCCEEDED : INIT_FAILED);
}

void OnTick()
{
}

double OnTester()
{
   return (HarnessDone &&
           HarnessFailures == 0 &&
           HarnessChecks >= 5 &&
           StationManifestOk &&
           StationTraceOk &&
           StressDiagnosticsOk &&
           StressRecalibrationOk &&
           BoundedSliceOk ? 1.0 : 0.0);
}
