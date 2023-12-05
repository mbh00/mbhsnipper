//+------------------------------------------------------------------+
//|                                                   MBHSniper1.mq4 |
//|                                       Copyright 2023, Sweet MBH. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, Sweet MBH."
#property link      "https://www.mql5.com"
#property version   "1.09"
#property strict
//--- input parameters
input int      AccPerc=1;
input int      DiffPerc=80;
input int      MagicNum=555;
input bool     Autolot=false;
input double   LotSize=0.01;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int BarsCount;
int BS=0;
bool onTrade=false;
bool cper=false;
int ticket=0;
int OnInit()
  {
//---
   BarsCount = 0;
   EventSetTimer(1);
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   if (Bars>BarsCount && IsTradeAllowed()) { 
      if(onTrade) CloseTi(ticket);
      cper=CheckPerc();
      BarsCount = Bars;
      Sleep(1000);
      if(onTrade==false && cper) Trade();
   }
  }
//+------------------------------------------------------------------+
void OnTimer()
  {
//---
   if(onTrade==false && cper) Trade();
  }
//+------------------------------------------------------------------+

void Trade()
{
   double lot=LotSize;        
   if(BS==1)
   {
    //  double price=High[1]+(5*Point)+(Ask - Bid);
      double price=High[1]+(5*Point)+(Ask - Bid);
      double sl=Low[1]-(Ask - Bid);
      if(Autolot) lot=CalculateLotSize(MathAbs(price-sl)/_Point);
     ticket=OrderSend(Symbol(),OP_BUYSTOP,lot,price,3,sl,0,"Manual",MagicNum,0,CLR_NONE);
      if(ticket<0)
        {
         Print("BUY STOP failed Price "+High[1]+" Lot "+lot+" SL "+Low[1]);
         Print("",GetLastError());
        }
      else{
         Print("BUY STOP placed successfully"); 
         onTrade=true;
         }
   }
   if(BS==0)
   {
      double price=Low[1]-(5*Point);
      double sl=High[1]+(Ask - Bid);
      if(Autolot) lot=CalculateLotSize(MathAbs(price-sl)/_Point);
      
     ticket=OrderSend(Symbol(),OP_SELLSTOP,lot,price,3,sl,0,"Manual",MagicNum,0,CLR_NONE);
      if(ticket<0)
        {
         Print("SELL STOP failed Price "+Low[1]+" Lot "+lot+" SL "+High[1]);
         Print("",GetLastError());
        }
      else{
         Print("SELL STOP placed successfully"); 
         onTrade=true;
         }
   }
}

double CalculateLotSize(double SL){          // Calculate the position size.
   double LotSi = 0;
   // We get the value of a tick.
   double nTickValue = MarketInfo(Symbol(), MODE_TICKVALUE);
   // If the digits are 3 or 5, we normalize multiplying by 10.
   if ((Digits == 3) || (Digits == 5)){
      nTickValue = nTickValue * 10;
   }
   // We apply the formula to calculate the position size and assign the value to the variable.
   //LotSi = (AccountBalance() * AccPerc / 100) / (SL * nTickValue);
   LotSi = (AccountBalance() * AccPerc / 100) / (SL*MarketInfo(Symbol(), MODE_TICKVALUE));
   LotSi = MathRound(LotSi / MarketInfo(Symbol(), MODE_LOTSTEP)) * MarketInfo(Symbol(), MODE_LOTSTEP);
   return LotSi;
}

void CloseTi(int Ti){

   int Slippage=3;
   // Normalization of the slippage.
   if(Digits==3 || Digits==5){
      Slippage=Slippage*10;
   }
      if(OrderSelect(Ti, SELECT_BY_TICKET)){
         double cp=NormalizeDouble(MarketInfo(OrderSymbol(),MODE_BID),Digits);
         RefreshRates();
         if(OrderType()==OP_BUY) cp=NormalizeDouble(MarketInfo(OrderSymbol(),MODE_BID),Digits);
         if(OrderType()==OP_SELL) cp=NormalizeDouble(MarketInfo(OrderSymbol(),MODE_ASK),Digits);

         if(OrderCloseTime()==0 && (((OrderType()==OP_BUY || OrderType()==OP_SELL) &&
         OrderClose(OrderTicket(),OrderLots(),cp,Slippage,CLR_NONE))
         ||
         ((OrderType()==OP_BUYSTOP || OrderType()==OP_SELLSTOP) && OrderDelete(OrderTicket()) ))){
            Print("New Bar found, previous position closed "+Ti);
            ticket=0;
            onTrade=false;
         }
         else{
            Print("Order failed to close with error - ",GetLastError());
         }
         if(OrderCloseTime()!=0) {ticket=0;onTrade=false;}
      }
      // If the OrderSelect() fails, we return the cause.
      else{
         Print("Failed to select the order - ",GetLastError());
      }  
}
bool CheckPerc()
{
   double h=0;
   if(Open[1]<Close[1]) 
   {
       BS=1;
       h=100*MathAbs(Close[1]-High[1])/MathAbs(Open[1]-Close[1]);
   }
   if(Open[1]>Close[1]) {
       h=100*MathAbs(Close[1]-Low[1])/MathAbs(Open[1]-Close[1]);
       BS=0;
   }
   if(h!=0 && h<DiffPerc) 
   {  
   if(BS==1) Print("Can place order BODY "+MathAbs(Open[1]-Close[1])+" Stick High "+MathAbs(Close[1]-High[1])+" % "+h);
   else Print("Can place order BODY "+MathAbs(Open[1]-Close[1])+" Stick Low"+MathAbs(Close[1]-Low[1])+" % "+h);
    return true;
   }
   else{
   if(BS==1) Print("Cannot place order BODY "+MathAbs(Open[1]-Close[1])+" Stick High "+MathAbs(Close[1]-High[1])+" % "+h);
   else Print("Cannot place order BODY "+MathAbs(Open[1]-Close[1])+" Stick Low"+MathAbs(Close[1]-Low[1])+" % "+h);
    return false;
   }
}