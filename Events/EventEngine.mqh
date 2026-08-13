#ifndef DSA_EVENT_ENGINE_MQH
#define DSA_EVENT_ENGINE_MQH

#include "..\\Validation\\ValidationEngine.mqh"

struct DSAEventSnapshot
{
   bool up_pressure;
   bool down_pressure;
   bool auxiliary_event;
   double up_price;
   double down_price;
   double auxiliary_price;
};

void DSA_DetectEvents(const int index,
                      const int rates_total,
                      const double &high[],
                      const double &low[],
                      DSAFeatureSnapshot &feature,
                      DSAModelSnapshot &model,
                      DSAValidationSnapshot &validation,
                      const double &trend_buffer[],
                      DSAEventSnapshot &event)
{
   event.up_pressure = false;
   event.down_pressure = false;
   event.auxiliary_event = false;
   event.up_price = EMPTY_VALUE;
   event.down_price = EMPTY_VALUE;
   event.auxiliary_price = EMPTY_VALUE;

   const double previous_trend = (index + 1 < rates_total && DSA_HasValue(trend_buffer[index + 1]) ? trend_buffer[index + 1] : feature.target);
   const double offset = MathMax(feature.candle_range * 0.25,5.0 * _Point);

   if(model.regime == DSA_REGIME_TREND_UP && feature.target > previous_trend + 0.20 * model.band_radius)
   {
      event.up_pressure = true;
      event.up_price = low[index] - offset;
   }

   if(model.regime == DSA_REGIME_TREND_DOWN && feature.target < previous_trend - 0.20 * model.band_radius)
   {
      event.down_pressure = true;
      event.down_price = high[index] + offset;
   }

   if(model.regime == DSA_REGIME_SHOCK ||
      model.regime == DSA_REGIME_VOLATILE ||
      validation.drift_score > 0.80 ||
      MathAbs(feature.robust_z) > 3.0)
   {
      event.auxiliary_event = true;
      event.auxiliary_price = feature.target;
   }
}

#endif
