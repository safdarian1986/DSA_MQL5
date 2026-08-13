#ifndef DSA_STATION_MANIFEST_MQH
#define DSA_STATION_MANIFEST_MQH

struct DSAStationDefinition
{
   int id;
   string module;
   string input_role;
   string algorithm;
   string output;
   int runtime_priority;
   bool can_run_on_live_candle0;
   bool can_commit_historical_state;
   bool requires_closed_bar;
   bool heavy_task;
   bool can_be_deferred;
   bool can_be_sliced;
};

void DSA_SetStation(DSAStationDefinition &station,
                    const int id,
                    const string module,
                    const string input_role,
                    const string algorithm,
                    const string output,
                    const int runtime_priority,
                    const bool live,
                    const bool historical,
                    const bool closed_bar,
                    const bool heavy,
                    const bool deferred,
                    const bool sliced)
{
   station.id = id;
   station.module = module;
   station.input_role = input_role;
   station.algorithm = algorithm;
   station.output = output;
   station.runtime_priority = runtime_priority;
   station.can_run_on_live_candle0 = live;
   station.can_commit_historical_state = historical;
   station.requires_closed_bar = closed_bar;
   station.heavy_task = heavy;
   station.can_be_deferred = deferred;
   station.can_be_sliced = sliced;
}

