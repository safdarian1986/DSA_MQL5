#ifndef DSA_FEATURE_ENGINE_MQH
#define DSA_FEATURE_ENGINE_MQH

#include "..\\Data\\MTFAlignment.mqh"

struct DSAFeatureSnapshot
{
   double target;
   double source_open;
   double source_high;
   double source_low;
   double source_close;
   double selected_upper;
   double selected_lower;
   double selected_spread;
   double selected_direction;
   double ohlc_average;
   double median_price;
   double oc_midpoint;
   double log_return;
   double absolute_return;
   double candle_range;
   double candle_body;
   double close_location;
   double gap;
   double quality_score;
   double robust_z;
   double volatility;
   double slope;
   double persistence;
   double range_efficiency;
   double acf1;
   double acf2;
   double pacf2;
   double cycle_score;
   double structure_position;
   double mtf_target;
   double mtf_deviation;
   bool mtf_available;
   bool multi_channel;
   int selected_channel_count;
   bool primary_analysis_available;
   bool primary_analysis_live;
   datetime primary_analysis_time;
   int maturity;
};

double DSA_SampledAcf(const int index,
                      const int rates_total,
                      const double &target_buffer[],
                      const int lag)
{
   const int available = rates_total - index - lag - 2;
   if(available < 8)
      return 0.0;

   const int max_samples = 192;
   const int stride = MathMax(1,(int)MathCeil((double)available / (double)max_samples));
   double sum_a = 0.0;
   double sum_b = 0.0;
   double sum_aa = 0.0;
   double sum_bb = 0.0;
   double sum_ab = 0.0;
   int count = 0;

   for(int j = index + 1; j + lag + 1 < rates_total; j += stride)
   {
      if(!DSA_HasValue(target_buffer[j]) ||
         !DSA_HasValue(target_buffer[j + 1]) ||
         !DSA_HasValue(target_buffer[j + lag]) ||
         !DSA_HasValue(target_buffer[j + lag + 1]))
         continue;

      const double a = target_buffer[j] - target_buffer[j + 1];
      const double b = target_buffer[j + lag] - target_buffer[j + lag + 1];
      sum_a += a;
      sum_b += b;
      sum_aa += a * a;
      sum_bb += b * b;
      sum_ab += a * b;
      ++count;
   }

   if(count < 8)
      return 0.0;

   const double n = (double)count;
   const double cov = sum_ab - sum_a * sum_b / n;
   const double var_a = sum_aa - sum_a * sum_a / n;
   const double var_b = sum_bb - sum_b * sum_b / n;
   return DSA_Clamp(DSA_SafeDiv(cov,MathSqrt(MathMax(var_a * var_b,DBL_EPSILON)),0.0),-1.0,1.0);
}

double DSA_SampledCycleScore(const int index,
                             const int rates_total,
                             const double &target_buffer[])
{
   const int available = rates_total - index - 3;
   if(available < 16)
      return 0.0;

   const int max_samples = 192;
   const int stride = MathMax(1,(int)MathCeil((double)available / (double)max_samples));
   double sin16 = 0.0;
   double cos16 = 0.0;
   double sin32 = 0.0;
   double cos32 = 0.0;
   double energy = 0.0;
   int count = 0;

   for(int j = index + 1; j + 1 < rates_total; j += stride)
   {
      if(!DSA_HasValue(target_buffer[j]) || !DSA_HasValue(target_buffer[j + 1]))
         continue;

      const double r = target_buffer[j] - target_buffer[j + 1];
      const double phase16 = 2.0 * M_PI * (double)count / 16.0;
      const double phase32 = 2.0 * M_PI * (double)count / 32.0;
      sin16 += r * MathSin(phase16);
      cos16 += r * MathCos(phase16);
      sin32 += r * MathSin(phase32);
      cos32 += r * MathCos(phase32);
      energy += r * r;
      ++count;
   }

   if(count < 16 || energy <= DBL_EPSILON)
      return 0.0;

   const double amp16 = MathSqrt(sin16 * sin16 + cos16 * cos16);
   const double amp32 = MathSqrt(sin32 * sin32 + cos32 * cos32);
   return DSA_Clamp((amp16 + amp32) / MathSqrt(energy * (double)count),0.0,1.0);
}

