#ifndef DSA_MODEL_BANK_MQH
#define DSA_MODEL_BANK_MQH

#include "..\\Features\\FeatureEngine.mqh"

struct DSAExpertEvidence
{
   double oos_error;
   double stability;
   double maturity;
   double coverage;
   double shock_resistance;
   double latency_score;
   double score;
   double weight;
   bool approved;
};

struct DSAModelSnapshot
{
   double naive;
   double drift;
   double holt_level;
   double holt_trend;
   double holt_forecast;
   double kalman_level;
   double kalman_slope;
   double kalman_trend_strength;
   double kalman_innovation;
   double kalman_residual;
   double kalman_state_uncertainty;
   double kalman_forecast;
   double ridge_forecast;
   int ridge_adaptive_lag;
   double ridge_feature_weight;
   double ridge_time_weight;
   double ridge_horizon_weight;
   double ridge_adaptive_score;
   double sequence_forecast;
   double sequence_confidence;
   double sequence_maturity;
   double central_forecast;
   double ensemble_state;
   double disagreement;
   double interval_radius;
   double band_radius;
   double horizon_growth;
   double model_score;
   double drift_score;
   double runtime_cost_score;
   double volatility_stress;
   int regime;
   bool safe_mode;
   double expert_weight_naive;
   double expert_weight_holt;
   double expert_weight_kalman;
   double expert_weight_ridge;
   double expert_weight_sequence;
   DSAExpertEvidence naive_evidence;
   DSAExpertEvidence holt_evidence;
   DSAExpertEvidence kalman_evidence;
   DSAExpertEvidence ridge_evidence;
   DSAExpertEvidence sequence_evidence;
};

double DSA_SequenceScaleReturn(const int index,
                               const int scale,
                               DSAFeatureSnapshot &feature,
                               const double &target_buffer[])
{
   if(scale <= 0)
      return 0.0;
   if(index == 0)
   {
      if(ArraySize(target_buffer) > scale && DSA_HasValue(target_buffer[scale]))
         return feature.target - target_buffer[scale];
      return 0.0;
   }

   double anchor = feature.target;
   if(index < ArraySize(target_buffer) && DSA_HasValue(target_buffer[index]))
      anchor = target_buffer[index];
   if(index + scale < ArraySize(target_buffer) &&
      DSA_HasValue(target_buffer[index + scale]))
      return anchor - target_buffer[index + scale];
   return 0.0;
}

double DSA_SequenceOriginReturn(const int origin,
                                const int scale,
                                const double &target_buffer[])
{
   if(scale <= 0)
      return 0.0;
   if(origin + scale < ArraySize(target_buffer) &&
      DSA_HasValue(target_buffer[origin]) &&
      DSA_HasValue(target_buffer[origin + scale]))
      return target_buffer[origin] - target_buffer[origin + scale];
   return 0.0;
}

