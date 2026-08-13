#property copyright "DSA-MQL5 Native"
#property version   "1.00"
#property tester_indicator "DSA_MQL5_Native.ex5"

#define DSA_DEEP_HARNESS_INDICATOR "DSA_MQL5_Native"

int IndicatorHandle = INVALID_HANDLE;
int HarnessFailures = 0;
bool HarnessFirstReadOk = false;

int OnInit()
{
   IndicatorHandle = iCustom(_Symbol,_Period,DSA_DEEP_HARNESS_INDICATOR,
                             "Host chart symbol",
                             4,
                             PERIOD_CURRENT,
                             PERIOD_CURRENT,
                             PERIOD_D1,
                             3,
                             true,
                             true,
                             true,
                             1);
   if(IndicatorHandle == INVALID_HANDLE)
   {
      Print("DSA deep-learning harness failed to create indicator handle. Error=",GetLastError());
      return INIT_FAILED;
   }

   Print("DSA deep-learning harness initialized for ",_Symbol," ",EnumToString(_Period));
   return INIT_SUCCEEDED;
}

void OnDeinit(const int reason)
{
   if(IndicatorHandle != INVALID_HANDLE)
      IndicatorRelease(IndicatorHandle);

   Print("DSA deep-learning harness completed. failures=",HarnessFailures," reason=",reason);
}

void OnTick()
{
   if(IndicatorHandle == INVALID_HANDLE)
      return;

   const int calculated = BarsCalculated(IndicatorHandle);
   if(calculated <= 0)
      return;

   double trend[];
   double upper[];
   double lower[];
   double forecast_upper[];
   double forecast_lower[];
   ArraySetAsSeries(trend,true);
   ArraySetAsSeries(upper,true);
   ArraySetAsSeries(lower,true);
   ArraySetAsSeries(forecast_upper,true);
   ArraySetAsSeries(forecast_lower,true);

   const int copied_trend = CopyBuffer(IndicatorHandle,0,0,2,trend);
   const int copied_upper = CopyBuffer(IndicatorHandle,2,0,2,upper);
   const int copied_lower = CopyBuffer(IndicatorHandle,3,0,2,lower);
   const int copied_forecast_upper = CopyBuffer(IndicatorHandle,4,0,2,forecast_upper);
   const int copied_forecast_lower = CopyBuffer(IndicatorHandle,5,0,2,forecast_lower);

   if(copied_trend <= 0 || copied_upper <= 0 || copied_lower <= 0 ||
      copied_forecast_upper <= 0 || copied_forecast_lower <= 0)
   {
      ++HarnessFailures;
      Print("DSA deep-learning harness CopyBuffer failure. Error=",GetLastError());
      return;
   }

   for(int index = 0; index < copied_upper && index < copied_lower; ++index)
   {
      if(upper[index] != EMPTY_VALUE && lower[index] != EMPTY_VALUE && upper[index] < lower[index])
      {
         ++HarnessFailures;
         Print("DSA deep-learning harness detected inverted band at index=",index);
      }
   }

   for(int index = 0; index < copied_forecast_upper && index < copied_forecast_lower; ++index)
   {
      if(forecast_upper[index] != EMPTY_VALUE &&
         forecast_lower[index] != EMPTY_VALUE &&
         forecast_upper[index] < forecast_lower[index])
      {
         ++HarnessFailures;
         Print("DSA deep-learning harness detected inverted uncertainty at index=",index);
      }
   }

   if(!HarnessFirstReadOk)
   {
      HarnessFirstReadOk = true;
      Print("DSA deep-learning harness first buffer read succeeded. calculated=",calculated);
   }
}

double OnTester()
{
   return (HarnessFailures == 0 ? 1.0 : 0.0);
}
