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
#include "Core\\StateRegistry.mqh"
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

double CandidateBufferAdaptiveTrend[];
double CandidateBufferSignal[];
double CandidateBufferUpperBand[];
double CandidateBufferLowerBand[];
double CandidateBufferUncertaintyUpper[];
double CandidateBufferUncertaintyLower[];
double CandidateBufferRegimeColor[];
double CandidateBufferHistoricalUp[];
double CandidateBufferHistoricalDown[];
double CandidateBufferAuxiliaryEvent[];

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

double CandidateCalcTarget[];
double CandidateCalcForecast[];
double CandidateCalcQuality[];
double CandidateCalcModelScore[];
double CandidateCalcDisagreement[];
double CandidateCalcDrift[];
double CandidateCalcVolatility[];
double CandidateCalcSlope[];
double CandidateCalcAbsoluteError[];
double CandidateCalcCoverage[];
double CandidateCalcConformalRadius[];
double CandidateCalcPacf[];
double CandidateCalcSafeModeScore[];
double CandidateCalcStressScore[];
double CandidateCalcForecastH2[];
double CandidateCalcForecastH4[];
double CandidateCalcForecastH8[];
double CandidateCalcHorizonGrowth[];
double CandidateCalcRidgeState[];
double CandidateCalcBarFingerprint[];

DSARuntimeSchedulerState RuntimeState;
DSAInputContract InputContract;
DSAAdaptiveTuningState AdaptiveTuning;
DSAAdaptiveJobState AdaptiveJob;
DSAClosedState ClosedState;
DSALiveState LiveState;
bool DSA_RetainedOutputAvailable = false;
bool DSA_CandidateBuildActive = false;
bool DSA_CandidateRejected = false;
string DSA_CandidateInputFingerprint = "";
string DSA_CandidateHistoryFingerprint = "";
int DSA_CandidateBuildTotal = 0;
long DSA_CandidateStateVersion = 0;

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
   DSA_RetainedOutputAvailable = false;
   DSA_CandidateBuildActive = false;
   DSA_CandidateRejected = false;
   DSA_CandidateInputFingerprint = "";
   DSA_CandidateHistoryFingerprint = "";
   DSA_CandidateBuildTotal = 0;
   DSA_CandidateStateVersion = 0;
   DSA_ResetClosedState(ClosedState);
   DSA_ResetLiveState(LiveState);
}

void DSA_SetCandidateSeries()
{
   ArraySetAsSeries(CandidateBufferAdaptiveTrend,true);
   ArraySetAsSeries(CandidateBufferSignal,true);
   ArraySetAsSeries(CandidateBufferUpperBand,true);
   ArraySetAsSeries(CandidateBufferLowerBand,true);
   ArraySetAsSeries(CandidateBufferUncertaintyUpper,true);
   ArraySetAsSeries(CandidateBufferUncertaintyLower,true);
   ArraySetAsSeries(CandidateBufferRegimeColor,true);
   ArraySetAsSeries(CandidateBufferHistoricalUp,true);
   ArraySetAsSeries(CandidateBufferHistoricalDown,true);
   ArraySetAsSeries(CandidateBufferAuxiliaryEvent,true);
   ArraySetAsSeries(CandidateCalcTarget,true);
   ArraySetAsSeries(CandidateCalcForecast,true);
   ArraySetAsSeries(CandidateCalcQuality,true);
   ArraySetAsSeries(CandidateCalcModelScore,true);
   ArraySetAsSeries(CandidateCalcDisagreement,true);
   ArraySetAsSeries(CandidateCalcDrift,true);
   ArraySetAsSeries(CandidateCalcVolatility,true);
   ArraySetAsSeries(CandidateCalcSlope,true);
   ArraySetAsSeries(CandidateCalcAbsoluteError,true);
   ArraySetAsSeries(CandidateCalcCoverage,true);
   ArraySetAsSeries(CandidateCalcConformalRadius,true);
   ArraySetAsSeries(CandidateCalcPacf,true);
   ArraySetAsSeries(CandidateCalcSafeModeScore,true);
   ArraySetAsSeries(CandidateCalcStressScore,true);
   ArraySetAsSeries(CandidateCalcForecastH2,true);
   ArraySetAsSeries(CandidateCalcForecastH4,true);
   ArraySetAsSeries(CandidateCalcForecastH8,true);
   ArraySetAsSeries(CandidateCalcHorizonGrowth,true);
   ArraySetAsSeries(CandidateCalcRidgeState,true);
   ArraySetAsSeries(CandidateCalcBarFingerprint,true);
}