double DSA_SequenceExpertForecast(const int index,
                                  const int rates_total,
                                  DSAFeatureSnapshot &feature,
                                  const double &target_buffer[],
                                  const double &volatility_buffer[],
                                  const double &quality_buffer[],
                                  const bool fast_path,
                                  double &confidence,
                                  double &maturity)
{
   confidence = 0.0;
   maturity = 0.0;

   if(index + 18 >= rates_total)
      return feature.target + feature.slope;

   const int scales[5] = {1,2,4,8,16};
   double current_signature[5];
   for(int i = 0; i < 5; ++i)
      current_signature[i] = DSA_SequenceScaleReturn(index,scales[i],feature,target_buffer);

   const int available = rates_total - index - 18;
   const int max_samples = (fast_path ? 80 : 240);
   const int stride = MathMax(1,(int)MathCeil((double)available / (double)max_samples));
   double weighted_delta_sum = 0.0;
   double weight_sum = 0.0;
   double best_similarity = 0.0;
   int matches = 0;

   for(int origin = index + 2; origin + 17 < rates_total; origin += stride)
   {
      if(!DSA_HasValue(target_buffer[origin - 1]) || !DSA_HasValue(target_buffer[origin]))
         continue;

      double distance = 0.0;
      double scale_weight_sum = 0.0;
      for(int i = 0; i < 5; ++i)
      {
         const double origin_return = DSA_SequenceOriginReturn(origin,scales[i],target_buffer);
         const double scale_weight = 1.0 / (double)scales[i];
         distance += scale_weight * MathAbs(current_signature[i] - origin_return);
         scale_weight_sum += scale_weight;
      }

      const double local_volatility = (DSA_HasValue(volatility_buffer[origin]) ? volatility_buffer[origin] : feature.volatility);
      const double normalized_distance = DSA_SafeDiv(distance,MathMax(scale_weight_sum * MathMax(local_volatility,feature.volatility),_Point),4.0);
      const double similarity = MathExp(-DSA_Clamp(normalized_distance,0.0,8.0));
      if(similarity < 0.025)
         continue;

      const double quality = (DSA_HasValue(quality_buffer[origin]) ? DSA_Clamp(quality_buffer[origin] / 100.0,0.20,1.0) : 0.65);
      const double age_decay = MathExp(-0.0015 * (double)(origin - index));
      const double weight = similarity * quality * age_decay;
      const double next_delta = target_buffer[origin - 1] - target_buffer[origin];
      weighted_delta_sum += weight * next_delta;
      weight_sum += weight;
      best_similarity = MathMax(best_similarity,similarity);
      ++matches;
   }

   const double scale_volatility = MathMax(feature.volatility,_Point);
   double momentum_delta = 0.0;
   double momentum_weight_sum = 0.0;
   for(int i = 0; i < 5; ++i)
   {
      const double scale_weight = 1.0 / MathSqrt((double)scales[i]);
      momentum_delta += scale_weight * DSA_Clamp(current_signature[i] / (double)scales[i],
                                                -2.0 * scale_volatility,
                                                2.0 * scale_volatility);
      momentum_weight_sum += scale_weight;
   }
   if(momentum_weight_sum > DBL_EPSILON)
      momentum_delta /= momentum_weight_sum;

   maturity = DSA_Clamp((double)matches / 48.0,0.0,1.0);
   confidence = DSA_Clamp(0.55 * maturity +
                          0.30 * best_similarity +
                          0.15 * DSA_Clamp(feature.quality_score / 100.0,0.0,1.0),
                          0.0,1.0);

   const double matched_delta = (weight_sum > DBL_EPSILON ? weighted_delta_sum / weight_sum : feature.slope);
   const double blended_delta = confidence * matched_delta + (1.0 - confidence) * (0.60 * feature.slope + 0.40 * momentum_delta);
   const double guard = MathMax(scale_volatility * (2.5 + 2.0 * confidence),8.0 * _Point);
   return DSA_Clamp(feature.target + blended_delta,feature.target - guard,feature.target + guard);
}

void DSA_ResetExpertEvidence(DSAExpertEvidence &evidence)
{
   evidence.oos_error = 0.0;
   evidence.stability = 0.0;
   evidence.maturity = 0.0;
   evidence.coverage = 0.0;
   evidence.shock_resistance = 0.0;
   evidence.latency_score = 0.0;
   evidence.score = 0.0;
   evidence.weight = 0.0;
   evidence.approved = false;
}

