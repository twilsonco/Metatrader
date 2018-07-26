//+------------------------------------------------------------------+
//|                                              KeltnerPullback.mqh |
//|                                 Copyright © 2017, Matthew Kastor |
//|                                 https://github.com/matthewkastor |
//+------------------------------------------------------------------+
#property copyright "Matthew Kastor"
#property link      "https://github.com/matthewkastor"
#property strict

#include <ChartObjects\ChartObjectsLines.mqh>
#include <ChartObjects\ChartObjectsShapes.mqh>
#include <Common\Comparators.mqh>
#include <Signals\AbstractSignal.mqh>
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class KeltnerPullback : public AbstractSignal
  {
private:
   Comparators       _compare;
   int               _maPeriod;
   double            _low;
   double            _high;
   double            _movingAverage;
   double            _movingAveragePrevious;
   ENUM_MA_METHOD    _maMethod;
   ENUM_APPLIED_PRICE _maAppliedPrice;
   int               _maShift;
   color             _maColor;
   double            _atr;
   int               _atrPeriod;
   double            _atrMultiplier;
   color             _atrColor;
   int               _minimumPointsDistance;
   CChartObjectTrend _maIndicator;
   string            _maIndicatorName;
   CChartObjectRectangle _atrIndicator;
   string            _atrIndicatorName;
public:
   void              DrawIndicator(string symbol,int shift);
                     KeltnerPullback(int maPeriod,ENUM_TIMEFRAMES timeframe,ENUM_MA_METHOD maMethod,ENUM_APPLIED_PRICE maAppliedPrice,int maShift,int atrPeriod,double atrMultiplier,int shift=0,int minimumPointsTpSl=50,color maColor=clrDeepPink,color atrColor=clrAquamarine);
   bool              Validate(ValidationResult *v);
   SignalResult     *Analyze(string symbol,int shift);
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
KeltnerPullback::KeltnerPullback(int maPeriod,ENUM_TIMEFRAMES timeframe,ENUM_MA_METHOD maMethod,ENUM_APPLIED_PRICE maAppliedPrice,int maShift,int atrPeriod,double atrMultiplier,int shift=0,int minimumPointsTpSl=50,color maColor=clrDeepPink,color atrColor=clrAquamarine)
  {
   this._maPeriod=maPeriod;
   this.Timeframe(timeframe);
   this._maMethod=maMethod;
   this._maAppliedPrice=maAppliedPrice;
   this._maShift=maShift;
   this._maColor=maColor;
   this._atrPeriod=atrPeriod;
   this._atrMultiplier=atrMultiplier;
   this._atrColor=atrColor;
   this.Shift(shift);
   this._minimumPointsDistance=minimumPointsTpSl;
   this._atrIndicatorName=StringConcatenate(this.ID(),"_ATR");
   this._maIndicatorName=StringConcatenate(this.ID(),"_MA");
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool KeltnerPullback::Validate(ValidationResult *v)
  {
   v.Result=true;

   if(!this._compare.IsNotBelow(this._maPeriod,1))
     {
      v.Result=false;
      v.AddMessage("Period must be 1 or greater.");
     }

   if(!this._compare.IsNotBelow(this.Shift(),0))
     {
      v.Result=false;
      v.AddMessage("Shift must be 0 or greater.");
     }

   return v.Result;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void KeltnerPullback::DrawIndicator(string symbol,int shift)
  {
   if(!this.DoesChartHaveEnoughBars(symbol,(shift+this._maPeriod)))
     {
      return;
     }
   if(!this.DoesChartHaveEnoughBars(symbol,(shift+this._atrPeriod)))
     {
      return;
     }

   long chartId=MarketWatch::GetChartId(symbol,this.Timeframe());
   if(this._maIndicator.Attach(chartId,this._maIndicatorName,0,2))
     {
      this._maIndicator.SetPoint(0,Time[shift+this._maPeriod],this._movingAveragePrevious);
      this._maIndicator.SetPoint(1,Time[shift],this._movingAverage);
     }
   else
     {
      this._maIndicator.Create(chartId,this._maIndicatorName,0,Time[shift+this._maPeriod],this._movingAveragePrevious,Time[shift],this._movingAverage);
      this._maIndicator.Color(this._maColor);
      this._maIndicator.Background(false);
     }

   if(this._atrIndicator.Attach(chartId,this._atrIndicatorName,0,2))
     {
      this._atrIndicator.SetPoint(0,Time[shift+this._atrPeriod],this._high);
      this._atrIndicator.SetPoint(1,Time[shift],this._low);
     }
   else
     {
      this._atrIndicator.Create(chartId,this._atrIndicatorName,0,Time[shift+this._atrPeriod],this._high,Time[shift],this._low);
      this._atrIndicator.Color(this._atrColor);
      this._atrIndicator.Background(false);
     }

   ChartRedraw(chartId);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
SignalResult *KeltnerPullback::Analyze(string symbol,int shift)
  {
   this.Signal.Reset();

   if(!this.DoesHistoryGoBackFarEnough(symbol,(shift+this._maPeriod)))
     {
      return this.Signal;
     }
   if(!this.DoesHistoryGoBackFarEnough(symbol,(shift+this._atrPeriod)))
     {
      return this.Signal;
     }

   this._atr=iATR(symbol,this.Timeframe(),this._atrPeriod,shift);

   this._movingAverage=iMA(symbol,this.Timeframe(),this._maPeriod,this._maShift,this._maMethod,this._maAppliedPrice,shift);
   this._movingAveragePrevious=iMA(symbol,this.Timeframe(),this._maPeriod,this._maShift,this._maMethod,this._maAppliedPrice,this._maPeriod+shift);

   this._low=this._movingAverage -(this._atr*this._atrMultiplier);
   this._high=this._movingAverage+(this._atr*this._atrMultiplier);

   this.DrawIndicator(symbol,shift);

   double point=MarketInfo(symbol,MODE_POINT);
   double minimumPoints=(double)this._minimumPointsDistance;

   MqlTick tick;
   bool gotTick=SymbolInfoTick(symbol,tick);

   if(gotTick)
     {
      if(this._movingAverage<this._movingAveragePrevious && tick.bid>=this._movingAverage)
        {
         this.Signal.isSet=true;
         this.Signal.time=tick.time;
         this.Signal.symbol=symbol;
         this.Signal.orderType=OP_SELL;
         this.Signal.price=tick.bid;
         this.Signal.stopLoss=(tick.bid+MathAbs(this._high-tick.bid));
         this.Signal.takeProfit=this._low;
        }
      if(this._movingAverage>this._movingAveragePrevious && tick.ask<=this._movingAverage)
        {
         this.Signal.isSet=true;
         this.Signal.orderType=OP_BUY;
         this.Signal.price=tick.ask;
         this.Signal.symbol=symbol;
         this.Signal.time=tick.time;
         this.Signal.stopLoss=(tick.ask-MathAbs(tick.ask-this._low));
         this.Signal.takeProfit=this._high;
        }
      if(this.Signal.isSet)
        {
         if(MathAbs(this.Signal.price-this.Signal.takeProfit)/point<minimumPoints)
           {
            this.Signal.Reset();
           }
         if(MathAbs(this.Signal.price-this.Signal.stopLoss)/point<minimumPoints)
           {
            this.Signal.Reset();
           }
        }
     }
   return this.Signal;
  }
//+------------------------------------------------------------------+
