#property copyright "DSA-MQL5 Native"
#property link      ""
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 30
#property indicator_plots   10
#property tester_everytick_calculate

#property indicator_label1  "Adaptive Trend"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrDodgerBlue
#property indicator_style1  STYLE_SOLID
#property indicator_width1  2

#property indicator_label2  "Signal"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrDeepSkyBlue
#property indicator_style2  STYLE_SOLID
#property indicator_width2  1

#property indicator_label3  "Upper Band"
#property indicator_type3   DRAW_LINE
#property indicator_color3  clrSilver
#property indicator_style3  STYLE_DASH
#property indicator_width3  1

#property indicator_label4  "Lower Band"
#property indicator_type4   DRAW_LINE
#property indicator_color4  clrSilver
#property indicator_style4  STYLE_DASH
#property indicator_width4  1

#property indicator_label5  "Uncertainty Upper"
#property indicator_type5   DRAW_LINE
#property indicator_color5  clrLightSteelBlue
#property indicator_style5  STYLE_DOT
#property indicator_width5  1

#property indicator_label6  "Uncertainty Lower"
#property indicator_type6   DRAW_LINE
#property indicator_color6  clrLightSteelBlue
#property indicator_style6  STYLE_DOT
#property indicator_width6  1

#property indicator_label7  "Regime Color"
#property indicator_type7   DRAW_NONE
#property indicator_color7  clrSlateGray

#property indicator_label8  "Historical Up"
#property indicator_type8   DRAW_ARROW
#property indicator_color8  clrLimeGreen
#property indicator_width8  1

#property indicator_label9  "Historical Down"
#property indicator_type9   DRAW_ARROW
#property indicator_color9  clrTomato
#property indicator_width9  1

#property indicator_label10 "Auxiliary Event"
#property indicator_type10  DRAW_ARROW
#property indicator_color10 clrGold
#property indicator_width10 1

#include "Core\\InputContract.mqh"
#include "Runtime\\TickScheduler.mqh"
#include "Visual\\VisualRenderer.mqh"
#include "Adaptation\\AdaptiveEngine.mqh"
#include "Stations\\StationManifest.mqh"

input string                 InpSymbol              = "Host chart symbol";
input ENUM_DSA_SELECTION_DATA InpSelectionData       = DSA_DATA_OHLC;
input ENUM_TIMEFRAMES        InpChartTimeframe      = PERIOD_CURRENT;
input ENUM_TIMEFRAMES        InpAnalysisTimeframe   = PERIOD_CURRENT;
input ENUM_TIMEFRAMES        InpFutureForecastRange = PERIOD_D1;
input ENUM_DSA_MODEL_MODE    InpModelMode           = DSA_MODEL_ADAPTIVE;
input bool                   InpHistoricalAnalysis  = true;
input bool                   InpForecastDisplay     = true;
input bool                   InpEventDisplay        = true;
input ENUM_DSA_VISUAL_DETAIL InpVisualDetail        = DSA_VISUAL_FULL;

double BufferAdaptiveTrend[];
double BufferSignal[];
double BufferUpperBand[];
double BufferLowerBand[];
double BufferUncertaintyUpper[];
double BufferUncertaintyLower[];
double BufferRegimeColor[];
double BufferHistoricalUp[];
double BufferHistoricalDown[];
double BufferAuxiliaryEvent[];

double CalcTarget[];
double CalcForecast[];
double CalcQuality[];
double CalcModelScore[];
double CalcDisagreement[];
double CalcDrift[];
double CalcVolatility[];
double CalcSlope[];
double CalcAbsoluteError[];
double CalcCoverage[];
double CalcConformalRadius[];
double CalcPacf[];
double CalcSafeModeScore[];
double CalcStressScore[];
double CalcForecastH2[];
double CalcForecastH4[];
double CalcForecastH8[];
double CalcHorizonGrowth[];
double CalcRidgeState[];
double CalcBarFingerprint[];

DSARuntimeSchedulerState RuntimeState;
DSAInputContract InputContract;
DSAAdaptiveTuningState AdaptiveTuning;
DSAAdaptiveJobState AdaptiveJob;

