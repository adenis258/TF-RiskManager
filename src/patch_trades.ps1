$content = [System.IO.File]::ReadAllText('TF_RiskManager_v15_5.mq5')

$c_all_find = 'int CloseAllPositions(string reason)
{
   int count = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket > 0 && PositionSelectByTicket(ticket))
      {'

$c_all_rep = 'int CloseAllPositions(string reason)
{
   int count = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket > 0 && PositionSelectByTicket(ticket))
      {
         // v15.5: Enforce 30-second safety hold
         if(TimeCurrent() - (datetime)PositionGetInteger(POSITION_TIME) < 30)
         {
            Print(" Trade close ignored in CloseAll: Position open for less than 30 seconds.\);
 continue;
 }'

$c_at_mkt_find = 'bool ClosePositionAtMarket(ulong ticket, string reason)
{
 if(!PositionSelectByTicket(ticket)) return false;'

$c_at_mkt_rep = 'bool ClosePositionAtMarket(ulong ticket, string reason)
{
 if(!PositionSelectByTicket(ticket)) return false;

 // v15.5: Enforce 30-second safety hold
 if(TimeCurrent() - (datetime)PositionGetInteger(POSITION_TIME) < 30)
 {
 Print(\Trade close ignored: Position open for less than 30 seconds.\);
 return false;
 }'

$content = $content.Replace($c_all_find, $c_all_rep)
$content = $content.Replace($c_at_mkt_find, $c_at_mkt_rep)

[System.IO.File]::WriteAllText('TF_RiskManager_v15_5.mq5', $content)
