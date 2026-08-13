#ifndef DSA_VISUAL_RENDERER_MQH
#define DSA_VISUAL_RENDERER_MQH

#include "..\\Events\\EventEngine.mqh"

void DSA_DeleteChartObjectsByPrefix(const string prefix)
{
   const int total = ObjectsTotal(0,0,-1);
   for(int i = total - 1; i >= 0; --i)
   {
      const string name = ObjectName(0,i,0,-1);
      if(StringFind(name,prefix) == 0)
         ObjectDelete(0,name);
   }
}

void DSA_SetObjectLineStyle(const string name,const color line_color,const ENUM_LINE_STYLE style,const int width)
{
   ObjectSetInteger(0,name,OBJPROP_COLOR,line_color);
   ObjectSetInteger(0,name,OBJPROP_STYLE,style);
   ObjectSetInteger(0,name,OBJPROP_WIDTH,width);
   ObjectSetInteger(0,name,OBJPROP_SELECTABLE,false);
   ObjectSetInteger(0,name,OBJPROP_HIDDEN,true);
   ObjectSetInteger(0,name,OBJPROP_BACK,false);
}

void DSA_CreateOrMoveTrend(const string name,
                           const datetime time1,
                           const double price1,
                           const datetime time2,
                           const double price2,
                           const color line_color,
                           const ENUM_LINE_STYLE style,
                           const int width)
{
   if(ObjectFind(0,name) < 0)
      ObjectCreate(0,name,OBJ_TREND,0,time1,price1,time2,price2);
   else
   {
      ObjectMove(0,name,0,time1,price1);
      ObjectMove(0,name,1,time2,price2);
   }

   ObjectSetInteger(0,name,OBJPROP_RAY_RIGHT,false);
   DSA_SetObjectLineStyle(name,line_color,style,width);
}

void DSA_CreateOrMoveRectangle(const string name,
                               const datetime time1,
                               const double price1,
                               const datetime time2,
                               const double price2,
                               const color rect_color)
{
   if(ObjectFind(0,name) < 0)
      ObjectCreate(0,name,OBJ_RECTANGLE,0,time1,price1,time2,price2);
   else
   {
      ObjectMove(0,name,0,time1,price1);
      ObjectMove(0,name,1,time2,price2);
   }

   ObjectSetInteger(0,name,OBJPROP_COLOR,rect_color);
   ObjectSetInteger(0,name,OBJPROP_FILL,true);
   ObjectSetInteger(0,name,OBJPROP_BACK,true);
   ObjectSetInteger(0,name,OBJPROP_SELECTABLE,false);
   ObjectSetInteger(0,name,OBJPROP_HIDDEN,true);
}

void DSA_RenderForecastObjects(DSAInputContract &contract,
                               const datetime origin_time,
                               const double origin_price,
                               const double forecast,
                               const double lower,
                               const double upper,
                               const double slope,
                               const double interval_radius,
                               const double horizon_growth,
                               const double model_score,
                               const double runtime_load)
{
   if(!contract.forecast_display)
   {
      DSA_DeleteChartObjectsByPrefix(DSA_OBJECT_PREFIX);
      return;
   }

   const int analysis_seconds = DSA_TimeframeSeconds(contract.analysis_timeframe,contract.chart_timeframe);
   int horizon = contract.horizon_bars;
   if(contract.visual_detail == DSA_VISUAL_BASIC)
      horizon = MathMin(horizon,16);
   else
      horizon = MathMin(horizon,48);
   if(runtime_load > 0.80)
      horizon = MathMin(horizon,8);

   const double confidence_scale = DSA_Clamp(model_score / 100.0,0.20,1.0);
   double previous_central = origin_price;
   double previous_lower = lower;
   double previous_upper = upper;
   datetime previous_time = origin_time;
   const double growth = DSA_Clamp(horizon_growth,1.0,2.50);

   for(int h = 1; h <= horizon; ++h)
   {
      const datetime next_time = (datetime)(origin_time + h * analysis_seconds);
      const double central = DSA_ProjectForecastPath(forecast,slope,h);
      const double horizon_weight = (horizon <= 1 ? 0.0 : (double)(h - 1) / (double)(horizon - 1));
      const double calibrated_horizon_scale = 1.0 + horizon_weight * (growth - 1.0);
      const double radius = MathMax(interval_radius *
                                    MathSqrt((double)MathMax(h,1)) *
                                    calibrated_horizon_scale *
                                    (1.15 - 0.35 * confidence_scale),
                                    _Point);
      const double next_lower = central - radius;
      const double next_upper = central + radius;

      const string suffix = IntegerToString(h);
      DSA_CreateOrMoveTrend(DSA_OBJECT_PREFIX + "fc_" + suffix,previous_time,previous_central,next_time,central,clrDeepSkyBlue,STYLE_DOT,2);
      DSA_CreateOrMoveTrend(DSA_OBJECT_PREFIX + "lo_" + suffix,previous_time,previous_lower,next_time,next_lower,clrSilver,STYLE_DASH,1);
      DSA_CreateOrMoveTrend(DSA_OBJECT_PREFIX + "up_" + suffix,previous_time,previous_upper,next_time,next_upper,clrSilver,STYLE_DASH,1);

      if(contract.visual_detail == DSA_VISUAL_FULL)
      {
         const double previous_mid_lower = 0.5 * (previous_central + previous_lower);
         const double previous_mid_upper = 0.5 * (previous_central + previous_upper);
         const double mid_lower = 0.5 * (central + next_lower);
         const double mid_upper = 0.5 * (central + next_upper);
         DSA_CreateOrMoveTrend(DSA_OBJECT_PREFIX + "sc_lo_" + suffix,previous_time,previous_mid_lower,next_time,mid_lower,clrLightSteelBlue,STYLE_DOT,1);
         DSA_CreateOrMoveTrend(DSA_OBJECT_PREFIX + "sc_up_" + suffix,previous_time,previous_mid_upper,next_time,mid_upper,clrLightSteelBlue,STYLE_DOT,1);
      }
      else
      {
         ObjectDelete(0,DSA_OBJECT_PREFIX + "sc_lo_" + suffix);
         ObjectDelete(0,DSA_OBJECT_PREFIX + "sc_up_" + suffix);
      }

      previous_time = next_time;
      previous_central = central;
      previous_lower = next_lower;
      previous_upper = next_upper;
   }

   for(int stale = horizon + 1; stale <= 48; ++stale)
   {
      const string suffix = IntegerToString(stale);
      ObjectDelete(0,DSA_OBJECT_PREFIX + "fc_" + suffix);
      ObjectDelete(0,DSA_OBJECT_PREFIX + "lo_" + suffix);
      ObjectDelete(0,DSA_OBJECT_PREFIX + "up_" + suffix);
      ObjectDelete(0,DSA_OBJECT_PREFIX + "sc_lo_" + suffix);
      ObjectDelete(0,DSA_OBJECT_PREFIX + "sc_up_" + suffix);
   }

   const datetime end_time = (datetime)(origin_time + horizon * analysis_seconds);
   DSA_CreateOrMoveRectangle(DSA_OBJECT_PREFIX + "forecast_box",origin_time,upper,end_time,lower,clrSlateGray);
}

#endif
