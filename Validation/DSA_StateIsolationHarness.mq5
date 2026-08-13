#property copyright "DSA-MQL5 Native"
#property version   "1.00"

#include "..\Core\StateRegistry.mqh"

bool HarnessDone = false;
int HarnessFailures = 0;
int HarnessChecks = 0;

void DSA_RecordFailure(const string message)
{
   ++HarnessFailures;
   Print("DSA state-isolation harness failure: ",message," error=",GetLastError());
}

bool DSA_CloseEnough(const double actual,const double expected,const double tolerance=1.0e-8)
{
   return MathAbs(actual - expected) <= tolerance;
}

void DSA_FillFrameArrays(datetime &time[],
                         double &target[],
                         double &forecast[],
                         double &trend[],
                         double &signal[],
                         double &upper_band[],
                         double &lower_band[],
                         double &uncertainty_upper[],
                         double &uncertainty_lower[],
                         double &regime[],
                         double &quality[],
                         double &model_score[],
                         double &drift[],
                         double &volatility[],
                         double &slope[],
                         double &safe_mode[],
                         double &stress[],
                         double &bar_fingerprint[])
{
   const int total = 3;
   ArrayResize(time,total);
   ArrayResize(target,total);
   ArrayResize(forecast,total);
   ArrayResize(trend,total);
   ArrayResize(signal,total);
   ArrayResize(upper_band,total);
   ArrayResize(lower_band,total);
   ArrayResize(uncertainty_upper,total);
   ArrayResize(uncertainty_lower,total);
   ArrayResize(regime,total);
   ArrayResize(quality,total);
   ArrayResize(model_score,total);
   ArrayResize(drift,total);
   ArrayResize(volatility,total);
   ArrayResize(slope,total);
   ArrayResize(safe_mode,total);
   ArrayResize(stress,total);
   ArrayResize(bar_fingerprint,total);

   ArraySetAsSeries(time,true);
   ArraySetAsSeries(target,true);
   ArraySetAsSeries(forecast,true);
   ArraySetAsSeries(trend,true);
   ArraySetAsSeries(signal,true);
   ArraySetAsSeries(upper_band,true);
   ArraySetAsSeries(lower_band,true);
   ArraySetAsSeries(uncertainty_upper,true);
   ArraySetAsSeries(uncertainty_lower,true);
   ArraySetAsSeries(regime,true);
   ArraySetAsSeries(quality,true);
   ArraySetAsSeries(model_score,true);
   ArraySetAsSeries(drift,true);
   ArraySetAsSeries(volatility,true);
   ArraySetAsSeries(slope,true);
   ArraySetAsSeries(safe_mode,true);
   ArraySetAsSeries(stress,true);
   ArraySetAsSeries(bar_fingerprint,true);

   for(int i = 0; i < total; ++i)
   {
      time[i] = D'2025.01.03 00:00' - i * 60;
      target[i] = 100.0 + (double)i;
      forecast[i] = target[i] + 0.10;
      trend[i] = target[i] - 0.20;
      signal[i] = target[i] - 0.10;
      upper_band[i] = target[i] + 0.60;
      lower_band[i] = target[i] - 0.60;
      uncertainty_upper[i] = forecast[i] + 0.35;
      uncertainty_lower[i] = forecast[i] - 0.35;
      regime[i] = DSA_REGIME_RANGE;
      quality[i] = 90.0 - i;
      model_score[i] = 80.0 - i;
      drift[i] = 0.05 * (double)i;
      volatility[i] = 0.20 + 0.02 * (double)i;
      slope[i] = 0.01 * (double)i;
      safe_mode[i] = 0.0;
      stress[i] = 0.10 * (double)i;
      bar_fingerprint[i] = 1000.0 + (double)i;
   }
}

void DSA_RunStateIsolationHarness()
{
   datetime time[];
   double target[];
   double forecast[];
   double trend[];
   double signal[];
   double upper_band[];
   double lower_band[];
   double uncertainty_upper[];
   double uncertainty_lower[];
   double regime[];
   double quality[];
   double model_score[];
   double drift[];
   double volatility[];
   double slope[];
   double safe_mode[];
   double stress[];
   double bar_fingerprint[];

   DSA_FillFrameArrays(time,target,forecast,trend,signal,upper_band,lower_band,
                       uncertainty_upper,uncertainty_lower,regime,quality,model_score,
                       drift,volatility,slope,safe_mode,stress,bar_fingerprint);

   DSAClosedState closed_state;
   DSALiveState live_state;
   DSA_ResetClosedState(closed_state);
   DSA_ResetLiveState(live_state);

   const long closed_version = 11;
   if(!DSA_CommitClosedStateFromBuffers(closed_state,1,time,target,forecast,trend,signal,
                                        upper_band,lower_band,uncertainty_upper,uncertainty_lower,
                                        regime,quality,model_score,drift,volatility,slope,
                                        safe_mode,stress,bar_fingerprint,closed_version,"unit_closed"))
      DSA_RecordFailure("closed state did not commit from valid closed buffers");
   ++HarnessChecks;

   const double committed_target = closed_state.frame.target;
   DSA_BeginLiveState(live_state,closed_state,time[0],closed_version);
   if(!DSA_LiveStateUsesClosedBase(live_state,closed_state) ||
      !live_state.frame.provisional ||
      !DSA_CloseEnough(live_state.frame.target,committed_target))
      DSA_RecordFailure("live state did not start from the committed closed state");
   ++HarnessChecks;

   target[0] = 125.0;
   forecast[0] = 125.2;
   trend[0] = 124.8;
   if(!DSA_CaptureLiveStateFromBuffers(live_state,0,time,target,forecast,trend,signal,
                                       upper_band,lower_band,uncertainty_upper,uncertainty_lower,
                                       regime,quality,model_score,drift,volatility,slope,
                                       safe_mode,stress,bar_fingerprint,closed_version))
      DSA_RecordFailure("live state did not capture Candle0 buffers");
   if(!DSA_LiveStateUsesClosedBase(live_state,closed_state) ||
      !DSA_CloseEnough(live_state.frame.target,125.0) ||
      !DSA_CloseEnough(closed_state.frame.target,committed_target))
      DSA_RecordFailure("Candle0 live capture mutated or detached from ClosedState");
   ++HarnessChecks;

   target[0] = 140.0;
   DSA_BeginLiveState(live_state,closed_state,(datetime)(time[0] + 30),closed_version);
   if(!DSA_LiveStateUsesClosedBase(live_state,closed_state) ||
      !DSA_CloseEnough(live_state.frame.target,committed_target))
      DSA_RecordFailure("new tick did not replace LiveState from ClosedState");
   if(!DSA_CloseEnough(closed_state.frame.target,committed_target))
      DSA_RecordFailure("ClosedState changed across live ticks");
   ++HarnessChecks;

   HarnessDone = true;
   Print("DSA state-isolation harness completed. failures=",HarnessFailures,
         " checks=",HarnessChecks);
}

int OnInit()
{
   DSA_RunStateIsolationHarness();
   return (HarnessFailures == 0 ? INIT_SUCCEEDED : INIT_FAILED);
}

void OnTick()
{
}

double OnTester()
{
   return (HarnessDone && HarnessFailures == 0 && HarnessChecks >= 4 ? 1.0 : 0.0);
}
