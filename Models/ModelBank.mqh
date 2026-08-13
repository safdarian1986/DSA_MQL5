#ifndef DSA_MODEL_BANK_MQH
#define DSA_MODEL_BANK_MQH

#include "..\\Features\\FeatureEngine.mqh"

struct DSAModelSnapshot
{
   double naive;
   double drift;
   double holt_level;
   double holt_trend;
   double holt_forecast;
   double kalman_level;
   double kalman_slope;
   double kalman_forecast;
   double ridge_forecast;
   double central_forecast;
   double ensemble_state;
   double disagreement;
   double interval_radius;
   double band_radius;
   double horizon_growth;
   double model_score;
   double drift_score;
   int regime;
   bool safe_mode;
};

int DSA_ClassifyRegime(DSAFeatureSnapshot &feature,const double disagreement,const double drift_score)
{
   if(feature.quality_score < 45.0 || MathAbs(feature.robust_z) > 4.0 || drift_score > 0.85)
      return DSA_REGIME_SHOCK;
   if(feature.multi_channel &&
      feature.selected_spread > MathMax(feature.volatility * 2.5,feature.candle_range * 0.75) &&
      disagreement > 0.55)
      return DSA_REGIME_VOLATILE;
   if(feature.volatility > MathMax(MathAbs(feature.target) * 0.015,10.0 * _Point) && MathAbs(feature.robust_z) > 2.0)
      return DSA_REGIME_VOLATILE;
   if(feature.slope > feature.volatility * 0.12 && feature.persistence > 0.20)
      return DSA_REGIME_TREND_UP;
   if(feature.slope < -feature.volatility * 0.12 && feature.persistence > 0.20)
      return DSA_REGIME_TREND_DOWN;
   if(feature.quality_score < 60.0 || disagreement > 0.70)
      return DSA_REGIME_UNCERTAIN;
   return DSA_REGIME_RANGE;
}

bool DSA_SolveLinearSystem5(double &ridge_work[],double &solution[])
{
   const int dim = 5;

   for(int pivot = 0; pivot < dim; ++pivot)
   {
      int best = pivot;
      double best_abs = MathAbs(ridge_work[pivot * 6 + pivot]);
      for(int row = pivot + 1; row < dim; ++row)
      {
         const double value_abs = MathAbs(ridge_work[row * 6 + pivot]);
         if(value_abs > best_abs)
         {
            best = row;
            best_abs = value_abs;
         }
      }

      if(best_abs <= DBL_EPSILON)
         return false;

      if(best != pivot)
      {
         for(int col = pivot; col <= dim; ++col)
         {
            const double temp = ridge_work[pivot * 6 + col];
            ridge_work[pivot * 6 + col] = ridge_work[best * 6 + col];
            ridge_work[best * 6 + col] = temp;
         }
      }

      const double divisor = ridge_work[pivot * 6 + pivot];
      for(int col = pivot; col <= dim; ++col)
         ridge_work[pivot * 6 + col] /= divisor;

      for(int row = 0; row < dim; ++row)
      {
         if(row == pivot)
            continue;
         const double factor = ridge_work[row * 6 + pivot];
         if(MathAbs(factor) <= DBL_EPSILON)
            continue;
         for(int col = pivot; col <= dim; ++col)
            ridge_work[row * 6 + col] -= factor * ridge_work[pivot * 6 + col];
      }
   }

   for(int row = 0; row < dim; ++row)
      solution[row] = ridge_work[row * 6 + dim];

   return true;
}

