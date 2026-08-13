#ifndef DSA_VALIDATION_ENGINE_MQH
#define DSA_VALIDATION_ENGINE_MQH

#include "..\\Models\\ModelBank.mqh"

struct DSAValidationSnapshot
{
   double absolute_error;
   double squared_error;
   double directional_hit;
   double coverage_hit;
   double model_score;
   double drift_score;
   double rolling_mae;
   double rolling_rmse;
   double directional_accuracy;
   double coverage_rate;
};

void DSA_ComputeRollingValidationMetrics(const int index,
                                         const int rates_total,
                                         const double &target_buffer[],
                                         const double &forecast_buffer[],
                                         const double &absolute_error_buffer[],
                                         const double &coverage_buffer[],
                                         double &rolling_mae,
                                         double &rolling_rmse,
                                         double &directional_accuracy,
                                         double &coverage_rate)
{
   rolling_mae = EMPTY_VALUE;
   rolling_rmse = EMPTY_VALUE;
   directional_accuracy = EMPTY_VALUE;
   coverage_rate = EMPTY_VALUE;

   const int available = rates_total - index - 3;
   if(available < 12)
      return;

   const int max_samples = 192;
   const int stride = MathMax(1,(int)MathCeil((double)available / (double)max_samples));
   double abs_sum = 0.0;
   double sq_sum = 0.0;
   double direction_hits = 0.0;
   double coverage_hits = 0.0;
   int error_count = 0;
   int direction_count = 0;
   int coverage_count = 0;

   for(int actual_index = index + 1; actual_index + 1 < rates_total; actual_index += stride)
   {
      if(DSA_HasValue(absolute_error_buffer[actual_index]))
      {
         const double error = MathMax(absolute_error_buffer[actual_index],0.0);
         abs_sum += error;
         sq_sum += error * error;
         ++error_count;
      }

      if(DSA_HasValue(target_buffer[actual_index]) &&
         DSA_HasValue(target_buffer[actual_index + 1]) &&
         DSA_HasValue(forecast_buffer[actual_index + 1]))
      {
         const double actual_direction = target_buffer[actual_index] - target_buffer[actual_index + 1];
         const double forecast_direction = forecast_buffer[actual_index + 1] - target_buffer[actual_index + 1];
         direction_hits += (actual_direction * forecast_direction >= 0.0 ? 1.0 : 0.0);
         ++direction_count;
      }

      if(DSA_HasValue(coverage_buffer[actual_index]))
      {
         coverage_hits += DSA_Clamp(coverage_buffer[actual_index],0.0,1.0);
         ++coverage_count;
      }
   }

   if(error_count >= 8)
   {
      rolling_mae = abs_sum / (double)error_count;
      rolling_rmse = MathSqrt(sq_sum / (double)error_count);
   }
   if(direction_count >= 8)
      directional_accuracy = direction_hits / (double)direction_count;
   if(coverage_count >= 8)
      coverage_rate = coverage_hits / (double)coverage_count;
}

void DSA_ValidatePrequential(const int index,
                             const int rates_total,
                             DSAFeatureSnapshot &feature,
                             DSAModelSnapshot &model,
                             const double &target_buffer[],
                             const double &forecast_buffer[],
                             const double &uncertainty_upper_buffer[],
                             const double &uncertainty_lower_buffer[],
                             const double &absolute_error_buffer[],
                             const double &coverage_buffer[],
                             DSAValidationSnapshot &validation)
{
   validation.absolute_error = 0.0;
   validation.squared_error = 0.0;
   validation.directional_hit = 0.0;
   validation.coverage_hit = 1.0;
   validation.rolling_mae = EMPTY_VALUE;
   validation.rolling_rmse = EMPTY_VALUE;
   validation.directional_accuracy = EMPTY_VALUE;
   validation.coverage_rate = EMPTY_VALUE;

   if(index + 1 < rates_total && DSA_HasValue(forecast_buffer[index + 1]))
   {
      const double forecast = forecast_buffer[index + 1];
      const double error = feature.target - forecast;
      validation.absolute_error = MathAbs(error);
      validation.squared_error = error * error;

      if(index + 1 < rates_total && DSA_HasValue(target_buffer[index + 1]))
      {
         const double previous_actual = target_buffer[index + 1];
         const double actual_direction = feature.target - previous_actual;
         const double forecast_direction = forecast - previous_actual;
         validation.directional_hit = (actual_direction * forecast_direction >= 0.0 ? 1.0 : 0.0);
      }

      if(index + 1 < rates_total &&
         DSA_HasValue(uncertainty_upper_buffer[index + 1]) &&
         DSA_HasValue(uncertainty_lower_buffer[index + 1]))
      {
         validation.coverage_hit = (feature.target >= uncertainty_lower_buffer[index + 1] &&
                                    feature.target <= uncertainty_upper_buffer[index + 1] ? 1.0 : 0.0);
      }
   }

   DSA_ComputeRollingValidationMetrics(index,rates_total,target_buffer,forecast_buffer,
                                       absolute_error_buffer,coverage_buffer,
                                       validation.rolling_mae,validation.rolling_rmse,
                                       validation.directional_accuracy,validation.coverage_rate);

   double validation_penalty = 0.0;
   if(DSA_HasValue(validation.rolling_rmse))
      validation_penalty += 8.0 * DSA_Clamp(validation.rolling_rmse / MathMax(model.interval_radius * 2.0,_Point),0.0,1.5);
   if(DSA_HasValue(validation.directional_accuracy) && validation.directional_accuracy < 0.50)
      validation_penalty += 12.0 * (0.50 - validation.directional_accuracy);
   if(DSA_HasValue(validation.coverage_rate))
      validation_penalty += 10.0 * MathAbs(0.90 - validation.coverage_rate);

   validation.model_score = DSA_Clamp(model.model_score - validation_penalty,0.0,100.0);
   validation.drift_score = model.drift_score;
}

#endif
