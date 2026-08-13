#property copyright "DSA-MQL5 Native"
#property version   "1.00"

#include "..\Models\ModelBank.mqh"

bool HarnessDone = false;
int HarnessFailures = 0;
int HarnessChecks = 0;
bool SequenceForecastOk = false;
bool DeepModeOk = false;
bool HybridBlendOk = false;
bool SafeModeSuppressesSequenceOk = false;

void DSA_RecordFailure(const string message)
{
   ++HarnessFailures;
   Print("DSA sequence-expert harness failure: ",message," error=",GetLastError());
}

void DSA_FillSequenceMarket(datetime &time[],
                            double &open_values[],
                            double &high_values[],
                            double &low_values[],
                            double &close_values[],
                            long &tick_volume[],
                            int &spread[],
                            double &target_buffer[],
                            double &trend_buffer[],
                            double &signal_buffer[],
                            double &forecast_buffer[],
                            double &forecast_h2_buffer[],
                            double &forecast_h4_buffer[],
                            double &forecast_h8_buffer[],
                            double &volatility_buffer[],
                            double &upper_buffer[],
                            double &lower_buffer[],
                            double &absolute_error_buffer[],
                            double &regime_buffer[],
                            double &ridge_state_buffer[],
                            double &quality_buffer[])
{
   const int total = 260;
   ArrayResize(time,total);
   ArrayResize(open_values,total);
   ArrayResize(high_values,total);
   ArrayResize(low_values,total);
   ArrayResize(close_values,total);
   ArrayResize(tick_volume,total);
   ArrayResize(spread,total);
   ArrayResize(target_buffer,total);
   ArrayResize(trend_buffer,total);
   ArrayResize(signal_buffer,total);
   ArrayResize(forecast_buffer,total);
   ArrayResize(forecast_h2_buffer,total);
   ArrayResize(forecast_h4_buffer,total);
   ArrayResize(forecast_h8_buffer,total);
   ArrayResize(volatility_buffer,total);
   ArrayResize(upper_buffer,total);
   ArrayResize(lower_buffer,total);
   ArrayResize(absolute_error_buffer,total);
   ArrayResize(regime_buffer,total);
   ArrayResize(ridge_state_buffer,total);
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
   ArraySetAsSeries(signal_buffer,true);
   ArraySetAsSeries(forecast_buffer,true);
   ArraySetAsSeries(forecast_h2_buffer,true);
   ArraySetAsSeries(forecast_h4_buffer,true);
   ArraySetAsSeries(forecast_h8_buffer,true);
   ArraySetAsSeries(volatility_buffer,true);
   ArraySetAsSeries(upper_buffer,true);
   ArraySetAsSeries(lower_buffer,true);
   ArraySetAsSeries(absolute_error_buffer,true);
   ArraySetAsSeries(regime_buffer,true);
   ArraySetAsSeries(ridge_state_buffer,true);
   ArraySetAsSeries(quality_buffer,true);

   const datetime newest = D'2025.01.10 00:00';
   for(int shift = 0; shift < total; ++shift)
   {
      const double cycle = MathSin((double)shift * 2.0 * M_PI / 16.0);
      const double slow = MathSin((double)shift * 2.0 * M_PI / 48.0);
      const double base = 100.0 - 0.03 * (double)shift + 0.85 * cycle + 0.45 * slow;
      time[shift] = newest - shift * 3600;
      open_values[shift] = base - 0.08;
      high_values[shift] = base + 0.35;
      low_values[shift] = base - 0.30;
      close_values[shift] = base + 0.10;
      tick_volume[shift] = 1000 + (shift % 8) * 15;
      spread[shift] = 10;
      target_buffer[shift] = 0.25 * (open_values[shift] + high_values[shift] + low_values[shift] + close_values[shift]);
      trend_buffer[shift] = target_buffer[shift] - 0.04;
      signal_buffer[shift] = target_buffer[shift] - 0.02;
      forecast_buffer[shift] = target_buffer[shift] + 0.05;
      forecast_h2_buffer[shift] = target_buffer[shift] + 0.08;
      forecast_h4_buffer[shift] = target_buffer[shift] + 0.12;
      forecast_h8_buffer[shift] = target_buffer[shift] + 0.18;
      volatility_buffer[shift] = 0.55;
      upper_buffer[shift] = forecast_buffer[shift] + 0.70;
      lower_buffer[shift] = forecast_buffer[shift] - 0.70;
      absolute_error_buffer[shift] = MathAbs(target_buffer[shift] - forecast_buffer[shift]);
      regime_buffer[shift] = (double)DSA_REGIME_RANGE;
      ridge_state_buffer[shift] = target_buffer[shift] + 0.03;
      quality_buffer[shift] = 94.0;
   }
}

