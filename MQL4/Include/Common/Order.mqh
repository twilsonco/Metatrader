//+------------------------------------------------------------------+
//|                                                        Order.mqh |
//|                                 Copyright © 2017, Matthew Kastor |
//|                                 https://github.com/matthewkastor |
//+------------------------------------------------------------------+
#property copyright "Matthew Kastor"
#property link      "https://github.com/matthewkastor"
#property strict
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
struct Order
  {
   int               ticketID;
   datetime          openTime;
   ENUM_ORDER_TYPE   orderType;
   double            lotSize;
   string            symbol;
   double            openPrice;
   double            stopLoss;
   double            takeProfit;
   double            commission;
   double            swap;
   double            profit;
   string            comment;
   datetime          expiration;
   double            closePrice;
   datetime          closeTime;
   int               magicNumber;
   void Order()
     {
      this.ticketID=NULL;
      this.openTime=NULL;
      this.orderType=NULL;
      this.lotSize=NULL;
      this.symbol=NULL;
      this.openPrice=NULL;
      this.stopLoss=NULL;
      this.takeProfit=NULL;
      this.commission=NULL;
      this.swap=NULL;
      this.profit=NULL;
      this.comment=NULL;
      this.expiration=NULL;
      this.closePrice=NULL;
      this.closeTime=NULL;
      this.magicNumber=NULL;
     }
  };
//+------------------------------------------------------------------+
