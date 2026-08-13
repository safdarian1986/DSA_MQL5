#ifndef DSA_TICK_SCHEDULER_MQH
#define DSA_TICK_SCHEDULER_MQH

#include "..\\Core\\DSACommon.mqh"

enum ENUM_DSA_PENDING_REASON
{
   DSA_REASON_NONE = 0,
   DSA_REASON_DRIFT = 1,
   DSA_REASON_FORECAST_DEGRADATION = 2,
   DSA_REASON_HISTORY_REVISION = 4,
   DSA_REASON_INPUT_CHANGE = 8,
   DSA_REASON_LOW_CONFIDENCE = 16,
   DSA_REASON_FEATURE_INSTABILITY = 32,
   DSA_REASON_MODEL_INSTABILITY = 64
};

struct DSARuntimeSchedulerState
{
   bool runtime_busy;
   bool heavy_task_active;
   bool rebuild_pending;
   bool recalibration_pending;
   int pending_reason_mask;
   long active_state_version;
   long history_version;
   string input_fingerprint;
   string history_fingerprint;
   int build_cursor;
   int build_total;
   int history_audit_cursor;
   int processed_count;
   bool build_complete;
   double ew_latency_ms;
   double ew_tick_interval_ms;
   double runtime_load;
   ulong last_tick_microseconds;
   datetime last_bar_time;
   datetime last_analysis_bar_time;
   ENUM_DSA_STATUS status;
};

void DSA_RuntimeInit(DSARuntimeSchedulerState &runtime)
{
   runtime.runtime_busy = false;
   runtime.heavy_task_active = false;
   runtime.rebuild_pending = true;
   runtime.recalibration_pending = false;
   runtime.pending_reason_mask = DSA_REASON_HISTORY_REVISION;
   runtime.active_state_version = 1;
   runtime.history_version = 1;
   runtime.input_fingerprint = "";
   runtime.history_fingerprint = "";
   runtime.build_cursor = -1;
   runtime.build_total = 0;
   runtime.history_audit_cursor = -1;
   runtime.processed_count = 0;
   runtime.build_complete = false;
   runtime.ew_latency_ms = 0.0;
   runtime.ew_tick_interval_ms = 1000.0;
   runtime.runtime_load = 0.0;
   runtime.last_tick_microseconds = 0;
   runtime.last_bar_time = 0;
   runtime.last_analysis_bar_time = 0;
   runtime.status = DSA_STATUS_BUILDING;
}

void DSA_RuntimeBeginTick(DSARuntimeSchedulerState &runtime)
{
   const ulong now = GetMicrosecondCount();
   if(runtime.last_tick_microseconds > 0 && now > runtime.last_tick_microseconds)
   {
      const double tick_interval_ms = (double)(now - runtime.last_tick_microseconds) / 1000.0;
      runtime.ew_tick_interval_ms = DSA_Ewma(runtime.ew_tick_interval_ms,tick_interval_ms,0.08);
   }
   runtime.last_tick_microseconds = now;
   runtime.runtime_busy = true;
}

void DSA_RuntimeEndTick(DSARuntimeSchedulerState &runtime,const ulong start_microseconds)
{
   const ulong now = GetMicrosecondCount();
   double latency_ms = 0.0;
   if(now > start_microseconds)
      latency_ms = (double)(now - start_microseconds) / 1000.0;
   runtime.ew_latency_ms = DSA_Ewma(runtime.ew_latency_ms,latency_ms,0.12);
   runtime.runtime_load = DSA_Clamp(DSA_SafeDiv(runtime.ew_latency_ms,MathMax(runtime.ew_tick_interval_ms,1.0),0.0),0.0,10.0);
   runtime.runtime_busy = false;
}

void DSA_CoalesceTrigger(DSARuntimeSchedulerState &runtime,const int reason_mask)
{
   runtime.pending_reason_mask |= reason_mask;
   if(reason_mask == DSA_REASON_HISTORY_REVISION || reason_mask == DSA_REASON_INPUT_CHANGE)
      runtime.rebuild_pending = true;
   else
      runtime.recalibration_pending = true;
}

int DSA_WorkBudgetBars(DSARuntimeSchedulerState &runtime,const int rates_total)
{
   int budget = 256;
   if(runtime.runtime_load > 0.80)
      budget = 32;
   else if(runtime.runtime_load > 0.55)
      budget = 96;
   else if(runtime.runtime_load < 0.20)
      budget = 768;

   if(rates_total < 2000 && runtime.runtime_load < 0.35)
      budget = MathMax(budget,512);

   if(budget < 8)
      budget = 8;
   if(budget > 1500)
      budget = 1500;
   return budget;
}

void DSA_StartProgressiveBuild(DSARuntimeSchedulerState &runtime,const int rates_total,const string input_fingerprint,const string history_fingerprint)
{
   runtime.heavy_task_active = true;
   runtime.rebuild_pending = true;
   runtime.build_complete = false;
   runtime.build_total = rates_total;
   runtime.history_audit_cursor = rates_total - 1;
   runtime.processed_count = 0;
   runtime.build_cursor = rates_total - 1;
   runtime.active_state_version++;
   runtime.history_version++;
   runtime.input_fingerprint = input_fingerprint;
   runtime.history_fingerprint = history_fingerprint;
   runtime.status = DSA_STATUS_BUILDING;
}

bool DSA_CanCommitCandidate(DSARuntimeSchedulerState &runtime,const string input_fingerprint,const string history_fingerprint)
{
   if(runtime.input_fingerprint != input_fingerprint)
      return false;
   if(runtime.history_fingerprint != history_fingerprint)
      return false;
   return true;
}

bool DSA_BuildInProgressMatches(DSARuntimeSchedulerState &runtime,
                                const int rates_total,
                                const string input_fingerprint,
                                const string history_fingerprint)
{
   if(!runtime.rebuild_pending || runtime.build_complete)
      return false;
   if(!DSA_CanCommitCandidate(runtime,input_fingerprint,history_fingerprint))
      return false;
   if(runtime.build_total != rates_total)
      return false;
   return (runtime.build_cursor >= 0);
}

void DSA_MarkBuildComplete(DSARuntimeSchedulerState &runtime)
{
   runtime.build_complete = true;
   runtime.rebuild_pending = false;
   runtime.heavy_task_active = false;
   runtime.history_audit_cursor = MathMax(runtime.build_total - 1,1);
   runtime.pending_reason_mask = DSA_REASON_NONE;
   runtime.status = DSA_STATUS_READY;
}

#endif
