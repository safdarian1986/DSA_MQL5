#ifndef DSA_STATE_REGISTRY_MQH
#define DSA_STATE_REGISTRY_MQH

#include "DSACommon.mqh"

struct DSAStateFrame
{
   bool valid;
   bool provisional;
   int source_index;
   datetime bar_time;
   long state_version;
   long base_closed_version;
   string transition;
   double target;
   double forecast;
   double trend;
   double signal;
   double upper_band;
   double lower_band;
   double uncertainty_upper;
   double uncertainty_lower;
   double regime;
   double quality;
   double model_score;
   double drift;
   double volatility;
   double slope;
   double safe_mode;
   double stress;
   double bar_fingerprint;
};

struct DSAClosedState
{
   DSAStateFrame frame;
};

struct DSALiveState
{
   DSAStateFrame frame;
};

void DSA_ResetStateFrame(DSAStateFrame &frame)
{
   frame.valid = false;
   frame.provisional = false;
   frame.source_index = -1;
   frame.bar_time = 0;
   frame.state_version = 0;
   frame.base_closed_version = 0;
   frame.transition = "";
   frame.target = EMPTY_VALUE;
   frame.forecast = EMPTY_VALUE;
   frame.trend = EMPTY_VALUE;
   frame.signal = EMPTY_VALUE;
   frame.upper_band = EMPTY_VALUE;
   frame.lower_band = EMPTY_VALUE;
   frame.uncertainty_upper = EMPTY_VALUE;
   frame.uncertainty_lower = EMPTY_VALUE;
   frame.regime = EMPTY_VALUE;
   frame.quality = EMPTY_VALUE;
   frame.model_score = EMPTY_VALUE;
   frame.drift = EMPTY_VALUE;
   frame.volatility = EMPTY_VALUE;
   frame.slope = EMPTY_VALUE;
   frame.safe_mode = EMPTY_VALUE;
   frame.stress = EMPTY_VALUE;
   frame.bar_fingerprint = EMPTY_VALUE;
}

void DSA_ResetClosedState(DSAClosedState &state)
{
   DSA_ResetStateFrame(state.frame);
}

void DSA_ResetLiveState(DSALiveState &state)
{
   DSA_ResetStateFrame(state.frame);
}

bool DSA_LoadStateFrameFromBuffers(DSAStateFrame &frame,
                                   const int index,
                                   const datetime &time[],
                                   const double &target_buffer[],
                                   const double &forecast_buffer[],
                                   const double &trend_buffer[],
                                   const double &signal_buffer[],
                                   const double &upper_band_buffer[],
                                   const double &lower_band_buffer[],
                                   const double &uncertainty_upper_buffer[],
                                   const double &uncertainty_lower_buffer[],
                                   const double &regime_buffer[],
                                   const double &quality_buffer[],
                                   const double &model_score_buffer[],
                                   const double &drift_buffer[],
                                   const double &volatility_buffer[],
                                   const double &slope_buffer[],
                                   const double &safe_mode_buffer[],
                                   const double &stress_buffer[],
                                   const double &bar_fingerprint_buffer[],
                                   const long state_version,
                                   const long base_closed_version,
                                   const bool provisional,
                                   const string transition)
{
   if(index < 0)
   {
      DSA_ResetStateFrame(frame);
      return false;
   }

   frame.valid = (DSA_HasValue(target_buffer[index]) && DSA_HasValue(forecast_buffer[index]));
   frame.provisional = provisional;
   frame.source_index = index;
   frame.bar_time = time[index];
   frame.state_version = state_version;
   frame.base_closed_version = base_closed_version;
   frame.transition = transition;
   frame.target = target_buffer[index];
   frame.forecast = forecast_buffer[index];
   frame.trend = trend_buffer[index];
   frame.signal = signal_buffer[index];
   frame.upper_band = upper_band_buffer[index];
   frame.lower_band = lower_band_buffer[index];
   frame.uncertainty_upper = uncertainty_upper_buffer[index];
   frame.uncertainty_lower = uncertainty_lower_buffer[index];
   frame.regime = regime_buffer[index];
   frame.quality = quality_buffer[index];
   frame.model_score = model_score_buffer[index];
   frame.drift = drift_buffer[index];
   frame.volatility = volatility_buffer[index];
   frame.slope = slope_buffer[index];
   frame.safe_mode = safe_mode_buffer[index];
   frame.stress = stress_buffer[index];
   frame.bar_fingerprint = bar_fingerprint_buffer[index];
   return frame.valid;
}

