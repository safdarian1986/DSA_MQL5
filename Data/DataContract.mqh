#ifndef DSA_DATA_CONTRACT_MQH
#define DSA_DATA_CONTRACT_MQH

#include "..\\Core\\InputContract.mqh"

struct DSASelectionChannels
{
   double open_value;
   double high_value;
   double low_value;
   double close_value;
   double central;
   double upper;
   double lower;
   double spread;
   double direction;
   int channel_count;
   bool uses_open;
   bool uses_high;
   bool uses_low;
   bool uses_close;
};

void DSA_ResetSelectionChannels(DSASelectionChannels &channels)
{
   channels.open_value = EMPTY_VALUE;
   channels.high_value = EMPTY_VALUE;
   channels.low_value = EMPTY_VALUE;
   channels.close_value = EMPTY_VALUE;
   channels.central = EMPTY_VALUE;
   channels.upper = EMPTY_VALUE;
   channels.lower = EMPTY_VALUE;
   channels.spread = 0.0;
   channels.direction = 0.0;
   channels.channel_count = 0;
   channels.uses_open = false;
   channels.uses_high = false;
   channels.uses_low = false;
   channels.uses_close = false;
}

void DSA_RegisterSelectionValue(DSASelectionChannels &channels,
                                const bool active,
                                const double value,
                                double &slot,
                                bool &flag,
                                double &upper,
                                double &lower)
{
   if(!active)
      return;

   slot = value;
   flag = true;
   ++channels.channel_count;
   if(channels.channel_count == 1)
   {
      upper = value;
      lower = value;
   }
   else
   {
      upper = MathMax(upper,value);
      lower = MathMin(lower,value);
   }
}

void DSA_BuildSelectionChannelsFromValues(const ENUM_DSA_SELECTION_DATA selection_data,
                                          const double open_value,
                                          const double high_value,
                                          const double low_value,
                                          const double close_value,
                                          DSASelectionChannels &channels)
{
   DSA_ResetSelectionChannels(channels);

   double upper = 0.0;
   double lower = 0.0;
   const bool use_open = (selection_data == DSA_DATA_OPEN || selection_data == DSA_DATA_OHLC || selection_data == DSA_DATA_OC);
   const bool use_high = (selection_data == DSA_DATA_HIGH || selection_data == DSA_DATA_OHLC || selection_data == DSA_DATA_HL);
   const bool use_low = (selection_data == DSA_DATA_LOW || selection_data == DSA_DATA_OHLC || selection_data == DSA_DATA_HL);
   const bool use_close = (selection_data == DSA_DATA_CLOSE || selection_data == DSA_DATA_OHLC || selection_data == DSA_DATA_OC);

   DSA_RegisterSelectionValue(channels,use_open,open_value,channels.open_value,channels.uses_open,upper,lower);
   DSA_RegisterSelectionValue(channels,use_high,high_value,channels.high_value,channels.uses_high,upper,lower);
   DSA_RegisterSelectionValue(channels,use_low,low_value,channels.low_value,channels.uses_low,upper,lower);
   DSA_RegisterSelectionValue(channels,use_close,close_value,channels.close_value,channels.uses_close,upper,lower);

   if(channels.channel_count <= 0)
   {
      DSA_RegisterSelectionValue(channels,true,close_value,channels.close_value,channels.uses_close,upper,lower);
   }

   switch(selection_data)
   {
      case DSA_DATA_OPEN:
         channels.central = open_value;
         break;
      case DSA_DATA_HIGH:
         channels.central = high_value;
         break;
      case DSA_DATA_LOW:
         channels.central = low_value;
         break;
      case DSA_DATA_HL:
         channels.central = 0.5 * (high_value + low_value);
         break;
      case DSA_DATA_OC:
         channels.central = 0.5 * (open_value + close_value);
         break;
      case DSA_DATA_OHLC:
         channels.central = 0.25 * (open_value + high_value + low_value + close_value);
         break;
      case DSA_DATA_CLOSE:
      default:
         channels.central = close_value;
         break;
   }

   channels.upper = upper;
   channels.lower = lower;
   channels.spread = MathMax(upper - lower,0.0);
   if(channels.uses_open && channels.uses_close)
      channels.direction = close_value - open_value;
   else if(channels.uses_high && channels.uses_low)
      channels.direction = high_value - low_value;
   else
      channels.direction = 0.0;
}

void DSA_BuildSelectionChannels(const int index,
                                const ENUM_DSA_SELECTION_DATA selection_data,
                                const double &open[],
                                const double &high[],
                                const double &low[],
                                const double &close[],
                                DSASelectionChannels &channels)
{
   DSA_BuildSelectionChannelsFromValues(selection_data,open[index],high[index],low[index],close[index],channels);
}

