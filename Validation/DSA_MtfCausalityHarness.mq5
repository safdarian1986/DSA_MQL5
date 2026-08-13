#property copyright "DSA-MQL5 Native"
#property version   "1.00"

#include "..\Data\MTFAlignment.mqh"

int HarnessFailures = 0;
int MtfSamples = 0;
DSAInputContract Contract;

void DSA_RecordFailure(const string message)
{
   ++HarnessFailures;
   Print("DSA MTF causality harness failure: ",message," error=",GetLastError());
}

void DSA_CheckHistoricalMtfSamples()
{
   DSA_BuildInputContract(Contract,
                          "Host chart symbol",
                          DSA_DATA_OHLC,
                          PERIOD_CURRENT,
                          PERIOD_H1,
                          PERIOD_D1,
                          DSA_MODEL_ADAPTIVE,
                          true,
                          true,
                          true,
                          DSA_VISUAL_FULL);

   const int bars = Bars(_Symbol,_Period);
   const int limit = MathMin(bars - 2,700);
   for(int shift = 1; shift <= limit; shift += 3)
   {
      const datetime host_time = iTime(_Symbol,_Period,shift);
      if(host_time <= 0)
         continue;

      DSAMtfSnapshot snapshot;
      if(!DSA_GetCausalAnalysisRate(Contract,host_time,snapshot))
         continue;

      const int higher_seconds = PeriodSeconds(Contract.analysis_timeframe);
      const datetime causal_available_time = (datetime)(snapshot.source_time + higher_seconds);
      if(causal_available_time > host_time)
      {
         DSA_RecordFailure(StringFormat("higher-TF candle leaked before close host=%s source=%s available=%s",
                                        TimeToString(host_time,TIME_DATE|TIME_MINUTES),
                                        TimeToString(snapshot.source_time,TIME_DATE|TIME_MINUTES),
                                        TimeToString(causal_available_time,TIME_DATE|TIME_MINUTES)));
         return;
      }

      if(!MathIsValidNumber(snapshot.open) ||
         !MathIsValidNumber(snapshot.high) ||
         !MathIsValidNumber(snapshot.low) ||
         !MathIsValidNumber(snapshot.close) ||
         snapshot.high < snapshot.low)
      {
         DSA_RecordFailure("invalid higher-timeframe OHLC snapshot");
         return;
      }

      ++MtfSamples;
   }
}

int OnInit()
{
   if(_Period >= PERIOD_H1)
   {
      DSA_RecordFailure("MTF causality harness must run on a timeframe lower than H1");
      return INIT_FAILED;
   }

   Print("DSA MTF causality harness initialized for ",_Symbol," ",EnumToString(_Period));
   return INIT_SUCCEEDED;
}

void OnTick()
{
   if(HarnessFailures == 0 && MtfSamples < 80)
      DSA_CheckHistoricalMtfSamples();
}

void OnDeinit(const int reason)
{
   Print("DSA MTF causality harness completed. failures=",HarnessFailures,
         " samples=",MtfSamples,
         " reason=",reason);
}

double OnTester()
{
   return (HarnessFailures == 0 && MtfSamples >= 80 ? 1.0 : 0.0);
}
