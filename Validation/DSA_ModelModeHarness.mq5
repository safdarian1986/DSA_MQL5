#property copyright "DSA-MQL5 Native"
#property version   "1.00"
#property tester_indicator "DSA_MQL5_Native.ex5"

#include "..\Core\InputContract.mqh"

#define DSA_MODE_HARNESS_INDICATOR "DSA_MQL5_Native"
#define DSA_MODE_COUNT 6

int IndicatorHandles[DSA_MODE_COUNT];
bool ModeOk[DSA_MODE_COUNT];
int HarnessFailures = 0;

void DSA_RecordFailure(const string message)
{
   ++HarnessFailures;
   Print("DSA model-mode harness failure: ",message," error=",GetLastError());
}

bool DSA_CopyOne(const int handle,const int buffer,const int shift,double &value)
{
   double data[];
   ArraySetAsSeries(data,true);
   const int copied = CopyBuffer(handle,buffer,shift,1,data);
   if(copied != 1)
      return false;
   value = data[0];
   return true;
}

void DSA_CheckModes()
{
   for(int mode = 0; mode < DSA_MODE_COUNT; ++mode)
   {
      if(ModeOk[mode])
         continue;

      const int handle = IndicatorHandles[mode];
      if(handle == INVALID_HANDLE)
         continue;

      if(BarsCalculated(handle) <= 0)
         continue;

      double trend = EMPTY_VALUE;
      double upper = EMPTY_VALUE;
      double lower = EMPTY_VALUE;
      double uncertainty_upper = EMPTY_VALUE;
      double uncertainty_lower = EMPTY_VALUE;
      if(!DSA_CopyOne(handle,0,0,trend) ||
         !DSA_CopyOne(handle,2,0,upper) ||
         !DSA_CopyOne(handle,3,0,lower) ||
         !DSA_CopyOne(handle,4,0,uncertainty_upper) ||
         !DSA_CopyOne(handle,5,0,uncertainty_lower))
      {
         DSA_RecordFailure("CopyBuffer failed for mode=" + IntegerToString(mode));
         continue;
      }

      if(!DSA_HasValue(trend) ||
         !DSA_HasValue(upper) ||
         !DSA_HasValue(lower) ||
         !DSA_HasValue(uncertainty_upper) ||
         !DSA_HasValue(uncertainty_lower))
         continue;

      if(upper < lower || uncertainty_upper < uncertainty_lower)
      {
         DSA_RecordFailure("band or uncertainty inversion for mode=" + IntegerToString(mode));
         continue;
      }

      ModeOk[mode] = true;
      Print("DSA model-mode harness mode ok. mode=",mode," calculated=",BarsCalculated(handle));
   }
}

int OnInit()
{
   for(int mode = 0; mode < DSA_MODE_COUNT; ++mode)
   {
      ModeOk[mode] = false;
      IndicatorHandles[mode] = iCustom(_Symbol,_Period,DSA_MODE_HARNESS_INDICATOR,
                                       "Host chart symbol",
                                       DSA_DATA_OHLC,
                                       PERIOD_CURRENT,
                                       PERIOD_CURRENT,
                                       PERIOD_D1,
                                       (ENUM_DSA_MODEL_MODE)mode,
                                       true,
                                       true,
                                       true,
                                       DSA_VISUAL_FULL);
      if(IndicatorHandles[mode] == INVALID_HANDLE)
      {
         DSA_RecordFailure("failed to create handle for mode=" + IntegerToString(mode));
         return INIT_FAILED;
      }
   }

   Print("DSA model-mode harness initialized for ",_Symbol," ",EnumToString(_Period));
   return INIT_SUCCEEDED;
}

void OnTick()
{
   DSA_CheckModes();
}

void OnDeinit(const int reason)
{
   for(int mode = 0; mode < DSA_MODE_COUNT; ++mode)
   {
      if(IndicatorHandles[mode] != INVALID_HANDLE)
         IndicatorRelease(IndicatorHandles[mode]);
   }

   Print("DSA model-mode harness completed. failures=",HarnessFailures,
         " modes=",ModeOk[0],",",ModeOk[1],",",ModeOk[2],",",ModeOk[3],",",ModeOk[4],",",ModeOk[5],
         " reason=",reason);
}

double OnTester()
{
   bool all_modes_ok = true;
   for(int mode = 0; mode < DSA_MODE_COUNT; ++mode)
      all_modes_ok = all_modes_ok && ModeOk[mode];

   return (HarnessFailures == 0 && all_modes_ok ? 1.0 : 0.0);
}