double DSA_RidgeForecast(const int index,
                         const int rates_total,
                         DSAFeatureSnapshot &feature,
                         DSAInputContract &contract,
                         const double &open[],
                         const double &high[],
                         const double &low[],
                         const double &close[],
                         const double &target_buffer[],
                         const double ridge_lambda_scale)
{
   if(index + 3 >= rates_total)
      return feature.target + feature.slope;

   const int available = rates_total - index - 4;
   if(available < 12)
      return feature.target + feature.slope;

   const int max_samples = 256;
   const int stride = MathMax(1,(int)MathCeil((double)available / (double)max_samples));
   double ridge_work[30];
   double beta[5];

   for(int r = 0; r < 5; ++r)
   {
      beta[r] = 0.0;
      for(int c = 0; c < 6; ++c)
         ridge_work[r * 6 + c] = 0.0;
   }

   int count = 0;
   for(int origin = index + 1; origin + 3 < rates_total; origin += stride)
   {
      const int outcome = origin - 1;
      if(outcome < index)
         continue;
      if(!DSA_HasValue(target_buffer[outcome]) ||
         !DSA_HasValue(target_buffer[origin]) ||
         !DSA_HasValue(target_buffer[origin + 1]) ||
         !DSA_HasValue(target_buffer[origin + 2]) ||
         !DSA_HasValue(target_buffer[origin + 3]))
         continue;

      const double y1 = target_buffer[origin];
      const double y2 = target_buffer[origin + 1];
      const double y3 = target_buffer[origin + 2];
      const double y4 = target_buffer[origin + 3];
      double x[5];
      DSASelectionChannels origin_channels;
      DSA_BuildSelectionChannels(origin,contract.selection_data,open,high,low,close,origin_channels);
      const double origin_channel_signal = (origin_channels.channel_count > 1 ? origin_channels.direction : 0.0);
      x[0] = 1.0;
      x[1] = y1;
      x[2] = y2;
      x[3] = y3;
      x[4] = y1 - y4 + 0.25 * origin_channel_signal;

      const double age = (double)(origin - index);
      const double adaptive_decay = 0.002 + 0.012 * (1.0 - DSA_Clamp(feature.quality_score / 100.0,0.0,1.0));
      const double weight = MathExp(-adaptive_decay * age);
      const double y = target_buffer[outcome];

      for(int r = 0; r < 5; ++r)
      {
         for(int c = 0; c < 5; ++c)
            ridge_work[r * 6 + c] += weight * x[r] * x[c];
         ridge_work[r * 6 + 5] += weight * x[r] * y;
      }
      ++count;
   }

   if(count < 12)
      return feature.target + feature.slope;

   const double lambda = (0.001 + 0.15 * (1.0 - DSA_Clamp(feature.quality_score / 100.0,0.0,1.0))) *
                         DSA_Clamp(ridge_lambda_scale,0.25,4.0);
   for(int d = 1; d < 5; ++d)
      ridge_work[d * 6 + d] += lambda * (double)count;

   if(!DSA_SolveLinearSystem5(ridge_work,beta))
      return feature.target + feature.slope;

   const double p1 = (DSA_HasValue(target_buffer[index + 1]) ? target_buffer[index + 1] : feature.target);
   const double p2 = (DSA_HasValue(target_buffer[index + 2]) ? target_buffer[index + 2] : p1);
   const double p3 = (DSA_HasValue(target_buffer[index + 3]) ? target_buffer[index + 3] : p2);
   const double p4 = (index + 4 < rates_total && DSA_HasValue(target_buffer[index + 4]) ? target_buffer[index + 4] : p3);
   double x_now[5];
   x_now[0] = 1.0;
   x_now[1] = feature.target;
   x_now[2] = p1;
   x_now[3] = p2;
   const double current_channel_signal = (feature.multi_channel ? feature.selected_direction : 0.0);
   x_now[4] = feature.target - p3 + 0.25 * (p1 - p4) + 0.25 * current_channel_signal;

   double forecast = 0.0;
   for(int i = 0; i < 5; ++i)
      forecast += beta[i] * x_now[i];

   const double guard = MathMax(feature.volatility * 6.0,10.0 * _Point);
   return DSA_Clamp(forecast,feature.target - guard,feature.target + guard);
}

double DSA_ProjectForecastPath(const double one_step_forecast,const double slope,const int horizon)
{
   const int h = MathMax(horizon,1);
   const double decay = MathExp(-0.04 * (double)h);
   return one_step_forecast + slope * (double)(h - 1) * decay;
}