void DSA_SetPlotDefaults()
{
   for(int plot = 0; plot < 10; ++plot)
      PlotIndexSetDouble(plot,PLOT_EMPTY_VALUE,EMPTY_VALUE);

   PlotIndexSetInteger(7,PLOT_ARROW,233);
   PlotIndexSetInteger(8,PLOT_ARROW,234);
   PlotIndexSetInteger(9,PLOT_ARROW,159);
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits);
   IndicatorSetString(INDICATOR_SHORTNAME,"DSA-MQL5 Native");
}

bool DSA_MapBuffers()
{
   bool ok = true;
   ok = ok && SetIndexBuffer(0,BufferAdaptiveTrend,INDICATOR_DATA);
   ok = ok && SetIndexBuffer(1,BufferSignal,INDICATOR_DATA);
   ok = ok && SetIndexBuffer(2,BufferUpperBand,INDICATOR_DATA);
   ok = ok && SetIndexBuffer(3,BufferLowerBand,INDICATOR_DATA);
   ok = ok && SetIndexBuffer(4,BufferUncertaintyUpper,INDICATOR_DATA);
   ok = ok && SetIndexBuffer(5,BufferUncertaintyLower,INDICATOR_DATA);
   ok = ok && SetIndexBuffer(6,BufferRegimeColor,INDICATOR_DATA);
   ok = ok && SetIndexBuffer(7,BufferHistoricalUp,INDICATOR_DATA);
   ok = ok && SetIndexBuffer(8,BufferHistoricalDown,INDICATOR_DATA);
   ok = ok && SetIndexBuffer(9,BufferAuxiliaryEvent,INDICATOR_DATA);

   ok = ok && SetIndexBuffer(10,CalcTarget,INDICATOR_CALCULATIONS);
   ok = ok && SetIndexBuffer(11,CalcForecast,INDICATOR_CALCULATIONS);
   ok = ok && SetIndexBuffer(12,CalcQuality,INDICATOR_CALCULATIONS);
   ok = ok && SetIndexBuffer(13,CalcModelScore,INDICATOR_CALCULATIONS);
   ok = ok && SetIndexBuffer(14,CalcDisagreement,INDICATOR_CALCULATIONS);
   ok = ok && SetIndexBuffer(15,CalcDrift,INDICATOR_CALCULATIONS);
   ok = ok && SetIndexBuffer(16,CalcVolatility,INDICATOR_CALCULATIONS);
   ok = ok && SetIndexBuffer(17,CalcSlope,INDICATOR_CALCULATIONS);
   ok = ok && SetIndexBuffer(18,CalcAbsoluteError,INDICATOR_CALCULATIONS);
   ok = ok && SetIndexBuffer(19,CalcCoverage,INDICATOR_CALCULATIONS);
   ok = ok && SetIndexBuffer(20,CalcConformalRadius,INDICATOR_CALCULATIONS);
   ok = ok && SetIndexBuffer(21,CalcPacf,INDICATOR_CALCULATIONS);
   ok = ok && SetIndexBuffer(22,CalcSafeModeScore,INDICATOR_CALCULATIONS);
   ok = ok && SetIndexBuffer(23,CalcStressScore,INDICATOR_CALCULATIONS);
   ok = ok && SetIndexBuffer(24,CalcForecastH2,INDICATOR_CALCULATIONS);
   ok = ok && SetIndexBuffer(25,CalcForecastH4,INDICATOR_CALCULATIONS);
   ok = ok && SetIndexBuffer(26,CalcForecastH8,INDICATOR_CALCULATIONS);
   ok = ok && SetIndexBuffer(27,CalcHorizonGrowth,INDICATOR_CALCULATIONS);
   ok = ok && SetIndexBuffer(28,CalcRidgeState,INDICATOR_CALCULATIONS);
   ok = ok && SetIndexBuffer(29,CalcBarFingerprint,INDICATOR_CALCULATIONS);

   ArraySetAsSeries(BufferAdaptiveTrend,true);
   ArraySetAsSeries(BufferSignal,true);
   ArraySetAsSeries(BufferUpperBand,true);
   ArraySetAsSeries(BufferLowerBand,true);
   ArraySetAsSeries(BufferUncertaintyUpper,true);
   ArraySetAsSeries(BufferUncertaintyLower,true);
   ArraySetAsSeries(BufferRegimeColor,true);
   ArraySetAsSeries(BufferHistoricalUp,true);
   ArraySetAsSeries(BufferHistoricalDown,true);
   ArraySetAsSeries(BufferAuxiliaryEvent,true);
   ArraySetAsSeries(CalcTarget,true);
   ArraySetAsSeries(CalcForecast,true);
   ArraySetAsSeries(CalcQuality,true);
   ArraySetAsSeries(CalcModelScore,true);
   ArraySetAsSeries(CalcDisagreement,true);
   ArraySetAsSeries(CalcDrift,true);
   ArraySetAsSeries(CalcVolatility,true);
   ArraySetAsSeries(CalcSlope,true);
   ArraySetAsSeries(CalcAbsoluteError,true);
   ArraySetAsSeries(CalcCoverage,true);
   ArraySetAsSeries(CalcConformalRadius,true);
   ArraySetAsSeries(CalcPacf,true);
   ArraySetAsSeries(CalcSafeModeScore,true);
   ArraySetAsSeries(CalcStressScore,true);
   ArraySetAsSeries(CalcForecastH2,true);
   ArraySetAsSeries(CalcForecastH4,true);
   ArraySetAsSeries(CalcForecastH8,true);
   ArraySetAsSeries(CalcHorizonGrowth,true);
   ArraySetAsSeries(CalcRidgeState,true);
   ArraySetAsSeries(CalcBarFingerprint,true);
   return ok;
}

