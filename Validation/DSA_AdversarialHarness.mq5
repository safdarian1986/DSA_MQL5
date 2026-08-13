#property copyright "DSA-MQL5 Native"
#property version   "1.00"
#property tester_indicator "DSA_MQL5_Native.ex5"

#include "..\Core\InputContract.mqh"

#define DSA_ADV_INDICATOR "DSA_MQL5_Native"
#define DSA_ADV_MODES 1

int IndicatorHandles[DSA_ADV_MODES];
bool ModeReadOk[DSA_ADV_MODES];
int HarnessFailures = 0;
int DeepBarsSeen = 0;
bool FullHistoryOk = false;
bool BufferSemanticsOk = false;
bool AntiRepaintCaptured = false;
bool AntiRepaintCompared = false;
datetime CapturedTime = 0;
datetime LastBarTime = 0;
int NewBarsAfterCapture = 0;
double CapturedBuffers[10];

void DSA_RecordFailure(const string message)
{
   ++HarnessFailures;
   Print("DSA adversarial harness failure: ",message," error=",GetLastError());
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

bool DSA_CheckStableValue(const double before,const double after,const int buffer)
{
   const bool before_has = DSA_HasValue(before);
   const bool after_has = DSA_HasValue(after);
   if(before_has != after_has)
      return false;
   if(!before_has)
      return true;
   if(buffer == 6)
      return ((int)before == (int)after);
   return (MathAbs(before - after) <= MathMax(_Point * 0.5,1.0e-8));
}

bool DSA_CheckBufferSemanticsAtShift(const int handle,const int shift,const string label)
{
   double values[10];
   for(int buffer = 0; buffer < 10; ++buffer)
   {
      if(!DSA_CopyOne(handle,buffer,shift,values[buffer]))
      {
         DSA_RecordFailure("CopyBuffer failed for " + label + " buffer=" + IntegerToString(buffer));
         return false;
      }
   }

   if(!DSA_HasValue(values[0]) || !DSA_HasValue(values[1]) ||
      !DSA_HasValue(values[2]) || !DSA_HasValue(values[3]) ||
      !DSA_HasValue(values[4]) || !DSA_HasValue(values[5]))
   {
      DSA_RecordFailure("required price buffers are empty at " + label);
      return false;
   }

   if(values[2] < values[3])
   {
      DSA_RecordFailure("adaptive band inverted at " + label);
      return false;
   }

   if(values[4] < values[5])
   {
      DSA_RecordFailure("uncertainty interval inverted at " + label);
      return false;
   }

   if(DSA_HasValue(values[6]) && ((int)values[6] < DSA_REGIME_TREND_UP || (int)values[6] > DSA_REGIME_UNCERTAIN))
   {
      DSA_RecordFailure("regime buffer outside official enum range at " + label);
      return false;
   }

   const double high = iHigh(_Symbol,_Period,shift);
   const double low = iLow(_Symbol,_Period,shift);
   if(DSA_HasValue(values[7]) && values[7] > low + MathMax(10.0 * _Point,1.0e-8))
   {
      DSA_RecordFailure("up event marker is not below the bar low at " + label);
      return false;
   }

   if(DSA_HasValue(values[8]) && values[8] < high - MathMax(10.0 * _Point,1.0e-8))
   {
      DSA_RecordFailure("down event marker is not above the bar high at " + label);
      return false;
   }

   if(DSA_HasValue(values[9]) && values[9] <= 0.0)
   {
      DSA_RecordFailure("auxiliary event marker is non-positive at " + label);
      return false;
   }

   return true;
}

bool DSA_MainBuffersReadyAtShift(const int handle,const int shift)
{
   for(int buffer = 0; buffer <= 5; ++buffer)
   {
      double value = EMPTY_VALUE;
      if(!DSA_CopyOne(handle,buffer,shift,value) || !DSA_HasValue(value))
         return false;
   }
   return true;
}

void DSA_UpdateModeReadStatus()
{
   for(int mode = 0; mode < DSA_ADV_MODES; ++mode)
   {
      if(ModeReadOk[mode] || IndicatorHandles[mode] == INVALID_HANDLE)
         continue;

      const int calculated = BarsCalculated(IndicatorHandles[mode]);
      if(calculated <= 0)
         continue;

      double value = EMPTY_VALUE;
      if(DSA_CopyOne(IndicatorHandles[mode],0,0,value) && DSA_HasValue(value))
      {
         ModeReadOk[mode] = true;
         Print("DSA adversarial harness mode read ok. mode=",mode," calculated=",calculated);
      }
   }
}

void DSA_UpdateFullHistoryStatus()
{
   if(FullHistoryOk)
      return;

   const int handle = IndicatorHandles[0];
   if(handle == INVALID_HANDLE)
      return;

   const int calculated = BarsCalculated(handle);
   if(calculated <= 0)
      return;

   DeepBarsSeen = MathMax(DeepBarsSeen,calculated);
   const int old_shift = calculated - 50;
   if(old_shift < 5000)
      return;

   const int mid_shift = old_shift / 2;
   if(!DSA_MainBuffersReadyAtShift(handle,1) ||
      !DSA_MainBuffersReadyAtShift(handle,mid_shift) ||
      !DSA_MainBuffersReadyAtShift(handle,old_shift))
      return;

   if(DSA_CheckBufferSemanticsAtShift(handle,1,"closed-newest") &&
      DSA_CheckBufferSemanticsAtShift(handle,mid_shift,"middle-history") &&
      DSA_CheckBufferSemanticsAtShift(handle,old_shift,"oldest-sampled-history"))
   {
      FullHistoryOk = true;
      BufferSemanticsOk = true;
      Print("DSA adversarial harness full-history sampled coverage ok. calculated=",calculated,
            " oldest_shift=",old_shift," mid_shift=",mid_shift);
   }
}

void DSA_UpdateAntiRepaintStatus()
{
   const int handle = IndicatorHandles[0];
   if(handle == INVALID_HANDLE || !FullHistoryOk)
      return;

   const datetime current_bar_time = iTime(_Symbol,_Period,0);
   if(LastBarTime == 0)
      LastBarTime = current_bar_time;
   else if(current_bar_time != LastBarTime)
   {
      LastBarTime = current_bar_time;
      if(AntiRepaintCaptured)
         ++NewBarsAfterCapture;
   }

   if(!AntiRepaintCaptured)
   {
      const int capture_shift = 10;
      CapturedTime = iTime(_Symbol,_Period,capture_shift);
      if(CapturedTime == 0)
         return;

      for(int buffer = 0; buffer < 10; ++buffer)
      {
         if(!DSA_CopyOne(handle,buffer,capture_shift,CapturedBuffers[buffer]))
            return;
      }

      AntiRepaintCaptured = true;
      NewBarsAfterCapture = 0;
      Print("DSA adversarial harness captured closed-bar state. time=",TimeToString(CapturedTime,TIME_DATE|TIME_MINUTES));
      return;
   }

   if(AntiRepaintCompared || NewBarsAfterCapture < 2)
      return;

   const int shifted_index = iBarShift(_Symbol,_Period,CapturedTime,false);
   if(shifted_index < 1)
   {
      DSA_RecordFailure("captured historical timestamp could not be resolved");
      AntiRepaintCompared = true;
      return;
   }

   for(int buffer = 0; buffer < 10; ++buffer)
   {
      double current = EMPTY_VALUE;
      if(!DSA_CopyOne(handle,buffer,shifted_index,current))
      {
         DSA_RecordFailure("CopyBuffer failed during anti-repaint comparison buffer=" + IntegerToString(buffer));
         AntiRepaintCompared = true;
         return;
      }

      if(!DSA_CheckStableValue(CapturedBuffers[buffer],current,buffer))
      {
         DSA_RecordFailure("closed-bar output changed after future ticks buffer=" + IntegerToString(buffer));
         AntiRepaintCompared = true;
         return;
      }
   }

   AntiRepaintCompared = true;
   Print("DSA adversarial harness anti-repaint comparison ok. shifted_index=",shifted_index);
}

int OnInit()
{
   for(int mode = 0; mode < DSA_ADV_MODES; ++mode)
   {
      ModeReadOk[mode] = false;
      IndicatorHandles[mode] = iCustom(_Symbol,_Period,DSA_ADV_INDICATOR,
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
         DSA_RecordFailure("failed to create indicator handle for mode=" + IntegerToString(mode));
         return INIT_FAILED;
      }
   }

   Print("DSA adversarial harness initialized for ",_Symbol," ",EnumToString(_Period));
   return INIT_SUCCEEDED;
}

void OnDeinit(const int reason)
{
   for(int mode = 0; mode < DSA_ADV_MODES; ++mode)
   {
      if(IndicatorHandles[mode] != INVALID_HANDLE)
         IndicatorRelease(IndicatorHandles[mode]);
   }

   Print("DSA adversarial harness completed. failures=",HarnessFailures,
         " deep_bars=",DeepBarsSeen,
         " full_history=",FullHistoryOk,
         " buffer_semantics=",BufferSemanticsOk,
         " anti_repaint=",AntiRepaintCompared,
         " reason=",reason);
}

void OnTick()
{
   DSA_UpdateModeReadStatus();
   DSA_UpdateFullHistoryStatus();
   DSA_UpdateAntiRepaintStatus();
}

double OnTester()
{
   bool all_modes_ok = true;
   for(int mode = 0; mode < DSA_ADV_MODES; ++mode)
      all_modes_ok = all_modes_ok && ModeReadOk[mode];

   return (HarnessFailures == 0 &&
           all_modes_ok &&
           DeepBarsSeen >= 5000 &&
           FullHistoryOk &&
           BufferSemanticsOk &&
           AntiRepaintCompared ? 1.0 : 0.0);
}