bool DSA_CommitClosedStateFromBuffers(DSAClosedState &state,
                                      const int index,
                                      const datetime &time[],
                                      const double &target_buffer[],
                                      const double &forecast_buffer[],
                                      const double &trend_buffer[],
                                      const double &signal_buffer[],
                                      const double &upper_band_buffer[],
                                      const double &lower_band_buffer[],
                                      const double &uncertainty_upper_buffer[],
                                      const double &uncertainty_lower_buffer[],
                                      const double &regime_buffer[],
                                      const double &quality_buffer[],
                                      const double &model_score_buffer[],
                                      const double &drift_buffer[],
                                      const double &volatility_buffer[],
                                      const double &slope_buffer[],
                                      const double &safe_mode_buffer[],
                                      const double &stress_buffer[],
                                      const double &bar_fingerprint_buffer[],
                                      const long state_version,
                                      const string transition)
{
   return DSA_LoadStateFrameFromBuffers(state.frame,index,time,target_buffer,forecast_buffer,
                                       trend_buffer,signal_buffer,upper_band_buffer,lower_band_buffer,
                                       uncertainty_upper_buffer,uncertainty_lower_buffer,regime_buffer,
                                       quality_buffer,model_score_buffer,drift_buffer,volatility_buffer,
                                       slope_buffer,safe_mode_buffer,stress_buffer,bar_fingerprint_buffer,
                                       state_version,0,false,transition);
}

void DSA_BeginLiveState(DSALiveState &live_state,
                        DSAClosedState &closed_state,
                        const datetime live_bar_time,
                        const long state_version)
{
   DSA_ResetLiveState(live_state);
   if(!closed_state.frame.valid)
      return;

   live_state.frame = closed_state.frame;
   live_state.frame.valid = true;
   live_state.frame.provisional = true;
   live_state.frame.source_index = 0;
   live_state.frame.bar_time = live_bar_time;
   live_state.frame.state_version = state_version;
   live_state.frame.base_closed_version = closed_state.frame.state_version;
   live_state.frame.transition = "live_from_closed";
}

bool DSA_CaptureLiveStateFromBuffers(DSALiveState &live_state,
                                     const int index,
                                     const datetime &time[],
                                     const double &target_buffer[],
                                     const double &forecast_buffer[],
                                     const double &trend_buffer[],
                                     const double &signal_buffer[],
                                     const double &upper_band_buffer[],
                                     const double &lower_band_buffer[],
                                     const double &uncertainty_upper_buffer[],
                                     const double &uncertainty_lower_buffer[],
                                     const double &regime_buffer[],
                                     const double &quality_buffer[],
                                     const double &model_score_buffer[],
                                     const double &drift_buffer[],
                                     const double &volatility_buffer[],
                                     const double &slope_buffer[],
                                     const double &safe_mode_buffer[],
                                     const double &stress_buffer[],
                                     const double &bar_fingerprint_buffer[],
                                     const long state_version)
{
   const long base_closed_version = live_state.frame.base_closed_version;
   return DSA_LoadStateFrameFromBuffers(live_state.frame,index,time,target_buffer,forecast_buffer,
                                       trend_buffer,signal_buffer,upper_band_buffer,lower_band_buffer,
                                       uncertainty_upper_buffer,uncertainty_lower_buffer,regime_buffer,
                                       quality_buffer,model_score_buffer,drift_buffer,volatility_buffer,
                                       slope_buffer,safe_mode_buffer,stress_buffer,bar_fingerprint_buffer,
                                       state_version,base_closed_version,true,"live_tick");
}

bool DSA_LiveStateUsesClosedBase(DSALiveState &live_state,DSAClosedState &closed_state)
{
   return (live_state.frame.valid &&
           live_state.frame.provisional &&
           closed_state.frame.valid &&
           live_state.frame.base_closed_version == closed_state.frame.state_version);
}

#endif