void DSA_ResetBuffers()
{
   ArrayInitialize(BufferAdaptiveTrend,EMPTY_VALUE);
   ArrayInitialize(BufferSignal,EMPTY_VALUE);
   ArrayInitialize(BufferUpperBand,EMPTY_VALUE);
   ArrayInitialize(BufferLowerBand,EMPTY_VALUE);
   ArrayInitialize(BufferUncertaintyUpper,EMPTY_VALUE);
   ArrayInitialize(BufferUncertaintyLower,EMPTY_VALUE);
   ArrayInitialize(BufferRegimeColor,EMPTY_VALUE);
   ArrayInitialize(BufferHistoricalUp,EMPTY_VALUE);
   ArrayInitialize(BufferHistoricalDown,EMPTY_VALUE);
   ArrayInitialize(BufferAuxiliaryEvent,EMPTY_VALUE);
   ArrayInitialize(CalcTarget,EMPTY_VALUE);
   ArrayInitialize(CalcForecast,EMPTY_VALUE);
   ArrayInitialize(CalcQuality,EMPTY_VALUE);
   ArrayInitialize(CalcModelScore,EMPTY_VALUE);
   ArrayInitialize(CalcDisagreement,EMPTY_VALUE);
   ArrayInitialize(CalcDrift,EMPTY_VALUE);
   ArrayInitialize(CalcVolatility,EMPTY_VALUE);
   ArrayInitialize(CalcSlope,EMPTY_VALUE);
   ArrayInitialize(CalcAbsoluteError,EMPTY_VALUE);
   ArrayInitialize(CalcCoverage,EMPTY_VALUE);
   ArrayInitialize(CalcConformalRadius,EMPTY_VALUE);
   ArrayInitialize(CalcPacf,EMPTY_VALUE);
   ArrayInitialize(CalcSafeModeScore,EMPTY_VALUE);
   ArrayInitialize(CalcStressScore,EMPTY_VALUE);
   ArrayInitialize(CalcForecastH2,EMPTY_VALUE);
   ArrayInitialize(CalcForecastH4,EMPTY_VALUE);
   ArrayInitialize(CalcForecastH8,EMPTY_VALUE);
   ArrayInitialize(CalcHorizonGrowth,EMPTY_VALUE);
   ArrayInitialize(CalcRidgeState,EMPTY_VALUE);
   ArrayInitialize(CalcBarFingerprint,EMPTY_VALUE);
}

