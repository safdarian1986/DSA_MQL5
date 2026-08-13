#property copyright "DSA-MQL5 Native"
#property version   "1.00"
#property tester_indicator "DSA_MQL5_Native.ex5"

#define DSA_CHART_HARNESS_INDICATOR "DSA_MQL5_Native"
#define DSA_CHART_OBJECT_PREFIX "DSA_MQL5_"

#include "..\Events\EventEngine.mqh"

int IndicatorHandle = INVALID_HANDLE;
int HarnessFailures = 0;
bool HarnessFirstReadOk = false;
bool HarnessObjectsSeen = false;
bool HarnessChartAttached = false;
bool HarnessSemanticOk = false;
bool HarnessEventTaxonomyOk = false;
bool HarnessSemanticChecked = false;

int DSA_CountProjectObjects()
{
   int count = 0;
   const int total = ObjectsTotal(0,0,-1);
   for(int index = total - 1; index >= 0; --index)
   {
      const string name = ObjectName(0,index,0,-1);
      if(StringFind(name,DSA_CHART_OBJECT_PREFIX) == 0)
         ++count;
   }
   return count;
}

void DSA_RecordFailure(const string message)
{
   ++HarnessFailures;
   Print("DSA chart-object harness failure: ",message," error=",GetLastError());
}

bool DSA_RequireObjectType(const string name,const ENUM_OBJECT expected_type)
{
   if(ObjectFind(0,name) < 0)
   {
      DSA_RecordFailure("missing object " + name);
      return false;
   }

   const ENUM_OBJECT actual_type = (ENUM_OBJECT)ObjectGetInteger(0,name,OBJPROP_TYPE,0);
   if(actual_type != expected_type)
   {
      DSA_RecordFailure("unexpected object type for " + name);
      return false;
   }

   return true;
}

datetime DSA_ObjectTime(const string name,const int point)
{
   return (datetime)ObjectGetInteger(0,name,OBJPROP_TIME,point);
}

double DSA_ObjectPrice(const string name,const int point)
{
   return ObjectGetDouble(0,name,OBJPROP_PRICE,point);
}

int DSA_ObjectWidth(const string name)
{
   return (int)ObjectGetInteger(0,name,OBJPROP_WIDTH,0);
}

bool DSA_ValidateEventTaxonomy()
{
   const int total = 8;
   double high[];
   double low[];
   double trend[];
   ArrayResize(high,total);
   ArrayResize(low,total);
   ArrayResize(trend,total);
   ArraySetAsSeries(high,true);
   ArraySetAsSeries(low,true);
   ArraySetAsSeries(trend,true);

   for(int i = 0; i < total; ++i)
   {
      high[i] = 110.0 + (double)i;
      low[i] = 100.0 - (double)i;
      trend[i] = 100.0;
   }

   DSAFeatureSnapshot feature;
   DSAModelSnapshot model;
   DSAValidationSnapshot validation;
   DSAEventSnapshot event;
   ZeroMemory(feature);
   ZeroMemory(model);
   ZeroMemory(validation);

   feature.target = 104.0;
   feature.candle_range = 2.0;
   feature.robust_z = 4.2;
   feature.structure_position = 0.96;
   feature.quality_score = 80.0;
   model.regime = DSA_REGIME_SHOCK;
   model.band_radius = 2.0;
   model.interval_radius = 2.0;
   validation.drift_score = 0.45;
   DSA_DetectEvents(1,total,high,low,feature,model,validation,trend,event);
   const bool closed_shock = (event.final_event &&
                              !event.provisional_event &&
                              event.auxiliary_event &&
                              event.event_type == DSA_EVENT_SHOCK &&
                              event.event_strength > 0.0);

   model.regime = DSA_REGIME_TREND_UP;
   feature.target = 112.0;
   feature.robust_z = 0.5;
   feature.structure_position = 0.50;
   validation.drift_score = 0.10;
   DSA_DetectEvents(0,total,high,low,feature,model,validation,trend,event);
   const bool live_trend = (event.provisional_event &&
                            !event.final_event &&
                            event.up_pressure &&
                            event.event_type == DSA_EVENT_TREND_UP &&
                            DSA_HasValue(event.up_price));

   model.regime = DSA_REGIME_RANGE;
   feature.target = 100.0;
   feature.robust_z = 3.8;
   validation.drift_score = 0.10;
   DSA_DetectEvents(2,total,high,low,feature,model,validation,trend,event);
   const bool anomaly = (event.final_event &&
                         event.auxiliary_event &&
                         event.event_type == DSA_EVENT_ANOMALY);

   return (closed_shock && live_trend && anomaly);
}

