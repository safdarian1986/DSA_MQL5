#ifndef DSA_EVENT_ENGINE_MQH
#define DSA_EVENT_ENGINE_MQH

#include "..\\Validation\\ValidationEngine.mqh"

enum ENUM_DSA_EVENT_TYPE
{
   DSA_EVENT_NONE = 0,
   DSA_EVENT_TREND_CHANGE = 1,
   DSA_EVENT_REGIME_CHANGE = 2,
   DSA_EVENT_SHOCK = 3,
   DSA_EVENT_ANOMALY = 4,
   DSA_EVENT_BREAKOUT = 5,
   DSA_EVENT_UP_PRESSURE = 6,
   DSA_EVENT_DOWN_PRESSURE = 7,
   DSA_EVENT_SIGNAL_END = 8
};

struct DSAEventSnapshot
{
   bool up_pressure;
   bool down_pressure;
   bool auxiliary_event;
   bool trend_change;
   bool regime_change;
   bool shock_event;
   bool anomaly_event;
   bool breakout_event;
   bool signal_end;
   bool final_event;
   bool provisional_event;
   bool immutable_historical_decision;
   bool uses_future_inputs;
   int event_type;
   long event_identity;
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
   event.trend_change = false;
   event.regime_change = false;
   event.shock_event = false;
   event.anomaly_event = false;
   event.breakout_event = false;
   event.signal_end = false;
   event.final_event = (index > 0);
   event.provisional_event = (index == 0);
   event.immutable_historical_decision = event.final_event;
   event.uses_future_inputs = false;
   event.event_type = DSA_EVENT_NONE;
   event.event_identity = 0;
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
   const bool trend_up = (model.regime == DSA_REGIME_TREND_UP && trend_move > 0.20);
   const bool trend_down = (model.regime == DSA_REGIME_TREND_DOWN && trend_move < -0.20);

   if(trend_up)
   {
      event.up_pressure = true;
      event.up_price = low[index] - offset;
      event.event_strength = MathMax(event.event_strength,DSA_Clamp(trend_move,0.0,1.0));
   }

   if(trend_down)
   {
      event.down_pressure = true;
      event.down_price = high[index] + offset;
      event.event_strength = MathMax(event.event_strength,DSA_Clamp(-trend_move,0.0,1.0));
   }

   const double trend_change_distance = MathMax(model.band_radius * 0.65,feature.volatility * 0.75);
   event.trend_change = ((trend_up && previous_trend < feature.target - trend_change_distance) ||
                         (trend_down && previous_trend > feature.target + trend_change_distance) ||
                         (MathAbs(feature.trend_acceleration) > feature.volatility * 0.55 &&
                          feature.persistence > 0.22 &&
                          feature.feature_reliability > 0.25));
   event.regime_change = (validation.drift_score > 0.68 ||
                          (model.disagreement > 0.62 && feature.feature_reliability < 0.45) ||
                          (model.volatility_stress > 0.70 && feature.vol_of_vol > 0.55));
   event.shock_event = (model.regime == DSA_REGIME_SHOCK);
   event.anomaly_event = (MathAbs(feature.robust_z) > 3.0);
   event.breakout_event = ((feature.structure_position > 0.92 || feature.structure_position < 0.08) &&
                           feature.persistence > 0.12 &&
                           structure_strength > 0.65);
   event.signal_end = ((feature.persistence < 0.08 && model.disagreement > 0.42) ||
                       (event.regime_change && MathAbs(trend_move) < 0.12));

   if(event.shock_event)
   {
      event.auxiliary_event = true;
      event.auxiliary_price = feature.target;
      event.event_type = DSA_EVENT_SHOCK;
      event.event_strength = MathMax(event.event_strength,MathMax(anomaly_strength,drift_strength));
   }
   else if(event.anomaly_event)
   {
      event.auxiliary_event = true;
      event.auxiliary_price = feature.target;
      event.event_type = DSA_EVENT_ANOMALY;
      event.event_strength = MathMax(event.event_strength,anomaly_strength);
   }
   else if(event.breakout_event)
   {
      event.auxiliary_event = true;
      event.auxiliary_price = feature.target;
      event.event_type = DSA_EVENT_BREAKOUT;
      event.event_strength = MathMax(event.event_strength,structure_strength);
   }
   else if(event.trend_change)
   {
      event.auxiliary_event = true;
      event.auxiliary_price = feature.target;
      event.event_type = DSA_EVENT_TREND_CHANGE;
      event.event_strength = MathMax(event.event_strength,DSA_Clamp(MathAbs(trend_move),0.0,1.0));
   }
   else if(event.regime_change)
   {
      event.auxiliary_event = true;
      event.auxiliary_price = feature.target;
      event.event_type = DSA_EVENT_REGIME_CHANGE;
      event.event_strength = MathMax(event.event_strength,drift_strength);
   }
   else if(event.signal_end)
   {
      event.auxiliary_event = true;
      event.auxiliary_price = feature.target;
      event.event_type = DSA_EVENT_SIGNAL_END;
      event.event_strength = MathMax(event.event_strength,DSA_Clamp(1.0 - feature.persistence,0.0,1.0));
   }
   else if(event.up_pressure)
      event.event_type = DSA_EVENT_UP_PRESSURE;
   else if(event.down_pressure)
      event.event_type = DSA_EVENT_DOWN_PRESSURE;

   if(event.event_type != DSA_EVENT_NONE)
      event.event_identity = ((long)feature.primary_analysis_time * 100L) + (long)event.event_type;
}

#endif
