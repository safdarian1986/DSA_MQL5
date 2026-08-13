#ifndef DSA_COMMON_MQH
#define DSA_COMMON_MQH

#define DSA_OBJECT_PREFIX "DSA_MQL5_"

enum ENUM_DSA_STATUS
{
   DSA_STATUS_BUILDING = 0,
   DSA_STATUS_READY = 1,
   DSA_STATUS_ERROR = 2
};

enum ENUM_DSA_REGIME
{
   DSA_REGIME_TREND_UP = 0,
   DSA_REGIME_TREND_DOWN = 1,
   DSA_REGIME_RANGE = 2,
   DSA_REGIME_VOLATILE = 3,
   DSA_REGIME_SHOCK = 4,
   DSA_REGIME_UNCERTAIN = 5
};

double DSA_Clamp(const double value,const double low,const double high)
{
   if(value < low)
      return low;
   if(value > high)
      return high;
   return value;
}

bool DSA_HasValue(const double value)
{
   return (value != EMPTY_VALUE && MathIsValidNumber(value));
}

double DSA_SafeDiv(const double numerator,const double denominator,const double fallback=0.0)
{
   if(MathAbs(denominator) <= DBL_EPSILON)
      return fallback;
   return numerator / denominator;
}

double DSA_Ewma(const double previous,const double value,const double alpha)
{
   const double a = DSA_Clamp(alpha,0.0,1.0);
   if(!DSA_HasValue(previous))
      return value;
   return a * value + (1.0 - a) * previous;
}

double DSA_PositivePrice(const double value,const double fallback)
{
   if(MathIsValidNumber(value) && value > 0.0)
      return value;
   return fallback;
}

int DSA_TimeframeSeconds(const ENUM_TIMEFRAMES timeframe,const ENUM_TIMEFRAMES fallback_timeframe)
{
   int seconds = PeriodSeconds(timeframe);
   if(seconds <= 0)
      seconds = PeriodSeconds(fallback_timeframe);
   if(seconds <= 0)
      seconds = PeriodSeconds(_Period);
   if(seconds <= 0)
      seconds = 60;
   return seconds;
}

string DSA_StatusName(const ENUM_DSA_STATUS status)
{
   if(status == DSA_STATUS_READY)
      return "Ready";
   if(status == DSA_STATUS_ERROR)
      return "Error";
   return "Building";
}

string DSA_RegimeName(const int regime)
{
   switch(regime)
   {
      case DSA_REGIME_TREND_UP:
         return "TREND_UP";
      case DSA_REGIME_TREND_DOWN:
         return "TREND_DOWN";
      case DSA_REGIME_RANGE:
         return "RANGE";
      case DSA_REGIME_VOLATILE:
         return "VOLATILE";
      case DSA_REGIME_SHOCK:
         return "SHOCK";
      default:
         return "UNCERTAIN";
   }
}

color DSA_RegimeColor(const int regime)
{
   switch(regime)
   {
      case DSA_REGIME_TREND_UP:
         return clrLimeGreen;
      case DSA_REGIME_TREND_DOWN:
         return clrTomato;
      case DSA_REGIME_RANGE:
         return clrDodgerBlue;
      case DSA_REGIME_VOLATILE:
         return clrOrange;
      case DSA_REGIME_SHOCK:
         return clrDarkRed;
      default:
         return clrSlateGray;
   }
}

#endif
