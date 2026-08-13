#property copyright "DSA-MQL5 Native"
#property version   "1.00"

#include "..\Features\FeatureEngine.mqh"

bool HarnessDone = false;
int HarnessFailures = 0;

void DSA_RecordFailure(const string message)
{
   ++HarnessFailures;
   Print("DSA selection-data harness failure: ",message," error=",GetLastError());
}

bool DSA_CloseEnough(const double actual,const double expected,const double tolerance=1.0e-8)
{
   return MathAbs(actual - expected) <= tolerance;
}

void DSA_CheckChannelContract(const ENUM_DSA_SELECTION_DATA selection_data,
                              const int expected_count,
                              const bool expected_open,
                              const bool expected_high,
                              const bool expected_low,
                              const bool expected_close,
                              const double expected_central,
                              const double expected_upper,
                              const double expected_lower,
                              const double expected_direction)
{
   double open_values[];
   double high_values[];
   double low_values[];
   double close_values[];
   ArrayResize(open_values,3);
   ArrayResize(high_values,3);
   ArrayResize(low_values,3);
   ArrayResize(close_values,3);
   ArraySetAsSeries(open_values,true);
   ArraySetAsSeries(high_values,true);
   ArraySetAsSeries(low_values,true);
   ArraySetAsSeries(close_values,true);

   open_values[0] = 10.0;
   high_values[0] = 14.0;
   low_values[0] = 8.0;
   close_values[0] = 12.0;

   DSASelectionChannels channels;
   DSA_BuildSelectionChannels(0,selection_data,open_values,high_values,low_values,close_values,channels);

   if(channels.channel_count != expected_count)
      DSA_RecordFailure("unexpected channel count for " + DSA_SelectionName(selection_data));
   if(channels.uses_open != expected_open ||
      channels.uses_high != expected_high ||
      channels.uses_low != expected_low ||
      channels.uses_close != expected_close)
      DSA_RecordFailure("unexpected channel flags for " + DSA_SelectionName(selection_data));
   if(!DSA_CloseEnough(channels.central,expected_central))
      DSA_RecordFailure("unexpected central value for " + DSA_SelectionName(selection_data));
   if(!DSA_CloseEnough(channels.upper,expected_upper) || !DSA_CloseEnough(channels.lower,expected_lower))
      DSA_RecordFailure("unexpected channel bounds for " + DSA_SelectionName(selection_data));
   if(!DSA_CloseEnough(channels.direction,expected_direction))
      DSA_RecordFailure("unexpected channel direction for " + DSA_SelectionName(selection_data));
}

