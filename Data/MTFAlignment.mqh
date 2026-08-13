#ifndef DSA_MTF_ALIGNMENT_MQH
#define DSA_MTF_ALIGNMENT_MQH

#include "DataContract.mqh"

struct DSAMtfSnapshot
{
   bool available;
   datetime source_time;
   double open;
   double high;
   double low;
   double close;
   long tick_volume;
   int spread;
};

void DSA_ResetMtfSnapshot(DSAMtfSnapshot &snapshot)
{
   snapshot.available = false;
   snapshot.source_time = 0;
   snapshot.open = 0.0;
   snapshot.high = 0.0;
   snapshot.low = 0.0;
   snapshot.close = 0.0;
   snapshot.tick_volume = 0;
   snapshot.spread = 0;
}

bool DSA_GetCausalAnalysisRate(DSAInputContract &contract,const datetime host_time,DSAMtfSnapshot &snapshot)
{
   DSA_ResetMtfSnapshot(snapshot);

   if(contract.analysis_timeframe == contract.chart_timeframe || contract.analysis_timeframe == PERIOD_CURRENT)
      return false;

   ResetLastError();
   int shift = iBarShift(contract.symbol,contract.analysis_timeframe,host_time,false);
   if(shift < 0)
      return false;

   shift++;

   MqlRates rates[];
   ArraySetAsSeries(rates,true);
   const int copied = CopyRates(contract.symbol,contract.analysis_timeframe,shift,1,rates);
   if(copied != 1)
      return false;

   snapshot.available = true;
   snapshot.source_time = rates[0].time;
   snapshot.open = rates[0].open;
   snapshot.high = rates[0].high;
   snapshot.low = rates[0].low;
   snapshot.close = rates[0].close;
   snapshot.tick_volume = rates[0].tick_volume;
   snapshot.spread = rates[0].spread;
   return true;
}

double DSA_MtfTarget(DSAMtfSnapshot &snapshot,const ENUM_DSA_SELECTION_DATA selection_data)
{
   if(!snapshot.available)
      return 0.0;

   DSASelectionChannels channels;
   DSA_BuildSelectionChannelsFromValues(selection_data,
                                        snapshot.open,
                                        snapshot.high,
                                        snapshot.low,
                                        snapshot.close,
                                        channels);
   return channels.central;
}

#endif