void DSA_ProcessBar(const int index,
                    const int rates_total,
                     const bool live_bar,
                    const datetime &time[],
                    const double &open[],
                    const double &high[],
                    const double &low[],
                    const double &close[],
                    const long &tick_volume[],
                    const int &spread[])
{
   DSAFeatureSnapshot feature;
   DSAModelSnapshot model;
   DSAValidationSnapshot validation;
   DSAEventSnapshot event;
   DSAAdaptiveSnapshot adaptive;

   DSA_BuildFeatureSnapshot(index,rates_total,InputContract,time,open,high,low,close,tick_volume,spread,
                            CalcTarget,BufferAdaptiveTrend,CalcSlope,CalcVolatility,CalcQuality,feature);

   DSA_ComputeModels(index,rates_total,InputContract,feature,open,high,low,close,
                      CalcTarget,BufferAdaptiveTrend,BufferSignal,
                      CalcForecast,CalcForecastH2,CalcForecastH4,CalcForecastH8,
                      CalcVolatility,BufferUncertaintyUpper,BufferUncertaintyLower,
                      CalcAbsoluteError,BufferRegimeColor,CalcRidgeState,
                      AdaptiveTuning.ridge_lambda_scale,AdaptiveTuning.interval_scale,live_bar,model);

   DSA_ValidatePrequential(index,rates_total,feature,model,CalcTarget,CalcForecast,
                           BufferUncertaintyUpper,BufferUncertaintyLower,validation);

   DSA_ComputeAdaptiveDiagnostics(feature,model,validation,RuntimeState.runtime_load,adaptive);

   DSA_DetectEvents(index,rates_total,high,low,feature,model,validation,BufferAdaptiveTrend,event);

   CalcTarget[index] = feature.target;
   CalcForecast[index] = model.central_forecast;
   CalcQuality[index] = feature.quality_score;
   CalcModelScore[index] = validation.model_score;
   CalcDisagreement[index] = model.disagreement;
   CalcDrift[index] = validation.drift_score;
   CalcVolatility[index] = feature.volatility;
   CalcSlope[index] = model.kalman_slope;
   CalcAbsoluteError[index] = validation.absolute_error;
   CalcCoverage[index] = validation.coverage_hit;
   CalcConformalRadius[index] = model.interval_radius;
   CalcPacf[index] = feature.pacf2;
   CalcSafeModeScore[index] = adaptive.safe_mode_score;
   CalcStressScore[index] = adaptive.stress_score;
   CalcForecastH2[index] = DSA_ProjectForecastPath(model.central_forecast,model.kalman_slope,2);
   CalcForecastH4[index] = DSA_ProjectForecastPath(model.central_forecast,model.kalman_slope,4);
   CalcForecastH8[index] = DSA_ProjectForecastPath(model.central_forecast,model.kalman_slope,8);
   CalcHorizonGrowth[index] = model.horizon_growth;
   CalcRidgeState[index] = model.ridge_forecast;
   CalcBarFingerprint[index] = DSA_BarRevisionFingerprint(index,rates_total,time,open,high,low,close,tick_volume,spread);

   if(live_bar && adaptive.recalibration_required && RuntimeState.build_complete)
   {
      DSA_CoalesceTrigger(RuntimeState,adaptive.reason_mask);
      DSA_StartAdaptiveJob(AdaptiveJob,RuntimeState,adaptive.reason_mask);
   }

   BufferAdaptiveTrend[index] = model.ensemble_state;
   BufferSignal[index] = model.holt_level;
   BufferUpperBand[index] = model.ensemble_state + model.band_radius;
   BufferLowerBand[index] = model.ensemble_state - model.band_radius;
   BufferUncertaintyUpper[index] = model.central_forecast + model.interval_radius;
   BufferUncertaintyLower[index] = model.central_forecast - model.interval_radius;
   BufferRegimeColor[index] = (double)model.regime;

   if(!InputContract.historical_display && !live_bar)
   {
      BufferAdaptiveTrend[index] = EMPTY_VALUE;
      BufferSignal[index] = EMPTY_VALUE;
      BufferUpperBand[index] = EMPTY_VALUE;
      BufferLowerBand[index] = EMPTY_VALUE;
      BufferUncertaintyUpper[index] = EMPTY_VALUE;
      BufferUncertaintyLower[index] = EMPTY_VALUE;
   }

   if(InputContract.event_display)
   {
      BufferHistoricalUp[index] = (event.up_pressure ? event.up_price : EMPTY_VALUE);
      BufferHistoricalDown[index] = (event.down_pressure ? event.down_price : EMPTY_VALUE);
      BufferAuxiliaryEvent[index] = (event.auxiliary_event ? event.auxiliary_price : EMPTY_VALUE);
   }
   else
   {
      BufferHistoricalUp[index] = EMPTY_VALUE;
      BufferHistoricalDown[index] = EMPTY_VALUE;
      BufferAuxiliaryEvent[index] = EMPTY_VALUE;
   }
}