void DSA_BuildExpertEvidence(const double forecast,
                             DSAFeatureSnapshot &feature,
                             const double interval_radius,
                             const double runtime_load,
                             const double maturity_hint,
                             const double latency_cost,
                             const bool advanced_expert,
                             DSAExpertEvidence &evidence)
{
   evidence.oos_error = MathAbs(feature.target - forecast);
   const double radius = MathMax(interval_radius,MathMax(feature.volatility,_Point));
   evidence.stability = DSA_Clamp(1.0 - evidence.oos_error / MathMax(radius * 2.5,_Point),0.0,1.0);
   evidence.maturity = DSA_Clamp(maturity_hint,0.0,1.0);
   evidence.coverage = (evidence.oos_error <= radius ? 1.0 : DSA_Clamp(radius / MathMax(evidence.oos_error,_Point),0.0,1.0));
   evidence.shock_resistance = DSA_Clamp(1.0 -
                                         0.45 * feature.volume_shock -
                                         0.35 * DSA_Clamp(feature.vol_of_vol / 2.0,0.0,1.0) -
                                         0.20 * DSA_Clamp(MathAbs(feature.robust_z) / 5.0,0.0,1.0),
                                         0.0,1.0);
   evidence.latency_score = DSA_Clamp(1.0 - latency_cost * DSA_Clamp(runtime_load,0.0,1.5) / 1.5,0.0,1.0);
   evidence.score = DSA_Clamp(0.28 * evidence.stability +
                              0.20 * evidence.maturity +
                              0.18 * evidence.coverage +
                              0.16 * evidence.shock_resistance +
                              0.12 * evidence.latency_score +
                              0.06 * feature.feature_reliability,
                              0.0,1.0);
   evidence.approved = (!advanced_expert ||
                        (evidence.maturity >= 0.25 &&
                         evidence.coverage >= 0.20 &&
                         evidence.stability >= 0.18 &&
                         evidence.shock_resistance >= 0.18 &&
                         evidence.latency_score >= 0.20 &&
                         evidence.score >= 0.30));
}

double DSA_EvidenceAdjustedWeight(const double prior,
                                  DSAExpertEvidence &evidence,
                                  const double unapproved_limit)
{
   double weight = MathMax(prior,0.0) * DSA_Clamp(0.20 + evidence.score,0.0,1.20);
   if(!evidence.approved)
      weight = MathMin(weight,MathMax(unapproved_limit,0.0));
   evidence.weight = weight;
   return weight;
}