bool DSA_ResizeCandidateBuffers(const int rates_total)
{
   bool ok = true;
   ok = ok && (ArrayResize(CandidateBufferAdaptiveTrend,rates_total) == rates_total);
   ok = ok && (ArrayResize(CandidateBufferSignal,rates_total) == rates_total);
   ok = ok && (ArrayResize(CandidateBufferUpperBand,rates_total) == rates_total);
   ok = ok && (ArrayResize(CandidateBufferLowerBand,rates_total) == rates_total);
   ok = ok && (ArrayResize(CandidateBufferUncertaintyUpper,rates_total) == rates_total);
   ok = ok && (ArrayResize(CandidateBufferUncertaintyLower,rates_total) == rates_total);
   ok = ok && (ArrayResize(CandidateBufferRegimeColor,rates_total) == rates_total);
   ok = ok && (ArrayResize(CandidateBufferHistoricalUp,rates_total) == rates_total);
   ok = ok && (ArrayResize(CandidateBufferHistoricalDown,rates_total) == rates_total);
   ok = ok && (ArrayResize(CandidateBufferAuxiliaryEvent,rates_total) == rates_total);
   ok = ok && (ArrayResize(CandidateCalcTarget,rates_total) == rates_total);
   ok = ok && (ArrayResize(CandidateCalcForecast,rates_total) == rates_total);
   ok = ok && (ArrayResize(CandidateCalcQuality,rates_total) == rates_total);
   ok = ok && (ArrayResize(CandidateCalcModelScore,rates_total) == rates_total);
   ok = ok && (ArrayResize(CandidateCalcDisagreement,rates_total) == rates_total);
   ok = ok && (ArrayResize(CandidateCalcDrift,rates_total) == rates_total);
   ok = ok && (ArrayResize(CandidateCalcVolatility,rates_total) == rates_total);
   ok = ok && (ArrayResize(CandidateCalcSlope,rates_total) == rates_total);
   ok = ok && (ArrayResize(CandidateCalcAbsoluteError,rates_total) == rates_total);
   ok = ok && (ArrayResize(CandidateCalcCoverage,rates_total) == rates_total);
   ok = ok && (ArrayResize(CandidateCalcConformalRadius,rates_total) == rates_total);
   ok = ok && (ArrayResize(CandidateCalcPacf,rates_total) == rates_total);
   ok = ok && (ArrayResize(CandidateCalcSafeModeScore,rates_total) == rates_total);
   ok = ok && (ArrayResize(CandidateCalcStressScore,rates_total) == rates_total);
   ok = ok && (ArrayResize(CandidateCalcForecastH2,rates_total) == rates_total);
   ok = ok && (ArrayResize(CandidateCalcForecastH4,rates_total) == rates_total);
   ok = ok && (ArrayResize(CandidateCalcForecastH8,rates_total) == rates_total);
   ok = ok && (ArrayResize(CandidateCalcHorizonGrowth,rates_total) == rates_total);
   ok = ok && (ArrayResize(CandidateCalcRidgeState,rates_total) == rates_total);
   ok = ok && (ArrayResize(CandidateCalcBarFingerprint,rates_total) == rates_total);
   if(ok)
      DSA_SetCandidateSeries();
   return ok;
}