void DSA_RunSequenceExpertHarness()
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
   double signal_buffer[];
   double forecast_buffer[];
   double forecast_h2_buffer[];
   double forecast_h4_buffer[];
   double forecast_h8_buffer[];
   double volatility_buffer[];
   double upper_buffer[];
   double lower_buffer[];
   double absolute_error_buffer[];
   double regime_buffer[];
   double ridge_state_buffer[];
   double quality_buffer[];

   DSA_FillSequenceMarket(time,open_values,high_values,low_values,close_values,tick_volume,spread,
                          target_buffer,trend_buffer,signal_buffer,forecast_buffer,
                          forecast_h2_buffer,forecast_h4_buffer,forecast_h8_buffer,
                          volatility_buffer,upper_buffer,lower_buffer,absolute_error_buffer,
                          regime_buffer,ridge_state_buffer,quality_buffer);

   DSAInputContract contract;
   DSA_BuildInputContract(contract,"Host chart symbol",DSA_DATA_OHLC,PERIOD_CURRENT,PERIOD_CURRENT,
                          PERIOD_D1,DSA_MODEL_ADAPTIVE,true,true,true,DSA_VISUAL_FULL);

   DSAFeatureSnapshot feature;
   DSA_BuildFeatureSnapshot(0,ArraySize(time),contract,time,open_values,high_values,low_values,close_values,
                            tick_volume,spread,true,target_buffer,trend_buffer,trend_buffer,
                            volatility_buffer,quality_buffer,feature);

   double sequence_confidence = 0.0;
   double sequence_maturity = 0.0;
   const double sequence_forecast = DSA_SequenceExpertForecast(0,ArraySize(time),feature,
                                                              target_buffer,volatility_buffer,quality_buffer,
                                                              false,sequence_confidence,sequence_maturity);

   SequenceForecastOk = (DSA_HasValue(sequence_forecast) &&
                         sequence_confidence > 0.25 &&
                         sequence_maturity > 0.25 &&
                         MathAbs(sequence_forecast - feature.target) <= MathMax(feature.volatility * 5.0,8.0 * _Point));
   if(!SequenceForecastOk)
      DSA_RecordFailure("sequence expert did not produce a mature bounded forecast");
   ++HarnessChecks;

   DSAInputContract deep_contract = contract;
   deep_contract.model_mode = DSA_MODEL_DEEP_LEARNING;
   DSAModelSnapshot deep_model;
   DSA_ComputeModels(0,ArraySize(time),deep_contract,feature,open_values,high_values,low_values,close_values,
                     target_buffer,trend_buffer,signal_buffer,forecast_buffer,
                     forecast_h2_buffer,forecast_h4_buffer,forecast_h8_buffer,
                     volatility_buffer,quality_buffer,upper_buffer,lower_buffer,absolute_error_buffer,regime_buffer,
                     ridge_state_buffer,1.0,1.0,0.05,false,deep_model);

   DeepModeOk = (deep_model.sequence_confidence > 0.25 &&
                 MathAbs(deep_model.central_forecast - deep_model.sequence_forecast) <
                 MathAbs(deep_model.central_forecast - deep_model.naive));
   if(!DeepModeOk)
      DSA_RecordFailure("DeepLearning mode did not prioritize the native sequence expert");
   ++HarnessChecks;

   DSAInputContract hybrid_contract = contract;
   hybrid_contract.model_mode = DSA_MODEL_HYBRID;
   DSAModelSnapshot hybrid_model;
   DSA_ComputeModels(0,ArraySize(time),hybrid_contract,feature,open_values,high_values,low_values,close_values,
                     target_buffer,trend_buffer,signal_buffer,forecast_buffer,
                     forecast_h2_buffer,forecast_h4_buffer,forecast_h8_buffer,
                     volatility_buffer,quality_buffer,upper_buffer,lower_buffer,absolute_error_buffer,regime_buffer,
                     ridge_state_buffer,1.0,1.0,0.05,false,hybrid_model);

   const double family_low = MathMin(MathMin(hybrid_model.holt_forecast,hybrid_model.ridge_forecast),hybrid_model.sequence_forecast) - _Point;
   const double family_high = MathMax(MathMax(hybrid_model.holt_forecast,hybrid_model.ridge_forecast),hybrid_model.sequence_forecast) + _Point;
   HybridBlendOk = (hybrid_model.sequence_confidence > 0.25 &&
                    hybrid_model.central_forecast >= family_low &&
                    hybrid_model.central_forecast <= family_high);
   if(!HybridBlendOk)
      DSA_RecordFailure("Hybrid mode did not blend statistical, ridge, and sequence families");
   ++HarnessChecks;

   DSAInputContract safe_contract = contract;
   safe_contract.model_mode = DSA_MODEL_SAFE_MODE;
   DSAModelSnapshot safe_model;
   DSA_ComputeModels(0,ArraySize(time),safe_contract,feature,open_values,high_values,low_values,close_values,
                     target_buffer,trend_buffer,signal_buffer,forecast_buffer,
                     forecast_h2_buffer,forecast_h4_buffer,forecast_h8_buffer,
                     volatility_buffer,quality_buffer,upper_buffer,lower_buffer,absolute_error_buffer,regime_buffer,
                     ridge_state_buffer,1.0,1.0,0.05,false,safe_model);

   SafeModeSuppressesSequenceOk = (MathAbs(safe_model.central_forecast - safe_model.sequence_forecast) >
                                   MathMax(_Point * 0.5,1.0e-8) &&
                                   safe_model.safe_mode);
   if(!SafeModeSuppressesSequenceOk)
      DSA_RecordFailure("SafeMode did not suppress sequence participation");
   ++HarnessChecks;

   HarnessDone = true;
   Print("DSA sequence-expert harness completed. failures=",HarnessFailures,
         " checks=",HarnessChecks,
         " sequence_forecast=",SequenceForecastOk,
         " deep_mode=",DeepModeOk,
         " hybrid_blend=",HybridBlendOk,
         " safe_suppresses_sequence=",SafeModeSuppressesSequenceOk,
         " confidence=",sequence_confidence,
         " maturity=",sequence_maturity);
}

int OnInit()
{
   DSA_RunSequenceExpertHarness();
   return (HarnessFailures == 0 ? INIT_SUCCEEDED : INIT_FAILED);
}

void OnTick()
{
}

double OnTester()
{
   return (HarnessDone &&
           HarnessFailures == 0 &&
           HarnessChecks >= 4 &&
           SequenceForecastOk &&
           DeepModeOk &&
           HybridBlendOk &&
           SafeModeSuppressesSequenceOk ? 1.0 : 0.0);
}