double DSA_HorizonResidualRatio(const int index,
                                const int rates_total,
                                const int horizon,
                                const double base_radius,
                                const double &target_buffer[],
                                const double &horizon_forecast_buffer[])
{
   if(horizon < 2 || index + horizon + 2 >= rates_total)
      return EMPTY_VALUE;

   const int available = rates_total - index - horizon - 2;
   if(available < 12)
      return EMPTY_VALUE;

   const int max_samples = 128;
   const int stride = MathMax(1,(int)MathCeil((double)available / (double)max_samples));
   const double radius = MathMax(base_radius * MathSqrt((double)horizon),_Point);
   double ratio_sum = 0.0;
   int count = 0;

   for(int actual_index = index + 1; actual_index + horizon < rates_total; actual_index += stride)
   {
      const int origin_index = actual_index + horizon;
      if(!DSA_HasValue(target_buffer[actual_index]) ||
         !DSA_HasValue(horizon_forecast_buffer[origin_index]))
         continue;

      ratio_sum += DSA_Clamp(MathAbs(target_buffer[actual_index] - horizon_forecast_buffer[origin_index]) / radius,0.0,4.0);
      ++count;
   }

   if(count < 8)
      return EMPTY_VALUE;
   return ratio_sum / (double)count;
}

double DSA_MultiHorizonGrowth(const int index,
                              const int rates_total,
                              const double base_radius,
                              const double &target_buffer[],
                              const double &forecast_h2_buffer[],
                              const double &forecast_h4_buffer[],
                              const double &forecast_h8_buffer[])
{
   double weighted_ratio_sum = 0.0;
   double weight_sum = 0.0;

   const double ratio_h2 = DSA_HorizonResidualRatio(index,rates_total,2,base_radius,target_buffer,forecast_h2_buffer);
   if(DSA_HasValue(ratio_h2))
   {
      weighted_ratio_sum += 0.45 * ratio_h2;
      weight_sum += 0.45;
   }

   const double ratio_h4 = DSA_HorizonResidualRatio(index,rates_total,4,base_radius,target_buffer,forecast_h4_buffer);
   if(DSA_HasValue(ratio_h4))
   {
      weighted_ratio_sum += 0.35 * ratio_h4;
      weight_sum += 0.35;
   }

   const double ratio_h8 = DSA_HorizonResidualRatio(index,rates_total,8,base_radius,target_buffer,forecast_h8_buffer);
   if(DSA_HasValue(ratio_h8))
   {
      weighted_ratio_sum += 0.20 * ratio_h8;
      weight_sum += 0.20;
   }

   if(weight_sum <= DBL_EPSILON)
      return 1.0;

   const double observed_ratio = weighted_ratio_sum / weight_sum;
   return DSA_Clamp(MathMax(1.0,observed_ratio),1.0,2.50);
}

double DSA_ConformalRadius(const int index,
                           const int rates_total,
                           const int regime,
                           DSAFeatureSnapshot &feature,
                           const double &absolute_error_buffer[],
                           const double &regime_buffer[],
                           const double fallback_radius)
{
   const int available = rates_total - index - 2;
   if(available < 8)
      return fallback_radius;

   const int max_samples = 256;
   const int stride = MathMax(1,(int)MathCeil((double)available / (double)max_samples));
   double q_regime = fallback_radius;
   double q_all = fallback_radius;
   int n_regime = 0;
   int n_all = 0;

   for(int j = rates_total - 2; j >= index + 1; j -= stride)
   {
      if(!DSA_HasValue(absolute_error_buffer[j]))
         continue;

      const double residual = MathMax(absolute_error_buffer[j],_Point);
      const double all_alpha = 2.0 / (double)MathMin(n_all + 20,260);
      if(residual > q_all)
         q_all += all_alpha * (residual - q_all);
      else
         q_all -= all_alpha * 0.10 * (q_all - residual);
      ++n_all;

      if(DSA_HasValue(regime_buffer[j]) && (int)regime_buffer[j] == regime)
      {
         const double regime_alpha = 2.0 / (double)MathMin(n_regime + 20,220);
         if(residual > q_regime)
            q_regime += regime_alpha * (residual - q_regime);
         else
            q_regime -= regime_alpha * 0.08 * (q_regime - residual);
         ++n_regime;
      }
   }

   if(n_all < 8)
      return fallback_radius;

   double radius = (n_regime >= 8 ? MathMax(q_regime,q_all * 0.70) : q_all);
   if(feature.mtf_available)
      radius *= 1.0 + 0.05 * DSA_Clamp(MathAbs(feature.mtf_deviation),0.0,4.0);

   return MathMax(radius,MathMax(feature.volatility * 0.65,_Point));
}