void DSA_ProcessHistoricalSlice(const int rates_total,
                                const datetime &time[],
                                const double &open[],
                                const double &high[],
                                const double &low[],
                                const double &close[],
                                const long &tick_volume[],
                                const int &spread[])
{
   if(rates_total < 2)
      return;

   int cursor = RuntimeState.build_cursor;
   if(cursor < 1 || cursor >= rates_total)
      cursor = rates_total - 1;

   const int budget = DSA_WorkBudgetBars(RuntimeState,rates_total);
   int processed = 0;

   while(cursor >= 1 && processed < budget)
   {
      DSA_ProcessBar(cursor,rates_total,false,time,open,high,low,close,tick_volume,spread);
      --cursor;
      ++processed;
   }

   RuntimeState.build_cursor = cursor;
   RuntimeState.processed_count += processed;

   if(RuntimeState.build_cursor < 1)
      DSA_MarkBuildComplete(RuntimeState);
}

bool DSA_AuditHistoricalRevisionSlice(const int rates_total,
                                      const string history_fingerprint,
                                      const datetime &time[],
                                      const double &open[],
                                      const double &high[],
                                      const double &low[],
                                      const double &close[],
                                      const long &tick_volume[],
                                      const int &spread[])
{
   if(!RuntimeState.build_complete || RuntimeState.rebuild_pending || rates_total < 3)
      return false;
   if(RuntimeState.runtime_load > 0.90)
      return false;

   int cursor = RuntimeState.history_audit_cursor;
   if(cursor < 1 || cursor >= rates_total)
      cursor = rates_total - 1;

   int budget = DSA_WorkBudgetBars(RuntimeState,rates_total) / 12;
   if(budget < 8)
      budget = 8;
   if(budget > 128)
      budget = 128;

   int checked = 0;
   while(cursor >= 1 && checked < budget)
   {
      const double stored = CalcBarFingerprint[cursor];
      if(DSA_HasValue(stored))
      {
         const double current = DSA_BarRevisionFingerprint(cursor,rates_total,time,open,high,low,close,tick_volume,spread);
         if(MathAbs(stored - current) > 0.5)
         {
            DSA_CoalesceTrigger(RuntimeState,DSA_REASON_HISTORY_REVISION);
            DSA_ResetBuffers();
            DSA_StartProgressiveBuild(RuntimeState,rates_total,InputContract.fingerprint,history_fingerprint);
            return true;
         }
      }

      --cursor;
      ++checked;
   }

   if(cursor < 1)
      cursor = rates_total - 1;
   RuntimeState.history_audit_cursor = cursor;
   return false;
}

void DSA_ProcessLivePath(const int rates_total,
                         const datetime &time[],
                         const double &open[],
                         const double &high[],
                         const double &low[],
                         const double &close[],
                         const long &tick_volume[],
                         const int &spread[])
{
   if(rates_total < 1)
      return;

   DSA_ProcessBar(0,rates_total,true,time,open,high,low,close,tick_volume,spread);

   DSA_RenderForecastObjects(InputContract,
                             time[0],
                             CalcTarget[0],
                             CalcForecast[0],
                             BufferUncertaintyLower[0],
                             BufferUncertaintyUpper[0],
                             CalcSlope[0],
                             MathMax(BufferUncertaintyUpper[0] - CalcForecast[0],_Point),
                             MathMax(CalcHorizonGrowth[0],1.0),
                             CalcModelScore[0],
                             RuntimeState.runtime_load);
}