void DSA_ResetCandidateBuffers()
{
   ArrayInitialize(CandidateBufferAdaptiveTrend,EMPTY_VALUE);
   ArrayInitialize(CandidateBufferSignal,EMPTY_VALUE);
   ArrayInitialize(CandidateBufferUpperBand,EMPTY_VALUE);
   ArrayInitialize(CandidateBufferLowerBand,EMPTY_VALUE);
   ArrayInitialize(CandidateBufferUncertaintyUpper,EMPTY_VALUE);
   ArrayInitialize(CandidateBufferUncertaintyLower,EMPTY_VALUE);
   ArrayInitialize(CandidateBufferRegimeColor,EMPTY_VALUE);
   ArrayInitialize(CandidateBufferHistoricalUp,EMPTY_VALUE);
   ArrayInitialize(CandidateBufferHistoricalDown,EMPTY_VALUE);
   ArrayInitialize(CandidateBufferAuxiliaryEvent,EMPTY_VALUE);
   ArrayInitialize(CandidateCalcTarget,EMPTY_VALUE);
   ArrayInitialize(CandidateCalcForecast,EMPTY_VALUE);
   ArrayInitialize(CandidateCalcQuality,EMPTY_VALUE);
   ArrayInitialize(CandidateCalcModelScore,EMPTY_VALUE);
   ArrayInitialize(CandidateCalcDisagreement,EMPTY_VALUE);
   ArrayInitialize(CandidateCalcDrift,EMPTY_VALUE);
   ArrayInitialize(CandidateCalcVolatility,EMPTY_VALUE);
   ArrayInitialize(CandidateCalcSlope,EMPTY_VALUE);
   ArrayInitialize(CandidateCalcAbsoluteError,EMPTY_VALUE);
   ArrayInitialize(CandidateCalcCoverage,EMPTY_VALUE);
   ArrayInitialize(CandidateCalcConformalRadius,EMPTY_VALUE);
   ArrayInitialize(CandidateCalcPacf,EMPTY_VALUE);
   ArrayInitialize(CandidateCalcSafeModeScore,EMPTY_VALUE);
   ArrayInitialize(CandidateCalcStressScore,EMPTY_VALUE);
   ArrayInitialize(CandidateCalcForecastH2,EMPTY_VALUE);
   ArrayInitialize(CandidateCalcForecastH4,EMPTY_VALUE);
   ArrayInitialize(CandidateCalcForecastH8,EMPTY_VALUE);
   ArrayInitialize(CandidateCalcHorizonGrowth,EMPTY_VALUE);
   ArrayInitialize(CandidateCalcRidgeState,EMPTY_VALUE);
   ArrayInitialize(CandidateCalcBarFingerprint,EMPTY_VALUE);
}

void DSA_ClearCandidateBuild()
{
   DSA_CandidateBuildActive = false;
   DSA_CandidateInputFingerprint = "";
   DSA_CandidateHistoryFingerprint = "";
   DSA_CandidateBuildTotal = 0;
   DSA_CandidateStateVersion = 0;
}

void DSA_StampCandidateBuild(const int rates_total)
{
   DSA_CandidateRejected = false;
   DSA_CandidateInputFingerprint = RuntimeState.input_fingerprint;
   DSA_CandidateHistoryFingerprint = RuntimeState.history_fingerprint;
   DSA_CandidateBuildTotal = rates_total;
   DSA_CandidateStateVersion = RuntimeState.active_state_version;
}

bool DSA_CandidateBuildMatches(const int rates_total)
{
   return (DSA_CandidateBuildActive &&
           DSA_CandidateInputFingerprint == RuntimeState.input_fingerprint &&
           DSA_CandidateHistoryFingerprint == RuntimeState.history_fingerprint &&
           DSA_CandidateBuildTotal == rates_total &&
           DSA_CandidateStateVersion == RuntimeState.active_state_version);
}

bool DSA_CommitClosedStateFromMainBuffers(const int index,
                                          const datetime &time[],
                                          const string transition)
{
   return DSA_CommitClosedStateFromBuffers(ClosedState,index,time,
                                          CalcTarget,CalcForecast,
                                          BufferAdaptiveTrend,BufferSignal,
                                          BufferUpperBand,BufferLowerBand,
                                          BufferUncertaintyUpper,BufferUncertaintyLower,
                                          BufferRegimeColor,CalcQuality,CalcModelScore,
                                          CalcDrift,CalcVolatility,CalcSlope,
                                          CalcSafeModeScore,CalcStressScore,CalcBarFingerprint,
                                          RuntimeState.active_state_version,transition);
}

void DSA_BeginLiveStateFromClosed(const datetime live_bar_time)
{
   DSA_BeginLiveState(LiveState,ClosedState,live_bar_time,RuntimeState.active_state_version);
}

bool DSA_CaptureLiveStateFromMainBuffers(const int index,const datetime &time[])
{
   return DSA_CaptureLiveStateFromBuffers(LiveState,index,time,
                                         CalcTarget,CalcForecast,
                                         BufferAdaptiveTrend,BufferSignal,
                                         BufferUpperBand,BufferLowerBand,
                                         BufferUncertaintyUpper,BufferUncertaintyLower,
                                         BufferRegimeColor,CalcQuality,CalcModelScore,
                                         CalcDrift,CalcVolatility,CalcSlope,
                                         CalcSafeModeScore,CalcStressScore,CalcBarFingerprint,
                                         RuntimeState.active_state_version);
}