void DSA_CheckFeatureSnapshot()
{
   const int total = 48;
   datetime time[];
   double open_values[];
   double high_values[];
   double low_values[];
   double close_values[];
   long tick_volume[];
   int spread[];
   double target_buffer[];
   double trend_buffer[];
   double slope_buffer[];
   double volatility_buffer[];
   double quality_buffer[];

   ArrayResize(time,total);
   ArrayResize(open_values,total);
   ArrayResize(high_values,total);
   ArrayResize(low_values,total);
   ArrayResize(close_values,total);
   ArrayResize(tick_volume,total);
   ArrayResize(spread,total);
   ArrayResize(target_buffer,total);
   ArrayResize(trend_buffer,total);
   ArrayResize(slope_buffer,total);
   ArrayResize(volatility_buffer,total);
   ArrayResize(quality_buffer,total);

   ArraySetAsSeries(time,true);
   ArraySetAsSeries(open_values,true);
   ArraySetAsSeries(high_values,true);
   ArraySetAsSeries(low_values,true);
   ArraySetAsSeries(close_values,true);
   ArraySetAsSeries(tick_volume,true);
   ArraySetAsSeries(spread,true);
   ArraySetAsSeries(target_buffer,true);
   ArraySetAsSeries(trend_buffer,true);
   ArraySetAsSeries(slope_buffer,true);
   ArraySetAsSeries(volatility_buffer,true);
   ArraySetAsSeries(quality_buffer,true);

   ArrayInitialize(target_buffer,EMPTY_VALUE);
   ArrayInitialize(trend_buffer,EMPTY_VALUE);
   ArrayInitialize(slope_buffer,EMPTY_VALUE);
   ArrayInitialize(volatility_buffer,EMPTY_VALUE);
   ArrayInitialize(quality_buffer,EMPTY_VALUE);

   const datetime now = D'2025.01.10 00:00';
   for(int i = 0; i < total; ++i)
   {
      const double base = 100.0 - (double)i * 0.35;
      time[i] = now - i * 3600;
      open_values[i] = base;
      high_values[i] = base + 1.60;
      low_values[i] = base - 0.80;
      close_values[i] = base + 0.45;
      tick_volume[i] = 100 + i;
      spread[i] = 12;
      target_buffer[i] = 0.25 * (open_values[i] + high_values[i] + low_values[i] + close_values[i]);
   }

   DSAInputContract contract;
   DSA_BuildInputContract(contract,
                          "Host chart symbol",
                          DSA_DATA_OHLC,
                          PERIOD_CURRENT,
                          PERIOD_CURRENT,
                          PERIOD_D1,
                          DSA_MODEL_ADAPTIVE,
                          true,
                          true,
                          true,
                          DSA_VISUAL_FULL);

   DSAFeatureSnapshot feature;
   DSA_BuildFeatureSnapshot(0,total,contract,time,open_values,high_values,low_values,close_values,
                            tick_volume,spread,true,target_buffer,trend_buffer,slope_buffer,
                            volatility_buffer,quality_buffer,feature);

   if(!feature.multi_channel || feature.selected_channel_count != 4)
      DSA_RecordFailure("OHLC feature snapshot did not preserve four independent channels");
   if(!DSA_CloseEnough(feature.source_open,open_values[0]) ||
      !DSA_CloseEnough(feature.source_high,high_values[0]) ||
      !DSA_CloseEnough(feature.source_low,low_values[0]) ||
      !DSA_CloseEnough(feature.source_close,close_values[0]))
      DSA_RecordFailure("OHLC feature snapshot channel values changed");
   if(!DSA_CloseEnough(feature.target,target_buffer[0]) ||
      !DSA_CloseEnough(feature.selected_spread,high_values[0] - low_values[0]) ||
      !DSA_CloseEnough(feature.selected_direction,close_values[0] - open_values[0]))
      DSA_RecordFailure("OHLC feature snapshot central/spread/direction mismatch");

   DSA_BuildInputContract(contract,
                          "Host chart symbol",
                          DSA_DATA_HL,
                          PERIOD_CURRENT,
                          PERIOD_CURRENT,
                          PERIOD_D1,
                          DSA_MODEL_ADAPTIVE,
                          true,
                          true,
                          true,
                          DSA_VISUAL_FULL);
   DSA_BuildFeatureSnapshot(0,total,contract,time,open_values,high_values,low_values,close_values,
                            tick_volume,spread,true,target_buffer,trend_buffer,slope_buffer,
                            volatility_buffer,quality_buffer,feature);
   if(!feature.multi_channel || feature.selected_channel_count != 2 ||
      !DSA_HasValue(feature.source_high) || !DSA_HasValue(feature.source_low) ||
      DSA_HasValue(feature.source_open) || DSA_HasValue(feature.source_close))
      DSA_RecordFailure("HL feature snapshot did not preserve only high/low channels");
}

void DSA_RunSelectionDataHarness()
{
   DSA_CheckChannelContract(DSA_DATA_OPEN,1,true,false,false,false,10.0,10.0,10.0,0.0);
   DSA_CheckChannelContract(DSA_DATA_HIGH,1,false,true,false,false,14.0,14.0,14.0,0.0);
   DSA_CheckChannelContract(DSA_DATA_LOW,1,false,false,true,false,8.0,8.0,8.0,0.0);
   DSA_CheckChannelContract(DSA_DATA_CLOSE,1,false,false,false,true,12.0,12.0,12.0,0.0);
   DSA_CheckChannelContract(DSA_DATA_OHLC,4,true,true,true,true,11.0,14.0,8.0,2.0);
   DSA_CheckChannelContract(DSA_DATA_HL,2,false,true,true,false,11.0,14.0,8.0,6.0);
   DSA_CheckChannelContract(DSA_DATA_OC,2,true,false,false,true,11.0,12.0,10.0,2.0);
   DSA_CheckFeatureSnapshot();
   HarnessDone = true;
   Print("DSA selection-data harness completed. failures=",HarnessFailures);
}

int OnInit()
{
   DSA_RunSelectionDataHarness();
   return (HarnessFailures == 0 ? INIT_SUCCEEDED : INIT_FAILED);
}

void OnTick()
{
}

double OnTester()
{
   return (HarnessDone && HarnessFailures == 0 ? 1.0 : 0.0);
}
