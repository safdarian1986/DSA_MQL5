#ifndef DSA_ADAPTIVE_ENGINE_MQH
#define DSA_ADAPTIVE_ENGINE_MQH

#include "..\\Runtime\\TickScheduler.mqh"
#include "..\\Validation\\ValidationEngine.mqh"

struct DSAAdaptiveSnapshot
{
   double safe_mode_score;
   double stress_score;
   double feature_instability;
   double calibration_confidence;
   int reason_mask;
   bool recalibration_required;
};

struct DSAAdaptiveTuningState
{
   double interval_scale;
   double ridge_lambda_scale;
   long tuning_version;
};

struct DSAAdaptiveJobState
{
   bool active;
   int reason_mask;
   int candidate_cursor;
   double best_interval_scale;
   double best_ridge_lambda_scale;
   double best_score;
   double best_ridge_score;
   long job_version;
};

void DSA_InitAdaptiveTuning(DSAAdaptiveTuningState &tuning)
{
   tuning.interval_scale = 1.0;
   tuning.ridge_lambda_scale = 1.0;
   tuning.tuning_version = 1;
}

void DSA_InitAdaptiveJob(DSAAdaptiveJobState &job)
{
   job.active = false;
   job.reason_mask = DSA_REASON_NONE;
   job.candidate_cursor = 0;
   job.best_interval_scale = 1.0;
   job.best_ridge_lambda_scale = 1.0;
   job.best_score = DBL_MAX;
   job.best_ridge_score = DBL_MAX;
   job.job_version = 0;
}

void DSA_ComputeAdaptiveDiagnostics(DSAFeatureSnapshot &feature,
                                    DSAModelSnapshot &model,
                                    DSAValidationSnapshot &validation,
                                    const double runtime_load,
                                    DSAAdaptiveSnapshot &adaptive)
{
   const double quality_risk = 1.0 - DSA_Clamp(feature.quality_score / 100.0,0.0,1.0);
   const double shock_risk = DSA_Clamp(MathAbs(feature.robust_z) / 5.0,0.0,1.0);
   const double mtf_risk = (feature.mtf_available ? DSA_Clamp(MathAbs(feature.mtf_deviation) / 5.0,0.0,1.0) : 0.0);
   const double memory_instability = DSA_Clamp((MathAbs(feature.acf1 - feature.acf2) + MathAbs(feature.pacf2)) * 0.5,0.0,1.0);
   const double cycle_instability = DSA_Clamp(feature.cycle_score * model.disagreement,0.0,1.0);
   const double volatility_instability = DSA_Clamp(0.60 * feature.vol_of_vol + 0.40 * feature.volume_shock,0.0,1.0);
   const double metric_risk = (DSA_HasValue(validation.rolling_rmse) ?
                               DSA_Clamp(validation.rolling_rmse / MathMax(model.interval_radius * 2.0,_Point),0.0,1.0) :
                               validation.drift_score);
   const double coverage_risk = (DSA_HasValue(validation.coverage_rate) ?
                                 DSA_Clamp(MathAbs(0.90 - validation.coverage_rate) / 0.90,0.0,1.0) :
                                 1.0 - validation.coverage_hit);

   adaptive.feature_instability = DSA_Clamp(0.45 * memory_instability +
                                            0.20 * cycle_instability +
                                            0.20 * mtf_risk +
                                            0.15 * volatility_instability,
                                            0.0,1.0);

   adaptive.safe_mode_score = DSA_Clamp(0.25 * quality_risk +
                                        0.20 * model.drift_score +
                                        0.20 * model.disagreement +
                                        0.10 * shock_risk +
                                        0.10 * metric_risk +
                                        0.15 * DSA_Clamp(runtime_load,0.0,1.0),
                                        0.0,1.0);

   adaptive.stress_score = DSA_Clamp(0.20 * shock_risk +
                                     0.20 * validation.drift_score +
                                     0.20 * adaptive.feature_instability +
                                     0.15 * coverage_risk +
                                     0.10 * volatility_instability +
                                     0.15 * DSA_Clamp(runtime_load,0.0,1.0),
                                     0.0,1.0);

   adaptive.calibration_confidence = DSA_Clamp(1.0 -
                                               0.35 * adaptive.stress_score -
                                               0.25 * adaptive.feature_instability -
                                               0.20 * model.disagreement -
                                               0.20 * quality_risk,
                                               0.0,1.0);

   adaptive.reason_mask = DSA_REASON_NONE;
   if(model.drift_score > 0.70)
      adaptive.reason_mask |= DSA_REASON_DRIFT;
   if(validation.absolute_error > model.interval_radius * 1.25)
      adaptive.reason_mask |= DSA_REASON_FORECAST_DEGRADATION;
   if(adaptive.calibration_confidence < 0.35)
      adaptive.reason_mask |= DSA_REASON_LOW_CONFIDENCE;
   if(adaptive.feature_instability > 0.65)
      adaptive.reason_mask |= DSA_REASON_FEATURE_INSTABILITY;
   if(model.disagreement > 0.75)
      adaptive.reason_mask |= DSA_REASON_MODEL_INSTABILITY;

   adaptive.recalibration_required = (adaptive.reason_mask != DSA_REASON_NONE);
}

