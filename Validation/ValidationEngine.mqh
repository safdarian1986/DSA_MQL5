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
};

void DSA_ValidatePrequential(const int index,
                             const int rates_total,
                             DSAFeatureSnapshot &feature,
                             DSAModelSnapshot &model,
                             const double &target_buffer[],
                             const double &forecast_buffer[],
                             const double &uncertainty_upper_buffer[],
                             const double &uncertainty_lower_buffer[],
                             DSAValidationSnapshot &validation)
{
   validation.absolute_error = 0.0;
   validation.squared_error = 0.0;
   validation.directional_hit = 0.0;
   validation.coverage_hit = 1.0;

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

   validation.model_score = model.model_score;
   validation.drift_score = model.drift_score;
}

#endif
