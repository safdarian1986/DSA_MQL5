#property copyright "DSA-MQL5 Native"
#property version   "1.00"

#include "..\Data\DataContract.mqh"
#include "..\Runtime\TickScheduler.mqh"

bool HarnessDone = false;
int HarnessFailures = 0;
int HarnessChecks = 0;
bool BarFingerprintChangedOk = false;
bool HistoryFingerprintChangedOk = false;
bool RevisionTriggerOk = false;
bool CompletedRevisionRestartOk = false;
bool StaleCandidateRejectedOk = false;
bool UnsampledCandidateRejectedOk = false;

void DSA_RecordFailure(const string message)
{
   ++HarnessFailures;
   Print("DSA history-revision harness failure: ",message," error=",GetLastError());
}

void DSA_FillSyntheticHistory(datetime &time[],
                              double &open_values[],
                              double &high_values[],
                              double &low_values[],
                              double &close_values[],
                              long &tick_volume[],
                              int &spread[])
{
   const int total = 128;
   ArrayResize(time,total);
   ArrayResize(open_values,total);
   ArrayResize(high_values,total);
   ArrayResize(low_values,total);
   ArrayResize(close_values,total);
   ArrayResize(tick_volume,total);
   ArrayResize(spread,total);

   ArraySetAsSeries(time,true);
   ArraySetAsSeries(open_values,true);
   ArraySetAsSeries(high_values,true);
   ArraySetAsSeries(low_values,true);
   ArraySetAsSeries(close_values,true);
   ArraySetAsSeries(tick_volume,true);
   ArraySetAsSeries(spread,true);

   const datetime newest = D'2025.01.10 00:00';
   for(int shift = 0; shift < total; ++shift)
   {
      const double base = 100.0 - (double)shift * 0.08;
      time[shift] = newest - shift * 3600;
      open_values[shift] = base;
      high_values[shift] = base + 0.35;
      low_values[shift] = base - 0.25;
      close_values[shift] = base + 0.10;
      tick_volume[shift] = 1000 + shift * 3;
      spread[shift] = 12 + (shift % 4);
   }
}

void DSA_RunHistoryRevisionHarness()
{
   datetime time[];
   double open_values[];
   double high_values[];
   double low_values[];
   double close_values[];
   long tick_volume[];
   int spread[];

   DSA_FillSyntheticHistory(time,open_values,high_values,low_values,close_values,tick_volume,spread);
   const int total = ArraySize(time);
   const int revised_shift = 119;

   const double before_bar = DSA_BarRevisionFingerprint(revised_shift,total,time,open_values,high_values,low_values,close_values,tick_volume,spread);
   const string before_history = DSA_HistoryFingerprint(total,time,open_values,high_values,low_values,close_values,tick_volume,spread);

   close_values[revised_shift] += 1.25;
   tick_volume[revised_shift] += 37;

   const double after_bar = DSA_BarRevisionFingerprint(revised_shift,total,time,open_values,high_values,low_values,close_values,tick_volume,spread);
   const string after_history = DSA_HistoryFingerprint(total,time,open_values,high_values,low_values,close_values,tick_volume,spread);

   BarFingerprintChangedOk = (MathAbs(before_bar - after_bar) > 0.5);
   if(!BarFingerprintChangedOk)
      DSA_RecordFailure("closed-bar fingerprint did not change after OHLCV revision");
   ++HarnessChecks;

   HistoryFingerprintChangedOk = (before_history != after_history);
   if(!HistoryFingerprintChangedOk)
      DSA_RecordFailure("history fingerprint did not include sampled closed-bar revision");
   ++HarnessChecks;

   DSARuntimeSchedulerState runtime;
   DSA_RuntimeInit(runtime);
   const string input_fingerprint = "history-revision-input";

   DSA_StartProgressiveBuild(runtime,total,input_fingerprint,before_history);
   runtime.build_cursor = 31;
   if(!DSA_BuildInProgressMatches(runtime,total,input_fingerprint,before_history))
      DSA_RecordFailure("active matching build was not recognized");
   ++HarnessChecks;

   DSA_MarkBuildComplete(runtime);
   DSA_CoalesceTrigger(runtime,DSA_REASON_HISTORY_REVISION);
   RevisionTriggerOk = (runtime.rebuild_pending &&
                        (runtime.pending_reason_mask & DSA_REASON_HISTORY_REVISION) != 0);
   if(!RevisionTriggerOk)
      DSA_RecordFailure("history revision did not coalesce into a rebuild trigger");
   ++HarnessChecks;

   CompletedRevisionRestartOk = !DSA_BuildInProgressMatches(runtime,total,input_fingerprint,before_history);
   if(!CompletedRevisionRestartOk)
      DSA_RecordFailure("completed revised history was mistaken for an active matching build");
   ++HarnessChecks;

   DSARuntimeSchedulerState candidate_runtime;
   DSA_RuntimeInit(candidate_runtime);
   DSA_StartProgressiveBuild(candidate_runtime,total,input_fingerprint,before_history);
   candidate_runtime.build_cursor = 1;

   StaleCandidateRejectedOk = (DSA_CanCommitCandidate(candidate_runtime,input_fingerprint,before_history) &&
                               !DSA_CanCommitCandidate(candidate_runtime,input_fingerprint,after_history));
   if(!StaleCandidateRejectedOk)
      DSA_RecordFailure("sampled stale candidate was not rejected after history fingerprint changed");
   ++HarnessChecks;

   DSA_FillSyntheticHistory(time,open_values,high_values,low_values,close_values,tick_volume,spread);
   double candidate_fingerprints[];
   ArrayResize(candidate_fingerprints,total);
   ArraySetAsSeries(candidate_fingerprints,true);
   for(int shift = 1; shift < total; ++shift)
      candidate_fingerprints[shift] = DSA_BarRevisionFingerprint(shift,total,time,open_values,high_values,low_values,close_values,tick_volume,spread);

   const int unsampled_shift = 37;
   close_values[unsampled_shift] -= 1.10;
   spread[unsampled_shift] += 5;
   UnsampledCandidateRejectedOk = !DSA_FingerprintBufferMatchesCurrent(total,time,open_values,high_values,low_values,close_values,tick_volume,spread,candidate_fingerprints);
   if(!UnsampledCandidateRejectedOk)
      DSA_RecordFailure("unsampled stale candidate fingerprint buffer was not rejected before commit");
   ++HarnessChecks;

   HarnessDone = true;
   Print("DSA history-revision harness completed. failures=",HarnessFailures,
         " checks=",HarnessChecks,
         " bar_fingerprint_changed=",BarFingerprintChangedOk,
         " history_fingerprint_changed=",HistoryFingerprintChangedOk,
         " revision_trigger=",RevisionTriggerOk,
         " completed_restart=",CompletedRevisionRestartOk,
         " stale_candidate_rejected=",StaleCandidateRejectedOk,
         " unsampled_candidate_rejected=",UnsampledCandidateRejectedOk);
}

int OnInit()
{
   DSA_RunHistoryRevisionHarness();
   return (HarnessFailures == 0 ? INIT_SUCCEEDED : INIT_FAILED);
}

void OnTick()
{
}

double OnTester()
{
   return (HarnessDone &&
           HarnessFailures == 0 &&
           HarnessChecks >= 7 &&
           BarFingerprintChangedOk &&
           HistoryFingerprintChangedOk &&
           RevisionTriggerOk &&
           CompletedRevisionRestartOk &&
           StaleCandidateRejectedOk &&
           UnsampledCandidateRejectedOk ? 1.0 : 0.0);
}