void DSA_StartAdaptiveJob(DSAAdaptiveJobState &job,
                          DSARuntimeSchedulerState &runtime,
                          const int reason_mask)
{
   if(job.active)
   {
      job.reason_mask |= reason_mask;
      return;
   }

   job.active = true;
   job.reason_mask = reason_mask;
   job.candidate_cursor = 0;
   job.best_interval_scale = 1.0;
   job.best_score = DBL_MAX;
   job.job_version = runtime.active_state_version;
   runtime.recalibration_pending = true;
   runtime.heavy_task_active = true;
}

double DSA_IntervalCandidateValue(const int candidate_index)
{
   switch(candidate_index)
   {
      case 0:
         return 0.85;
      case 1:
         return 1.00;
      case 2:
         return 1.15;
      case 3:
         return 1.35;
      default:
         return 1.60;
   }
}

double DSA_RidgeCandidateValue(const int candidate_index)
{
   switch(candidate_index)
   {
      case 0:
         return 0.50;
      case 1:
         return 0.75;
      case 2:
         return 1.00;
      case 3:
         return 1.50;
      default:
         return 2.25;
   }
}

double DSA_EvaluateIntervalCandidate(const int rates_total,
                                     const double candidate_scale,
                                     const double &absolute_error_buffer[],
                                     const double &radius_buffer[])
{
   if(rates_total < 24)
      return DBL_MAX;

   const int max_samples = 256;
   const int available = rates_total - 2;
   const int stride = MathMax(1,(int)MathCeil((double)available / (double)max_samples));
   int count = 0;
   int covered = 0;
   double width_sum = 0.0;

   for(int index = rates_total - 2; index >= 1; index -= stride)
   {
      if(!DSA_HasValue(absolute_error_buffer[index]) || !DSA_HasValue(radius_buffer[index]))
         continue;

      const double radius = MathMax(radius_buffer[index] * candidate_scale,_Point);
      if(absolute_error_buffer[index] <= radius)
         ++covered;
      width_sum += radius;
      ++count;
   }

   if(count < 16)
      return DBL_MAX;

   const double coverage = (double)covered / (double)count;
   const double target_coverage = 0.90;
   const double coverage_penalty = MathAbs(target_coverage - coverage) * 100.0;
   const double miss_penalty = (coverage < target_coverage ? (target_coverage - coverage) * 80.0 : 0.0);
   const double width_penalty = DSA_SafeDiv(width_sum,(double)count,0.0) * 0.01;
   return coverage_penalty + miss_penalty + width_penalty;
}

