#property copyright "DSA-MQL5 Native"
#property version   "1.00"

#include "..\Adaptation\AdaptiveEngine.mqh"

bool HarnessDone = false;
int HarnessFailures = 0;
int HarnessChecks = 0;
bool FeatureContextOk = false;
bool RegimeContextOk = false;
bool RuntimeScoreOk = false;
bool RollingMetricsOk = false;
bool AdaptiveStressOk = false;

void DSA_RecordFailure(const string message)
{
   ++HarnessFailures;
   Print("DSA feature-regime harness failure: ",message," error=",GetLastError());
}

bool DSA_CloseEnough(const double actual,const double expected,const double tolerance=1.0e-8)
{
   return MathAbs(actual - expected) <= tolerance;
}

void DSA_FillSyntheticMarket(datetime &time[],
                             double &open_values[],
                             double &high_values[],
                             double &low_values[],
                             double &close_values[],
                             long &tick_volume[],
                             int &spread[],
                             double &target_buffer[],
                             double &trend_buffer[],
                             double &slope_buffer[],
                             double &volatility_buffer[],
                             double &quality_buffer[],
                             double &forecast_buffer[],
                             double &forecast_h2_buffer[],
                             double &forecast_h4_buffer[],
                             double &forecast_h8_buffer[],
                             double &upper_buffer[],
                             double &lower_buffer[],
                             double &absolute_error_buffer[],
                             double &coverage_buffer[],
                             double &regime_buffer[],
                             double &ridge_state_buffer[])
{
   const int total = 220;
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
   ArrayResize(forecast_buffer,total);
   ArrayResize(forecast_h2_buffer,total);
   ArrayResize(forecast_h4_buffer,total);
   ArrayResize(forecast_h8_buffer,total);
   ArrayResize(upper_buffer,total);
   ArrayResize(lower_buffer,total);
   ArrayResize(absolute_error_buffer,total);
   ArrayResize(coverage_buffer,total);
   ArrayResize(regime_buffer,total);
   ArrayResize(ridge_state_buffer,total);

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
   ArraySetAsSeries(forecast_buffer,true);
   ArraySetAsSeries(forecast_h2_buffer,true);
   ArraySetAsSeries(forecast_h4_buffer,true);
   ArraySetAsSeries(forecast_h8_buffer,true);
   ArraySetAsSeries(upper_buffer,true);
   ArraySetAsSeries(lower_buffer,true);
   ArraySetAsSeries(absolute_error_buffer,true);
   ArraySetAsSeries(coverage_buffer,true);
   ArraySetAsSeries(regime_buffer,true);
   ArraySetAsSeries(ridge_state_buffer,true);

   const datetime newest = D'2025.01.10 00:00';
   for(int shift = 0; shift < total; ++shift)
   {
      const double seasonal = 0.30 * MathSin((double)shift / 6.0);
      double base = 110.0 - (double)shift * 0.05 + seasonal;
      if(shift == 0)
         base += 2.8;
      if(shift == 1)
         base += 1.1;

      const double range = (shift % 11 == 0 ? 1.80 : 0.55 + 0.02 * (double)(shift % 7));
      time[shift] = newest - shift * 3600;
      open_values[shift] = base - 0.10;
      high_values[shift] = base + range;
      low_values[shift] = base - range * 0.80;
      close_values[shift] = base + 0.15;
      tick_volume[shift] = (shift == 0 ? 4200 : 1000 + (shift % 13) * 12);
      spread[shift] = 10 + (shift % 4);

      target_buffer[shift] = 0.25 * (open_values[shift] + high_values[shift] + low_values[shift] + close_values[shift]);
      trend_buffer[shift] = target_buffer[shift] - 0.08;
      slope_buffer[shift] = 0.04;
      volatility_buffer[shift] = 0.65;
      quality_buffer[shift] = 92.0;
      forecast_buffer[shift] = target_buffer[shift] + (shift % 3 == 0 ? 0.35 : -0.18);
      forecast_h2_buffer[shift] = target_buffer[shift] + 0.20;
      forecast_h4_buffer[shift] = target_buffer[shift] + 0.35;
      forecast_h8_buffer[shift] = target_buffer[shift] + 0.50;
      upper_buffer[shift] = forecast_buffer[shift] + 0.90;
      lower_buffer[shift] = forecast_buffer[shift] - 0.90;
      absolute_error_buffer[shift] = MathAbs(target_buffer[shift] - forecast_buffer[shift]);
      coverage_buffer[shift] = (shift % 9 == 1 ? 0.0 : 1.0);
      regime_buffer[shift] = (double)DSA_REGIME_RANGE;
      ridge_state_buffer[shift] = target_buffer[shift] + 0.05;
   }
}