double DSA_SourceTarget(const int index,
                        const ENUM_DSA_SELECTION_DATA selection_data,
                        const double &open[],
                        const double &high[],
                        const double &low[],
                        const double &close[])
{
   DSASelectionChannels channels;
   DSA_BuildSelectionChannels(index,selection_data,open,high,low,close,channels);
   return channels.central;
}

double DSA_OHLCAverage(const int index,const double &open[],const double &high[],const double &low[],const double &close[])
{
   return 0.25 * (open[index] + high[index] + low[index] + close[index]);
}

double DSA_MedianPrice(const int index,const double &high[],const double &low[])
{
   return 0.5 * (high[index] + low[index]);
}

double DSA_OpenCloseMidpoint(const int index,const double &open[],const double &close[])
{
   return 0.5 * (open[index] + close[index]);
}

double DSA_LogReturn(const double value,const double previous)
{
   if(value <= 0.0 || previous <= 0.0)
      return 0.0;
   return MathLog(value / previous);
}

double DSA_TimeGapPenalty(const int index,
                          const int rates_total,
                          const datetime &time[],
                          const ENUM_TIMEFRAMES timeframe)
{
   if(index + 1 >= rates_total)
      return 0.0;

   const int expected = DSA_TimeframeSeconds(timeframe,_Period);
   const int actual = (int)MathAbs((long)(time[index] - time[index + 1]));
   if(expected <= 0)
      return 0.0;
   if(actual <= expected * 3 / 2)
      return 0.0;
   return DSA_Clamp(100.0 * DSA_SafeDiv((double)(actual - expected),(double)MathMax(expected,1),0.0),0.0,40.0);
}

double DSA_DataQualityScore(const int index,
                            const int rates_total,
                            const datetime &time[],
                            const double &open[],
                            const double &high[],
                            const double &low[],
                            const double &close[],
                            const long &tick_volume[],
                            const int &spread[],
                            const ENUM_TIMEFRAMES timeframe)
{
   double score = 100.0;

   if(!MathIsValidNumber(open[index]) || !MathIsValidNumber(high[index]) ||
      !MathIsValidNumber(low[index]) || !MathIsValidNumber(close[index]))
      score -= 50.0;

   if(high[index] < low[index])
      score -= 35.0;
   if(open[index] <= 0.0 || high[index] <= 0.0 || low[index] <= 0.0 || close[index] <= 0.0)
      score -= 20.0;
   if(tick_volume[index] < 0)
      score -= 10.0;
   if(spread[index] < 0)
      score -= 5.0;

   score -= DSA_TimeGapPenalty(index,rates_total,time,timeframe);
   return DSA_Clamp(score,0.0,100.0);
}

double DSA_RevisionHashMix(const double hash,const double value)
{
   double safe_value = value;
   if(!MathIsValidNumber(safe_value))
      safe_value = 0.0;

   safe_value = MathMod(MathAbs(safe_value),1000000007.0);
   return MathMod(hash * 4099.0 + safe_value + 17.0,2000000000.0);
}

double DSA_RevisionPriceValue(const double value)
{
   if(!MathIsValidNumber(value))
      return 0.0;

   const double point = MathMax(_Point,1.0e-10);
   return MathRound(value / point);
}

double DSA_BarRevisionFingerprint(const int index,
                                  const int rates_total,
                                  const datetime &time[],
                                  const double &open[],
                                  const double &high[],
                                  const double &low[],
                                  const double &close[],
                                  const long &tick_volume[],
                                  const int &spread[])
{
   if(index < 0 || index >= rates_total)
      return EMPTY_VALUE;

   double hash = 166136261.0;
   hash = DSA_RevisionHashMix(hash,(double)(long)time[index]);
   hash = DSA_RevisionHashMix(hash,DSA_RevisionPriceValue(open[index]));
   hash = DSA_RevisionHashMix(hash,DSA_RevisionPriceValue(high[index]));
   hash = DSA_RevisionHashMix(hash,DSA_RevisionPriceValue(low[index]));
   hash = DSA_RevisionHashMix(hash,DSA_RevisionPriceValue(close[index]));
   hash = DSA_RevisionHashMix(hash,(double)tick_volume[index]);
   hash = DSA_RevisionHashMix(hash,(double)spread[index]);
   return hash + 1.0;
}

string DSA_HistoryFingerprint(const int rates_total,const datetime &time[])
{
   if(rates_total <= 0)
      return "empty";
   const datetime oldest = time[rates_total - 1];
   string fingerprint = StringFormat("oldest=%I64d",(long)oldest);
   int offsets[8] = {1,2,4,8,16,64,512,4096};
   for(int i = 0; i < 8; ++i)
   {
      const int offset = offsets[i];
      if(offset < rates_total)
      {
         const int index = rates_total - 1 - offset;
         fingerprint += StringFormat("|o%d=%I64d",offset,(long)time[index]);
      }
   }
   return fingerprint;
}

#endif