bool DSA_HasRetainedOutput()
{
   return (DSA_RetainedOutputAvailable &&
           ArraySize(BufferAdaptiveTrend) > 0 &&
           DSA_HasValue(BufferAdaptiveTrend[0]));
}

void DSA_PrepareBackgroundBuild(const int rates_total,const string history_fingerprint)
{
   if(!(RuntimeState.rebuild_pending || !RuntimeState.build_complete))
      return;

   const bool build_in_progress_matches = DSA_BuildInProgressMatches(RuntimeState,rates_total,InputContract.fingerprint,history_fingerprint);
   if(build_in_progress_matches && !DSA_CandidateRejected &&
      (!DSA_CandidateBuildActive || DSA_CandidateBuildMatches(rates_total)))
      return;

   const bool retained_output = DSA_HasRetainedOutput();
   DSA_CandidateBuildActive = retained_output;
   if(DSA_CandidateBuildActive)
   {
      if(!DSA_ResizeCandidateBuffers(rates_total))
      {
         DSA_CandidateBuildActive = false;
         DSA_ResetBuffers();
      }
      else
         DSA_ResetCandidateBuffers();
   }
   else
      DSA_ResetBuffers();

   DSA_StartProgressiveBuild(RuntimeState,rates_total,InputContract.fingerprint,history_fingerprint);
   if(DSA_CandidateBuildActive)
      DSA_StampCandidateBuild(rates_total);
   else
   {
      DSA_ClearCandidateBuild();
      DSA_CandidateRejected = false;
   }
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
                    const int &spread[],
                    const bool analysis_bar_commit=false)
{
   DSA_ProcessBarInto(index,rates_total,live_bar,time,open,high,low,close,tick_volume,spread,
                      BufferAdaptiveTrend,BufferSignal,BufferUpperBand,BufferLowerBand,
                      BufferUncertaintyUpper,BufferUncertaintyLower,BufferRegimeColor,
                      BufferHistoricalUp,BufferHistoricalDown,BufferAuxiliaryEvent,
                      CalcTarget,CalcForecast,CalcQuality,CalcModelScore,CalcDisagreement,
                      CalcDrift,CalcVolatility,CalcSlope,CalcAbsoluteError,CalcCoverage,
                      CalcConformalRadius,CalcPacf,CalcSafeModeScore,CalcStressScore,
                      CalcForecastH2,CalcForecastH4,CalcForecastH8,CalcHorizonGrowth,
                      CalcRidgeState,CalcBarFingerprint,analysis_bar_commit);
}