void DSA_ComputeModels(const int index,
                       const int rates_total,
                       DSAInputContract &contract,
                       DSAFeatureSnapshot &feature,
                       const double &open[],
                       const double &high[],
                       const double &low[],
                       const double &close[],
                       const double &target_buffer[],
                       const double &trend_buffer[],
                       const double &signal_buffer[],
                       const double &forecast_buffer[],
                       const double &forecast_h2_buffer[],
                       const double &forecast_h4_buffer[],
                       const double &forecast_h8_buffer[],
                       const double &volatility_buffer[],
                       const double &uncertainty_upper_buffer[],
                       const double &uncertainty_lower_buffer[],
                        const double &absolute_error_buffer[],
                        const double &regime_buffer[],
                        const double &ridge_state_buffer[],
                        const double ridge_lambda_scale,
                        const double interval_scale,
                        const bool fast_path,
                        DSAModelSnapshot &model)
{
   double previous_target = feature.target;
   if(index + 1 < rates_total && DSA_HasValue(target_buffer[index + 1]))
      previous_target = target_buffer[index + 1];

   double previous_slope = feature.slope;
   if(index + 1 < rates_total && DSA_HasValue(trend_buffer[index + 1]) &&
      index + 2 < rates_total && DSA_HasValue(trend_buffer[index + 2]))
      previous_slope = trend_buffer[index + 1] - trend_buffer[index + 2];

   model.naive = previous_target;
   model.drift = previous_target + previous_slope;

   const double previous_holt_level = (index + 1 < rates_total && DSA_HasValue(signal_buffer[index + 1]) ? signal_buffer[index + 1] : previous_target);
   const double previous_holt_trend = previous_slope;
   const double alpha = DSA_Clamp(0.10 + 0.30 * DSA_SafeDiv(feature.quality_score,100.0,0.5),0.08,0.45);
   const double beta = DSA_Clamp(0.04 + 0.18 * feature.persistence,0.03,0.25);
   model.holt_level = alpha * feature.target + (1.0 - alpha) * (previous_holt_level + previous_holt_trend);
   model.holt_trend = beta * (model.holt_level - previous_holt_level) + (1.0 - beta) * previous_holt_trend;
   model.holt_forecast = model.holt_level + model.holt_trend;

   const double previous_kalman_level = (index + 1 < rates_total && DSA_HasValue(trend_buffer[index + 1]) ? trend_buffer[index + 1] : previous_target);
   const double kalman_prediction = previous_kalman_level + previous_slope;
   const double innovation = feature.target - kalman_prediction;
   const double quality_gain = DSA_Clamp(feature.quality_score / 100.0,0.20,1.0);
   const double kalman_gain = DSA_Clamp(0.12 + 0.28 * quality_gain,0.12,0.40);
   model.kalman_level = kalman_prediction + kalman_gain * innovation;
   model.kalman_slope = previous_slope + kalman_gain * 0.35 * innovation;
   model.kalman_forecast = model.kalman_level + model.kalman_slope;

   if(fast_path && index + 1 < rates_total && DSA_HasValue(ridge_state_buffer[index + 1]))
      model.ridge_forecast = ridge_state_buffer[index + 1];
   else
      model.ridge_forecast = DSA_RidgeForecast(index,rates_total,feature,contract,open,high,low,close,target_buffer,ridge_lambda_scale);

   double w_naive = 0.15;
   double w_holt = 0.25;
   double w_kalman = 0.35;
   double w_ridge = 0.25;

   if(feature.maturity < 12)
   {
      w_naive = 0.65;
      w_holt = 0.20;
      w_kalman = 0.15;
      w_ridge = 0.00;
   }
   else if(feature.maturity < 40)
   {
      w_naive = 0.25;
      w_holt = 0.35;
      w_kalman = 0.35;
      w_ridge = 0.05;
   }

   if(contract.model_mode == DSA_MODEL_STATISTICAL)
   {
      w_naive = 0.20;
      w_holt = 0.35;
      w_kalman = 0.45;
      w_ridge = 0.00;
   }
   else if(contract.model_mode == DSA_MODEL_MACHINE_LEARNING)
   {
      w_naive = 0.10;
      w_holt = 0.10;
      w_kalman = 0.20;
      w_ridge = 0.60;
   }
   else if(contract.model_mode == DSA_MODEL_HYBRID)
   {
      w_naive = 0.12;
      w_holt = 0.28;
      w_kalman = 0.35;
      w_ridge = 0.25;
   }
   else if(contract.model_mode == DSA_MODEL_DEEP_LEARNING)
   {
      w_naive = 0.45;
      w_holt = 0.10;
      w_kalman = 0.45;
      w_ridge = 0.00;
   }
   else if(contract.model_mode == DSA_MODEL_SAFE_MODE)
   {
      w_naive = 0.45;
      w_holt = 0.10;
      w_kalman = 0.45;
      w_ridge = 0.00;
   }

   const double spread_1 = MathAbs(model.naive - model.holt_forecast);
   const double spread_2 = MathAbs(model.kalman_forecast - model.ridge_forecast);
   model.disagreement = DSA_Clamp((spread_1 + spread_2) / MathMax(4.0 * feature.volatility,_Point),0.0,1.0);

   double previous_forecast = EMPTY_VALUE;
   if(index + 1 < rates_total && DSA_HasValue(forecast_buffer[index + 1]))
      previous_forecast = forecast_buffer[index + 1];
   const double current_oos_error = (DSA_HasValue(previous_forecast) ? MathAbs(feature.target - previous_forecast) : feature.volatility);

   double previous_radius = feature.volatility;
   if(index + 1 < rates_total &&
      DSA_HasValue(uncertainty_upper_buffer[index + 1]) &&
      DSA_HasValue(uncertainty_lower_buffer[index + 1]))
      previous_radius = MathAbs(uncertainty_upper_buffer[index + 1] - uncertainty_lower_buffer[index + 1]) * 0.5;

   model.interval_radius = DSA_Ewma(previous_radius,MathMax(current_oos_error,feature.volatility),0.08);
   model.interval_radius = MathMax(model.interval_radius,feature.volatility * 0.65);

   model.drift_score = DSA_Clamp(current_oos_error / MathMax(model.interval_radius * 2.5,_Point),0.0,1.0);
   model.regime = DSA_ClassifyRegime(feature,model.disagreement,model.drift_score);
   model.interval_radius = MathMax(model.interval_radius,
                                   DSA_ConformalRadius(index,rates_total,model.regime,feature,
                                                       absolute_error_buffer,regime_buffer,model.interval_radius));
   model.interval_radius *= DSA_Clamp(interval_scale,0.75,1.75);
   model.horizon_growth = DSA_MultiHorizonGrowth(index,rates_total,model.interval_radius,
                                                 target_buffer,
                                                 forecast_h2_buffer,forecast_h4_buffer,forecast_h8_buffer);
   model.drift_score = DSA_Clamp(current_oos_error / MathMax(model.interval_radius * 2.5,_Point),0.0,1.0);
   model.safe_mode = (contract.model_mode == DSA_MODEL_SAFE_MODE ||
                      feature.quality_score < 50.0 ||
                      model.disagreement > 0.82 ||
                      model.drift_score > 0.88 ||
                      model.regime == DSA_REGIME_SHOCK);

   if(model.safe_mode)
   {
      w_naive = 0.45;
      w_holt = 0.05;
      w_kalman = 0.50;
      w_ridge = 0.00;
      model.interval_radius *= 1.35;
   }

   const double weight_sum = MathMax(w_naive + w_holt + w_kalman + w_ridge,DBL_EPSILON);
   model.central_forecast = (w_naive * model.naive +
                             w_holt * model.holt_forecast +
                             w_kalman * model.kalman_forecast +
                             w_ridge * model.ridge_forecast) / weight_sum;

   model.ensemble_state = model.kalman_level;
   model.band_radius = MathMax(feature.volatility,model.interval_radius * 0.70);
   model.model_score = DSA_Clamp(100.0 -
                                 35.0 * model.drift_score -
                                 20.0 * model.disagreement -
                                 25.0 * (1.0 - feature.quality_score / 100.0),
                                 0.0,100.0);
}

#endif