bool DSA_GetStationDefinition(const int id,DSAStationDefinition &station)
{
   switch(id)
   {
      case 1:  DSA_SetStation(station,1,"s01_problem_contract.mqh","Inputs","A01","Contract",0,true,true,false,false,false,false); return true;
      case 2:  DSA_SetStation(station,2,"s02_target_series.mqh","Selection Data","F01-F04","Target",0,true,true,false,false,false,false); return true;
      case 3:  DSA_SetStation(station,3,"s03_forecast_horizon.mqh","Forecast Range / TF","F26","Horizon",1,true,true,false,false,false,false); return true;
      case 4:  DSA_SetStation(station,4,"s04_history_loader.mqh","Symbol / TF","A03+A22","Full History Build",8,false,true,true,true,true,true); return true;
      case 5:  DSA_SetStation(station,5,"s05_dual_state_snapshot.mqh","History / Candle0","F40/A04","Closed/Live State",1,true,true,false,false,false,false); return true;
      case 6:  DSA_SetStation(station,6,"s06_schema_validator.mqh","OHLCV","A01","Data Contract",1,true,true,false,false,false,false); return true;
      case 7:  DSA_SetStation(station,7,"s07_gap_missing.mqh","Time","F07/F09","Gap Map",2,false,true,true,false,false,false); return true;
      case 8:  DSA_SetStation(station,8,"s08_robust_outlier.mqh","Market Data","F08","Outlier",2,true,true,false,false,false,false); return true;
      case 9:  DSA_SetStation(station,9,"s09_causal_mtf_alignment.mqh","TF Data","F36","Causal MTF",2,false,true,true,true,true,true); return true;
      case 10: DSA_SetStation(station,10,"s10_quality_score.mqh","Diagnostics","F10","Quality",2,true,true,false,false,false,false); return true;
      case 11: DSA_SetStation(station,11,"s11_price_channels.mqh","Selection Data","F01-F03","Price Features",0,true,true,false,false,false,false); return true;
      case 12: DSA_SetStation(station,12,"s12_return_candle_features.mqh","OHLC","F04","Geometry",0,true,true,false,false,false,false); return true;
      case 13: DSA_SetStation(station,13,"s13_volume_spread_features.mqh","Volume / Spread","Robust","Volume Features",0,true,true,false,false,false,false); return true;
      case 14: DSA_SetStation(station,14,"s14_recursive_moments.mqh","Features","F05","EW State",0,true,true,false,false,false,false); return true;
      case 15: DSA_SetStation(station,15,"s15_causal_feature_matrix.mqh","Features","F14","Feature Vector",0,true,true,false,false,false,false); return true;
      case 16: DSA_SetStation(station,16,"s16_acf_pacf.mqh","Residual","F13","ACF/PACF",6,false,true,true,true,true,true); return true;
      case 17: DSA_SetStation(station,17,"s17_adaptive_lags.mqh","Memory/OOS","F06/F15","Lags",6,false,true,true,true,true,true); return true;
      case 18: DSA_SetStation(station,18,"s18_fourier_cycle.mqh","Residual","F34","Cycle",6,false,true,true,true,true,true); return true;
      case 19: DSA_SetStation(station,19,"s19_market_structure.mqh","H/L/Range","Adaptive","Structure",3,true,true,false,false,true,false); return true;
      case 20: DSA_SetStation(station,20,"s20_trend_efficiency.mqh","Price","F11","Trend",0,true,true,false,false,false,false); return true;
      case 21: DSA_SetStation(station,21,"s21_adaptive_holt.mqh","Target","F16","Holt State",0,true,true,false,false,false,false); return true;
      case 22: DSA_SetStation(station,22,"s22_kalman_state.mqh","Target","F17","Kalman State",0,true,true,false,false,false,false); return true;
      case 23: DSA_SetStation(station,23,"s23_volatility_engine.mqh","Returns","F18","Volatility",0,true,true,false,false,false,false); return true;
      case 24: DSA_SetStation(station,24,"s24_change_anomaly.mqh","Residual","F08/F24","Change/Anomaly",2,true,true,false,false,false,false); return true;
      case 25: DSA_SetStation(station,25,"s25_regime_engine.mqh","State","F32","Regime",0,true,true,false,false,false,false); return true;
      case 26: DSA_SetStation(station,26,"s26_naive_drift.mqh","Target","Baseline","Naive",0,true,true,false,false,false,false); return true;
      case 27: DSA_SetStation(station,27,"s27_holt_forecast.mqh","Holt","F16","Holt Path",0,true,true,false,false,false,false); return true;
      case 28: DSA_SetStation(station,28,"s28_kalman_forecast.mqh","Kalman","F17","Kalman Path",0,true,true,false,false,false,false); return true;
      case 29: DSA_SetStation(station,29,"s29_ar_ridge.mqh","Features","F19","Ridge Path",5,false,true,true,true,true,true); return true;
      case 30: DSA_SetStation(station,30,"s30_multihorizon_forecast.mqh","Models","F26","Forecast Matrix",2,true,true,false,false,false,false); return true;
      case 31: DSA_SetStation(station,31,"s31_prequential_store.mqh","Forecast / Actual","F35","OOS Error",1,false,true,true,false,false,false); return true;
      case 32: DSA_SetStation(station,32,"s32_model_score.mqh","Errors","F23","Score",2,false,true,true,false,false,false); return true;
      case 33: DSA_SetStation(station,33,"s33_adaptive_weights.mqh","Score / Regime","F22","Weights",2,true,true,false,false,false,false); return true;
      case 34: DSA_SetStation(station,34,"s34_ensemble_forecast.mqh","Models","F21","Central",0,true,true,false,false,false,false); return true;
      case 35: DSA_SetStation(station,35,"s35_conformal_interval.mqh","Residual","F20","Lower / Upper",1,true,true,false,false,false,false); return true;
      case 36: DSA_SetStation(station,36,"s36_oos_metrics.mqh","Forecast / Actual","Metrics","Validation",2,false,true,true,false,false,false); return true;
      case 37: DSA_SetStation(station,37,"s37_drift_engine.mqh","Data / Error","F28/F39","Drift",4,true,true,false,false,true,false); return true;
      case 38: DSA_SetStation(station,38,"s38_candidate_generator.mqh","State","F06","Candidates",5,false,false,true,true,true,true); return true;
      case 39: DSA_SetStation(station,39,"s39_recalibration.mqh","Candidates","A15","Approved State",5,false,true,true,true,true,true); return true;
      case 40: DSA_SetStation(station,40,"s40_safe_mode.mqh","Risk States","F33","Safe / Normal",4,true,true,false,false,false,false); return true;
      case 41: DSA_SetStation(station,41,"s41_model_agreement.mqh","Forecasts","F31","Agreement",1,true,true,false,false,false,false); return true;
      case 42: DSA_SetStation(station,42,"s42_trend_breakout_event.mqh","Structure","F37","Breakout",3,true,true,false,false,true,false); return true;
      case 43: DSA_SetStation(station,43,"s43_shock_regime_event.mqh","State","F24/F37","Events",3,true,true,false,false,true,false); return true;
      case 44: DSA_SetStation(station,44,"s44_historical_pressure.mqh","Walk-Forward","F29/F30","Historical Event",3,false,true,true,false,false,false); return true;
      case 45: DSA_SetStation(station,45,"s45_event_commit.mqh","Candidate","Causal Commit","Final Event",3,false,true,true,false,false,false); return true;
      case 46: DSA_SetStation(station,46,"s46_visual_scene.mqh","Outputs","A19","Scene",3,true,true,false,false,true,false); return true;
      case 47: DSA_SetStation(station,47,"s47_historical_buffers.mqh","0 to Oldest","Buffer Mapping","History",3,true,true,false,false,false,false); return true;
      case 48: DSA_SetStation(station,48,"s48_future_objects.mqh","Forecast","Object Mapping","Future",3,true,false,false,false,true,false); return true;
      case 49: DSA_SetStation(station,49,"s49_tick_scheduler.mqh","Tick / NewBar / Internal Triggers","A21+A23+A24","Execution Route",0,true,true,false,false,false,false); return true;
      case 50: DSA_SetStation(station,50,"s50_state_commit.mqh","Valid State","A20","Commit",1,true,true,false,false,false,false); return true;
      default:
         return false;
   }
}

#endif
