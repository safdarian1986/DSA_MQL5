#ifndef DSA_EVENT_ENGINE_MQH
#define DSA_EVENT_ENGINE_MQH

#include "..\\Validation\\ValidationEngine.mqh"

enum ENUM_DSA_EVENT_TYPE
{
   DSA_EVENT_NONE = 0,
   DSA_EVENT_TREND_UP = 1,
   DSA_EVENT_TREND_DOWN = 2,
   DSA_EVENT_SHOCK = 3,
   DSA_EVENT_ANOMALY = 4,
   DSA_EVENT_DRIFT = 5,
   DSA_EVENT_STRUCTURE = 6
};

struct DSAEventSnapshot
{
   bool up_pressure;
   bool down_pressure;
   bool auxiliary_event;
   bool final_event;
   bool provisional_event;
   int event_type;
   double up_price;
   double down_price;
   double auxiliary_price;
   double event_strength;
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
   event.final_event = (index > 0);
   event.provisional_event = (index == 0);
   event.event_type = DSA_EVENT_NONE;
   event.up_price = EMPTY_VALUE;
   event.down_price = EMPTY_VALUE;
   event.auxiliary_price = EMPTY_VALUE;
   event.event_strength = 0.0;

   const double previous_trend = (index + 1 < rates_total && DSA_HasValue(trend_buffer[index + 1]) ? trend_buffer[index + 1] : feature.target);
   const double offset = MathMax(feature.candle_range * 0.25,5.0 * _Point);
   const double trend_move = DSA_SafeDiv(feature.target - previous_trend,MathMax(model.band_radius,_Point),0.0);
   const double anomaly_strength = DSA_Clamp(MathAbs(feature.robust_z) / 5.0,0.0,1.0);
   const double drift_strength = DSA_Clamp(validation.drift_score,0.0,1.0);
   const double structure_strength = DSA_Clamp(MathAbs(feature.structure_position - 0.50) * 2.0,0.0,1.0);

   if(model.regime == DSA_REGIME_TREND_UP && trend_move > 0.20)
   {
      event.up_pressure = true;
      event.up_price = low[index] - offset;
      event.event_type = DSA_EVENT_TREND_UP;
      event.event_strength = MathMax(event.event_strength,DSA_Clamp(trend_move,0.0,1.0));
   }

   if(model.regime == DSA_REGIME_TREND_DOWN && trend_move < -0.20)
   {
      event.down_pressure = true;
      event.down_price = high[index] + offset;
      event.event_type = DSA_EVENT_TREND_DOWN;
      event.event_strength = MathMax(event.event_strength,DSA_Clamp(-trend_move,0.0,1.0));
   }

   if(model.regime == DSA_REGIME_SHOCK)
   {
      event.auxiliary_event = true;
      event.auxiliary_price = feature.target;
      event.event_type = DSA_EVENT_SHOCK;
      event.event_strength = MathMax(event.event_strength,MathMax(anomaly_strength,drift_strength));
   }
   else if(MathAbs(feature.robust_z) > 3.0)
   {
      event.auxiliary_event = true;
      event.auxiliary_price = feature.target;
      event.event_type = DSA_EVENT_ANOMALY;
      event.event_strength = MathMax(event.event_strength,anomaly_strength);
   }
   else if(validation.drift_score > 0.80)
   {
      event.auxiliary_event = true;
      event.auxiliary_price = feature.target;
      event.event_type = DSA_EVENT_DRIFT;
      event.event_strength = MathMax(event.event_strength,drift_strength);
   }
   else if((model.regime == DSA_REGIME_VOLATILE || structure_strength > 0.75) &&
           event.event_type == DSA_EVENT_NONE)
   {
      event.auxiliary_event = true;
      event.auxiliary_price = feature.target;
      event.event_type = DSA_EVENT_STRUCTURE;
      event.event_strength = MathMax(event.event_strength,structure_strength);
   }
}

#endif
