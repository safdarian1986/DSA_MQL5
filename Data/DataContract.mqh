#ifndef DSA_DATA_CONTRACT_MQH
#define DSA_DATA_CONTRACT_MQH

#include "..\\Core\\InputContract.mqh"

double DSA_SourceTarget(const int index,
                        const ENUM_DSA_SELECTION_DATA selection_data,
                        const double &open[],
                        const double &high[],
                        const double &low[],
                        const double &close[])
{
   switch(selection_data)
   {
      case DSA_DATA_OPEN:
         return open[index];
      case DSA_DATA_HIGH:
         return high[index];
      case DSA_DATA_LOW:
         return low[index];
      case DSA_DATA_HL:
         return 0.5 * (high[index] + low[index]);
      case DSA_DATA_OC:
         return 0.5 * (open[index] + close[index]);
      case DSA_DATA_OHLC:
         return 0.25 * (open[index] + high[index] + low[index] + close[index]);
      case DSA_DATA_CLOSE:
      default:
         return close[index];
   }
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