void DSA_BuildFeatureSnapshot(const int index,
                              const int rates_total,
                              DSAInputContract &contract,
                              const datetime &time[],
                              const double &open[],
                              const double &high[],
                              const double &low[],
                              const double &close[],
                              const long &tick_volume[],
                              const int &spread[],
                              const bool live_bar,
                              const double &target_buffer[],
                              const double &trend_buffer[],
                              const double &slope_buffer[],
                              const double &volatility_buffer[],
                              const double &quality_buffer[],
                              DSAFeatureSnapshot &feature)
{
   DSASelectionChannels channels;
   DSAMtfSnapshot primary_snapshot;
   const bool use_primary_analysis = DSA_GetPrimaryAnalysisSnapshot(contract,time[index],live_bar,primary_snapshot);
   const double source_open = (use_primary_analysis ? primary_snapshot.open : open[index]);
   const double source_high = (use_primary_analysis ? primary_snapshot.high : high[index]);
   const double source_low = (use_primary_analysis ? primary_snapshot.low : low[index]);
   const double source_close = (use_primary_analysis ? primary_snapshot.close : close[index]);
   const long source_tick_volume = (use_primary_analysis ? primary_snapshot.tick_volume : tick_volume[index]);
   const int source_spread = (use_primary_analysis ? primary_snapshot.spread : spread[index]);
   const ENUM_TIMEFRAMES source_timeframe = (use_primary_analysis ? contract.analysis_timeframe : contract.chart_timeframe);

   DSA_BuildSelectionChannelsFromValues(contract.selection_data,
                                        source_open,
                                        source_high,
                                        source_low,
                                        source_close,
                                        channels);

   feature.target = channels.central;
   feature.source_open = channels.open_value;
   feature.source_high = channels.high_value;
   feature.source_low = channels.low_value;
   feature.source_close = channels.close_value;
   feature.selected_upper = channels.upper;
   feature.selected_lower = channels.lower;
   feature.selected_spread = channels.spread;
   feature.selected_direction = channels.direction;
   feature.selected_channel_count = channels.channel_count;
   feature.multi_channel = (channels.channel_count > 1);
   feature.primary_analysis_available = use_primary_analysis;
   feature.primary_analysis_live = (use_primary_analysis && primary_snapshot.live);
   feature.primary_analysis_time = (use_primary_analysis ? primary_snapshot.source_time : time[index]);
   feature.ohlc_average = 0.25 * (source_open + source_high + source_low + source_close);
   feature.median_price = 0.5 * (source_high + source_low);
   feature.oc_midpoint = 0.5 * (source_open + source_close);
   feature.candle_range = MathMax(source_high - source_low,_Point);
   feature.candle_body = MathAbs(source_close - source_open);
   feature.close_location = DSA_SafeDiv(source_close - source_low,feature.candle_range,0.5);

   double previous_target = feature.target;
   if(index + 1 < rates_total && DSA_HasValue(target_buffer[index + 1]))
      previous_target = target_buffer[index + 1];
   else if(index + 1 < rates_total)
      previous_target = DSA_SourceTarget(index + 1,contract.selection_data,open,high,low,close);

   feature.log_return = DSA_LogReturn(feature.target,previous_target);
   feature.absolute_return = MathAbs(feature.target - previous_target);
   feature.gap = (index + 1 < rates_total ? MathAbs(source_open - previous_target) : 0.0);
   feature.quality_score = DSA_OhlcvQualityScore(source_open,source_high,source_low,source_close,
                                                 source_tick_volume,source_spread);
   if(!use_primary_analysis)
      feature.quality_score -= DSA_TimeGapPenalty(index,rates_total,time,source_timeframe);
   feature.quality_score = DSA_Clamp(feature.quality_score,0.0,100.0);

   double previous_volatility = feature.candle_range;
   if(index + 1 < rates_total && DSA_HasValue(volatility_buffer[index + 1]))
      previous_volatility = volatility_buffer[index + 1];
   const double channel_volatility = MathMax(feature.selected_spread * 0.50,MathAbs(feature.selected_direction));
   feature.volatility = DSA_Ewma(previous_volatility,
                                 MathMax(MathMax(feature.absolute_return,feature.candle_range * 0.35),
                                         channel_volatility * 0.35),
                                 0.08);
   feature.volatility = MathMax(feature.volatility,_Point);

   double previous_slope = 0.0;
   if(index + 1 < rates_total && DSA_HasValue(slope_buffer[index + 1]))
      previous_slope = slope_buffer[index + 1];
   feature.slope = DSA_Ewma(previous_slope,feature.target - previous_target,0.10);

   const double previous_trend = (index + 1 < rates_total && DSA_HasValue(trend_buffer[index + 1]) ? trend_buffer[index + 1] : previous_target);
   feature.robust_z = DSA_SafeDiv(feature.target - previous_trend,MathMax(feature.volatility,_Point),0.0);
   feature.persistence = (feature.slope == 0.0 ? 0.0 : DSA_Clamp(MathAbs(feature.slope) / MathMax(feature.volatility,_Point),0.0,3.0) / 3.0);
   feature.range_efficiency = DSA_Clamp(DSA_SafeDiv(MathAbs(source_close - source_open),feature.candle_range,0.0),0.0,1.0);
   if(feature.multi_channel && feature.selected_spread > _Point)
   {
      const double channel_efficiency = DSA_Clamp(DSA_SafeDiv(MathAbs(feature.selected_direction),
                                                              MathMax(feature.selected_spread,_Point),
                                                              feature.range_efficiency),0.0,1.0);
      feature.range_efficiency = 0.50 * feature.range_efficiency + 0.50 * channel_efficiency;
   }
   feature.acf1 = DSA_SampledAcf(index,rates_total,target_buffer,1);
   feature.acf2 = DSA_SampledAcf(index,rates_total,target_buffer,2);
   feature.pacf2 = DSA_SafeDiv(feature.acf2 - feature.acf1 * feature.acf1,
                               1.0 - feature.acf1 * feature.acf1,
                               0.0);
   feature.pacf2 = DSA_Clamp(feature.pacf2,-1.0,1.0);
   feature.cycle_score = DSA_SampledCycleScore(index,rates_total,target_buffer);
   const double structure_range = (feature.multi_channel ? MathMax(feature.selected_spread,_Point) : feature.candle_range);
   const double structure_low = (feature.multi_channel ? feature.selected_lower : low[index]);
   feature.structure_position = DSA_Clamp(DSA_SafeDiv(feature.target - structure_low,structure_range,0.5),0.0,1.0);
   feature.mtf_available = false;
   feature.mtf_target = feature.target;
   feature.mtf_deviation = 0.0;

   DSAMtfSnapshot mtf_snapshot;
   if(use_primary_analysis)
   {
      feature.mtf_available = true;
      feature.mtf_target = feature.target;
      feature.mtf_deviation = 0.0;
   }
   else if(DSA_GetCausalAnalysisRate(contract,time[index],mtf_snapshot))
   {
      feature.mtf_available = true;
      feature.mtf_target = DSA_MtfTarget(mtf_snapshot,contract.selection_data);
      feature.mtf_deviation = DSA_SafeDiv(feature.target - feature.mtf_target,MathMax(feature.volatility,_Point),0.0);
   }

   feature.maturity = rates_total - index;

   if(index + 1 < rates_total && DSA_HasValue(quality_buffer[index + 1]))
      feature.quality_score = DSA_Ewma(quality_buffer[index + 1],feature.quality_score,0.15);
}

#endif