int OnInit()
{
   if(!DSA_MapBuffers())
      return INIT_FAILED;

   DSA_SetPlotDefaults();
   DSA_RuntimeInit(RuntimeState);
   DSA_InitAdaptiveTuning(AdaptiveTuning);
   DSA_InitAdaptiveJob(AdaptiveJob);
   DSA_DeleteChartObjectsByPrefix(DSA_OBJECT_PREFIX);
   return INIT_SUCCEEDED;
}

void OnDeinit(const int reason)
{
   DSA_DeleteChartObjectsByPrefix(DSA_OBJECT_PREFIX);
}

int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
{
   if(rates_total < 3)
      return 0;

   ArraySetAsSeries(time,true);
   ArraySetAsSeries(open,true);
   ArraySetAsSeries(high,true);
   ArraySetAsSeries(low,true);
   ArraySetAsSeries(close,true);
   ArraySetAsSeries(tick_volume,true);
   ArraySetAsSeries(volume,true);
   ArraySetAsSeries(spread,true);

   const ulong started = GetMicrosecondCount();
   DSA_RuntimeBeginTick(RuntimeState);

   DSA_BuildInputContract(InputContract,InpSymbol,InpSelectionData,InpChartTimeframe,
                          InpAnalysisTimeframe,InpFutureForecastRange,InpModelMode,
                          InpHistoricalAnalysis,InpForecastDisplay,InpEventDisplay,InpVisualDetail);

   const string history_fingerprint = DSA_HistoryFingerprint(rates_total,time);
   const bool input_changed = (RuntimeState.input_fingerprint != "" && RuntimeState.input_fingerprint != InputContract.fingerprint);
   const bool history_changed = (prev_calculated == 0 || RuntimeState.history_fingerprint != history_fingerprint);

   if(input_changed)
      DSA_CoalesceTrigger(RuntimeState,DSA_REASON_INPUT_CHANGE);
   if(history_changed)
      DSA_CoalesceTrigger(RuntimeState,DSA_REASON_HISTORY_REVISION);

   if(RuntimeState.rebuild_pending || !RuntimeState.build_complete)
   {
      if(!DSA_CanCommitCandidate(RuntimeState,InputContract.fingerprint,history_fingerprint) ||
         RuntimeState.build_total != rates_total ||
         RuntimeState.build_cursor < 0)
      {
         DSA_ResetBuffers();
         DSA_StartProgressiveBuild(RuntimeState,rates_total,InputContract.fingerprint,history_fingerprint);
      }
      DSA_ProcessHistoricalSlice(rates_total,time,open,high,low,close,tick_volume,spread);
   }
   else if(RuntimeState.last_bar_time != 0 && RuntimeState.last_bar_time != time[0])
   {
      DSA_ProcessBar(1,rates_total,false,time,open,high,low,close,tick_volume,spread);
   }

   DSA_ProcessLivePath(rates_total,time,open,high,low,close,tick_volume,spread);
   const bool revision_detected = DSA_AuditHistoricalRevisionSlice(rates_total,history_fingerprint,
                                                                   time,open,high,low,close,tick_volume,spread);
   if(!revision_detected && RuntimeState.build_complete && RuntimeState.recalibration_pending && RuntimeState.runtime_load < 0.85)
      DSA_ProcessAdaptiveJobSlice(AdaptiveJob,AdaptiveTuning,RuntimeState,rates_total,
                                  CalcAbsoluteError,CalcConformalRadius,
                                  CalcModelScore,CalcDisagreement,CalcStressScore);

   RuntimeState.last_bar_time = time[0];

   DSA_RuntimeEndTick(RuntimeState,started);
   return rates_total;
}