void DSA_ProcessBarInto(const int index,
                        const int rates_total,
                        const bool live_bar,
                        const datetime &time[],
                        const double &open[],
                        const double &high[],
                        const double &low[],
                        const double &close[],
                        const long &tick_volume[],
                        const int &spread[],
                        double &trend_buffer[],
                        double &signal_buffer[],
                        double &upper_band_buffer[],
                        double &lower_band_buffer[],
                        double &uncertainty_upper_buffer[],
                        double &uncertainty_lower_buffer[],
                        double &regime_buffer[],
                        double &up_event_buffer[],
                        double &down_event_buffer[],
                        double &aux_event_buffer[],
                        double &target_buffer[],
                        double &forecast_buffer[],
                        double &quality_buffer[],
                        double &model_score_buffer[],
                        double &disagreement_buffer[],
                        double &drift_buffer[],
                        double &volatility_buffer[],
                        double &slope_buffer[],
                        double &absolute_error_buffer[],
                        double &coverage_buffer[],
                        double &conformal_radius_buffer[],
                        double &pacf_buffer[],
                        double &safe_mode_buffer[],
                        double &stress_buffer[],
                        double &forecast_h2_buffer[],
                        double &forecast_h4_buffer[],
                        double &forecast_h8_buffer[],
                        double &horizon_growth_buffer[],
                        double &ridge_state_buffer[],
                        double &bar_fingerprint_buffer[],
                        const bool analysis_bar_commit=false)
{
   DSAFeatureSnapshot feature;
   DSAModelSnapshot model;
   DSAValidationSnapshot validation;
   DSAEventSnapshot event;
   DSAAdaptiveSnapshot adaptive;

   DSA_BuildFeatureSnapshot(index,rates_total,InputContract,time,open,high,low,close,tick_volume,spread,
                            live_bar,target_buffer,trend_buffer,slope_buffer,volatility_buffer,quality_buffer,
                            feature,analysis_bar_commit);

   DSA_ComputeModels(index,rates_total,InputContract,feature,open,high,low,close,
                      target_buffer,trend_buffer,signal_buffer,
                      forecast_buffer,forecast_h2_buffer,forecast_h4_buffer,forecast_h8_buffer,
                      volatility_buffer,quality_buffer,uncertainty_upper_buffer,uncertainty_lower_buffer,
                      absolute_error_buffer,regime_buffer,ridge_state_buffer,
                      AdaptiveTuning.ridge_lambda_scale,AdaptiveTuning.interval_scale,
                      RuntimeState.runtime_load,live_bar,model);

   DSA_ValidatePrequential(index,rates_total,feature,model,target_buffer,forecast_buffer,
                           uncertainty_upper_buffer,uncertainty_lower_buffer,
                           absolute_error_buffer,coverage_buffer,validation);

   DSA_ComputeAdaptiveDiagnostics(feature,model,validation,RuntimeState.runtime_load,adaptive);

   DSA_DetectEvents(index,rates_total,high,low,feature,model,validation,trend_buffer,event);

   target_buffer[index] = feature.target;
   forecast_buffer[index] = model.central_forecast;
   quality_buffer[index] = feature.quality_score;
   model_score_buffer[index] = validation.model_score;
   disagreement_buffer[index] = model.disagreement;
   drift_buffer[index] = validation.drift_score;
   volatility_buffer[index] = feature.volatility;
   slope_buffer[index] = model.kalman_slope;
   absolute_error_buffer[index] = validation.absolute_error;
   coverage_buffer[index] = validation.coverage_hit;
   conformal_radius_buffer[index] = model.interval_radius;
   pacf_buffer[index] = feature.pacf2;
   safe_mode_buffer[index] = adaptive.safe_mode_score;
   stress_buffer[index] = adaptive.stress_score;
   forecast_h2_buffer[index] = DSA_ProjectForecastPath(model.central_forecast,model.kalman_slope,2);
   forecast_h4_buffer[index] = DSA_ProjectForecastPath(model.central_forecast,model.kalman_slope,4);
   forecast_h8_buffer[index] = DSA_ProjectForecastPath(model.central_forecast,model.kalman_slope,8);
   horizon_growth_buffer[index] = model.horizon_growth;
   ridge_state_buffer[index] = model.ridge_forecast;
   bar_fingerprint_buffer[index] = DSA_BarRevisionFingerprint(index,rates_total,time,open,high,low,close,tick_volume,spread);

   if(live_bar && adaptive.recalibration_required && RuntimeState.build_complete)
   {
      DSA_CoalesceTrigger(RuntimeState,adaptive.reason_mask);
      DSA_StartAdaptiveJob(AdaptiveJob,RuntimeState,adaptive.reason_mask);
   }

   trend_buffer[index] = model.ensemble_state;
   signal_buffer[index] = model.holt_level;
   upper_band_buffer[index] = model.ensemble_state + model.band_radius;
   lower_band_buffer[index] = model.ensemble_state - model.band_radius;
   uncertainty_upper_buffer[index] = model.central_forecast + model.interval_radius;
   uncertainty_lower_buffer[index] = model.central_forecast - model.interval_radius;
   regime_buffer[index] = (double)model.regime;

   if(!InputContract.historical_display && !live_bar)
   {
      trend_buffer[index] = EMPTY_VALUE;
      signal_buffer[index] = EMPTY_VALUE;
      upper_band_buffer[index] = EMPTY_VALUE;
      lower_band_buffer[index] = EMPTY_VALUE;
      uncertainty_upper_buffer[index] = EMPTY_VALUE;
      uncertainty_lower_buffer[index] = EMPTY_VALUE;
   }

   if(InputContract.event_display)
   {
      up_event_buffer[index] = (event.up_pressure ? event.up_price : EMPTY_VALUE);
      down_event_buffer[index] = (event.down_pressure ? event.down_price : EMPTY_VALUE);
      aux_event_buffer[index] = (event.auxiliary_event ? event.auxiliary_price : EMPTY_VALUE);
   }
   else
   {
      up_event_buffer[index] = EMPTY_VALUE;
      down_event_buffer[index] = EMPTY_VALUE;
      aux_event_buffer[index] = EMPTY_VALUE;
   }
}

