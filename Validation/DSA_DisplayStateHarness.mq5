#property copyright "DSA-MQL5 Native"
#property version   "1.00"
#property tester_indicator "DSA_MQL5_Native.ex5"

#include "..\Core\InputContract.mqh"

#define DSA_DISPLAY_INDICATOR "DSA_MQL5_Native"
#define DSA_DISPLAY_OBJECT_PREFIX "DSA_MQL5_"

int HiddenHistoryHandle = INVALID_HANDLE;
int NoForecastHandle = INVALID_HANDLE;
int NoEventHandle = INVALID_HANDLE;
int HarnessFailures = 0;
bool HiddenHistoryOk = false;
bool ForecastHiddenOk = false;
bool EventsHiddenOk = false;

void DSA_RecordFailure(const string message)
{
   ++HarnessFailures;
   Print("DSA display-state harness failure: ",message," error=",GetLastError());
}

bool DSA_CopyOne(const int handle,const int buffer,const int shift,double &value)
{
   double data[];
   ArraySetAsSeries(data,true);
   ResetLastError();
   const int copied = CopyBuffer(handle,buffer,shift,1,data);
   if(copied != 1)
      return false;
   value = data[0];
   return true;
}

bool DSA_BufferHasValue(const int handle,const int buffer,const int shift)
{
   double value = EMPTY_VALUE;
   return (DSA_CopyOne(handle,buffer,shift,value) && DSA_HasValue(value));
}

bool DSA_BufferEmpty(const int handle,const int buffer,const int shift)
{
   double value = 0.0;
   return (DSA_CopyOne(handle,buffer,shift,value) && !DSA_HasValue(value));
}

int DSA_CountProjectObjects()
{
   int count = 0;
   const int total = ObjectsTotal(0,0,-1);
   for(int index = total - 1; index >= 0; --index)
   {
      const string name = ObjectName(0,index,0,-1);
      if(StringFind(name,DSA_DISPLAY_OBJECT_PREFIX) == 0)
         ++count;
   }
   return count;
}

void DSA_CheckHiddenHistory()
{
   if(HiddenHistoryOk || HiddenHistoryHandle == INVALID_HANDLE)
      return;
   if(BarsCalculated(HiddenHistoryHandle) < 40)
      return;

   const int shift = 10;
   if(!DSA_BufferHasValue(HiddenHistoryHandle,10,shift) ||
      !DSA_BufferHasValue(HiddenHistoryHandle,11,shift) ||
      !DSA_BufferHasValue(HiddenHistoryHandle,16,shift))
   {
      return;
   }

   for(int buffer = 0; buffer <= 5; ++buffer)
   {
      if(!DSA_BufferEmpty(HiddenHistoryHandle,buffer,shift))
      {
         DSA_RecordFailure("historical display buffer is visible while Historical Analysis is false");
         HiddenHistoryOk = true;
         return;
      }
   }

   HiddenHistoryOk = true;
   Print("DSA display-state harness hidden-history check ok. shift=",shift);
}

void DSA_CheckForecastHidden()
{
   if(ForecastHiddenOk || NoForecastHandle == INVALID_HANDLE)
      return;
   if(BarsCalculated(NoForecastHandle) < 10)
      return;

   if(!DSA_BufferHasValue(NoForecastHandle,10,0) ||
      !DSA_BufferHasValue(NoForecastHandle,11,0))
   {
      return;
   }

   const int object_count = DSA_CountProjectObjects();
   if(object_count != 0)
   {
      DSA_RecordFailure("forecast objects are visible while Forecast Display is false");
      ForecastHiddenOk = true;
      return;
   }

   ForecastHiddenOk = true;
   Print("DSA display-state harness forecast-hidden check ok.");
}

void DSA_CheckEventsHidden()
{
   if(EventsHiddenOk || NoEventHandle == INVALID_HANDLE)
      return;
   if(BarsCalculated(NoEventHandle) < 40)
      return;

   const int shift = 10;
   if(!DSA_BufferHasValue(NoEventHandle,10,shift) ||
      !DSA_BufferHasValue(NoEventHandle,11,shift))
   {
      return;
   }

   for(int buffer = 7; buffer <= 9; ++buffer)
   {
      if(!DSA_BufferEmpty(NoEventHandle,buffer,shift))
      {
         DSA_RecordFailure("event marker buffer is visible while Event Display is false");
         EventsHiddenOk = true;
         return;
      }
   }

   EventsHiddenOk = true;
   Print("DSA display-state harness event-hidden check ok. shift=",shift);
}

int OnInit()
{
   HiddenHistoryHandle = iCustom(_Symbol,_Period,DSA_DISPLAY_INDICATOR,
                                 "Host chart symbol",
                                 DSA_DATA_OHLC,
                                 PERIOD_CURRENT,
                                 PERIOD_CURRENT,
                                 PERIOD_D1,
                                 DSA_MODEL_ADAPTIVE,
                                 false,
                                 false,
                                 true,
                                 DSA_VISUAL_BASIC);
   if(HiddenHistoryHandle == INVALID_HANDLE)
   {
      DSA_RecordFailure("failed to create hidden-history indicator handle");
      return INIT_FAILED;
   }

   NoForecastHandle = iCustom(_Symbol,_Period,DSA_DISPLAY_INDICATOR,
                              "Host chart symbol",
                              DSA_DATA_OHLC,
                              PERIOD_CURRENT,
                              PERIOD_CURRENT,
                              PERIOD_D1,
                              DSA_MODEL_ADAPTIVE,
                              true,
                              false,
                              true,
                              DSA_VISUAL_FULL);
   if(NoForecastHandle == INVALID_HANDLE)
   {
      DSA_RecordFailure("failed to create no-forecast indicator handle");
      return INIT_FAILED;
   }

   if(!ChartIndicatorAdd(0,0,NoForecastHandle))
      Print("DSA display-state harness could not attach no-forecast indicator. error=",GetLastError());

   NoEventHandle = iCustom(_Symbol,_Period,DSA_DISPLAY_INDICATOR,
                           "Host chart symbol",
                           DSA_DATA_OHLC,
                           PERIOD_CURRENT,
                           PERIOD_CURRENT,
                           PERIOD_D1,
                           DSA_MODEL_ADAPTIVE,
                           true,
                           false,
                           false,
                           DSA_VISUAL_BASIC);
   if(NoEventHandle == INVALID_HANDLE)
   {
      DSA_RecordFailure("failed to create no-event indicator handle");
      return INIT_FAILED;
   }

   Print("DSA display-state harness initialized for ",_Symbol," ",EnumToString(_Period));
   return INIT_SUCCEEDED;
}

void OnDeinit(const int reason)
{
   if(HiddenHistoryHandle != INVALID_HANDLE)
      IndicatorRelease(HiddenHistoryHandle);
   if(NoForecastHandle != INVALID_HANDLE)
      IndicatorRelease(NoForecastHandle);
   if(NoEventHandle != INVALID_HANDLE)
      IndicatorRelease(NoEventHandle);

   Print("DSA display-state harness completed. failures=",HarnessFailures,
         " hidden_history=",HiddenHistoryOk,
         " forecast_hidden=",ForecastHiddenOk,
         " events_hidden=",EventsHiddenOk,
         " reason=",reason);
}

void OnTick()
{
   DSA_CheckHiddenHistory();
   DSA_CheckForecastHidden();
   DSA_CheckEventsHidden();
}

double OnTester()
{
   return (HarnessFailures == 0 &&
           HiddenHistoryOk &&
           ForecastHiddenOk &&
           EventsHiddenOk ? 1.0 : 0.0);
}