double DSA_EvaluateRidgeCandidate(const int rates_total,
                                  const double candidate_lambda_scale,
                                  const double &absolute_error_buffer[],
                                  const double &radius_buffer[],
                                  const double &model_score_buffer[],
                                  const double &disagreement_buffer[],
                                  const double &stress_buffer[])
{
   if(rates_total < 24)
      return DBL_MAX;

   const int max_samples = 192;
   const int available = rates_total - 2;
   const int stride = MathMax(1,(int)MathCeil((double)available / (double)max_samples));
   int count = 0;
   int missed = 0;
   double error_pressure_sum = 0.0;
   double instability_sum = 0.0;
   double quality_gap_sum = 0.0;

   for(int index = rates_total - 2; index >= 1; index -= stride)
   {
      if(!DSA_HasValue(absolute_error_buffer[index]) || !DSA_HasValue(radius_buffer[index]))
         continue;

      const double radius = MathMax(radius_buffer[index],_Point);
      const double error_pressure = DSA_Clamp(absolute_error_buffer[index] / radius,0.0,4.0);
      const double disagreement = (DSA_HasValue(disagreement_buffer[index]) ? DSA_Clamp(disagreement_buffer[index],0.0,1.0) : 0.0);
      const double stress = (DSA_HasValue(stress_buffer[index]) ? DSA_Clamp(stress_buffer[index],0.0,1.0) : 0.0);
      const double score = (DSA_HasValue(model_score_buffer[index]) ? DSA_Clamp(model_score_buffer[index],0.0,100.0) : 60.0);

      error_pressure_sum += error_pressure;
      instability_sum += 0.55 * disagreement + 0.45 * stress;
      quality_gap_sum += 1.0 - score / 100.0;
      if(error_pressure > 1.0)
         ++missed;
      ++count;
   }

   if(count < 16)
      return DBL_MAX;

   const double average_error_pressure = error_pressure_sum / (double)count;
   const double average_instability = instability_sum / (double)count;
   const double average_quality_gap = quality_gap_sum / (double)count;
   const double miss_rate = (double)missed / (double)count;
   double target_lambda = 0.65 +
                          1.35 * average_instability +
                          0.70 * MathMax(average_error_pressure - 0.90,0.0) +
                          0.35 * average_quality_gap +
                          0.35 * MathMax(miss_rate - 0.10,0.0);
   target_lambda = DSA_Clamp(target_lambda,0.50,2.25);

   const double candidate = DSA_Clamp(candidate_lambda_scale,0.50,2.25);
   const double regularization_distance = MathAbs(MathLog(candidate / target_lambda));
   const double error_pressure_penalty = MathAbs(average_error_pressure - 0.85) * 20.0;
   const double miss_penalty = MathMax(miss_rate - 0.10,0.0) * 35.0;
   return regularization_distance * 45.0 +
          error_pressure_penalty +
          miss_penalty +
          average_instability * 6.0 +
          average_quality_gap * 4.0;
}

void DSA_ProcessAdaptiveJobSlice(DSAAdaptiveJobState &job,
                                 DSAAdaptiveTuningState &tuning,
                                 DSARuntimeSchedulerState &runtime,
                                 const int rates_total,
                                 const double &absolute_error_buffer[],
                                 const double &radius_buffer[],
                                 const double &model_score_buffer[],
                                 const double &disagreement_buffer[],
                                 const double &stress_buffer[])
{
   if(!job.active)
      return;

   if(job.job_version != runtime.active_state_version)
   {
      DSA_InitAdaptiveJob(job);
      runtime.heavy_task_active = false;
      runtime.recalibration_pending = false;
      return;
   }

   if(job.candidate_cursor < 5)
   {
      const double candidate_scale = DSA_IntervalCandidateValue(job.candidate_cursor);
      const double score = DSA_EvaluateIntervalCandidate(rates_total,candidate_scale,absolute_error_buffer,radius_buffer);
      if(score < job.best_score)
      {
         job.best_score = score;
         job.best_interval_scale = candidate_scale;
      }
      ++job.candidate_cursor;
      return;
   }

   if(job.candidate_cursor < 10)
   {
      const double candidate_lambda = DSA_RidgeCandidateValue(job.candidate_cursor - 5);
      const double score = DSA_EvaluateRidgeCandidate(rates_total,candidate_lambda,
                                                      absolute_error_buffer,radius_buffer,
                                                      model_score_buffer,disagreement_buffer,stress_buffer);
      if(score < job.best_ridge_score)
      {
         job.best_ridge_score = score;
         job.best_ridge_lambda_scale = candidate_lambda;
      }
      ++job.candidate_cursor;
      return;
   }

   if(job.best_score < DBL_MAX)
   {
      tuning.interval_scale = DSA_Clamp(job.best_interval_scale,0.75,1.75);
      tuning.tuning_version++;
   }

   if(job.best_ridge_score < DBL_MAX)
   {
      tuning.ridge_lambda_scale = DSA_Clamp(job.best_ridge_lambda_scale,0.50,2.25);
      tuning.tuning_version++;
   }

   DSA_InitAdaptiveJob(job);
   runtime.heavy_task_active = false;
   runtime.recalibration_pending = false;
   runtime.pending_reason_mask = DSA_REASON_NONE;
}

#endif