void DSA_ProcessCandidateBar(const int index,
                             const int rates_total,
                             const datetime &time[],
                             const double &open[],
                             const double &high[],
                             const double &low[],
                             const double &close[],
                             const long &tick_volume[],
                             const int &spread[],
                             const bool analysis_bar_commit=false)
{
   DSA_ProcessBarInto(index,rates_total,false,time,open,high,low,close,tick_volume,spread,
                      CandidateBufferAdaptiveTrend,CandidateBufferSignal,
                      CandidateBufferUpperBand,CandidateBufferLowerBand,
                      CandidateBufferUncertaintyUpper,CandidateBufferUncertaintyLower,
                      CandidateBufferRegimeColor,CandidateBufferHistoricalUp,
                      CandidateBufferHistoricalDown,CandidateBufferAuxiliaryEvent,
                      CandidateCalcTarget,CandidateCalcForecast,CandidateCalcQuality,
                      CandidateCalcModelScore,CandidateCalcDisagreement,CandidateCalcDrift,
                      CandidateCalcVolatility,CandidateCalcSlope,CandidateCalcAbsoluteError,
                      CandidateCalcCoverage,CandidateCalcConformalRadius,CandidateCalcPacf,
                      CandidateCalcSafeModeScore,CandidateCalcStressScore,
                      CandidateCalcForecastH2,CandidateCalcForecastH4,CandidateCalcForecastH8,
                      CandidateCalcHorizonGrowth,CandidateCalcRidgeState,CandidateCalcBarFingerprint,
                      analysis_bar_commit);
}

void DSA_ProcessAnalysisCommitBar(const int index,
                                  const int rates_total,
                                  const datetime &time[],
                                  const double &open[],
                                  const double &high[],
                                  const double &low[],
                                  const double &close[],
                                  const long &tick_volume[],
                                  const int &spread[])
{
   DSA_ProcessBarInto(index,rates_total,false,time,open,high,low,close,tick_volume,spread,
                      BufferAdaptiveTrend,BufferSignal,BufferUpperBand,BufferLowerBand,
                      BufferUncertaintyUpper,BufferUncertaintyLower,BufferRegimeColor,
                      BufferHistoricalUp,BufferHistoricalDown,BufferAuxiliaryEvent,
                      CalcTarget,CalcForecast,CalcQuality,CalcModelScore,CalcDisagreement,
                      CalcDrift,CalcVolatility,CalcSlope,CalcAbsoluteError,CalcCoverage,
                      CalcConformalRadius,CalcPacf,CalcSafeModeScore,CalcStressScore,
                      CalcForecastH2,CalcForecastH4,CalcForecastH8,CalcHorizonGrowth,
                      CalcRidgeState,CalcBarFingerprint,true);
   DSA_CommitClosedStateFromMainBuffers(index,time,"analysis_commit");
}

void DSA_HoldClosedAnalysisState(const int index,
                                 const int rates_total,
                                 const datetime &time[],
                                 const double &open[],
                                 const double &high[],
                                 const double &low[],
                                 const double &close[],
                                 const long &tick_volume[],
                                 const int &spread[])
{
   if(index < 1 || index + 1 >= rates_total)
      return;

   const int source = index + 1;
   BufferAdaptiveTrend[index] = BufferAdaptiveTrend[source];
   BufferSignal[index] = BufferSignal[source];
   BufferUpperBand[index] = BufferUpperBand[source];
   BufferLowerBand[index] = BufferLowerBand[source];
   BufferUncertaintyUpper[index] = BufferUncertaintyUpper[source];
   BufferUncertaintyLower[index] = BufferUncertaintyLower[source];
   BufferRegimeColor[index] = BufferRegimeColor[source];
   BufferHistoricalUp[index] = BufferHistoricalUp[source];
   BufferHistoricalDown[index] = BufferHistoricalDown[source];
   BufferAuxiliaryEvent[index] = BufferAuxiliaryEvent[source];
   CalcTarget[index] = CalcTarget[source];
   CalcForecast[index] = CalcForecast[source];
   CalcQuality[index] = CalcQuality[source];
   CalcModelScore[index] = CalcModelScore[source];
   CalcDisagreement[index] = CalcDisagreement[source];
   CalcDrift[index] = CalcDrift[source];
   CalcVolatility[index] = CalcVolatility[source];
   CalcSlope[index] = CalcSlope[source];
   CalcAbsoluteError[index] = CalcAbsoluteError[source];
   CalcCoverage[index] = CalcCoverage[source];
   CalcConformalRadius[index] = CalcConformalRadius[source];
   CalcPacf[index] = CalcPacf[source];
   CalcSafeModeScore[index] = CalcSafeModeScore[source];
   CalcStressScore[index] = CalcStressScore[source];
   CalcForecastH2[index] = CalcForecastH2[source];
   CalcForecastH4[index] = CalcForecastH4[source];
   CalcForecastH8[index] = CalcForecastH8[source];
   CalcHorizonGrowth[index] = CalcHorizonGrowth[source];
   CalcRidgeState[index] = CalcRidgeState[source];
   CalcBarFingerprint[index] = DSA_BarRevisionFingerprint(index,rates_total,time,open,high,low,close,tick_volume,spread);
   DSA_CommitClosedStateFromMainBuffers(index,time,"analysis_hold");
}

