#property copyright "DSA-MQL5 Native"
#property version   "1.00"
#property tester_indicator "DSA_MQL5_Native.ex5"

#include "..\Core\InputContract.mqh"

int HarnessFailures = 0;
int Handle = INVALID_HANDLE;
int Samples = 0;

void DSA_RecordFailure(const string message)
{
   ++HarnessFailures;
   Print("DSA analysis-timeframe harness failure: ",message," error=",GetLastError());
}

bool DSA_ReadIndicatorTarget(const int shift,double &target)
{
   double values[];
   ArraySetAsSeries(values,true);
   ResetLastError();
   const int copied = CopyBuffer(Handle,10,shift,1,values);
   if(copied != 1 || !MathIsValidNumber(values[0]) || values[0] == EMPTY_VALUE)
      return false;
   target = values[0];
   return true;
}

bool DSA_ExpectedClosedAnalysisClose(const datetime host_time,double &expected)
{
   int analysis_shift = iBarShift(_Symbol,PERIOD_H1,host_time,false);
   if(analysis_shift < 0)
      return false;
   ++analysis_shift;
   expected = iClose(_Symbol,PERIOD_H1,analysis_shift);
   return (expected > 0.0 && MathIsValidNumber(expected));
}

void DSA_CheckPrimaryAnalysisTimeframe()
{
   const int bars = Bars(_Symbol,_Period);
   const int limit = MathMin(bars - 10,220);
   for(int shift = 4; shift <= limit && Samples < 80; shift += 2)
   {
      const datetime host_time = iTime(_Symbol,_Period,shift);
      if(host_time <= 0)
         continue;

      double actual = 0.0;
      if(!DSA_ReadIndicatorTarget(shift,actual))
         continue;

      double expected = 0.0;
      if(!DSA_ExpectedClosedAnalysisClose(host_time,expected))
         continue;

      if(MathAbs(actual - expected) > MathMax(_Point * 0.5,1.0e-8))
      {
         DSA_RecordFailure(StringFormat("primary analysis target mismatch host=%s shift=%d actual=%.10f expected=%.10f",
                                        TimeToString(host_time,TIME_DATE|TIME_MINUTES),
                                        shift,
                                        actual,
                                        expected));
         return;
      }

      ++Samples;
   }
}

int OnInit()
{
   if(_Period >= PERIOD_H1)
   {
      DSA_RecordFailure("analysis-timeframe harness must run on a timeframe lower than H1");
      return INIT_FAILED;
   }

   Handle = iCustom(_Symbol,
                    _Period,
                    "DSA_MQL5_Native",
                    "Host chart symbol",
                    DSA_DATA_CLOSE,
                    PERIOD_CURRENT,
                    PERIOD_H1,
                    PERIOD_D1,
                    DSA_MODEL_ADAPTIVE,
                    true,
                    true,
                    true,
                    DSA_VISUAL_BASIC);
   if(Handle == INVALID_HANDLE)
   {
      DSA_RecordFailure("failed to create DSA indicator handle");
      return INIT_FAILED;
   }

   Print("DSA analysis-timeframe harness initialized for ",_Symbol," ",EnumToString(_Period));
   return INIT_SUCCEEDED;
}

void OnTick()
{
   if(HarnessFailures == 0 && Samples < 80)
      DSA_CheckPrimaryAnalysisTimeframe();
}

void OnDeinit(const int reason)
{
   if(Handle != INVALID_HANDLE)
      IndicatorRelease(Handle);

   Print("DSA analysis-timeframe harness completed. failures=",HarnessFailures,
         " samples=",Samples,
         " reason=",reason);
}

double OnTester()
{
   return (HarnessFailures == 0 && Samples >= 80 ? 1.0 : 0.0);
}