bool DSA_ValidateForecastObjects()
{
   bool ok = true;
   const int project_count = DSA_CountProjectObjects();
   if(project_count <= 0)
      return false;

   if(project_count > 245)
   {
      DSA_RecordFailure("unbounded project object count");
      ok = false;
   }

   ok = DSA_RequireObjectType(DSA_CHART_OBJECT_PREFIX + "fc_1",OBJ_TREND) && ok;
   ok = DSA_RequireObjectType(DSA_CHART_OBJECT_PREFIX + "lo_1",OBJ_TREND) && ok;
   ok = DSA_RequireObjectType(DSA_CHART_OBJECT_PREFIX + "up_1",OBJ_TREND) && ok;
   ok = DSA_RequireObjectType(DSA_CHART_OBJECT_PREFIX + "forecast_box",OBJ_RECTANGLE) && ok;
   ok = DSA_RequireObjectType(DSA_CHART_OBJECT_PREFIX + "sc_lo_1",OBJ_TREND) && ok;
   ok = DSA_RequireObjectType(DSA_CHART_OBJECT_PREFIX + "sc_up_1",OBJ_TREND) && ok;
   if(!ok)
      return false;

   const datetime fc_t0 = DSA_ObjectTime(DSA_CHART_OBJECT_PREFIX + "fc_1",0);
   const datetime fc_t1 = DSA_ObjectTime(DSA_CHART_OBJECT_PREFIX + "fc_1",1);
   const datetime lo_t1 = DSA_ObjectTime(DSA_CHART_OBJECT_PREFIX + "lo_1",1);
   const datetime up_t1 = DSA_ObjectTime(DSA_CHART_OBJECT_PREFIX + "up_1",1);
   const datetime box_t0 = DSA_ObjectTime(DSA_CHART_OBJECT_PREFIX + "forecast_box",0);
   const datetime box_t1 = DSA_ObjectTime(DSA_CHART_OBJECT_PREFIX + "forecast_box",1);

   if(fc_t1 <= fc_t0 || lo_t1 != fc_t1 || up_t1 != fc_t1 || box_t1 <= box_t0)
   {
      DSA_RecordFailure("future time anchors are not strictly forward and aligned");
      ok = false;
   }

   const double fc_p1 = DSA_ObjectPrice(DSA_CHART_OBJECT_PREFIX + "fc_1",1);
   const double lo_p1 = DSA_ObjectPrice(DSA_CHART_OBJECT_PREFIX + "lo_1",1);
   const double up_p1 = DSA_ObjectPrice(DSA_CHART_OBJECT_PREFIX + "up_1",1);
   const double sc_lo_p1 = DSA_ObjectPrice(DSA_CHART_OBJECT_PREFIX + "sc_lo_1",1);
   const double sc_up_p1 = DSA_ObjectPrice(DSA_CHART_OBJECT_PREFIX + "sc_up_1",1);
   const double box_p0 = DSA_ObjectPrice(DSA_CHART_OBJECT_PREFIX + "forecast_box",0);
   const double box_p1 = DSA_ObjectPrice(DSA_CHART_OBJECT_PREFIX + "forecast_box",1);

   if(up_p1 < lo_p1 || fc_p1 < lo_p1 || fc_p1 > up_p1)
   {
      DSA_RecordFailure("forecast line is outside uncertainty boundaries");
      ok = false;
   }

   if(sc_lo_p1 < lo_p1 || sc_lo_p1 > fc_p1 || sc_up_p1 < fc_p1 || sc_up_p1 > up_p1)
   {
      DSA_RecordFailure("scenario boundaries are outside the forecast cone");
      ok = false;
   }

   if(box_p0 < box_p1)
   {
      DSA_RecordFailure("forecast rectangle upper/lower prices are inverted");
      ok = false;
   }

   if(DSA_ObjectWidth(DSA_CHART_OBJECT_PREFIX + "fc_1") < 2 ||
      ObjectFind(0,DSA_CHART_OBJECT_PREFIX + "sc_lo_1") < 0 ||
      ObjectFind(0,DSA_CHART_OBJECT_PREFIX + "sc_up_1") < 0 ||
      ObjectFind(0,DSA_CHART_OBJECT_PREFIX + "forecast_box") < 0)
   {
      DSA_RecordFailure("forecast object visual vocabulary is missing");
      ok = false;
   }

   if(ObjectFind(0,DSA_CHART_OBJECT_PREFIX + "fc_49") >= 0 ||
      ObjectFind(0,DSA_CHART_OBJECT_PREFIX + "sc_lo_49") >= 0 ||
      ObjectFind(0,DSA_CHART_OBJECT_PREFIX + "sc_up_49") >= 0)
   {
      DSA_RecordFailure("stale future objects beyond renderer horizon were not removed");
      ok = false;
   }

   return ok;
}