int DSA_ClassifyRegime(DSAFeatureSnapshot &feature,const double disagreement,const double drift_score)
{
   if(feature.quality_score < 45.0 ||
      MathAbs(feature.robust_z) > 4.0 ||
      drift_score > 0.85 ||
      (feature.volume_shock > 0.80 && MathAbs(feature.robust_z) > 2.0))
      return DSA_REGIME_SHOCK;
   if(feature.vol_of_vol > 0.75 && disagreement > 0.35)
      return DSA_REGIME_VOLATILE;
   if(feature.multi_channel &&
      feature.selected_spread > MathMax(feature.volatility * 2.5,feature.candle_range * 0.75) &&
      disagreement > 0.55)
      return DSA_REGIME_VOLATILE;
   if(feature.volatility > MathMax(MathAbs(feature.target) * 0.015,10.0 * _Point) && MathAbs(feature.robust_z) > 2.0)
      return DSA_REGIME_VOLATILE;
   if(feature.cusum_pressure > 0.45 && feature.persistence > 0.15)
      return DSA_REGIME_TREND_UP;
   if(feature.cusum_pressure < -0.45 && feature.persistence > 0.15)
      return DSA_REGIME_TREND_DOWN;
   if(feature.slope > feature.volatility * 0.12 && feature.persistence > 0.20)
      return DSA_REGIME_TREND_UP;
   if(feature.slope < -feature.volatility * 0.12 && feature.persistence > 0.20)
      return DSA_REGIME_TREND_DOWN;
   if(feature.congestion_score > 0.65 && MathAbs(feature.cusum_pressure) < 0.35)
      return DSA_REGIME_RANGE;
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
                         const double ridge_lambda_scale,
                         int &adaptive_lag,
                         double &feature_weight,
                         double &time_weight,
                         double &horizon_weight,
                         double &adaptive_score)
{
   adaptive_lag = MathMax(2,MathMin(feature.adaptive_lag,8));
   feature_weight = DSA_Clamp(0.55 * feature.feature_reliability +
                              0.25 * feature.range_efficiency +
                              0.20 * MathAbs(feature.causal_correlation),
                              0.0,1.0);
   time_weight = DSA_Clamp(0.65 + 0.35 * DSA_Clamp(feature.quality_score / 100.0,0.0,1.0) -
                           0.20 * DSA_Clamp(feature.vol_of_vol / 2.0,0.0,1.0),
                           0.20,1.0);
   horizon_weight = DSA_Clamp(1.0 -
                              0.25 * DSA_Clamp(feature.vol_of_vol / 2.0,0.0,1.0) -
                              0.20 * feature.volume_shock +
                              0.15 * feature.cycle_stability,
                              0.30,1.0);
   adaptive_score = DSA_Clamp(0.30 * feature_weight +
                              0.25 * time_weight +
                              0.20 * horizon_weight +
                              0.15 * feature.cycle_stability +
                              0.10 * feature.persistence,
                              0.0,1.0);

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
      double origin_channel_signal = 0.0;
      if(!DSA_UseAnalysisRate(contract))
      {
         DSASelectionChannels origin_channels;
         DSA_BuildSelectionChannels(origin,contract.selection_data,open,high,low,close,origin_channels);
         origin_channel_signal = (origin_channels.channel_count > 1 ? origin_channels.direction : 0.0);
      }
      x[0] = 1.0;
      x[1] = y1;
      x[2] = y2;
      x[3] = y3;
      x[4] = y1 - y4 + 0.25 * origin_channel_signal;

      const double age = (double)(origin - index);
      const double adaptive_decay = 0.002 + 0.012 * (1.0 - time_weight);
      const double feature_fit = DSA_Clamp(0.55 * feature_weight +
                                           0.25 * feature.cycle_stability +
                                           0.20 * DSA_Clamp(1.0 - MathAbs(feature.robust_z) / 6.0,0.0,1.0),
                                           0.05,1.0);
      const double weight = MathExp(-adaptive_decay * age) * feature_fit;
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
   const int lag_index = MathMin(index + adaptive_lag,rates_total - 1);
   const double p_adaptive = (DSA_HasValue(target_buffer[lag_index]) ? target_buffer[lag_index] : p3);
   double x_now[5];
   x_now[0] = 1.0;
   x_now[1] = feature.target;
   x_now[2] = p1;
   x_now[3] = p2;
   const double current_channel_signal = (feature.multi_channel ? feature.selected_direction : 0.0);
   x_now[4] = feature_weight * (feature.target - p_adaptive) +
              horizon_weight * 0.25 * (p1 - p4) +
              0.25 * current_channel_signal;

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
                       const double &quality_buffer[],
                       const double &uncertainty_upper_buffer[],
                       const double &uncertainty_lower_buffer[],
                        const double &absolute_error_buffer[],
                        const double &regime_buffer[],
                        const double &ridge_state_buffer[],
                        const double ridge_lambda_scale,
                        const double interval_scale,
                        const double runtime_load,
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
   model.kalman_innovation = innovation;
   model.kalman_residual = feature.target - model.kalman_level;
   model.kalman_state_uncertainty = MathMax(feature.volatility,
                                            MathAbs(model.kalman_residual) +
                                            (1.0 - kalman_gain) * MathMax(feature.mad_volatility,_Point));
   model.kalman_trend_strength = DSA_Clamp(MathAbs(model.kalman_slope) /
                                           MathMax(model.kalman_state_uncertainty,_Point),
                                           0.0,3.0) / 3.0;

   if(fast_path && index + 1 < rates_total && DSA_HasValue(ridge_state_buffer[index + 1]))
   {
      model.ridge_forecast = ridge_state_buffer[index + 1];
      model.ridge_adaptive_lag = MathMax(2,MathMin(feature.adaptive_lag,8));
      model.ridge_feature_weight = feature.feature_reliability;
      model.ridge_time_weight = DSA_Clamp(feature.quality_score / 100.0,0.20,1.0);
      model.ridge_horizon_weight = DSA_Clamp(1.0 - 0.25 * feature.vol_of_vol,0.30,1.0);
      model.ridge_adaptive_score = DSA_Clamp(0.45 * model.ridge_feature_weight +
                                             0.30 * model.ridge_time_weight +
                                             0.25 * model.ridge_horizon_weight,
                                             0.0,1.0);
   }
   else
      model.ridge_forecast = DSA_RidgeForecast(index,rates_total,feature,contract,open,high,low,close,target_buffer,ridge_lambda_scale,
                                               model.ridge_adaptive_lag,
                                               model.ridge_feature_weight,
                                               model.ridge_time_weight,
                                               model.ridge_horizon_weight,
                                               model.ridge_adaptive_score);

   const bool sequence_mode = (contract.model_mode == DSA_MODEL_DEEP_LEARNING ||
                               contract.model_mode == DSA_MODEL_HYBRID);
   if(sequence_mode)
      model.sequence_forecast = DSA_SequenceExpertForecast(index,rates_total,feature,
                                                           target_buffer,volatility_buffer,quality_buffer,
                                                           fast_path,
                                                           model.sequence_confidence,
                                                           model.sequence_maturity);
   else
   {
      model.sequence_forecast = feature.target + feature.slope;
      model.sequence_confidence = 0.0;
      model.sequence_maturity = 0.0;
   }

   double w_naive = 0.15;
   double w_holt = 0.25;
   double w_kalman = 0.35;
   double w_ridge = 0.25;
   double w_sequence = 0.12 * model.sequence_confidence;

   if(feature.maturity < 12)
   {
      w_naive = 0.65;
      w_holt = 0.20;
      w_kalman = 0.15;
      w_ridge = 0.00;
      w_sequence = 0.00;
   }
   else if(feature.maturity < 40)
   {
      w_naive = 0.25;
      w_holt = 0.35;
      w_kalman = 0.35;
      w_ridge = 0.05;
      w_sequence = 0.05 * model.sequence_confidence;
   }

   if(contract.model_mode == DSA_MODEL_STATISTICAL)
   {
      w_naive = 0.20;
      w_holt = 0.35;
      w_kalman = 0.45;
      w_ridge = 0.00;
      w_sequence = 0.00;
   }
   else if(contract.model_mode == DSA_MODEL_MACHINE_LEARNING)
   {
      w_naive = 0.10;
      w_holt = 0.10;
      w_kalman = 0.20;
      w_ridge = 0.60;
      w_sequence = 0.00;
   }
   else if(contract.model_mode == DSA_MODEL_HYBRID)
   {
      w_naive = 0.10;
      w_holt = 0.22;
      w_kalman = 0.28;
      w_ridge = 0.25;
      w_sequence = 0.15 + 0.20 * model.sequence_confidence;
   }
   else if(contract.model_mode == DSA_MODEL_DEEP_LEARNING)
   {
      w_naive = 0.10;
      w_holt = 0.05;
      w_kalman = 0.15;
      w_ridge = 0.00;
      w_sequence = 0.70 + 0.25 * model.sequence_confidence;
   }
   else if(contract.model_mode == DSA_MODEL_SAFE_MODE)
   {
      w_naive = 0.45;
      w_holt = 0.10;
      w_kalman = 0.45;
      w_ridge = 0.00;
      w_sequence = 0.00;
   }

   const double quality_confidence = DSA_Clamp(feature.quality_score / 100.0,0.0,1.0);
   const double maturity_confidence = DSA_Clamp((double)(feature.maturity - 40) / 160.0,0.0,1.0);
   const double trend_pressure = DSA_Clamp(MathAbs(feature.cusum_pressure),0.0,1.0);
   const double instability_pressure = DSA_Clamp(0.45 * feature.vol_of_vol +
                                                 0.35 * feature.volume_shock +
                                                 0.20 * (1.0 - quality_confidence),
                                                 0.0,1.0);

   if(trend_pressure > 0.35 && feature.persistence > 0.15)
   {
      w_holt += 0.05 * trend_pressure;
      w_kalman += 0.08 * trend_pressure;
      w_naive = MathMax(w_naive - 0.04 * trend_pressure,0.0);
   }

   if(instability_pressure > 0.35)
   {
      w_naive += 0.10 * instability_pressure;
      w_kalman += 0.08 * instability_pressure;
      w_holt = MathMax(w_holt - 0.03 * instability_pressure,0.0);
      w_ridge = MathMax(w_ridge - 0.15 * instability_pressure,0.0);
      w_sequence = MathMax(w_sequence - 0.12 * instability_pressure,0.0);
   }

   if(feature.congestion_score > 0.55)
   {
      w_naive += 0.08 * feature.congestion_score;
      w_holt += 0.04 * feature.congestion_score;
      w_kalman = MathMax(w_kalman - 0.04 * feature.congestion_score,0.0);
      w_ridge = MathMax(w_ridge - 0.04 * feature.congestion_score,0.0);
   }

   if(maturity_confidence > 0.0 && instability_pressure < 0.40 && contract.model_mode != DSA_MODEL_STATISTICAL)
   {
      const double ridge_boost = 0.08 * maturity_confidence * quality_confidence;
      w_ridge += ridge_boost;
      w_naive = MathMax(w_naive - 0.04 * ridge_boost,0.0);
      w_sequence += 0.06 * maturity_confidence * model.sequence_confidence;
   }

   const double spread_1 = MathAbs(model.naive - model.holt_forecast);
   const double spread_2 = MathAbs(model.kalman_forecast - model.ridge_forecast);
   const double spread_3 = MathAbs(model.sequence_forecast - 0.5 * (model.kalman_forecast + model.holt_forecast));
   model.disagreement = DSA_Clamp((spread_1 + spread_2 + spread_3 * model.sequence_confidence) /
                                  MathMax((4.0 + model.sequence_confidence) * feature.volatility,_Point),0.0,1.0);

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
   model.interval_radius *= 1.0 + 0.15 * feature.vol_of_vol + 0.10 * feature.volume_shock;
   model.horizon_growth = DSA_MultiHorizonGrowth(index,rates_total,model.interval_radius,
                                                 target_buffer,
                                                 forecast_h2_buffer,forecast_h4_buffer,forecast_h8_buffer);
   model.drift_score = DSA_Clamp(current_oos_error / MathMax(model.interval_radius * 2.5,_Point),0.0,1.0);
   model.safe_mode = (contract.model_mode == DSA_MODEL_SAFE_MODE ||
                      feature.quality_score < 50.0 ||
                      model.disagreement > 0.82 ||
                      model.drift_score > 0.88 ||
                      feature.volume_shock > 0.92 ||
                      feature.vol_of_vol > 1.20 ||
                      model.regime == DSA_REGIME_SHOCK);

   if(model.safe_mode)
   {
      w_naive = 0.45;
      w_holt = 0.05;
      w_kalman = 0.50;
      w_ridge = 0.00;
      w_sequence = 0.00;
      model.interval_radius *= 1.35;
   }

   const double naive_maturity = DSA_Clamp((double)feature.maturity / 12.0,0.0,1.0);
   const double linear_maturity = DSA_Clamp((double)feature.maturity / 40.0,0.0,1.0);
   const double ridge_maturity = DSA_Clamp((double)(feature.maturity - 24) / 160.0,0.0,1.0) * model.ridge_adaptive_score;
   const double sequence_maturity = model.sequence_maturity * model.sequence_confidence;
   DSA_BuildExpertEvidence(model.naive,feature,model.interval_radius,runtime_load,naive_maturity,0.05,false,model.naive_evidence);
   DSA_BuildExpertEvidence(model.holt_forecast,feature,model.interval_radius,runtime_load,linear_maturity,0.10,false,model.holt_evidence);
   DSA_BuildExpertEvidence(model.kalman_forecast,feature,model.interval_radius,runtime_load,linear_maturity,0.12,false,model.kalman_evidence);
   DSA_BuildExpertEvidence(model.ridge_forecast,feature,model.interval_radius,runtime_load,ridge_maturity,0.30,true,model.ridge_evidence);
   DSA_BuildExpertEvidence(model.sequence_forecast,feature,model.interval_radius,runtime_load,sequence_maturity,0.40,true,model.sequence_evidence);

   if(model.safe_mode)
   {
      model.ridge_evidence.approved = false;
      model.sequence_evidence.approved = false;
   }
   if(contract.model_mode == DSA_MODEL_STATISTICAL || contract.model_mode == DSA_MODEL_SAFE_MODE)
   {
      model.ridge_evidence.approved = false;
      model.sequence_evidence.approved = false;
   }
   if(contract.model_mode == DSA_MODEL_MACHINE_LEARNING)
      model.sequence_evidence.approved = false;
   if(!sequence_mode)
      model.sequence_evidence.approved = false;

   w_naive = DSA_EvidenceAdjustedWeight(w_naive,model.naive_evidence,0.05);
   w_holt = DSA_EvidenceAdjustedWeight(w_holt,model.holt_evidence,0.04);
   w_kalman = DSA_EvidenceAdjustedWeight(w_kalman,model.kalman_evidence,0.05);
   w_ridge = DSA_EvidenceAdjustedWeight(w_ridge,model.ridge_evidence,0.02);
   w_sequence = DSA_EvidenceAdjustedWeight(w_sequence,model.sequence_evidence,0.02);
   if(!model.ridge_evidence.approved && contract.model_mode != DSA_MODEL_MACHINE_LEARNING && contract.model_mode != DSA_MODEL_HYBRID)
      w_ridge = 0.0;
   if(!model.sequence_evidence.approved)
      w_sequence = 0.0;

   const double weight_sum = MathMax(w_naive + w_holt + w_kalman + w_ridge + w_sequence,DBL_EPSILON);
   model.expert_weight_naive = w_naive / weight_sum;
   model.expert_weight_holt = w_holt / weight_sum;
   model.expert_weight_kalman = w_kalman / weight_sum;
   model.expert_weight_ridge = w_ridge / weight_sum;
   model.expert_weight_sequence = w_sequence / weight_sum;
   model.naive_evidence.weight = model.expert_weight_naive;
   model.holt_evidence.weight = model.expert_weight_holt;
   model.kalman_evidence.weight = model.expert_weight_kalman;
   model.ridge_evidence.weight = model.expert_weight_ridge;
   model.sequence_evidence.weight = model.expert_weight_sequence;
   model.central_forecast = (w_naive * model.naive +
                             w_holt * model.holt_forecast +
                             w_kalman * model.kalman_forecast +
                             w_ridge * model.ridge_forecast +
                             w_sequence * model.sequence_forecast) / weight_sum;

   model.ensemble_state = model.kalman_level;
   model.band_radius = MathMax(feature.volatility,model.interval_radius * 0.70);
   model.runtime_cost_score = DSA_Clamp(runtime_load,0.0,1.5) / 1.5;
   model.volatility_stress = DSA_Clamp(0.45 * feature.vol_of_vol +
                                       0.35 * feature.volume_shock +
                                       0.20 * MathAbs(feature.cusum_pressure),
                                       0.0,1.0);
   model.model_score = DSA_Clamp(100.0 -
                                 35.0 * model.drift_score -
                                 20.0 * model.disagreement -
                                 25.0 * (1.0 - feature.quality_score / 100.0) -
                                 12.0 * model.runtime_cost_score -
                                 8.0 * model.volatility_stress,
                                 0.0,100.0);
}

#endif