void DSA_RunFeatureRegimeHarness()
{
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
   double forecast_buffer[];
   double forecast_h2_buffer[];
   double forecast_h4_buffer[];
   double forecast_h8_buffer[];
   double upper_buffer[];
   double lower_buffer[];
   double absolute_error_buffer[];
   double coverage_buffer[];
   double regime_buffer[];
   double ridge_state_buffer[];

   DSA_FillSyntheticMarket(time,open_values,high_values,low_values,close_values,tick_volume,spread,
                           target_buffer,trend_buffer,slope_buffer,volatility_buffer,quality_buffer,
                           forecast_buffer,forecast_h2_buffer,forecast_h4_buffer,forecast_h8_buffer,
                           upper_buffer,lower_buffer,absolute_error_buffer,coverage_buffer,
                           regime_buffer,ridge_state_buffer);

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
   DSA_BuildFeatureSnapshot(0,ArraySize(time),contract,time,open_values,high_values,low_values,close_values,
                            tick_volume,spread,true,target_buffer,trend_buffer,slope_buffer,
                            volatility_buffer,quality_buffer,feature);

   FeatureContextOk = (DSA_HasValue(feature.mad_volatility) &&
                       DSA_HasValue(feature.parkinson_volatility) &&
                       DSA_HasValue(feature.vol_of_vol) &&
                       DSA_HasValue(feature.cusum_pressure) &&
                       feature.volume_shock > 0.50 &&
                       feature.support_level <= low_values[0] &&
                       feature.resistance_level >= high_values[0] &&
                       feature.congestion_score >= 0.0 &&
                       feature.structure_position >= 0.0 &&
                       feature.structure_position <= 1.0);
   if(!FeatureContextOk)
      DSA_RecordFailure("feature context did not expose volatility, volume, and structure fields");
   ++HarnessChecks;

   DSAModelSnapshot calm_model;
   DSA_ComputeModels(0,ArraySize(time),contract,feature,open_values,high_values,low_values,close_values,
                     target_buffer,trend_buffer,trend_buffer,forecast_buffer,
                     forecast_h2_buffer,forecast_h4_buffer,forecast_h8_buffer,
                     volatility_buffer,upper_buffer,lower_buffer,absolute_error_buffer,
                     regime_buffer,ridge_state_buffer,1.0,1.0,0.05,true,calm_model);

   DSAModelSnapshot loaded_model;
   DSA_ComputeModels(0,ArraySize(time),contract,feature,open_values,high_values,low_values,close_values,
                     target_buffer,trend_buffer,trend_buffer,forecast_buffer,
                     forecast_h2_buffer,forecast_h4_buffer,forecast_h8_buffer,
                     volatility_buffer,upper_buffer,lower_buffer,absolute_error_buffer,
                     regime_buffer,ridge_state_buffer,1.0,1.0,1.35,true,loaded_model);

   RegimeContextOk = (calm_model.regime >= DSA_REGIME_TREND_UP &&
                      calm_model.regime <= DSA_REGIME_UNCERTAIN &&
                      DSA_HasValue(calm_model.volatility_stress) &&
                      calm_model.interval_radius > 0.0);
   if(!RegimeContextOk)
      DSA_RecordFailure("regime or volatility-stress context was invalid");
   ++HarnessChecks;

   RuntimeScoreOk = (loaded_model.runtime_cost_score > calm_model.runtime_cost_score &&
                     loaded_model.model_score < calm_model.model_score);
   if(!RuntimeScoreOk)
      DSA_RecordFailure("runtime load did not penalize model score");
   ++HarnessChecks;

   DSAValidationSnapshot validation;
   DSA_ValidatePrequential(0,ArraySize(time),feature,calm_model,target_buffer,forecast_buffer,
                           upper_buffer,lower_buffer,absolute_error_buffer,coverage_buffer,validation);
   RollingMetricsOk = (DSA_HasValue(validation.rolling_mae) &&
                       DSA_HasValue(validation.rolling_rmse) &&
                       DSA_HasValue(validation.directional_accuracy) &&
                       DSA_HasValue(validation.coverage_rate) &&
                       validation.coverage_rate < 1.0 &&
                       validation.model_score <= calm_model.model_score);
   if(!RollingMetricsOk)
      DSA_RecordFailure("rolling validation metrics did not update model score");
   ++HarnessChecks;

   DSAAdaptiveSnapshot adaptive;
   DSA_ComputeAdaptiveDiagnostics(feature,loaded_model,validation,1.35,adaptive);
   AdaptiveStressOk = (adaptive.stress_score > 0.0 &&
                       adaptive.safe_mode_score > 0.0 &&
                       adaptive.reason_mask != DSA_REASON_NONE);
   if(!AdaptiveStressOk)
      DSA_RecordFailure("adaptive diagnostics did not react to stress and runtime load");
   ++HarnessChecks;

   HarnessDone = true;
   Print("DSA feature-regime harness completed. failures=",HarnessFailures,
         " checks=",HarnessChecks,
         " feature_context=",FeatureContextOk,
         " regime_context=",RegimeContextOk,
         " runtime_score=",RuntimeScoreOk,
         " rolling_metrics=",RollingMetricsOk,
         " adaptive_stress=",AdaptiveStressOk,
         " coverage_rate=",validation.coverage_rate,
         " runtime_cost=",loaded_model.runtime_cost_score);
}

int OnInit()
{
   DSA_RunFeatureRegimeHarness();
   return (HarnessFailures == 0 ? INIT_SUCCEEDED : INIT_FAILED);
}

void OnTick()
{
}

double OnTester()
{
   return (HarnessDone &&
           HarnessFailures == 0 &&
           HarnessChecks >= 5 &&
           FeatureContextOk &&
           RegimeContextOk &&
           RuntimeScoreOk &&
           RollingMetricsOk &&
           AdaptiveStressOk ? 1.0 : 0.0);
}
