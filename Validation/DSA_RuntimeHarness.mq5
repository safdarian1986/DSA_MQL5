#property copyright "DSA-MQL5 Native"
#property version   "1.00"
#property tester_indicator "DSA_MQL5_Native.ex5"

#define DSA_HARNESS_INDICATOR "DSA_MQL5_Native"

int IndicatorHandle = INVALID_HANDLE;
int HarnessFailures = 0;
bool HarnessFirstReadOk = false;

bool DSA_ReadIndicatorHandle(const int handle,const string label,bool &first_read_ok)
{
   if(handle == INVALID_HANDLE)
      return false;

   const int calculated = BarsCalculated(handle);
   if(calculated <= 0)
      return false;

   double trend[];
   double upper[];
   double lower[];
   double up_event[];
   double down_event[];
   ArraySetAsSeries(trend,true);
   ArraySetAsSeries(upper,true);
   ArraySetAsSeries(lower,true);
   ArraySetAsSeries(up_event,true);
   ArraySetAsSeries(down_event,true);

   const int copied_trend = CopyBuffer(handle,0,0,3,trend);
   const int copied_upper = CopyBuffer(handle,2,0,3,upper);
   const int copied_lower = CopyBuffer(handle,3,0,3,lower);
   const int copied_up = CopyBuffer(handle,7,0,3,up_event);
   const int copied_down = CopyBuffer(handle,8,0,3,down_event);

   if(copied_trend <= 0 || copied_upper <= 0 || copied_lower <= 0)
   {
      ++HarnessFailures;
      Print("DSA runtime harness CopyBuffer failure for ",label,". Error=",GetLastError());
      return false;
   }

   for(int index = 0; index < copied_upper && index < copied_lower; ++index)
   {
      if(upper[index] != EMPTY_VALUE && lower[index] != EMPTY_VALUE && upper[index] < lower[index])
      {
         ++HarnessFailures;
         Print("DSA runtime harness detected inverted band for ",label," at index=",index);
      }
   }

   if(copied_up < 0 || copied_down < 0)
   {
      ++HarnessFailures;
      Print("DSA runtime harness event-buffer read failure for ",label,". Error=",GetLastError());
   }

   if(!first_read_ok)
   {
      first_read_ok = true;
      Print("DSA runtime harness first buffer read succeeded for ",label,". calculated=",calculated);
   }

   return true;
}

int OnInit()
{
   IndicatorHandle = iCustom(_Symbol,_Period,DSA_HARNESS_INDICATOR);
   if(IndicatorHandle == INVALID_HANDLE)
   {
      Print("DSA runtime harness failed to create indicator handle. Error=",GetLastError());
      return INIT_FAILED;
   }

   Print("DSA runtime harness initialized for ",_Symbol," ",EnumToString(_Period));
   return INIT_SUCCEEDED;
}

void OnDeinit(const int reason)
{
   if(IndicatorHandle != INVALID_HANDLE)
      IndicatorRelease(IndicatorHandle);

   Print("DSA runtime harness completed. failures=",HarnessFailures," reason=",reason);
}

void OnTick()
{
   if(IndicatorHandle == INVALID_HANDLE)
      return;

   DSA_ReadIndicatorHandle(IndicatorHandle,"default",HarnessFirstReadOk);
}

double OnTester()
{
   return (HarnessFailures == 0 ? 1.0 : 0.0);
}