void DSA_CommitCandidateBuffers(const int rates_total)
{
   const int total = MathMin(rates_total,ArraySize(CandidateCalcTarget));
   for(int index = total - 1; index >= 1; --index)
   {
      BufferAdaptiveTrend[index] = CandidateBufferAdaptiveTrend[index];
      BufferSignal[index] = CandidateBufferSignal[index];
      BufferUpperBand[index] = CandidateBufferUpperBand[index];
      BufferLowerBand[index] = CandidateBufferLowerBand[index];
      BufferUncertaintyUpper[index] = CandidateBufferUncertaintyUpper[index];
      BufferUncertaintyLower[index] = CandidateBufferUncertaintyLower[index];
      BufferRegimeColor[index] = CandidateBufferRegimeColor[index];
      BufferHistoricalUp[index] = CandidateBufferHistoricalUp[index];
      BufferHistoricalDown[index] = CandidateBufferHistoricalDown[index];
      BufferAuxiliaryEvent[index] = CandidateBufferAuxiliaryEvent[index];
      CalcTarget[index] = CandidateCalcTarget[index];
      CalcForecast[index] = CandidateCalcForecast[index];
      CalcQuality[index] = CandidateCalcQuality[index];
      CalcModelScore[index] = CandidateCalcModelScore[index];
      CalcDisagreement[index] = CandidateCalcDisagreement[index];
      CalcDrift[index] = CandidateCalcDrift[index];
      CalcVolatility[index] = CandidateCalcVolatility[index];
      CalcSlope[index] = CandidateCalcSlope[index];
      CalcAbsoluteError[index] = CandidateCalcAbsoluteError[index];
      CalcCoverage[index] = CandidateCalcCoverage[index];
      CalcConformalRadius[index] = CandidateCalcConformalRadius[index];
      CalcPacf[index] = CandidateCalcPacf[index];
      CalcSafeModeScore[index] = CandidateCalcSafeModeScore[index];
      CalcStressScore[index] = CandidateCalcStressScore[index];
      CalcForecastH2[index] = CandidateCalcForecastH2[index];
      CalcForecastH4[index] = CandidateCalcForecastH4[index];
      CalcForecastH8[index] = CandidateCalcForecastH8[index];
      CalcHorizonGrowth[index] = CandidateCalcHorizonGrowth[index];
      CalcRidgeState[index] = CandidateCalcRidgeState[index];
      CalcBarFingerprint[index] = CandidateCalcBarFingerprint[index];
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
      const bool analysis_commit_bar = DSA_IsAnalysisCommitHostBar(InputContract,cursor,rates_total,time);
      if(DSA_CandidateBuildActive)
         DSA_ProcessCandidateBar(cursor,rates_total,time,open,high,low,close,tick_volume,spread,analysis_commit_bar);
      else
         DSA_ProcessBar(cursor,rates_total,false,time,open,high,low,close,tick_volume,spread,analysis_commit_bar);
      --cursor;
      ++processed;
   }

   RuntimeState.build_cursor = cursor;
   RuntimeState.processed_count += processed;

   if(RuntimeState.build_cursor < 1)
   {
      if(DSA_CandidateBuildActive)
      {
         if(!DSA_CandidateBuildMatches(rates_total) ||
            !DSA_FingerprintBufferMatchesCurrent(rates_total,time,open,high,low,close,tick_volume,spread,CandidateCalcBarFingerprint))
         {
            DSA_ClearCandidateBuild();
            DSA_CandidateRejected = true;
            DSA_CoalesceTrigger(RuntimeState,DSA_REASON_HISTORY_REVISION);
            return;
         }

         DSA_CommitCandidateBuffers(rates_total);
         DSA_ClearCandidateBuild();
         DSA_CandidateRejected = false;
      }
      DSA_MarkBuildComplete(RuntimeState);
      DSA_RetainedOutputAvailable = true;
      DSA_CommitClosedStateFromMainBuffers(1,time,"build_complete");
   }
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
            DSA_PrepareBackgroundBuild(rates_total,history_fingerprint);
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

   DSA_BeginLiveStateFromClosed(time[0]);
   DSA_ProcessBar(0,rates_total,true,time,open,high,low,close,tick_volume,spread);
   DSA_CaptureLiveStateFromMainBuffers(0,time);

   const double render_target = (LiveState.frame.valid ? LiveState.frame.target : CalcTarget[0]);
   const double render_forecast = (LiveState.frame.valid ? LiveState.frame.forecast : CalcForecast[0]);
   const double render_lower = (LiveState.frame.valid ? LiveState.frame.uncertainty_lower : BufferUncertaintyLower[0]);
   const double render_upper = (LiveState.frame.valid ? LiveState.frame.uncertainty_upper : BufferUncertaintyUpper[0]);
   const double render_slope = (LiveState.frame.valid ? LiveState.frame.slope : CalcSlope[0]);
   const double render_score = (LiveState.frame.valid ? LiveState.frame.model_score : CalcModelScore[0]);

   DSA_RenderForecastObjects(InputContract,
                              time[0],
                              render_target,
                              render_forecast,
                              render_lower,
                              render_upper,
                              render_slope,
                              MathMax(render_upper - render_forecast,_Point),
                              MathMax(CalcHorizonGrowth[0],1.0),
                              render_score,
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
   DSA_ResetClosedState(ClosedState);
   DSA_ResetLiveState(LiveState);
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

   const string history_fingerprint = DSA_HistoryFingerprint(rates_total,time,open,high,low,close,tick_volume,spread);
   const bool input_changed = (RuntimeState.input_fingerprint != "" && RuntimeState.input_fingerprint != InputContract.fingerprint);
   const bool history_changed = (prev_calculated == 0 || RuntimeState.history_fingerprint != history_fingerprint);

   if(input_changed)
      DSA_CoalesceTrigger(RuntimeState,DSA_REASON_INPUT_CHANGE);
   if(history_changed)
      DSA_CoalesceTrigger(RuntimeState,DSA_REASON_HISTORY_REVISION);

   const bool new_bar = (RuntimeState.last_bar_time != 0 && RuntimeState.last_bar_time != time[0]);
   const datetime current_analysis_bar_time = DSA_CurrentAnalysisBarTime(InputContract,time[0]);
   const bool new_analysis_bar = (RuntimeState.last_analysis_bar_time != 0 &&
                                  current_analysis_bar_time != 0 &&
                                  RuntimeState.last_analysis_bar_time != current_analysis_bar_time);
   const bool medium_path_due = DSA_ShouldRunMediumPath(InputContract,new_bar,new_analysis_bar);

   DSA_PrepareBackgroundBuild(rates_total,history_fingerprint);

   if(medium_path_due && RuntimeState.build_complete && !RuntimeState.rebuild_pending)
      DSA_ProcessAnalysisCommitBar(1,rates_total,time,open,high,low,close,tick_volume,spread);
   else if(new_bar && DSA_UseAnalysisRate(InputContract) && RuntimeState.build_complete && !RuntimeState.rebuild_pending)
      DSA_HoldClosedAnalysisState(1,rates_total,time,open,high,low,close,tick_volume,spread);

   DSA_ProcessLivePath(rates_total,time,open,high,low,close,tick_volume,spread);

   if(RuntimeState.rebuild_pending || !RuntimeState.build_complete)
      DSA_ProcessHistoricalSlice(rates_total,time,open,high,low,close,tick_volume,spread);

   const bool revision_detected = DSA_AuditHistoricalRevisionSlice(rates_total,history_fingerprint,
                                                                   time,open,high,low,close,tick_volume,spread);
   if(!revision_detected && RuntimeState.build_complete && RuntimeState.recalibration_pending && RuntimeState.runtime_load < 0.85)
      DSA_ProcessAdaptiveJobSlice(AdaptiveJob,AdaptiveTuning,RuntimeState,rates_total,
                                  CalcAbsoluteError,CalcConformalRadius,
                                  CalcModelScore,CalcDisagreement,CalcStressScore);

   RuntimeState.last_bar_time = time[0];
   if(current_analysis_bar_time != 0)
      RuntimeState.last_analysis_bar_time = current_analysis_bar_time;

   DSA_RuntimeEndTick(RuntimeState,started);
   return rates_total;
}
