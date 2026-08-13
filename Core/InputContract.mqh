#ifndef DSA_INPUT_CONTRACT_MQH
#define DSA_INPUT_CONTRACT_MQH

#include "DSACommon.mqh"

enum ENUM_DSA_SELECTION_DATA
{
   DSA_DATA_OPEN = 0,
   DSA_DATA_HIGH = 1,
   DSA_DATA_LOW = 2,
   DSA_DATA_CLOSE = 3,
   DSA_DATA_OHLC = 4,
   DSA_DATA_HL = 5,
   DSA_DATA_OC = 6
};

enum ENUM_DSA_MODEL_MODE
{
   DSA_MODEL_ADAPTIVE = 0,
   DSA_MODEL_STATISTICAL = 1,
   DSA_MODEL_MACHINE_LEARNING = 2,
   DSA_MODEL_DEEP_LEARNING = 3,
   DSA_MODEL_HYBRID = 4,
   DSA_MODEL_SAFE_MODE = 5
};

enum ENUM_DSA_VISUAL_DETAIL
{
   DSA_VISUAL_BASIC = 0,
   DSA_VISUAL_FULL = 1
};

struct DSAInputContract
{
   string symbol;
   ENUM_TIMEFRAMES chart_timeframe;
   ENUM_TIMEFRAMES analysis_timeframe;
   ENUM_TIMEFRAMES forecast_range;
   ENUM_DSA_SELECTION_DATA selection_data;
   ENUM_DSA_MODEL_MODE model_mode;
   bool historical_display;
   bool forecast_display;
   bool event_display;
   ENUM_DSA_VISUAL_DETAIL visual_detail;
   string fingerprint;
   int horizon_bars;
};

string DSA_SelectionName(const ENUM_DSA_SELECTION_DATA selection_data)
{
   switch(selection_data)
   {
      case DSA_DATA_OPEN:
         return "O";
      case DSA_DATA_HIGH:
         return "H";
      case DSA_DATA_LOW:
         return "L";
      case DSA_DATA_CLOSE:
         return "C";
      case DSA_DATA_HL:
         return "HL";
      case DSA_DATA_OC:
         return "OC";
      default:
         return "OHLC";
   }
}

string DSA_ModelModeName(const ENUM_DSA_MODEL_MODE mode)
{
   switch(mode)
   {
      case DSA_MODEL_STATISTICAL:
         return "Statistical";
      case DSA_MODEL_MACHINE_LEARNING:
         return "MachineLearning";
      case DSA_MODEL_DEEP_LEARNING:
         return "DeepLearning";
      case DSA_MODEL_HYBRID:
         return "Hybrid";
      case DSA_MODEL_SAFE_MODE:
         return "SafeMode";
      default:
         return "Adaptive";
   }
}

int DSA_ForecastHorizonBars(const ENUM_TIMEFRAMES forecast_range,const ENUM_TIMEFRAMES analysis_timeframe)
{
   const int forecast_seconds = DSA_TimeframeSeconds(forecast_range,PERIOD_D1);
   const int analysis_seconds = DSA_TimeframeSeconds(analysis_timeframe,_Period);
   int bars = (int)MathCeil(DSA_SafeDiv((double)forecast_seconds,(double)analysis_seconds,1.0));
   if(bars < 1)
      bars = 1;
   if(bars > 200)
      bars = 200;
   return bars;
}

void DSA_BuildInputContract(DSAInputContract &contract,
                            const string official_symbol_input,
                            const ENUM_DSA_SELECTION_DATA selection_data,
                            const ENUM_TIMEFRAMES chart_timeframe_input,
                            const ENUM_TIMEFRAMES analysis_timeframe_input,
                            const ENUM_TIMEFRAMES forecast_range,
                            const ENUM_DSA_MODEL_MODE model_mode,
                            const bool historical_display,
                            const bool forecast_display,
                            const bool event_display,
                            const ENUM_DSA_VISUAL_DETAIL visual_detail)
{
   contract.symbol = _Symbol;
   contract.chart_timeframe = _Period;
   contract.analysis_timeframe = analysis_timeframe_input;
   if(contract.analysis_timeframe == PERIOD_CURRENT)
      contract.analysis_timeframe = _Period;
   contract.forecast_range = forecast_range;
   contract.selection_data = selection_data;
   contract.model_mode = model_mode;
   contract.historical_display = historical_display;
   contract.forecast_display = forecast_display;
   contract.event_display = event_display;
   contract.visual_detail = visual_detail;
   contract.horizon_bars = DSA_ForecastHorizonBars(contract.forecast_range,contract.analysis_timeframe);

   contract.fingerprint = StringFormat("%s|%d|%d|%d|%d",
                                       DSA_SelectionName(contract.selection_data),
                                       (int)contract.chart_timeframe,
                                       (int)contract.analysis_timeframe,
                                       (int)contract.forecast_range,
                                       (int)contract.model_mode);
}

#endif