int OnInit()
{
   IndicatorHandle = iCustom(_Symbol,_Period,DSA_CHART_HARNESS_INDICATOR);
   if(IndicatorHandle == INVALID_HANDLE)
   {
      Print("DSA chart-object harness failed to create indicator handle. Error=",GetLastError());
      return INIT_FAILED;
   }

   HarnessChartAttached = ChartIndicatorAdd(0,0,IndicatorHandle);
   if(!HarnessChartAttached)
      Print("DSA chart-object harness could not attach indicator to chart. Error=",GetLastError());

   Print("DSA chart-object harness initialized for ",_Symbol," ",EnumToString(_Period),
         " attached=",HarnessChartAttached);
   HarnessEventTaxonomyOk = DSA_ValidateEventTaxonomy();
   if(!HarnessEventTaxonomyOk)
      DSA_RecordFailure("event taxonomy and live/final flags failed synthetic validation");
   return INIT_SUCCEEDED;
}

void OnDeinit(const int reason)
{
   if(IndicatorHandle != INVALID_HANDLE)
      IndicatorRelease(IndicatorHandle);

   Print("DSA chart-object harness completed. failures=",HarnessFailures,
         " first_read=",HarnessFirstReadOk,
         " objects_seen=",HarnessObjectsSeen,
         " event_taxonomy=",HarnessEventTaxonomyOk,
         " reason=",reason);
}

void OnTick()
{
   if(IndicatorHandle == INVALID_HANDLE)
      return;

   const int calculated = BarsCalculated(IndicatorHandle);
   if(calculated <= 0)
      return;

   double trend[];
   double upper[];
   double lower[];
   ArraySetAsSeries(trend,true);
   ArraySetAsSeries(upper,true);
   ArraySetAsSeries(lower,true);

   const int copied_trend = CopyBuffer(IndicatorHandle,0,0,2,trend);
   const int copied_upper = CopyBuffer(IndicatorHandle,2,0,2,upper);
   const int copied_lower = CopyBuffer(IndicatorHandle,3,0,2,lower);

   if(copied_trend <= 0 || copied_upper <= 0 || copied_lower <= 0)
   {
      ++HarnessFailures;
      Print("DSA chart-object harness CopyBuffer failure. Error=",GetLastError());
      return;
   }

   for(int index = 0; index < copied_upper && index < copied_lower; ++index)
   {
      if(upper[index] != EMPTY_VALUE && lower[index] != EMPTY_VALUE && upper[index] < lower[index])
      {
         ++HarnessFailures;
         Print("DSA chart-object harness detected inverted band at index=",index);
      }
   }

   if(!HarnessFirstReadOk)
   {
      HarnessFirstReadOk = true;
      Print("DSA chart-object harness first buffer read succeeded. calculated=",calculated);
   }

   const int object_count = DSA_CountProjectObjects();
   if(object_count > 0 && !HarnessObjectsSeen)
   {
      HarnessObjectsSeen = true;
      Print("DSA chart-object harness project objects seen. count=",object_count);
   }

   if(HarnessObjectsSeen && !HarnessSemanticOk && !HarnessSemanticChecked)
   {
      HarnessSemanticChecked = true;
      HarnessSemanticOk = DSA_ValidateForecastObjects();
      if(HarnessSemanticOk)
         Print("DSA chart-object harness semantic object validation succeeded. count=",object_count);
   }
}

double OnTester()
{
   return (HarnessFailures == 0 &&
           HarnessFirstReadOk &&
           HarnessChartAttached &&
           HarnessObjectsSeen &&
           HarnessSemanticOk &&
           HarnessEventTaxonomyOk ? 1.0 : 0.0);
}
