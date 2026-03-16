//+------------------------------------------------------------------+
//|                  TF Complete Manager v15.4                       |
//|         Enhanced Version - Risk + Monitor + Smart Entry          |
//|   v15.0: GUI Overlap Fix / Z-Order / Layout Optimization        |
//+------------------------------------------------------------------+
#property strict
#property description "Complete TF System: Risk + Monitor + Reliability + Advanced Features"
#property version   "15.4"
#property copyright "Andre Denis-2026-03-03 | v15.4"

#include <Trade\Trade.mqh>

//+------------------------------------------------------------------+
//| INPUT PARAMETERS                                                 |
//+------------------------------------------------------------------+
// v14.21: TF Account Type selector
enum ENUM_TF_ACCOUNT
{
   TF_STEP1    = 0,   // 1-Step Evaluation
   TF_STEP2    = 1,   // 2-Step Evaluation
   TF_INSTANT  = 2,   // Instant Funding
   TF_FLEX     = 3,   // Flex Challenge
};

input group "========== TF ACCOUNT TYPE =========="
// v14.26: TLL mode is AUTOMATICALLY set by AccountType — no GUI toggle needed.
//   2-Step Evaluation          → STATIC  (floor = InitBal - TLL_Fixed; never moves)
//   1-Step / Instant / Flex    → TRAILING (floor = HWM - TLL_Fixed; locks at InitBal)
// TradingFunds official rules: tradingfunds.com/trailing-vs-static-drawdown-...
input ENUM_TF_ACCOUNT  AccountType        = TF_STEP1;  // v14.21: Select your TF account type
input bool             FlexFundedAccount  = false;     // v14.21: Flex only — true = Funded (6% TLL), false = Eval (8% TLL)

input group "========== RISK MANAGER =========="
input double AccountSize               = 10000.0;   // Original Account Size ($)
input bool   UseAutoDetection          = false;     // Auto-detect account size
input double DailyLossLimitPct         = 5.0;       // Daily Loss Limit (%)
input double TFShieldPercentage        = 2.0;       // TF Shield Loss Limit (%)
input double MaxTrailingDrawdownPct    = 8.0;       // Max Trailing Drawdown (%)
input double WarningThreshold          = 80.0;      // Warning threshold (%)
input double DailyGainTargetPct        = 2.0;       // Daily Gain Target (%)
input double TotalTargetGainPct        = 6.0;       // Total Target Gain (%)
input bool   EnableTFShield            = true;      // Enable TF Shield
input bool   EnableDailyTargetAutoClose= true;      // Auto-close on target
input bool   ShowRiskPanel             = true;      // Show Risk Panel
input int    PanelOffsetX              = 10;        // Panel X offset
input int    PanelOffsetY              = 70;        // Panel Y offset
input double RiskPerTradePct           = 2.0;       // Risk Per Trade (%)
input double FixedLotSize              = 2.0;      // Fixed Lot Size (if Risk % = 0)
input int    UnblockCountdownMinutes   = 5;        // Minutes to unblock after breach
input int    TLL_CooldownMinutes       = 5;         // v14.16 B1: Pause after TLL breach then auto-resume (default 5 min)
input int    LockReleaseMinutes        = 5;         // Manual trading lock auto-release in minutes (0 = manual unlock only)


input group "========== PROFIT RATCHET (GIVE-BACK RULE) =========="
input bool   EnableProfitRatchet   = true;      // Enable Daily Profit Trailing
input double RatchetActivationPct  = 1.0;       // Activate when Daily Gain >= X%
input double RatchetLockPct        = 0.5;       // Lock Daily Gain at Y% (0=BE)

input group "========== TILT PROTECTION =========="
input bool   EnableTiltProtection  = true;      // Enable Anti-Revenge logic
input int    MaxConsecutiveLosses  = 5;         // Max consecutive losses before pause
input int    TiltPauseMinutes      = 5;        // Minutes to block trading after tilt

input group "========== EXPOSURE LIMITS =========="
input double MaxTotalLots          = 10.0;      // Max allowed total volume (0=Unlimited)
input int    MaxOpenPositions      = 5;         // Max allowed open positions (0=Unlimited)

input group "========== MARKET MONITOR =========="
input bool   EnableAutoClose           = true;      // Enable Auto-Close Monitor
input int    DefaultSL_Pips            = 500;        // Default Stop Loss (pips)
input int    DefaultTP_Pips            = 0;       // Default Take Profit (pips)
input bool   DefaultTrailingEnabled    = false;     // Enable Trailing Stop by Default
input int    TrailingDistance_Pips     = 200;        // Trailing Distance (pips)
input int    TrailingActivation_Pips   = 900;        // Start Trailing After (pips)
input bool   ShowMonitorGUI            = true;      // Show Market Monitor GUI

input group "========== GENERAL =========="
input bool   ShowAlert                 = true;      // Pop-up alerts
input bool   LogToTerminal             = true;      // Log to Terminal
input int    MagicNumber               = 99999;     // Magic Number
input int    MaxSlippagePips           = 50;         // Max Slippage
input int    MaxSpreadPips             = 70;        // Max Spread (pips) to allow entry (Default 70 = $0.70 on US500)
input bool   EnableEmergencyStop       = false;     // Manual Kill Switch
input double GuiScale                  = 1.3;       // GUI Scaling (e.g., 1.0 = Normal, 0.8 = Small)
input int    DailyResetHour            = 19;         // Daily reset hour (0=midnight, 1-23=specific hour)
input int    BrokerGMTOffset       = 2;         // v14.16 A1: Broker GMT offset (UTC+2→2). Daily reset auto-set to 19:00 UTC = 19:00 NY
enum ENUM_MANUAL_FILLING { FILLING_AUTO, FILLING_FOK, FILLING_IOC, FILLING_RETURN };
input ENUM_MANUAL_FILLING ManualFillingMode = FILLING_AUTO; // Order Filling Mode

input group "========== TRAILING & EXECUTION RELIABILITY =========="
input bool   UseRealTrailing           = false;     // Server-side trailing (recommended)
input int    MaxCloseRetries           = 3;         // Max retries for close/modify
input int    RetryDelayMs              = 300;       // Delay between retries (ms)

input group "========== ATR DYNAMIC DISTANCES =========="
input bool   Input_UseATR              = false;     // Enable ATR-based dynamic SL/TP/Trailing
input int    ATR_Period                = 14;        // ATR period (bars)
input double ATR_Multi_SL              = 2.0;       // Multiplier for initial Stop Loss
input double ATR_Multi_TP              = 3.0;       // Multiplier for Take Profit
input double ATR_Multi_Activation      = 2.0;       // Multiplier for trailing activation
input double ATR_Multi_TrailingDist    = 2.5;       // Multiplier for trailing distance

input group "========== BREAKEVEN BUFFER =========="
input bool   UseBreakevenBuffer        = true;      // Enable breakeven buffer
enum ENUM_BUFFER_TYPE { BUFFER_FIXED, BUFFER_ATR };
input ENUM_BUFFER_TYPE BreakevenType   = BUFFER_FIXED;
input int    BreakevenFixedPips        = 500;         // Fixed buffer in pips
input double BreakevenATRMulti         = 0.3;       // ATR multiplier for buffer

input group "========== MULTI-PARTIAL TP =========="
input bool   UseMultiPartialTP         = false;     // Enable multi-level partial TP
input int    PartialLevelCount         = 2;         // Number of partial levels (1-3)
input double PartialPct1               = 50.0;      // % to close at level 1
input int    PartialPips1              = 75;        // Pips or ATR multi for level 1
input double PartialPct2               = 30.0;
input int    PartialPips2              = 150;
input double PartialPct3               = 20.0;
input int    PartialPips3              = 250;
input bool   UseATRForPartialLevels    = false;     // Use ATR multipliers instead of fixed pips
input double PartialATRMulti1          = 1.5;
input double PartialATRMulti2          = 3.0;
input double PartialATRMulti3          = 5.0;

input group "========== CHART LINES =========="
input bool   ShowChartLines            = true;      // Show draggable SL/TP lines on chart
input color  SL_LineColor              = clrRed;    // SL line color
input color  TP_LineColor              = clrLime;   // TP line color

input group "========== NEWS & TIME FILTER =========="
input bool   UseNewsFilter             = true;      // Enable news filter
input int    NewsPreMinutes            = 5;        // Minutes before high-impact news to block
input int    NewsPostMinutes           = 0;        // Minutes after high-impact news to block
input string NewsCurrencyFilter        = "USD";     // Currencies to filter (comma-separated, e.g. USD,EUR)
input bool   IncludeMediumImpact       = false;     // Include Medium impact (Yellow) news
input bool   IncludeLowImpact          = false;     // Include Low impact (Green) news (Visual Only)
input color  NewsColorHigh             = clrRed;    // Color for High Impact News
input color  NewsColorMedium           = clrOrange; // Color for Medium Impact News
input color  NewsColorLow              = clrLime;   // Color for Low Impact News
input bool   CloseOnHighNews           = true;      // Close open positions before high-impact news
input bool   UseTimeFilter             = false;     // Enable trading time filter
input string AllowedStartTime          = "00:00";   // Start trading time (server time, HH:MM)
input string AllowedEndTime            = "23:59";   // End trading time (HH:MM)

input group "========== ZIGZAG STUDY =========="
input bool   ZZ_Enabled          = true;    // Enable Sierra Chart-style ZigZag overlay
input int    ZZ_Strength         = 5;       // Bars each side to confirm pivot (Sierra "Num Bars")
input int    ZZ_LookbackBars     = 200;     // Historical bars to scan and draw
input bool   ZZ_ShowPivotLabels  = true;    // Show price label at each confirmed swing
input bool   ZZ_ShowLegPips      = true;    // Append index-point size to pivot label
input bool   ZZ_ShowWaveCount    = false;   // Number each wave leg (1, 2, 3 …)
input color  ZZ_UpColor          = clrDodgerBlue;   // Up-leg line color
input color  ZZ_DownColor        = clrOrangeRed;    // Down-leg line color
input int    ZZ_LineWidth        = 2;       // Line thickness (pixels)
input int    ZZ_LabelFontSize    = 8;       // Font size for all ZigZag labels

//+------------------------------------------------------------------+
//| STRUCT & GLOBAL VARIABLES                                        |
//+------------------------------------------------------------------+
#define MAX_POSITIONS 500

struct PositionMonitor
{
   ulong             ticket;
   ENUM_POSITION_TYPE type;
   double            volume;
   double            entry_price;
   int               sl_pips;
   int               tp_pips;
   bool              monitoring_enabled;
   datetime          open_time;
   double            current_profit_pips;
   bool              trailing_enabled;
   double            trailing_sl_price;
   double            highest_price;
   double            lowest_price;
   bool              breakeven_locked;
   int               partial_levels_hit;   // bitmask: 1=level1, 2=level2, 4=level3
};

PositionMonitor monitored_positions[];
int             monitor_count          = 0;

CTrade          trade;

int             atr_handle             = INVALID_HANDLE;
double          current_atr            = 0.0;

string          SL_LinePrefix          = "DynSL_";
string          TP_LinePrefix          = "DynTP_";

datetime        last_news_check        = 0;
bool            in_news_window         = false;

bool            UseServerTrailing;
bool            Runtime_UseATR;
//+------------------------------------------------------------------+
//| Data-Driven Settings Panel Toggles                               |
//+------------------------------------------------------------------+
enum ENUM_TOGGLE_VARS
{
    TOGGLE_MONITOR,
    TOGGLE_TRAILING,
    TOGGLE_TIME_FILTER,
    TOGGLE_NEWS_FILTER,
    TOGGLE_ATR_MODE
};

enum ENUM_INPUT_VARS
{
    INPUT_RISK_PCT,
    INPUT_DLL_PCT,
    INPUT_DGT_PCT,
    INPUT_TLL_PCT,
    INPUT_TFS_PCT,
    INPUT_SL_PIPS,
    INPUT_TP_PIPS,
    INPUT_TRAIL_DIST,
    INPUT_TRAIL_ACT,
    INPUT_NEWS_PRE,
    INPUT_NEWS_POST,
    INPUT_LOCK_RELEASE,
    INPUT_PDC,
    INPUT_HWM,
    INPUT_START_BAL,
    INPUT_GUI_SCALE
};

struct ToggleSetting
{
    string name; // e.g., "MON"
    string label; // e.g., "Monitor :"
    ENUM_TOGGLE_VARS var_id;
};

struct InputSetting
{
    string name;
    string label;
    ENUM_INPUT_VARS var_id;
    int precision; // For DoubleToString formatting
};

// Initialize the array of toggle settings
ToggleSetting g_toggle_settings[] =
{
    { "MON",  "Monitor :",     TOGGLE_MONITOR       },
    { "TRL",  "Trailing :",    TOGGLE_TRAILING      },
    { "TIME", "Time Filter :", TOGGLE_TIME_FILTER   },
    { "NEWS", "News Filter :", TOGGLE_NEWS_FILTER   },
    { "ATR",  "ATR Mode :",    TOGGLE_ATR_MODE      }
};

InputSetting g_input_settings[] = {
    {"Risk",     "Risk % :",               INPUT_RISK_PCT,   2},
    {"DLL",      "Daily Loss % :",         INPUT_DLL_PCT,    2},
    {"DailyGain","Daily Gain % :",         INPUT_DGT_PCT,    2},
    {"TLL",      "Max Trailing DD % :",    INPUT_TLL_PCT,    2},
    {"TFShield", "TF Shield % :",          INPUT_TFS_PCT,    2},
    {"SL",       "Default SL (pips):",     INPUT_SL_PIPS,    0},
    {"TP",       "Default TP (pips):",     INPUT_TP_PIPS,    0},
    {"TrailDist","Trailing Dist (pips):",  INPUT_TRAIL_DIST, 0},
    {"TrailAct", "Trail Activation:",      INPUT_TRAIL_ACT,  0},
    {"NewsPre",  "News Pre (min):",        INPUT_NEWS_PRE,   0},
    {"NewsPost", "News Post (min):",       INPUT_NEWS_POST,  0},
    {"LockRel",  "Lock Release (min):",    INPUT_LOCK_RELEASE,0},
    {"PDC",      "Prior Day Close:",       INPUT_PDC,        2},
    {"HWM",      "Manual HWM:",            INPUT_HWM,        2},
    {"StartBal", "Start Bal (Man):",       INPUT_START_BAL,  2},
    {"GUIScale", "GUI Scale:",             INPUT_GUI_SCALE,  2}
};

bool            Runtime_EnableAutoClose;
bool            Runtime_UseTimeFilter;
bool            Runtime_UseNewsFilter;
bool            Runtime_EnableEmergencyStop;
int             Runtime_LockReleaseMinutes;
datetime        Runtime_LockReleaseEndTime = 0;
string          g_active_edit_object = "";      // v14.40: Name of the OBJ_EDIT currently being edited
int             Runtime_NewsPreMinutes;
int             Runtime_NewsPostMinutes;
string          Runtime_NewsCurrencyFilter;
bool            Runtime_IncludeMediumImpact;
bool            Runtime_IncludeLowImpact;
color           Runtime_NewsColorHigh;
color           Runtime_NewsColorMedium;
color           Runtime_NewsColorLow;
double          Runtime_RiskPerTradePct;
double          Runtime_FixedLotSize;


// v11.0 Manual Inputs & Buffers
double   Manual_PriorDayClose      = 0.0;
double   Manual_HighWaterMark      = 0.0;
double   Manual_StartingBalance    = 0.0;
bool     Manual_TFS_Breach         = false;
double   Buffer_DLL                = 0.0;
double   Buffer_TLL                = 0.0;
double   Buffer_Effective          = 0.0;   // v14.32: min(Buffer_DLL, Buffer_TLL) — the binding constraint
double   Buffer_Effective_Pct      = 0.0;   // % of the binding fixed amount
bool     TLL_IsBinding             = false; // true when TLL is the tighter of the two limits
double   Buffer_TF                 = 0.0;
double   Buffer_DLL_Pct            = 0.0;
double   Buffer_TLL_Pct            = 0.0;
double   Buffer_TF_Pct             = 0.0;



// Advanced Risk Globals
double   Runtime_RatchetActivation;
double   Runtime_RatchetLock;
int ConsecutiveLossCount = 0;
datetime TiltBlockEndTime = 0;

/* ── v14.19: Mod8 DISABLED ── BEGIN
// v14.18 Mod8: Price Direction Change Alert
double   Mod8_LastBreakHigh  = 0.0;
double   Mod8_LastBreakLow   = 0.0;
datetime Mod8_LastAlertBar   = 0;
bool     Mod8_AlertedUp      = false;
bool     Mod8_AlertedDown    = false;
── Mod8 globals DISABLED END ── */

// Risk manager globals - complete declaration
double   WorkingAccountSize;
double   TFShieldLimit;
double   WarningLevel;
double   DailyLossLimit;
double   TLLLimit;
double   DailyDDWarningLevel;
double   StartingBalance;
double   Runtime_DailyGainTarget;
double   Runtime_DailyGainTargetPct;
double   Runtime_TotalTargetGainPct;
double   Runtime_PriorDayClose;
double   Runtime_HighWaterMark;
double   Runtime_DailyLossLimitPct;
double   Runtime_TFShieldPercentage;
double   Runtime_MaxTrailingDDPct;
double   Runtime_WarningThreshold;
double   Runtime_AccumulatedNetLoss;
double   CurrentFloatingLoss;
double   CurrentFloatingPL;
double   TodaysRealizedProfit;
double   TodaysTotalGain;
double   HighWaterMark;
double   CurrentEquity;
double   PriorDayClose;
double   DailyHighWaterMark;
double   DLL_BreachLevel;
double   TLL_BreachLevel;
double   DLL_Buffer;
double   TLL_Buffer;
datetime LastResetDate;
long     CurrentAccountNumber;
bool     TFShieldBreached;
bool     WarningIssued;
bool     DailyLossBreached;
bool     TLLBreached;
bool     DailyDDWarningIssued;
bool     DailyTargetReached;
bool     SettingsPanelExpanded = false;
int      SettingsPanelBaseY    = 0;   // dynamic base
int      MainContentTopY       = 0;
double   Runtime_GuiScale;
datetime DailyLossBreachTime = 0;
datetime TLLBreachTime = 0;
datetime TLLCooldownEndTime         = 0;
datetime DailyTargetBreachTime = 0;

string PeakFileName = "";
string LogFileName  = "";
string StateFileName = "";
string MAIN_TITLE   = "MAIN_TITLE";
string MAIN_TOGGLE  = "MAIN_TOGGLE";
string SET_BG       = "SET_BG";
string SET_TITLE    = "SET_TITLE";

int      Runtime_SL_Pips        = 500;
int      Runtime_TP_Pips        = 900;
int      Runtime_PanelBottomY   = 0;
bool     Runtime_TrailingEnabled= false;
int      Runtime_TrailingDistance = 200;
int      Runtime_TrailingActivation = 900;
bool     Runtime_IsPendingMode     = false;
double   Runtime_PendingPrice       = 0.0;
bool     Runtime_UseAutoScaling     = false;
ENUM_TF_ACCOUNT Runtime_AccountType = TF_STEP1;
bool     Runtime_FlexFundedAccount  = false;


// v14.21: Account-type-driven limit globals
bool     TLL_IsTrailing          = true;   // false = 2-Step static TLL
double   TLL_FixedAmount         = 0.0;    // StartingBalance × TLL_pct
double   DLL_FixedAmount         = 0.0;    // StartingBalance × DLL_pct
double   TLL_LockFloor           = 0.0;    // TLL floor can never exceed this level (= StartingBalance)

// Missing Global Variables from previous versions
bool     DailyLossAlertSent         = false;
bool     GainTargetAlertSent        = false;
bool     RatchetAlertSent  = false;
bool     TLLAlertSent      = false;
double   DistToDGT                  = 0.0;
double   DistToTTG                  = 0.0;
double   RiskExposure               = 0.0;
double   RiskUnderOverTarget        = 0.0;

double   point_value;
double   pip_size;
bool     is_index;
int      symbol_digits;


// v14.20 ZigZag: Pivot point struct (Sierra Chart-style)
struct ZZ_PivotPoint
{
   datetime  time;
   double    price;
   int       bar_idx;
   int       type;      // +1 = swing high,  -1 = swing low
};

// v14.20 ZigZag: Runtime state
ZZ_PivotPoint ZZ_Clean[];            // Consolidated alternating pivot array
int           ZZ_CleanCount  = 0;    // Number of confirmed clean pivots

// v14.21: TLL-mode toggle button name constant
// v14.30: LBL_TLL_STATUS removed — TLL type is a fixed property of AccountType,
//         never changes at runtime. Shown once in the Experts log on EA load.

string        ZZ_ObjPrefix   = "ZZ_"; // Chart-object name prefix

//+------------------------------------------------------------------+
//| Forward Declarations                                             |
//+------------------------------------------------------------------+
bool IsPositionMonitored(ulong ticket);
void ScanAndAddPositions();
void CreateTransparentPanel();
void UpdateRiskPanel();
void CreatePanelLabel(string name, string txt, int x, int y, color clr, int fsize, bool bold);
void CreatePanelButton(string name, string txt, int x, int y, int w, int h, color bg, color txtclr, int fsize);
void CreatePanelEdit(string name, string txt, int x, int y, int w, int fsize);
void CreatePanelHeader(string name, string txt, int x, int y, color clr, int fsize);
void CreatePanelInfo(string name, string label, string value, int x, int y, color valclr, int lbl_w, int fsize);
void CreatePanelPosLine(string name, string ticket, string lots, string sl, string tp, int x, int y, color pl_clr);
void CancelAllPendingOrders(string reason);
void CreateSettingsPanelObjects();
void SaveSettingsFromPanel();
void DeleteSettingsPanelObjects();
void ToggleSettingsPanel();
void UpdateSettingsPanel();
string GetAccountTypeDisplayText();
void CycleAccountTypeSetting();
// CreateField and AddToggle: v14.12 helpers retained for reference, superseded by v15.0 settings panel
void RecalculateLimits();
void RecalculateBuffers();
void CalculateZigZag();
void DrawZigZagLines();
void DeleteZigZagObjects();
bool ZZ_IsPivotHigh(int idx, int strength);
bool ZZ_IsPivotLow(int idx, int strength);


int Scaled(int px) { return (int)MathRound(px * Runtime_GuiScale); }
int ScaledFont() { return (int)MathRound(9 * Runtime_GuiScale); }

void CreateField(string id, string lbl_text, string val, int x, int &y, int label_w, int value_w)
{
   string lbl_name = "SET_L_" + id;
   ObjectDelete(0, lbl_name);
   ObjectCreate(0, lbl_name, OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, lbl_name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, lbl_name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, lbl_name, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, lbl_name, OBJPROP_COLOR, clrWhite);
   ObjectSetInteger(0, lbl_name, OBJPROP_FONTSIZE, ScaledFont());
   ObjectSetString(0, lbl_name, OBJPROP_TEXT, lbl_text);
   ObjectSetInteger(0, lbl_name, OBJPROP_ZORDER, 1005);

   string val_name = "SET_V_" + id;
   ObjectDelete(0, val_name);
   ObjectCreate(0, val_name, OBJ_EDIT, 0, 0, 0);
   ObjectSetInteger(0, val_name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, val_name, OBJPROP_XDISTANCE, x + label_w);
   ObjectSetInteger(0, val_name, OBJPROP_YDISTANCE, y - Scaled(2));
   ObjectSetInteger(0, val_name, OBJPROP_XSIZE, value_w);
   ObjectSetInteger(0, val_name, OBJPROP_YSIZE, Scaled(24));
   ObjectSetInteger(0, val_name, OBJPROP_FONTSIZE, ScaledFont());
   ObjectSetInteger(0, val_name, OBJPROP_COLOR, clrWhite);
   ObjectSetInteger(0, val_name, OBJPROP_BGCOLOR, C'15,35,70');
   ObjectSetString(0, val_name, OBJPROP_TEXT, val);
   ObjectSetInteger(0, val_name, OBJPROP_ZORDER, 1005);
}

//+------------------------------------------------------------------+
//| v14.20 ZZ-04: ZZ_IsPivotHigh                                     |
//| True when bar[idx] is the highest High in a ±strength window.    |
//| Mirrors Sierra Chart "Number of Bars for High" parameter.        |
//| MQL5 index convention: idx=0 is current bar (rightmost),         |
//| idx+j = older bars (left on chart), idx-j = newer (right).       |
//+------------------------------------------------------------------+
bool ZZ_IsPivotHigh(int idx, int strength)
{
   if(idx < strength) return false;   // need strength confirmed bars to the right
   double h = iHigh(_Symbol, PERIOD_CURRENT, idx);
   for(int j = 1; j <= strength; j++)
   {
      if(iHigh(_Symbol, PERIOD_CURRENT, idx + j) >= h) return false;  // left / older
      if(iHigh(_Symbol, PERIOD_CURRENT, idx - j) >= h) return false;  // right / newer
   }
   return true;
}

//+------------------------------------------------------------------+
//| v14.20 ZZ-05: ZZ_IsPivotLow                                      |
//| True when bar[idx] is the lowest Low in a ±strength window.      |
//+------------------------------------------------------------------+
bool ZZ_IsPivotLow(int idx, int strength)
{
   if(idx < strength) return false;
   double l = iLow(_Symbol, PERIOD_CURRENT, idx);
   for(int j = 1; j <= strength; j++)
   {
      if(iLow(_Symbol, PERIOD_CURRENT, idx + j) <= l) return false;  // left / older
      if(iLow(_Symbol, PERIOD_CURRENT, idx - j) <= l) return false;  // right / newer
   }
   return true;
}

//+------------------------------------------------------------------+
//| v14.20 ZZ-06: DeleteZigZagObjects                                |
//| Removes all chart objects whose name starts with ZZ_ObjPrefix.   |
//+------------------------------------------------------------------+
void DeleteZigZagObjects()
{
   ObjectsDeleteAll(0, ZZ_ObjPrefix);
   ChartRedraw();
}

//+------------------------------------------------------------------+
//| v14.20 ZZ-07: CalculateZigZag                                    |
//| Pass 1 – scan for raw confirmed pivots (oldest bar → newest)     |
//| Pass 2 – consolidate into strict alternating H/L sequence        |
//| Pass 3 – delegate drawing to DrawZigZagLines()                   |
//+------------------------------------------------------------------+
void CalculateZigZag()
{
   if(!ZZ_Enabled) return;

   DeleteZigZagObjects();

   int total_bars = iBars(_Symbol, PERIOD_CURRENT);
   if(total_bars < ZZ_Strength * 2 + 2) return;

   // scan_end  = most-recent bar we can fully confirm (needs strength bars to its right)
   // scan_start= oldest bar in the lookback window
   int scan_end   = ZZ_Strength;
   int scan_start = (int)MathMin(ZZ_LookbackBars + ZZ_Strength,
                                 total_bars - ZZ_Strength - 1);

   // ── Pass 1: collect raw pivots ──────────────────────────────────
   ZZ_PivotPoint raw[];
   int raw_count = 0;

   for(int i = scan_start; i >= scan_end; i--)
   {
      bool is_ph = ZZ_IsPivotHigh(i, ZZ_Strength);
      bool is_pl = ZZ_IsPivotLow(i,  ZZ_Strength);

      // Rare doji — both true on the same bar: keep the side further from last pivot
      if(is_ph && is_pl)
      {
         if(ZZ_CleanCount > 0)
         {
            double dh = MathAbs(iHigh(_Symbol,PERIOD_CURRENT,i) - ZZ_Clean[ZZ_CleanCount-1].price);
            double dl = MathAbs(iLow (_Symbol,PERIOD_CURRENT,i) - ZZ_Clean[ZZ_CleanCount-1].price);
            is_ph = (dh >= dl);
            is_pl = !is_ph;
         }
         else
            is_pl = false;
      }

      if(is_ph || is_pl)
      {
         ArrayResize(raw, raw_count + 1);
         raw[raw_count].time    = iTime(_Symbol, PERIOD_CURRENT, i);
         raw[raw_count].bar_idx = i;
         raw[raw_count].type    = is_ph ? 1 : -1;
         raw[raw_count].price   = is_ph ? iHigh(_Symbol, PERIOD_CURRENT, i)
                                        : iLow (_Symbol, PERIOD_CURRENT, i);
         raw_count++;
      }
   }

   if(raw_count == 0) return;

   // ── Pass 2: enforce strict alternating H / L sequence ──────────
   ArrayResize(ZZ_Clean, 0);
   ZZ_CleanCount = 0;

   for(int i = 0; i < raw_count; i++)
   {
      if(ZZ_CleanCount == 0)
      {
         ArrayResize(ZZ_Clean, 1);
         ZZ_Clean[ZZ_CleanCount++] = raw[i];
      }
      else if(raw[i].type == ZZ_Clean[ZZ_CleanCount - 1].type)
      {
         // Same direction → keep only the more extreme pivot
         if(raw[i].type ==  1 && raw[i].price > ZZ_Clean[ZZ_CleanCount-1].price)
            ZZ_Clean[ZZ_CleanCount-1] = raw[i];
         else if(raw[i].type == -1 && raw[i].price < ZZ_Clean[ZZ_CleanCount-1].price)
            ZZ_Clean[ZZ_CleanCount-1] = raw[i];
      }
      else
      {
         ArrayResize(ZZ_Clean, ZZ_CleanCount + 1);
         ZZ_Clean[ZZ_CleanCount++] = raw[i];
      }
   }

   // ── Pass 3: draw ─────────────────────────────────────────────────
   DrawZigZagLines();
}

//+------------------------------------------------------------------+
//| v14.20 ZZ-08: DrawZigZagLines                                    |
//| Draws OBJ_TREND legs between consecutive pivots.                 |
//| Optional: price labels, leg-size in pts, wave-count numbers.     |
//+------------------------------------------------------------------+
void DrawZigZagLines()
{
   if(ZZ_CleanCount < 2) return;

   for(int i = 0; i < ZZ_CleanCount - 1; i++)
   {
      ZZ_PivotPoint p1 = ZZ_Clean[i];
      ZZ_PivotPoint p2 = ZZ_Clean[i + 1];

      bool  up_leg    = (p2.price > p1.price);
      color leg_color = up_leg ? ZZ_UpColor : ZZ_DownColor;

      // ── Segment line ────────────────────────────────────────────
      string ln = ZZ_ObjPrefix + "L" + IntegerToString(i);
      if(ObjectFind(0, ln) >= 0) ObjectDelete(0, ln);
      if(ObjectCreate(0, ln, OBJ_TREND, 0, p1.time, p1.price, p2.time, p2.price))
      {
         ObjectSetInteger(0, ln, OBJPROP_COLOR,      leg_color);
         ObjectSetInteger(0, ln, OBJPROP_WIDTH,      ZZ_LineWidth);
         ObjectSetInteger(0, ln, OBJPROP_STYLE,      STYLE_SOLID);
         ObjectSetInteger(0, ln, OBJPROP_RAY_RIGHT,  false);
         ObjectSetInteger(0, ln, OBJPROP_RAY_LEFT,   false);
         ObjectSetInteger(0, ln, OBJPROP_SELECTABLE, false);
         ObjectSetInteger(0, ln, OBJPROP_HIDDEN,     true);
         ObjectSetInteger(0, ln, OBJPROP_ZORDER,     1);
      }

      // ── Pivot price label at p2 ─────────────────────────────────
      if(ZZ_ShowPivotLabels)
      {
         string pl = ZZ_ObjPrefix + "PL" + IntegerToString(i + 1);
         if(ObjectFind(0, pl) >= 0) ObjectDelete(0, pl);

         double leg_pts = MathAbs(p2.price - p1.price) / pip_size;
         string txt     = DoubleToString(p2.price, _Digits);
         if(ZZ_ShowLegPips)
            txt = txt + " (" + DoubleToString(leg_pts, 0) + "pt)";

         if(ObjectCreate(0, pl, OBJ_TEXT, 0, p2.time, p2.price))
         {
            ObjectSetString (0, pl, OBJPROP_TEXT,     txt);
            ObjectSetInteger(0, pl, OBJPROP_COLOR,    leg_color);
            ObjectSetInteger(0, pl, OBJPROP_FONTSIZE, ZZ_LabelFontSize);
            ObjectSetString (0, pl, OBJPROP_FONT,     "Segoe UI");
            // Swing high → ANCHOR_LEFT_UPPER places text below the dot
            // Swing low  → ANCHOR_LEFT_LOWER places text above the dot
            ObjectSetInteger(0, pl, OBJPROP_ANCHOR,
                             p2.type == 1 ? ANCHOR_LEFT_UPPER : ANCHOR_LEFT_LOWER);
            ObjectSetInteger(0, pl, OBJPROP_SELECTABLE, false);
            ObjectSetInteger(0, pl, OBJPROP_HIDDEN,     true);
            ObjectSetInteger(0, pl, OBJPROP_ZORDER,     2);
         }
      }

      // ── Wave-count number at midpoint of leg ────────────────────
      if(ZZ_ShowWaveCount)
      {
         string wc   = ZZ_ObjPrefix + "WC" + IntegerToString(i);
         datetime mt = (datetime)((long)p1.time + ((long)p2.time - (long)p1.time) / 2);
         double   mp = (p1.price + p2.price) / 2.0;
         if(ObjectFind(0, wc) >= 0) ObjectDelete(0, wc);
         if(ObjectCreate(0, wc, OBJ_TEXT, 0, mt, mp))
         {
            ObjectSetString (0, wc, OBJPROP_TEXT,       IntegerToString(i + 1));
            ObjectSetInteger(0, wc, OBJPROP_COLOR,      clrYellow);
            ObjectSetInteger(0, wc, OBJPROP_FONTSIZE,   ZZ_LabelFontSize - 1);
            ObjectSetString (0, wc, OBJPROP_FONT,       "Segoe UI Bold");
            ObjectSetInteger(0, wc, OBJPROP_ANCHOR,     ANCHOR_CENTER);
            ObjectSetInteger(0, wc, OBJPROP_SELECTABLE, false);
            ObjectSetInteger(0, wc, OBJPROP_HIDDEN,     true);
         }
      }
   }

   // ── Arrow at most-recent confirmed pivot ────────────────────────
   if(ZZ_CleanCount > 0)
   {
      ZZ_PivotPoint last = ZZ_Clean[ZZ_CleanCount - 1];
      string dot = ZZ_ObjPrefix + "DOT";
      if(ObjectFind(0, dot) >= 0) ObjectDelete(0, dot);
      if(ObjectCreate(0, dot, OBJ_ARROW, 0, last.time, last.price))
      {
         ObjectSetInteger(0, dot, OBJPROP_ARROWCODE,  last.type == 1 ? 233 : 234);
         ObjectSetInteger(0, dot, OBJPROP_COLOR,
                          last.type == 1 ? ZZ_UpColor : ZZ_DownColor);
         ObjectSetInteger(0, dot, OBJPROP_WIDTH,      2);
         ObjectSetInteger(0, dot, OBJPROP_SELECTABLE, false);
         ObjectSetInteger(0, dot, OBJPROP_HIDDEN,     true);
      }
   }

   ChartRedraw();
}

/* ── v14.19: CheckPriceDirectionChange() DISABLED ── BEGIN
//+------------------------------------------------------------------+
//| v14.18 Mod8: Price Direction Change Alert                        |
//| Fires when price breaks the high/low of the prior 3 M1 candles  |
//+------------------------------------------------------------------+
void CheckPriceDirectionChange()
{
   // Only run once per new M1 bar to avoid repeat alerts
   datetime current_bar = iTime(_Symbol, PERIOD_M1, 1);
   if(current_bar == Mod8_LastAlertBar)
   {
      // Same bar - still check price crosses but only alert once per direction
   }
   else
   {
      // New bar: reset flags and recalculate range
      Mod8_LastAlertBar  = current_bar;
      Mod8_AlertedUp     = false;
      Mod8_AlertedDown   = false;

      // High/Low of the 3 closed M1 candles prior to the forming candle
      // [1]=last closed, [2]=2 back, [3]=3 back
      double h1 = iHigh(_Symbol, PERIOD_M1, 1);
      double h2 = iHigh(_Symbol, PERIOD_M1, 2);
      double h3 = iHigh(_Symbol, PERIOD_M1, 3);
      double l1 = iLow(_Symbol,  PERIOD_M1, 1);
      double l2 = iLow(_Symbol,  PERIOD_M1, 2);
      double l3 = iLow(_Symbol,  PERIOD_M1, 3);

      Mod8_LastBreakHigh = MathMax(h1, MathMax(h2, h3));
      Mod8_LastBreakLow  = MathMin(l1, MathMin(l2, l3));
   }

   if(Mod8_LastBreakHigh <= 0 || Mod8_LastBreakLow <= 0) return;

   double current_ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double current_bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);

   // Bullish breakout: ask crosses above 3-candle high
   if(!Mod8_AlertedUp && current_ask > Mod8_LastBreakHigh)
   {
      Mod8_AlertedUp = true;
      PlaySound("alert.wav");
      Alert("🔼 DIRECTION CHANGE: Price broke ABOVE ", DoubleToString(Mod8_LastBreakHigh, _Digits),
            " (3-candle high). Ask=", DoubleToString(current_ask, _Digits));
      if(LogToTerminal)
         Print("Mod8 BreakUP: Ask=", DoubleToString(current_ask, _Digits),
               " > 3C-High=", DoubleToString(Mod8_LastBreakHigh, _Digits));
   }

   // Bearish breakout: bid crosses below 3-candle low
   if(!Mod8_AlertedDown && current_bid < Mod8_LastBreakLow)
   {
      Mod8_AlertedDown = true;
      PlaySound("alert.wav");
      Alert("🔽 DIRECTION CHANGE: Price broke BELOW ", DoubleToString(Mod8_LastBreakLow, _Digits),
            " (3-candle low). Bid=", DoubleToString(current_bid, _Digits));
      if(LogToTerminal)
         Print("Mod8 BreakDN: Bid=", DoubleToString(current_bid, _Digits),
               " < 3C-Low=", DoubleToString(Mod8_LastBreakLow, _Digits));
   }
}
── CheckPriceDirectionChange() DISABLED END ── */

//+------------------------------------------------------------------+
//| v14.16 B2: Move all monitored positions to break-even on demand  |
//+------------------------------------------------------------------+
void MoveAllToBreakeven()
{
   int moved = 0, skipped_protected = 0, skipped_in_loss = 0, failed = 0, total_open = 0;
   for(int i = 0; i < monitor_count; i++)
   {
      if(!PositionSelectByTicket(monitored_positions[i].ticket)) continue;
      total_open++;
      double entry     = monitored_positions[i].entry_price;
      double cur_price = (monitored_positions[i].type == POSITION_TYPE_BUY)
                         ? SymbolInfoDouble(_Symbol, SYMBOL_BID)
                         : SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      double buffer = 0.0;
      if(UseBreakevenBuffer)
      {
         if(BreakevenType == BUFFER_FIXED)
            buffer = BreakevenFixedPips * pip_size;
         else
            buffer = (Runtime_UseATR && current_atr > 0)
                     ? current_atr * BreakevenATRMulti
                     : BreakevenFixedPips * pip_size;
      }
      double new_sl = (monitored_positions[i].type == POSITION_TYPE_BUY)
                      ? entry + buffer : entry - buffer;
      double cur_sl = PositionGetDouble(POSITION_SL);
      double cur_tp = PositionGetDouble(POSITION_TP);

      // Check if price has moved far enough to place BE SL safely
      bool price_past_be = (monitored_positions[i].type == POSITION_TYPE_BUY)
                           ? (cur_price > new_sl + pip_size)
                           : (cur_price < new_sl - pip_size);
      if(!price_past_be)
      {
         skipped_in_loss++;
         if(LogToTerminal)
            Print("BE_ALL SKIP (in loss) #", monitored_positions[i].ticket,
                  " cur=", DoubleToString(cur_price, _Digits),
                  " new_sl=", DoubleToString(new_sl, _Digits));
         continue;
      }

      // Check if existing SL is already at or better than target BE level
      bool already_protected = false;
      if(cur_sl > 0)
      {
         already_protected = (monitored_positions[i].type == POSITION_TYPE_BUY)
                             ? (cur_sl >= new_sl - point_value)
                             : (cur_sl <= new_sl + point_value);
      }
      if(already_protected)
      {
         skipped_protected++;
         if(LogToTerminal)
            Print("BE_ALL SKIP (already protected) #", monitored_positions[i].ticket,
                  " cur_sl=", DoubleToString(cur_sl, _Digits),
                  " new_sl=", DoubleToString(new_sl, _Digits));
         continue;
      }

      if(ModifyPositionSLTP(monitored_positions[i].ticket, new_sl, cur_tp, "BE_ALL"))
      {
         monitored_positions[i].breakeven_locked = true;
         moved++;
         if(LogToTerminal)
            Print("BE_ALL MOVED #", monitored_positions[i].ticket,
                  "  SL->", DoubleToString(new_sl, _Digits),
                  "  entry:", DoubleToString(entry, _Digits),
                  "  buf:", DoubleToString(buffer / pip_size, 1), " pips");
      }
      else
      {
         failed++;
         if(LogToTerminal)
            Print("BE_ALL FAILED #", monitored_positions[i].ticket, " — broker rejected modify");
      }
   }

   if(LogToTerminal)
      Print("BE_ALL: total=", total_open, " moved=", moved,
            " already_protected=", skipped_protected,
            " in_loss=", skipped_in_loss, " failed=", failed);

   // Only alert on actionable outcomes — suppress informational false positives
   if(!ShowAlert) return;
   if(total_open == 0)
      Alert("ℹ️ BE ALL: No open positions.");
   else if(moved > 0 && skipped_in_loss == 0 && skipped_protected == 0)
      Alert("✅ BE ALL: All ", moved, " position(s) moved to break-even.");
   else if(moved > 0)
      Alert("✅ BE ALL: ", moved, " moved. ", skipped_protected, " already protected. ", skipped_in_loss, " still in loss.");
   else if(skipped_in_loss > 0 && skipped_protected == 0)
      Alert("⛔ BE ALL: ", skipped_in_loss, " position(s) still in loss — cannot move to BE yet.");
   else if(skipped_protected > 0 && skipped_in_loss == 0)
      Alert("✅ BE ALL: All positions already protected at or beyond break-even.");
   else if(failed > 0)
      Alert("⚠️ BE ALL: ", failed, " modify(s) rejected by broker. Check Journal.");
   // Mixed state (some protected, some in loss) — terminal log only, no popup
}

int CloseAllPositions(string reason);
//+------------------------------------------------------------------+
//| Modify Position SLTP                                             |
//+------------------------------------------------------------------+
bool ModifyPositionSLTP(ulong ticket, double new_sl, double new_tp, string reason)
{
   if(!PositionSelectByTicket(ticket)) return false;
   new_sl = NormalizeDouble(new_sl, _Digits);
   new_tp = NormalizeDouble(new_tp, _Digits);
   MqlTradeRequest request; MqlTradeResult result;
   ZeroMemory(request); ZeroMemory(result);
   request.action   = TRADE_ACTION_SLTP;
   request.position = ticket;
   request.symbol   = PositionGetString(POSITION_SYMBOL);
   request.sl       = new_sl;
   request.tp       = new_tp;
   request.magic    = MagicNumber;
   request.comment  = reason;
   bool success = OrderSend(request, result);
   if(success && (result.retcode == TRADE_RETCODE_DONE || result.retcode == TRADE_RETCODE_NO_CHANGES))
     {
      if(LogToTerminal) Print("SL/TP modified ", ticket,
                              " SL=", DoubleToString(new_sl, _Digits),
                              " TP=", DoubleToString(new_tp, _Digits),
                              " - ", reason);
      return true;
     }
   Print("Failed to modify SL/TP ", ticket, " - Error ", result.retcode);
   return false;
}
int GetMonitorIndexByTicket(ulong ticket);
void DrawOrUpdateSLTPLines(int idx);
// AddPositionToMonitor(ulong ticket) — v15.2: orphan forward declaration removed.
// Position-adding logic is handled entirely inline by ScanAndAddPositions().
void UpdateMonitorGUI();
void MonitorPositions();
void ProcessTrailingStop(int idx, double current_price, double pip_distance);
void ProcessFixedStops(int idx, double pip_distance);
void RemoveFromMonitor(int idx);
bool ClosePositionAtMarket(ulong ticket, string reason);
bool ClosePartialPosition(ulong ticket, double volume, string reason);
void ExecuteSmartEntry(int type);
void DrawNewsLines();
void DrawTimeFilterLines();
void SaveDailySnapshot(double balance);
bool IsNewBar();

//+------------------------------------------------------------------+
//| Expert initialization                                            |
//+------------------------------------------------------------------+
datetime GetLockClock()
{
   datetime now = TimeTradeServer();
   if(now <= 0) now = TimeLocal();
   return now;
}

int OnInit()
{
   Runtime_GuiScale = GuiScale;
   Runtime_AccountType = AccountType;
   Runtime_FlexFundedAccount = FlexFundedAccount;
   
   Print("Initializing TF Complete Manager v15.2");
   EventSetTimer(1);
   
   symbol_digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
   point_value   = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   
   string sym_name = _Symbol;
   StringToUpper(sym_name);
   is_index = (StringFind(sym_name, "500") >= 0 || StringFind(sym_name, "30") >= 0 || 
                    StringFind(sym_name, "100") >= 0 || StringFind(sym_name, "GER") >= 0 || 
                    StringFind(sym_name, "UK") >= 0 || StringFind(sym_name, "FRA") >= 0 || 
                    StringFind(sym_name, "JPN") >= 0 || StringFind(sym_name, "SPX") >= 0 ||
                    symbol_digits <= 3);

   if (is_index)
   {
      pip_size = 0.01;
      
      if(StringFind(sym_name, "US30") >= 0 || StringFind(sym_name, "WALL") >= 0) pip_size = 1.00;
      if(StringFind(sym_name, "NAS") >= 0 || StringFind(sym_name, "USTECH") >= 0) pip_size = 0.10;
      if(StringFind(sym_name, "GER") >= 0 || StringFind(sym_name, "DE40") >= 0) pip_size = 1.00;
      
      Print("Index detected: Forcing pip_size = ", DoubleToString(pip_size, 2));
      if(pip_size == 0.01) Alert("US500 Mode: 1 Pip = $0.01 Price Change (1:1 with MT5 points)");
   }
   else if (symbol_digits == 5)
      pip_size = 0.0001;
   else if (symbol_digits == 3)
      pip_size = 0.01;
   else
      pip_size = MathPow(10, -symbol_digits);

   int filling_flags = (int)SymbolInfoInteger(_Symbol, SYMBOL_FILLING_MODE);
   int exe_mode = (int)SymbolInfoInteger(_Symbol, SYMBOL_TRADE_EXEMODE);
   double tick_val = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double tick_size_check = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   double contract_size_check = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_CONTRACT_SIZE);
   
   PrintFormat("Initialization: Symbol=%s, Digits=%d, Point=%f, PipSize=%f, IsIndex=%s, FillingFlags=%d, ExeMode=%d", 
               _Symbol, symbol_digits, point_value, pip_size, (is_index?"YES":"NO"), filling_flags, exe_mode);
   
   if(ShowAlert){
      Sleep(3000);
      if(!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED)) Alert("CRITICAL WARNING: AutoTrading DISABLED in Terminal!");
      if(!AccountInfoInteger(ACCOUNT_TRADE_ALLOWED))   Alert("CRITICAL WARNING: Trading DISABLED for Account!");
      if(!AccountInfoInteger(ACCOUNT_TRADE_EXPERT))    Alert("CRITICAL WARNING: EAs DISABLED for Account!");
      ENUM_SYMBOL_TRADE_MODE _tm=(ENUM_SYMBOL_TRADE_MODE)SymbolInfoInteger(_Symbol,SYMBOL_TRADE_MODE);
      if(_tm==SYMBOL_TRADE_MODE_DISABLED)       Alert("CRITICAL WARNING: Trading DISABLED for Symbol!");
      else if(_tm==SYMBOL_TRADE_MODE_CLOSEONLY) Alert("CRITICAL WARNING: Symbol is CLOSE ONLY!");
   }else{
      ENUM_SYMBOL_TRADE_MODE _tm=(ENUM_SYMBOL_TRADE_MODE)SymbolInfoInteger(_Symbol,SYMBOL_TRADE_MODE);
      if(!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED)) Print("INIT WARN: AutoTrading DISABLED");
      if(!AccountInfoInteger(ACCOUNT_TRADE_ALLOWED))   Print("INIT WARN: Trading DISABLED");
      if(!AccountInfoInteger(ACCOUNT_TRADE_EXPERT))    Print("INIT WARN: EAs DISABLED");
      if(_tm==SYMBOL_TRADE_MODE_DISABLED)              Print("INIT WARN: Trading DISABLED for Symbol");
      else if(_tm==SYMBOL_TRADE_MODE_CLOSEONLY)        Print("INIT WARN: Symbol CLOSE ONLY");
   }

   long login = AccountInfoInteger(ACCOUNT_LOGIN);
   PeakFileName = StringFormat("TF_HWM_%d.dat", login);
   LogFileName  = StringFormat("TF_Log_%d.csv", login);
   StateFileName = StringFormat("TF_State_%d.dat", login);

   if (UseAutoDetection)
   {
      double current_equity = AccountInfoDouble(ACCOUNT_EQUITY);
      WorkingAccountSize = (current_equity > 0.0) ? current_equity : AccountSize;
   }
   else
      WorkingAccountSize = AccountSize;

   Runtime_DailyLossLimitPct   = DailyLossLimitPct;
   Runtime_TFShieldPercentage  = TFShieldPercentage;
   Runtime_MaxTrailingDDPct    = MaxTrailingDrawdownPct;
   Runtime_WarningThreshold    = WarningThreshold;
   Runtime_DailyGainTargetPct  = DailyGainTargetPct;
   Runtime_DailyGainTarget     = WorkingAccountSize * (DailyGainTargetPct / 100.0);
   Runtime_TotalTargetGainPct  = TotalTargetGainPct;

   Runtime_RatchetActivation   = WorkingAccountSize * (RatchetActivationPct / 100.0);
   Runtime_RatchetLock         = WorkingAccountSize * (RatchetLockPct / 100.0);
   ConsecutiveLossCount        = 0;
   TiltBlockEndTime            = 0;

   Runtime_PriorDayClose       = 0.0;
   Runtime_HighWaterMark       = 0.0;
   
   Runtime_EnableAutoClose     = EnableAutoClose;
   Runtime_UseTimeFilter       = UseTimeFilter;
   Runtime_UseNewsFilter       = UseNewsFilter;
   Runtime_NewsPreMinutes      = NewsPreMinutes;
   Runtime_NewsPostMinutes     = NewsPostMinutes;
   Runtime_NewsCurrencyFilter  = NewsCurrencyFilter;
   Runtime_IncludeMediumImpact = IncludeMediumImpact;
   Runtime_IncludeLowImpact    = IncludeLowImpact;
   Runtime_NewsColorHigh       = NewsColorHigh;
   Runtime_NewsColorMedium     = NewsColorMedium;
   Runtime_NewsColorLow        = NewsColorLow;
   Runtime_RiskPerTradePct     = RiskPerTradePct;
   Runtime_FixedLotSize        = FixedLotSize;

   Runtime_SL_Pips            = DefaultSL_Pips;
   Runtime_TP_Pips            = DefaultTP_Pips;
   Runtime_TrailingEnabled    = DefaultTrailingEnabled;
   Runtime_TrailingDistance   = TrailingDistance_Pips;
   Runtime_TrailingActivation = TrailingActivation_Pips;

   ArrayResize(monitored_positions, 0);
   monitor_count = 0;

   Runtime_UseATR = Input_UseATR;
   Runtime_EnableEmergencyStop = EnableEmergencyStop;
   Runtime_LockReleaseMinutes = MathMax(0, LockReleaseMinutes);
   Runtime_LockReleaseEndTime = (Runtime_EnableEmergencyStop && Runtime_LockReleaseMinutes > 0) ? (GetLockClock() + Runtime_LockReleaseMinutes * 60) : 0;
   if (Runtime_UseATR)
   {
      atr_handle = iATR(_Symbol, PERIOD_CURRENT, ATR_Period);
      if (atr_handle == INVALID_HANDLE)
      {
         Print("❌ Failed to create ATR handle - disabling ATR mode");
         Runtime_UseATR = false;
      }
      else
         Print("✓ ATR enabled (period=", ATR_Period, ")");
   }

   UseServerTrailing = UseRealTrailing;

   int fh = FileOpen(PeakFileName, FILE_READ|FILE_BIN|FILE_COMMON);
   if (fh != INVALID_HANDLE)
   {
      HighWaterMark = FileReadDouble(fh);
      FileClose(fh);
   }
   else
      HighWaterMark = WorkingAccountSize;

   CurrentEquity = AccountInfoDouble(ACCOUNT_EQUITY);
   long account_number = AccountInfoInteger(ACCOUNT_LOGIN);
   if (account_number != CurrentAccountNumber)
   {
      CurrentAccountNumber   = account_number;
      TFShieldBreached       = false;
      WarningIssued          = false;
      DailyLossBreached      = false;
      TLLBreached            = false;
      DailyDDWarningIssued   = false;
      DailyTargetReached     = false;
      HighWaterMark          = CurrentEquity;
      PriorDayClose          = CurrentEquity;
      DailyHighWaterMark     = CurrentEquity;
      SaveHighWaterMark();
      RecalculateLimits();
      if (LogToTerminal)
         Print("🔄 ACCOUNT RESET #", account_number, " HWM=$", DoubleToString(CurrentEquity, 2));
   }

   if (Runtime_PriorDayClose > 0.0)
      PriorDayClose = Runtime_PriorDayClose;
   else
      PriorDayClose = CurrentEquity;

   // v14.28: Try to restore PDC / HWM / Bal from state file
   {
      double s_pdc=0, s_hwm=0, s_bal=0;
      if(LoadDailyState(s_pdc, s_hwm, s_bal))
      {
         PriorDayClose      = s_pdc;
         if(s_hwm > HighWaterMark) HighWaterMark = s_hwm;
         WorkingAccountSize = s_bal;
         Print("v14.28 State restored: PDC=",DoubleToString(s_pdc,2),
               "  HWM=",DoubleToString(s_hwm,2),
               "  Bal=",DoubleToString(s_bal,2));
      }
      else Print("v14.28 No valid state file — using live values.");
   }

   RecalculateLimits();
   DailyHighWaterMark = CurrentEquity;

   if (CurrentEquity > HighWaterMark && Runtime_HighWaterMark == 0.0)
   {
      HighWaterMark = CurrentEquity;
      SaveHighWaterMark();
      RecalculateLimits();
   }

   LastResetDate         = TimeCurrent();
   CurrentAccountNumber  = AccountInfoInteger(ACCOUNT_LOGIN);
   TodaysRealizedProfit  = 0.0;
   CurrentFloatingLoss   = 0.0;
   CurrentFloatingPL     = 0.0;
   TodaysTotalGain       = 0.0;
   TFShieldBreached      = false;
   WarningIssued         = false;
   DailyLossBreached     = false;
   TLLBreached           = false;
   DailyDDWarningIssued  = false;
   DailyTargetReached    = false;
   SettingsPanelExpanded = false;

   RecalculateBuffers();   // v14.33: compute correct buffers before first panel render

   if (ShowRiskPanel)
   {
         CreateTransparentPanel();
      }

   if (ShowMonitorGUI)
   {
         UpdateMonitorGUI();
   }

   ChartRedraw();
   
   Print("========================================");
   Print("TF COMPLETE MANAGER v15.2");
   Print("Loaded at Server Time: ", TimeToString(TimeCurrent()));
   Print("========================================");
   Print("✓ VERSION: 15.2");
   Print("✓ GUI: Object names reconciled — live tick updates active");
   Print("✓ GUI: Inactive input race condition fixed (all edit fields)");
   Print("✓ GUI: Settings panel inputs validated with side-effect propagation");
   Print("✓ Symbol: ", _Symbol);
   Print("✓ Digits: ", symbol_digits);
   Print("✓ pip_size: ", DoubleToString(pip_size, 5));
   Print("✓ Account: #", AccountInfoInteger(ACCOUNT_LOGIN));
   Print("========================================");
   Print("INPUT SETTINGS:");
   Print(" ShowRiskPanel: ",   ShowRiskPanel   ? "TRUE" : "FALSE");
   Print(" EnableAutoClose: ", EnableAutoClose ? "TRUE" : "FALSE");
   Print(" ShowMonitorGUI: ", ShowMonitorGUI  ? "TRUE" : "FALSE");
   Print(" LogToTerminal: ",  LogToTerminal   ? "TRUE" : "FALSE");
   Print(" Runtime_SL_Pips: ", Runtime_SL_Pips);
   Print(" Runtime_TP_Pips: ", Runtime_TP_Pips);
   Print("========================================");
   Print("BUTTON CHECK:");
   if (ShowRiskPanel)
      Print(" ✓ Risk Panel ENABLED - Button will be created");
   else
      Print(" ❌ Risk Panel DISABLED - Button will NOT be created!");
   Print("========================================");
   Print("Account Size: $",       DoubleToString(WorkingAccountSize, 2));
   Print("High Water Mark: $",    DoubleToString(HighWaterMark, 2));
   Print("Prior Day Close: $",    DoubleToString(PriorDayClose, 2));
   Print("DLL Limit: $",          DoubleToString(DailyLossLimit, 2));
   Print("TLL Limit: $",          DoubleToString(TLLLimit, 2));
   Print("DLL Breach Level: $",   DoubleToString(DLL_BreachLevel, 2));
   Print("TLL Breach Level: $",   DoubleToString(TLL_BreachLevel, 2));
   // v14.21: Account type & limit-basis log
   string v1421_acct = (Runtime_AccountType==TF_STEP1)   ? "1-Step Evaluation"  :
                       (Runtime_AccountType==TF_STEP2)   ? "2-Step Evaluation"  :
                       (Runtime_AccountType==TF_INSTANT) ? "Instant Funding"    : "Flex Challenge";
   Print("Account Type    : ", v1421_acct,
         (Runtime_AccountType==TF_FLEX ? (Runtime_FlexFundedAccount ? " [Funded]" : " [Eval]") : ""));
   Print("DLL Basis       : InitBal x ", DoubleToString(Runtime_DailyLossLimitPct,1),
         "% = $", DoubleToString(DLL_FixedAmount,2),
         " | Daily Floor = $", DoubleToString(DLL_BreachLevel,2));
   Print("TLL Type        : ", TLL_IsTrailing ? "TRAILING (floor locks at InitBal)" : "STATIC (fixed at inception)");
   Print("TLL Basis       : InitBal x ", DoubleToString(Runtime_MaxTrailingDDPct,1),
         "% = $", DoubleToString(TLL_FixedAmount,2),
         " | Breach Level = $", DoubleToString(TLL_BreachLevel,2));
   // v14.23: Warn if user inputs differ from TF-mandated values
   if(MathAbs(DailyLossLimitPct    - Runtime_DailyLossLimitPct) > 0.01 ||
      MathAbs(MaxTrailingDrawdownPct - Runtime_MaxTrailingDDPct)  > 0.01)
   {
      string warn_msg = StringFormat(
         "v14.23 NOTE: Input DLL=%.1f%% / TLL=%.1f%% overridden by TF rules → DLL=%.1f%% / TLL=%.1f%%",
         DailyLossLimitPct, MaxTrailingDrawdownPct,
         Runtime_DailyLossLimitPct, Runtime_MaxTrailingDDPct);
      Print("⚠  ", warn_msg);
      if(ShowAlert) Alert(warn_msg);
   }
   Print("Symbol Digits: ", symbol_digits, " | Point: ", point_value);
   Print("Detected Pip Size: ", pip_size, " (Is US500/SPX: ", (pip_size == 0.01), ")");
   Print("========================================");

   
   // v14.20 ZZ-09: Initial ZigZag draw on EA load
   if(ZZ_Enabled)
      CalculateZigZag();

ScanAndAddPositions();
   return(INIT_SUCCEEDED);
}


//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+

void OnTick()
{
   // NOTE (v15.2 Fix): The g_active_edit_object OnTick guard was REMOVED.
   // Rationale: UpdateRiskPanel() (called every tick) never touches any OBJ_EDIT
   // object, and UpdateSettingsPanel() is now buttons-only (v15.2 Fix E).
   // The old guard caused a permanent freeze: CHARTEVENT_OBJECT_ENDEDIT only
   // fires reliably on Enter — if the user clicked an edit box and then clicked
   // the chart background without pressing Enter, g_active_edit_object was never
   // cleared and OnTick was permanently paused, making the entire EA appear dead.
   // The variable is still maintained for the AddSettingsRow rebuild-guard only.

   // --- The rest of your original OnTick function starts here ---
   if(IsStopped()) return;

   static datetime _scan_sec=0;
   if(TimeCurrent()!=_scan_sec){ ScanAndAddPositions(); _scan_sec=TimeCurrent(); }
   if(IsStopped()) return;
   
   CurrentEquity = AccountInfoDouble(ACCOUNT_EQUITY);
   
   if(CurrentEquity > HighWaterMark)
   {
      HighWaterMark = CurrentEquity;
      RecalculateLimits();   // v14.21: TLL_BreachLevel auto-recalculated inside
      if(TLL_IsTrailing) SaveHighWaterMark();
      SaveDailyState();   // v14.28: persist PDC+HWM+Bal on every HWM update;
   }
   
   TodaysTotalGain = CurrentEquity - PriorDayClose;
   
   // ---------------------------------------------------------
   // UNBLOCK CHECK (Countdown)
   // ---------------------------------------------------------
   if (UnblockCountdownMinutes > 0)
   {
      datetime now = TimeCurrent();
      
      if (DailyLossBreached && DailyLossBreachTime > 0 && (now - DailyLossBreachTime >= UnblockCountdownMinutes * 60))
      {
         DailyLossBreached = false;
         DailyLossBreachTime = 0;
         DailyDDWarningIssued = false;
         Print("✅ Daily Loss Limit Block EXPIRED (", UnblockCountdownMinutes, "m passed). Trading Resumed.");
         if(ShowAlert) Alert("✅ Daily Loss Limit Block EXPIRED. Trading Resumed.");
      }
      
      if (DailyTargetReached && DailyTargetBreachTime > 0 && (now - DailyTargetBreachTime >= UnblockCountdownMinutes * 60))
      {
         DailyTargetReached = false;
         DailyTargetBreachTime = 0;
         Print("✅ Daily Gain Target Block EXPIRED (", UnblockCountdownMinutes, "m passed). Trading Resumed.");
         if(ShowAlert) Alert("✅ Daily Gain Target Block EXPIRED. Trading Resumed.");
      }
   }
   
   CalculateRiskMetrics();
   
   CheckRatchet();
   
   RecalculateBuffers();
   
   if(!DailyLossBreached && CurrentEquity < DLL_BreachLevel)   // v14.25: strict < prevents false trigger at exact equality
   {
      DailyLossBreached=true; DailyLossBreachTime=TimeCurrent();
      if(PositionsTotal()>0) CloseAllPositions("DLL Breach");   // v14.25: liquidate open trades on DLL breach
      if(!DailyLossAlertSent && ShowAlert){
         Alert(StringFormat("⛔ DLL HIT!  Day start=$%.2f | Now=$%.2f | Loss=-$%.2f | Limit=$%.2f",
               PriorDayClose, CurrentEquity, PriorDayClose-CurrentEquity, DLL_FixedAmount));
         DailyLossAlertSent=true; }
      if(LogToTerminal) PrintFormat("v14.25 DLL BREACH: PDC=%.2f Equity=%.2f Loss=%.2f Limit=%.2f Floor=%.2f",
            PriorDayClose, CurrentEquity, PriorDayClose-CurrentEquity, DLL_FixedAmount, DLL_BreachLevel);
   }
   // v14.16 B1: TLL breach
   if(!TLLBreached && CurrentEquity < TLL_BreachLevel)   // v14.25: strict < prevents false trigger at exact equality
   {
      TLLBreached=true; TLLBreachTime=TimeCurrent();
      // TLLCooldownEndTime=TimeCurrent()+TLL_CooldownMinutes*60; // REMOVED: Cooldown is not needed for terminal breach.
      TLLAlertSent=false;
      if(PositionsTotal()>0) CloseAllPositions("TLL Breach");
      if(!TLLAlertSent){
         if(ShowAlert)     Alert("⛔ TLL BREACHED! TRADING PERMANENTLY STOPPED. Account liquidated.");
         if(LogToTerminal) Print("⛔ TLL BREACH Eq=$",DoubleToString(CurrentEquity,2)," Lvl=$",DoubleToString(TLL_BreachLevel,2),". TRADING STOPPED.");
         TLLAlertSent=true;}
   }
   // v14.40: Cooldown is now used for the 80% RISK CRITICAL warning, not the terminal TLL breach.
   if(TLLCooldownEndTime > 0 && TimeCurrent() >= TLLCooldownEndTime)
   {
      TLLCooldownEndTime = 0; // Reset the timer
      if(LogToTerminal) Print("✅ Risk Warning Cooldown expired. Trading RESUMED ",TimeToString(TimeCurrent()));
      if(ShowAlert)     Alert("✅ Risk Warning Cooldown expired. Trading RESUMED.");
   }
   
   if(!DailyTargetReached && EnableDailyTargetAutoClose && 
      CurrentEquity >= (PriorDayClose + Runtime_DailyGainTarget))
   {
      DailyTargetReached = true;
      DailyTargetBreachTime = TimeCurrent();
      if(!GainTargetAlertSent && ShowAlert)
      {
         Alert("🏆 DAILY GAIN TARGET HIT! Trading stopped.");
         GainTargetAlertSent = true;
      }
   }
   
   // Reset alerts on new day
   static datetime last_reset_check = 0;
   if(TimeCurrent() - last_reset_check >= 60)
   {
      last_reset_check = TimeCurrent();
      MqlDateTime dt;
      TimeToStruct(TimeCurrent(), dt);
      static int last_day=dt.day; static int last_reset_key=-1;
      int  effective_reset_hour=(DailyResetHour+BrokerGMTOffset)%24;  // v14.25: correct UTC→broker-local hour
      bool a2_new_day=(dt.day!=last_day);
      int  a2_key=dt.day*100+effective_reset_hour;
      bool a2_hour=(dt.hour==effective_reset_hour&&dt.min==0&&last_reset_key!=a2_key);
      if(a2_new_day||a2_hour)
      {
         last_day=dt.day; last_reset_key=a2_key;
         DailyLossAlertSent=false; GainTargetAlertSent=false; RatchetAlertSent=false; TLLAlertSent=false;
         DailyLossBreached=false; DailyTargetReached=false;
         TLLBreached=false;
         PriorDayClose=CurrentEquity;
         RecalculateLimits();   // v14.25: resets DLL_BreachLevel to new PDC-DLLFixed (clears any ratchet floor)
         SaveDailyState();      // v14.28: persist new PDC immediately after daily reset
         if(LogToTerminal) PrintFormat("v14.28 Daily reset: PDC=%.2f DLL_Floor=%.2f TLL_Floor=%.2f",
               PriorDayClose, DLL_BreachLevel, TLL_BreachLevel);
         if(LogToTerminal) Print("Daily reset ",TimeToString(TimeCurrent())," EffHour=",effective_reset_hour," GMT=UTC+",BrokerGMTOffset);
      }
   }
   
   if(!CheckTradingConditions()) return;
   // CheckPriceDirectionChange();  // v14.18 Mod8 DISABLED in v14.20
   // v14.20 ZZ-11: ZigZag — recalculate once per new bar
   if(ZZ_Enabled && IsNewBar())
      CalculateZigZag();

   
   // ALWAYS run monitoring to update lines and sync logic
   SyncMonitoredPositions();
   MonitorPositions();
   
   // --- GUI UPDATE THROTTLE ---
   static uint last_gui_update = 0;
   if(GetTickCount() - last_gui_update > 200)
   {
      if(ShowRiskPanel) UpdateRiskPanel();   // v14.33: lightweight per-tick value update
      if(ShowMonitorGUI) UpdateMonitorGUI();
      ChartRedraw();
      last_gui_update = GetTickCount();
   }
}

//+------------------------------------------------------------------+
//| Calculate Risk Metrics                                           |
//+------------------------------------------------------------------+
void CalculateRiskMetrics()
{
   // v14.31: DistToDGT is computed in CreateTransparentPanel using the same target-level convention as TTG
   double ttg_target_amount = WorkingAccountSize * (Runtime_TotalTargetGainPct / 100.0);
   DistToTTG = (WorkingAccountSize + ttg_target_amount) - CurrentEquity;

   RiskExposure = 0.0;
   for(int i = 0; i < monitor_count; i++)
   {
      if(!PositionSelectByTicket(monitored_positions[i].ticket)) continue;
      double vol = PositionGetDouble(POSITION_VOLUME);
      double sl  = PositionGetDouble(POSITION_SL);
      double cur_price = (monitored_positions[i].type == POSITION_TYPE_BUY)
                         ? SymbolInfoDouble(_Symbol, SYMBOL_BID)
                         : SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      double dist = 0.0;
      if(sl > 0)   dist = MathAbs(cur_price - sl);
      else if(monitored_positions[i].sl_pips > 0) dist = monitored_positions[i].sl_pips * pip_size;
      if(dist <= 0) continue;
      if(is_index && pip_size > 0) RiskExposure += dist * vol;
      else
      {
         double tv = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
         double ts = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
         if(ts > 0) RiskExposure += dist * vol * tv / ts;
      }
   }
   RiskUnderOverTarget = DailyLossLimit - RiskExposure;
}

//+------------------------------------------------------------------+
//| Check Profit Ratchet                                             |
//+------------------------------------------------------------------+
void CheckRatchet()
{
   if(!EnableProfitRatchet) return;
   
   if(TodaysTotalGain >= Runtime_RatchetActivation)
   {
      double ratchet_level = PriorDayClose + Runtime_RatchetLock;
      
      if(ratchet_level > DLL_BreachLevel)
      {
         DLL_BreachLevel = ratchet_level;
         DailyLossLimit = DLL_FixedAmount;  // v14.25: fixed per-day budget; DLL_BreachLevel is the equity floor
         
         static datetime last_ratchet_msg=0;
         if(!RatchetAlertSent){
            Print("🔒 PROFIT RATCHET ACTIVATED! DLL→",DoubleToString(DLL_BreachLevel,2));
            if(ShowAlert) Alert("🔒 PROFIT RATCHET ACTIVATED! Gains Locked.");
            RatchetAlertSent=true; last_ratchet_msg=TimeCurrent();}
      }
   }
}

//+------------------------------------------------------------------+
//| Recalculate Limits  — v14.21 TF-compliant                        |
//|                                                                  |
//| DLL (all account types):                                         |
//|   Fixed $ = InitialBalance × DLL_pct   (NOT % of prior day EOD) |
//|   Daily floor = PriorDayClose - DLL_fixed_amount                 |
//|                                                                  |
//| TLL — 2-Step Evaluation (STATIC):                                |
//|   Breach level = InitialBalance × (1 - TLL_pct/100) — FIXED     |
//|   HWM does NOT move the floor.                                   |
//|                                                                  |
//| TLL — 1-Step / Instant / Flex (TRAILING):                        |
//|   Breach level = HWM - (InitialBalance × TLL_pct/100)            |
//|   Floor cap: breach level can never exceed InitialBalance        |
//|   (floor locks at InitialBalance once HWM = InitBal + TLL_fixed) |
//+------------------------------------------------------------------+
void RecalculateLimits()
{
   double pdc = (Manual_PriorDayClose  > 0) ? Manual_PriorDayClose  : PriorDayClose;
   // v14.27: guard against stale/corrupt manual PDC
   if(pdc > WorkingAccountSize * 2.5 || pdc < WorkingAccountSize * 0.1)
   {
      if(LogToTerminal) PrintFormat("v14.27 WARN: PDC %.2f out of range [%.2f-%.2f] — auto-cleared",
                                    pdc, WorkingAccountSize*0.1, WorkingAccountSize*2.5);
      Manual_PriorDayClose = 0.0;  // auto-clear corrupt value
      pdc = PriorDayClose;         // fall back to auto
   }
   double hwm = (Manual_HighWaterMark  > 0) ? Manual_HighWaterMark  : HighWaterMark;
   double bal = (Manual_StartingBalance > 0) ? Manual_StartingBalance : WorkingAccountSize;

   StartingBalance    = bal;
   WorkingAccountSize = bal;

   // ── TF Shield ─────────────────────────────────────────────────
   TFShieldLimit = bal * (Runtime_TFShieldPercentage / 100.0);
   WarningLevel  = TFShieldLimit * (Runtime_WarningThreshold / 100.0);

   // ── DLL: fixed dollar amount based on INITIAL balance ─────────
   // TF rule: % applies to the account's initial/starting balance,
   // not the prior day close balance.
   DLL_FixedAmount     = bal * (Runtime_DailyLossLimitPct / 100.0);
   DailyLossLimit      = DLL_FixedAmount;
   DailyDDWarningLevel = DLL_FixedAmount * (Runtime_WarningThreshold / 100.0);
   DLL_BreachLevel     = pdc - DLL_FixedAmount;

   // ── TLL: account-type-dependent ───────────────────────────────
   // v14.23: Fully self-configuring per-account percentages.
   // Source: TradingFunds official FAQ + Flex Challenge image (2026-03-01).
   // User inputs (DailyLossLimitPct / MaxTrailingDrawdownPct) are IGNORED
   // for limit calculation — the EA enforces the correct TF rules automatically.
   //
   //  Account          DLL%   TLL%   TLL Type
   //  1-Step Eval       5%     8%    Trailing
   //  2-Step Eval       5%     8%    Static
   //  Instant Funding   5%     6%    Trailing
   //  Flex Eval         5%     8%    Trailing
   //  Flex Funded       5%     6%    Trailing

   double effective_dll_pct = 5.0;   // universal across all TF account types
   double effective_tll_pct = 8.0;   // default — overridden below for Instant & Flex Funded

   switch(Runtime_AccountType)
   {
      case TF_STEP1:    effective_dll_pct = 5.0; effective_tll_pct = 8.0; break;
      case TF_STEP2:    effective_dll_pct = 5.0; effective_tll_pct = 8.0; break;
      case TF_INSTANT:  effective_dll_pct = 5.0; effective_tll_pct = 6.0; break;
      case TF_FLEX:
         effective_dll_pct = 5.0;
         effective_tll_pct = Runtime_FlexFundedAccount ? 6.0 : 8.0;
         break;
      default:          effective_dll_pct = 5.0; effective_tll_pct = 8.0; break;
   }

   // Override Runtime percentages so all downstream logic stays consistent
   Runtime_DailyLossLimitPct = effective_dll_pct;
   Runtime_MaxTrailingDDPct  = effective_tll_pct;

   DLL_FixedAmount = bal * (effective_dll_pct / 100.0);
   TLL_FixedAmount = bal * (effective_tll_pct / 100.0);
   TLLLimit        = TLL_FixedAmount;

   TLL_IsTrailing = (Runtime_AccountType != TF_STEP2);

   if(!TLL_IsTrailing)
   {
      // 2-Step Evaluation — STATIC: breach level is fixed at inception
      TLL_BreachLevel = bal - TLL_FixedAmount;
      TLL_LockFloor   = TLL_BreachLevel;   // permanent — never changes
   }
   else
   {
      // 1-Step / Instant / Flex — TRAILING TLL
      // Breach level trails HWM upward, but is capped at InitialBalance.
      // Once HWM reaches (InitialBalance + TLL_fixed_amount) the floor
      // locks at InitialBalance and stops trailing further up.
      TLL_LockFloor   = bal;
      TLL_BreachLevel = hwm - TLL_FixedAmount;
      if(TLL_BreachLevel > TLL_LockFloor)
         TLL_BreachLevel = TLL_LockFloor;
   }
}

//+------------------------------------------------------------------+
//| Recalculate Buffers — FIXED DLL (v14.33)                        |
//+------------------------------------------------------------------+
void RecalculateBuffers()
{
   double pdc=(Manual_PriorDayClose>0)?Manual_PriorDayClose:PriorDayClose;
   if(pdc>WorkingAccountSize*2.5||pdc<WorkingAccountSize*0.1) { Manual_PriorDayClose=0.0; pdc=PriorDayClose; }  // v14.27 guard
   double hwm=(Manual_HighWaterMark  >0)?Manual_HighWaterMark :HighWaterMark;
   double bal=(Manual_StartingBalance>0)?Manual_StartingBalance:WorkingAccountSize;
   double equity=AccountInfoDouble(ACCOUNT_EQUITY);
   TodaysTotalGain=equity-pdc;

   // v14.33 FIX: DLL buffer ALWAYS calculated from PriorDayClose, never from HighWaterMark.
   // The ratchet can raise DLL_BreachLevel, but the reported buffer must reflect the
   // true daily room (how far equity is above the daily floor), not the ratchet floor.
   Buffer_DLL     = equity - (pdc - DLL_FixedAmount);
   Buffer_DLL_Pct = (DLL_FixedAmount > 0) ? (Buffer_DLL / DLL_FixedAmount) * 100.0 : 0.0;

   // v14.33: TLL buffer — trailing or static, unchanged from v14.32
   if(TLL_IsTrailing)
   {
      double temp = hwm - TLL_FixedAmount;
      // v15.2 Fix D: MathMax→MathMin — TLL_LockFloor is the upper cap, not a lower floor.
       TLL_BreachLevel = MathMin(TLL_LockFloor, temp);
      Buffer_TLL      = equity - TLL_BreachLevel;
   }
   else
      Buffer_TLL = equity - TLL_BreachLevel;     // static floor

   Buffer_TLL_Pct = (TLL_FixedAmount > 0) ? (Buffer_TLL / TLL_FixedAmount) * 100.0 : 0.0;

   // v14.33: Effective buffer = binding (tightest) of DLL and TLL
   TLL_IsBinding        = (Buffer_TLL < Buffer_DLL);
   Buffer_Effective     = MathMin(Buffer_DLL, Buffer_TLL);
   Buffer_Effective_Pct = TLL_IsBinding ? Buffer_TLL_Pct : Buffer_DLL_Pct;

   // v14.33 FIX: TF Shield — daily basis (same logic as DLL), not floating open-loss.
   // This prevents false TF Shield warnings when positions are in profit.
   if(EnableTFShield)
   {
      double tf_fixed = bal * (Runtime_TFShieldPercentage / 100.0);
      Buffer_TF     = equity - (pdc - tf_fixed);
      Buffer_TF_Pct = (tf_fixed > 0) ? (Buffer_TF / tf_fixed) * 100.0 : 0.0;
   }
   else
   {
      Buffer_TF = 0.0; Buffer_TF_Pct = 0.0;
   }

   // v15.2 engine review: use the same daily-basis TF Shield model for breach
   // detection as the displayed TFS Buffer, preventing false lock/popups when
   // the account is positive on the day but has floating losing legs.
   double tf_limit=bal*(Runtime_TFShieldPercentage/100.0), current_loss=0.0;

   // v14.17 Mod1: 3-alert burst — 5-min reset, 30s intra-burst spacing
   static datetime dll_alert_window=0; static int dll_alert_count=0; static datetime dll_last_alert=0;
   static datetime tll_alert_window=0; static int tll_alert_count=0; static datetime tll_last_alert=0;
   static datetime tfs_alert_window=0; static int tfs_alert_count=0; static datetime tfs_last_alert=0;
   // v14.32/v14.33: Alert on EFFECTIVE buffer (binding risk), not on each buffer independently
   if(Buffer_Effective_Pct<=20.0&&Buffer_Effective_Pct>0&&Buffer_Effective>1.0 && !TLLBreached){
      if(dll_alert_window==0||TimeCurrent()-dll_alert_window>=300){dll_alert_window=TimeCurrent();dll_alert_count=0;dll_last_alert=0;}
      if(dll_alert_count<1){ // Fire only ONCE per window
         string eff_which = TLL_IsBinding ? "TLL" : "DLL";
         TLLCooldownEndTime = TimeCurrent() + TLL_CooldownMinutes * 60; // Start 5-min cooldown
         if(ShowAlert)Alert("⚠️ RISK CRITICAL [",eff_which,"]: >80% consumed. Trading PAUSED for ", TLL_CooldownMinutes, " min.");
         if(LogToTerminal)Print("⚠️ RISK CRITICAL [",eff_which,"] $",DoubleToString(Buffer_Effective,2)," left (",DoubleToString(Buffer_Effective_Pct,1),"%). PAUSED until ", TimeToString(TLLCooldownEndTime));
         dll_alert_count++;dll_last_alert=TimeCurrent();}}
   else{dll_alert_window=0;dll_alert_count=0;dll_last_alert=0;}
   if(Buffer_TLL_Pct<=20.0&&Buffer_TLL_Pct>0&&TLLLimit>1.0&&Buffer_TLL>1.0){
      if(tll_alert_window==0||TimeCurrent()-tll_alert_window>=300){tll_alert_window=TimeCurrent();tll_alert_count=0;tll_last_alert=0;}
      if(tll_alert_count<3&&TimeCurrent()-tll_last_alert>=30){
         if(ShowAlert)Alert("⚠️ TLL CRITICAL: >80% consumed ($",DoubleToString(Buffer_TLL,2)," left)");
         if(LogToTerminal)Print("⚠️ TLL CRITICAL $",DoubleToString(Buffer_TLL,2)," left (",DoubleToString(Buffer_TLL_Pct,1),"%)");
         tll_alert_count++;tll_last_alert=TimeCurrent();}}
   else{tll_alert_window=0;tll_alert_count=0;tll_last_alert=0;}
   if(Buffer_TF_Pct<=20.0&&Buffer_TF_Pct>0&&TFShieldLimit>1.0&&Buffer_TF>1.0){
      if(tfs_alert_window==0||TimeCurrent()-tfs_alert_window>=300){tfs_alert_window=TimeCurrent();tfs_alert_count=0;tfs_last_alert=0;}
      if(tfs_alert_count<3&&TimeCurrent()-tfs_last_alert>=30){
         if(ShowAlert)Alert("⚠️ TF SHIELD CRITICAL: >80% consumed ($",DoubleToString(Buffer_TF,2)," left)");
         if(LogToTerminal)Print("⚠️ TF SHIELD CRITICAL $",DoubleToString(Buffer_TF,2)," left (",DoubleToString(Buffer_TF_Pct,1),"%)");
         tfs_alert_count++;tfs_last_alert=TimeCurrent();}}
   else{tfs_alert_window=0;tfs_alert_count=0;tfs_last_alert=0;}
   static int tf_confirm=0; static datetime last_tfs_alert=0;
   bool tf_daily_breach = EnableTFShield && (Buffer_TF <= 0.0);
   if(tf_daily_breach){
      tf_confirm++;
      if(tf_confirm>=2&&TimeCurrent()-last_tfs_alert>30){
         if(Manual_TFS_Breach){if(ShowAlert)Alert("🚨 TF SHIELD 2ND VIOLATION 🚨");if(LogToTerminal)Print("🚨 TF SHIELD 2ND VIOLATION 🚨");}
         else{if(ShowAlert)Alert("⚠️ TF SHIELD 1ST: Closing ALL positions");
              if(LogToTerminal)Print("⚠️ TF SHIELD 1ST Daily buffer breached. Buffer=$",DoubleToString(Buffer_TF,2)," Limit=$",DoubleToString(tf_limit,2)," (",DoubleToString(Runtime_TFShieldPercentage,1),"% of $",DoubleToString(bal,2),")");}
         last_tfs_alert=TimeCurrent(); if(PositionsTotal()>0)CloseAllPositions("TF Shield breach");}}
   else{tf_confirm=0;}
}

//+------------------------------------------------------------------+
//| Check Trading Conditions                                         |
//+------------------------------------------------------------------+
bool CheckTradingConditions()
{
   if(Runtime_EnableEmergencyStop)
   {
      if(Runtime_LockReleaseEndTime > 0 && GetLockClock() >= Runtime_LockReleaseEndTime)
      {
         Runtime_EnableEmergencyStop = false;
         Runtime_LockReleaseEndTime = 0;
         if(LogToTerminal)
            Print("Trading lock auto-released");
      }
      else
      {
         if(LogToTerminal)
            Print("Trading blocked: Lock active");
         return false;
      }
   }
   
   // Tilt Protection
   if(EnableTiltProtection && TiltBlockEndTime > TimeCurrent())
   {
      static datetime _last_tilt_alert = 0;
      if(TimeCurrent() - _last_tilt_alert >= 30)
      {
         int _secs = (int)(TiltBlockEndTime - TimeCurrent());
         PlaySound("alert.wav");
         Alert("⛔ TILT PROTECTION: Trading paused. Resumes in ", _secs/60, " min ", _secs%60, " sec (", TimeToString(TiltBlockEndTime, TIME_MINUTES), ")");
         if(LogToTerminal) Print("Tilt blocked until ", TimeToString(TiltBlockEndTime));
         _last_tilt_alert = TimeCurrent();
      }
      return false;
   }
   
   // Time filter
   if(Runtime_UseTimeFilter)
   {
      MqlDateTime tm;
      TimeToStruct(TimeCurrent(), tm);
      string cur_time = StringFormat("%02d:%02d", tm.hour, tm.min);
      
      bool is_allowed = false;
      if (AllowedStartTime <= AllowedEndTime) 
      {
          if (cur_time >= AllowedStartTime && cur_time <= AllowedEndTime)
              is_allowed = true;
      }
      else 
      {
          if (cur_time >= AllowedStartTime || cur_time <= AllowedEndTime)
              is_allowed = true;
      }

      if (!is_allowed)
      {
         static datetime last_time_log = 0;
         if(LogToTerminal && TimeCurrent() - last_time_log >= 60)
         {
            Print("Time filter blocked: Server Time ", cur_time, " is outside ", AllowedStartTime, "–", AllowedEndTime);
            last_time_log = TimeCurrent();
         }
         return false;
      }
   }

   // News filter
   if(Runtime_UseNewsFilter)
   {
      datetime now = TimeCurrent();
      if(now - last_news_check >= 60)
      {
         last_news_check = now;
         in_news_window = false;

         MqlCalendarValue values[];
         datetime from = now-(Runtime_NewsPreMinutes*60+600);
         datetime to   = now+86400;

         if(CalendarValueHistory(values, from, to))
         {
            for(int i = 0; i < ArraySize(values); i++)
            {
               MqlCalendarEvent event;
               if(!CalendarEventById(values[i].event_id, event)) continue;

               if(StringLen(Runtime_NewsCurrencyFilter) > 0)
               {
                  string event_currency = "";
                  MqlCalendarCountry country;
                  if(CalendarCountryById(event.country_id, country))
                     event_currency = country.currency;
                  
                  if(StringFind(Runtime_NewsCurrencyFilter, event_currency) < 0) continue;
               }

               bool is_high = (event.importance == CALENDAR_IMPORTANCE_HIGH);
               bool is_med  = (event.importance == CALENDAR_IMPORTANCE_MODERATE);

               if(!is_high && !(Runtime_IncludeMediumImpact && is_med)) continue;

               datetime event_time = values[i].time;
               datetime block_start = event_time - Runtime_NewsPreMinutes * 60;
               datetime block_end   = event_time + Runtime_NewsPostMinutes * 60;

               if(now >= block_start && now <= block_end)
               {
                  in_news_window = true;
                  if(LogToTerminal)
                     Print("News filter active: high-impact event at ", TimeToString(event_time));
                  
                  if(CloseOnHighNews && PositionsTotal() > 0)
                  {
                     CloseAllPositions();
                  }
                  
                  break;
               }
            }
         }
      }
   }
   else in_news_window = false;

   if(in_news_window) return false;
   
   // v14.40: Enforce cooldown from 80% risk warning
   if(TLLCooldownEndTime > 0 && TimeCurrent() < TLLCooldownEndTime)
   {
       if(LogToTerminal){int _s=(int)(TLLCooldownEndTime-TimeCurrent());
         if(_s>0)Print("Risk warning cooldown: ",_s,"s remaining (resumes ",TimeToString(TLLCooldownEndTime),")");}
      return false;
   }

   if(DailyLossBreached)
   {
      if(LogToTerminal)
         Print("Trading blocked: Daily Loss Limit breached");
      return false;
   }
   
   if(TLLBreached)
   {
      if(LogToTerminal){int _s=(int)(TLLCooldownEndTime-TimeCurrent());
         if(_s>0)Print("TLL cooldown: ",_s,"s remaining (resumes ",TimeToString(TLLCooldownEndTime),")");}
      return false;
   }
   
   if(DailyTargetReached && EnableDailyTargetAutoClose)
   {
      if(LogToTerminal)
         Print("Trading blocked: Daily Gain Target reached");
      return false;
   }
   
   if(MaxOpenPositions>0){
   int _cp=0;
   for(int _ci=0;_ci<PositionsTotal();_ci++){ulong _t=PositionGetTicket(_ci);
      if(_t>0&&PositionSelectByTicket(_t)&&PositionGetString(POSITION_SYMBOL)==_Symbol&&PositionGetInteger(POSITION_MAGIC)==MagicNumber)_cp++;}
   if(_cp>=MaxOpenPositions){if(LogToTerminal)Print("Blocked MaxOpenPos(",_cp,"/",MaxOpenPositions,")");return false;}}
   
   if(MaxTotalLots>0){
   double _tv=0;
   for(int i=0;i<PositionsTotal();i++){ulong t=PositionGetTicket(i);
      if(t>0&&PositionSelectByTicket(t)&&PositionGetString(POSITION_SYMBOL)==_Symbol&&PositionGetInteger(POSITION_MAGIC)==MagicNumber)_tv+=PositionGetDouble(POSITION_VOLUME);}
   if(_tv>=MaxTotalLots){if(LogToTerminal)Print("Blocked MaxTotalLots");return false;}}
   
   return true;
}

//+------------------------------------------------------------------+
//| Create Transparent Panel                                         |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| Create Order Box with improved spatial positioning               |
//+------------------------------------------------------------------+
void CreateOrderBox(int base_x, int base_y) {
   int x = base_x;
   int y = base_y;
   int horizontal_gap = Scaled(15);  // Increased for better spacing to prevent overlap
   int vertical_gap = Scaled(25);    // Slightly increased for row separation
   int button_height = Scaled(22);   // Adjusted for scaled font visibility
   int edit_width = Scaled(60);      // Widened to fit values without clipping
   int label_font_size = ScaledFont();

   // Top row buttons/labels ("LATEST SET BE LOCK") with wider spacing
   CreatePanelLabel("LBL_LATEST", "LATEST", x, y, clrDodgerBlue, label_font_size, true);
   x += Scaled(70) + horizontal_gap;  // Wider base + gap to fix overlap
   CreatePanelButton("BTN_Settings", "SET", x, y, Scaled(50), button_height, C'20,40,80', clrWhite, label_font_size);
   x += Scaled(50) + horizontal_gap;
   CreatePanelButton("BTN_BE", "BE", x, y, Scaled(40), button_height, C'20,40,80', clrWhite, label_font_size);
   x += Scaled(40) + horizontal_gap;
   CreatePanelButton("BTN_LOCK", "LOCK", x, y, Scaled(60), button_height, C'20,40,80', clrWhite, label_font_size);

   // Next row: Bid/Ask display
   y += vertical_gap;
   x = base_x;  // Reset x for new row
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double spread = ask - bid;
   string bid_ask_text = "Bid " + DoubleToString(bid, 2) + " Ask " + DoubleToString(ask, 2);
   CreatePanelLabel("LBL_BID_ASK", bid_ask_text, x, y, clrWhite, label_font_size, false);
   CreatePanelLabel("LBL_SPREAD", DoubleToString(spread, 2), x + Scaled(120), y, clrWhite, label_font_size, false);

   // Next row: BUY/SELL buttons
   y += vertical_gap;
   x = base_x;
   CreatePanelButton("BTN_BUY", "BUY", x, y, Scaled(60), button_height + Scaled(5), clrGreen, clrBlack, label_font_size);  // Taller for prominence
   x += Scaled(65) + horizontal_gap;
   CreatePanelButton("BTN_SELL", "SELL", x, y, Scaled(60), button_height + Scaled(5), clrRed, clrBlack, label_font_size);

   // Next row: MARKET / Limit with edit field
   y += vertical_gap;
   x = base_x;
   CreatePanelButton("BTN_MARKET", "MARKET", x, y, Scaled(70), button_height, clrGray, clrWhite, label_font_size);
   x += Scaled(75) + horizontal_gap;
   CreatePanelButton("BTN_LIMIT", "LIMIT", x, y, Scaled(50), button_height, clrGray, clrWhite, label_font_size);
   x += Scaled(50) + horizontal_gap / 2;  // Smaller gap here for compactness
   CreatePanelEdit("EDIT_LIMIT_PRICE", "", x, y, edit_width + Scaled(10), label_font_size);  // Widened

   // Next row: Size
   y += vertical_gap;
   x = base_x;
   CreatePanelLabel("LBL_SIZE", "Size ", x, y, clrWhite, label_font_size, false);
   x += Scaled(50);
   CreatePanelEdit("EDIT_SIZE", DoubleToString(Runtime_FixedLotSize, 2), x, y, edit_width, label_font_size);

   // Next row: SL / TP with edits
   y += vertical_gap;
   x = base_x;
   CreatePanelLabel("LBL_SL", "SL: ", x, y, clrWhite, label_font_size, false);
   x += Scaled(40);
   int sl_edit_x = x;
   CreatePanelEdit("EDIT_SL", IntegerToString(Runtime_SL_Pips), x, y, edit_width, label_font_size);
   x += edit_width + horizontal_gap;
   CreatePanelLabel("LBL_TP", "TP: ", x, y, clrWhite, label_font_size, false);
   x += Scaled(40);
   int tp_edit_x = x;
   CreatePanelEdit("EDIT_TP", IntegerToString(Runtime_TP_Pips), x, y, edit_width, label_font_size);

   // Next row: Dollar risk values ($10 $0)
   y += vertical_gap;
   x = base_x;
   string sl_dollar = "";  // Updated in UpdateRiskPanel
   string tp_dollar = "";  // Updated in UpdateRiskPanel
   double rr_value = (Runtime_SL_Pips > 0) ? (double)Runtime_TP_Pips / Runtime_SL_Pips : 0.0;
   string rr_text = DoubleToString(rr_value, 1);
   CreatePanelLabel("LBL_SL_DOLLAR", sl_dollar, sl_edit_x, y, clrYellow, label_font_size, false);
   CreatePanelLabel("LBL_RR", rr_text, sl_edit_x + Scaled(60), y, clrWhite, label_font_size, false);
   CreatePanelLabel("LBL_TP_DOLLAR", tp_dollar, tp_edit_x, y, clrYellow, label_font_size, false);

   // Update global for panel bottom if needed for subsequent sections
   Runtime_PanelBottomY = y + vertical_gap;
}

//+------------------------------------------------------------------+
//| Create Transparent Risk Panel — CLEAN v14.33                    |
//+------------------------------------------------------------------+
void CreateTransparentPanel()
{
   if(!ShowRiskPanel) return;
   
   int x = PanelOffsetX;
   int y = 10 + Scaled(10);  // Lowered by ~1% of panel height
   
   ObjectDelete(0, "TF_Panel_BG");

   // Cosmetic pass 1b: force recreation of top order-box objects so updated
   // positions/text take effect even when objects already existed on chart.
   string top_objs[] = {
      "BTN_BE","BTN_LOCK",
      "LBL_BID_ASK","LBL_SPREAD",
      "BTN_SELL","BTN_BUY",
      "BTN_MARKET","BTN_LIMIT","EDIT_LIMIT_PRICE",
      "LBL_SIZE","EDIT_SIZE",
      "LBL_SL","EDIT_SL","LBL_TP","EDIT_TP",
      "LBL_SL_DOLLAR","LBL_RR","LBL_TP_DOLLAR",
      "BTN_FlattenAll","BTN_Settings"
   };
   for(int i=0; i<ArraySize(top_objs); i++)
      ObjectDelete(0, top_objs[i]);

   CreateOrderBox(x, y);

   // Flatten All Button - moved to SET position
   string btn_name = "BTN_FlattenAll";
   if(ObjectFind(0, btn_name) < 0)
   {
      ObjectCreate(0, btn_name, OBJ_BUTTON, 0, 0, 0);
      ObjectSetInteger(0, btn_name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(0, btn_name, OBJPROP_XSIZE, (int)(54 * Runtime_GuiScale));
      ObjectSetInteger(0, btn_name, OBJPROP_YSIZE, (int)(20 * Runtime_GuiScale));
      ObjectSetString(0, btn_name, OBJPROP_TEXT, "FLATTEN");
      ObjectSetInteger(0, btn_name, OBJPROP_BGCOLOR, clrRed);
      ObjectSetInteger(0, btn_name, OBJPROP_COLOR, clrWhite);
      ObjectSetInteger(0, btn_name, OBJPROP_FONTSIZE, (int)(8 * Runtime_GuiScale));
      ObjectSetString(0, btn_name, OBJPROP_FONT, "Segoe UI");
   }
   ObjectSetInteger(0, btn_name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, btn_name, OBJPROP_YDISTANCE, y);

   // Settings button is now natively handled inside CreateOrderBox.

   /*
   // Flatten All Button
   string btn_name = "BTN_FlattenAll";
   if(ObjectFind(0, btn_name) < 0)
   {
      ObjectCreate(0, btn_name, OBJ_BUTTON, 0, 0, 0);
      ObjectSetInteger(0, btn_name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(0, btn_name, OBJPROP_XDISTANCE, x + (int)(10 * Runtime_GuiScale));
      ObjectSetInteger(0, btn_name, OBJPROP_YDISTANCE, y + (int)(18 * Runtime_GuiScale));
      ObjectSetInteger(0, btn_name, OBJPROP_XSIZE, (int)(54 * Runtime_GuiScale));
      ObjectSetInteger(0, btn_name, OBJPROP_YSIZE, (int)(20 * Runtime_GuiScale));
      ObjectSetString(0, btn_name, OBJPROP_TEXT, "FLATTEN");
      ObjectSetInteger(0, btn_name, OBJPROP_BGCOLOR, clrRed);
      ObjectSetInteger(0, btn_name, OBJPROP_COLOR, clrWhite);
      ObjectSetInteger(0, btn_name, OBJPROP_FONTSIZE, (int)(8 * Runtime_GuiScale));
      ObjectSetString(0, btn_name, OBJPROP_FONT, "Segoe UI");
   }

   // Settings Button
   string set_name = "BTN_Settings";
   if(ObjectFind(0, set_name) < 0)
   {
      ObjectCreate(0, set_name, OBJ_BUTTON, 0, 0, 0);
      ObjectSetInteger(0, set_name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(0, set_name, OBJPROP_XDISTANCE, x + (int)(68 * Runtime_GuiScale));
      ObjectSetInteger(0, set_name, OBJPROP_YDISTANCE, y + (int)(18 * Runtime_GuiScale));
      ObjectSetInteger(0, set_name, OBJPROP_XSIZE, (int)(44 * Runtime_GuiScale));
      ObjectSetInteger(0, set_name, OBJPROP_YSIZE, (int)(20 * Runtime_GuiScale));
      ObjectSetString(0, set_name, OBJPROP_TEXT, "SET");
      ObjectSetInteger(0, set_name, OBJPROP_BGCOLOR, clrGray);
      ObjectSetInteger(0, set_name, OBJPROP_COLOR, clrWhite);
      ObjectSetInteger(0, set_name, OBJPROP_FONTSIZE, (int)(8 * Runtime_GuiScale));
      ObjectSetString(0, set_name, OBJPROP_FONT, "Segoe UI");
   }

   // BE ALL button (v15.0 addition)
   string be_name = "BTN_BE_ALL";
   if(ObjectFind(0, be_name) < 0)
   {
      ObjectCreate(0, be_name, OBJ_BUTTON, 0, 0, 0);
      ObjectSetInteger(0, be_name, OBJPROP_CORNER,    CORNER_LEFT_UPPER);
      ObjectSetInteger(0, be_name, OBJPROP_XDISTANCE, x + (int)(114 * Runtime_GuiScale));
      ObjectSetInteger(0, be_name, OBJPROP_YDISTANCE, y + (int)(18  * Runtime_GuiScale));
      ObjectSetInteger(0, be_name, OBJPROP_XSIZE,     (int)(36  * Runtime_GuiScale));
      ObjectSetInteger(0, be_name, OBJPROP_YSIZE,     (int)(20  * Runtime_GuiScale));
      ObjectSetString (0, be_name, OBJPROP_TEXT,      "BE");
      ObjectSetInteger(0, be_name, OBJPROP_BGCOLOR,   clrDodgerBlue);
      ObjectSetInteger(0, be_name, OBJPROP_COLOR,     clrWhite);
      ObjectSetInteger(0, be_name, OBJPROP_FONTSIZE,  (int)(8 * Runtime_GuiScale));
      ObjectSetString (0, be_name, OBJPROP_FONT,      "Segoe UI");
      ObjectSetInteger(0, be_name, OBJPROP_ZORDER,    10);
      ObjectSetInteger(0, be_name, OBJPROP_STATE,     false);
   }

   // Kill Switch (E-STOP)
   string kill_name = "BTN_KillSwitch";
   if(ObjectFind(0, kill_name) < 0)
   {
      ObjectCreate(0, kill_name, OBJ_BUTTON, 0, 0, 0);
      ObjectSetInteger(0, kill_name, OBJPROP_CORNER,    CORNER_LEFT_UPPER);
      ObjectSetInteger(0, kill_name, OBJPROP_XDISTANCE, x + (int)(151 * Runtime_GuiScale));
      ObjectSetInteger(0, kill_name, OBJPROP_YDISTANCE, y + (int)(18 * Runtime_GuiScale));
      ObjectSetInteger(0, kill_name, OBJPROP_XSIZE,     (int)(44 * Runtime_GuiScale));
      ObjectSetInteger(0, kill_name, OBJPROP_YSIZE,     (int)(20 * Runtime_GuiScale));
      ObjectSetInteger(0, kill_name, OBJPROP_FONTSIZE,  (int)(8 * Runtime_GuiScale));
      ObjectSetString (0, kill_name, OBJPROP_FONT,      "Segoe UI");
      ObjectSetString (0, kill_name, OBJPROP_TOOLTIP,   "Trading lock with optional auto-release timer");
   }
   ObjectSetString (0, kill_name, OBJPROP_TEXT,   Runtime_EnableEmergencyStop ? "LOCKED" : "LOCK");
   ObjectSetInteger(0, kill_name, OBJPROP_BGCOLOR, Runtime_EnableEmergencyStop ? clrRed : clrDimGray);
   ObjectSetInteger(0, kill_name, OBJPROP_COLOR,   clrWhite);

   // Market Price Section — split static label + dynamic value objects (names match UpdateRiskPanel)
   int y_price  = y + (int)(54 * Runtime_GuiScale);
   int mkt_fsz  = (int)(8 * Runtime_GuiScale);
   int mkt_fsz7 = (int)(7 * Runtime_GuiScale);

   // Row 1: Bid | Ask
   if(ObjectFind(0,"LBL_BidLbl") < 0) {
      ObjectCreate(0,"LBL_BidLbl",OBJ_LABEL,0,0,0);
      ObjectSetInteger(0,"LBL_BidLbl",OBJPROP_CORNER,CORNER_LEFT_UPPER);
      ObjectSetInteger(0,"LBL_BidLbl",OBJPROP_XDISTANCE,x+(int)(10*Runtime_GuiScale));
      ObjectSetInteger(0,"LBL_BidLbl",OBJPROP_YDISTANCE,y_price + (int)(1*Runtime_GuiScale));
      ObjectSetInteger(0,"LBL_BidLbl",OBJPROP_COLOR,clrSilver);
      ObjectSetInteger(0,"LBL_BidLbl",OBJPROP_FONTSIZE,mkt_fsz);
      ObjectSetString (0,"LBL_BidLbl",OBJPROP_FONT,"Segoe UI");
      ObjectSetString (0,"LBL_BidLbl",OBJPROP_TEXT,"Bid:"); }
   if(ObjectFind(0,"LBL_BIDVAL") < 0) {
      ObjectCreate(0,"LBL_BIDVAL",OBJ_LABEL,0,0,0);
      ObjectSetInteger(0,"LBL_BIDVAL",OBJPROP_CORNER,CORNER_LEFT_UPPER);
      ObjectSetInteger(0,"LBL_BIDVAL",OBJPROP_XDISTANCE,x+(int)(36*Runtime_GuiScale));
      ObjectSetInteger(0,"LBL_BIDVAL",OBJPROP_YDISTANCE,y_price + (int)(1*Runtime_GuiScale));
      ObjectSetInteger(0,"LBL_BIDVAL",OBJPROP_COLOR,clrWhite);
      ObjectSetInteger(0,"LBL_BIDVAL",OBJPROP_FONTSIZE,mkt_fsz);
      ObjectSetString (0,"LBL_BIDVAL",OBJPROP_FONT,"Segoe UI"); }
   ObjectSetString(0,"LBL_BIDVAL",OBJPROP_TEXT,DoubleToString(SymbolInfoDouble(_Symbol,SYMBOL_BID),_Digits));

   if(ObjectFind(0,"LBL_AskLbl") < 0) {
      ObjectCreate(0,"LBL_AskLbl",OBJ_LABEL,0,0,0);
      ObjectSetInteger(0,"LBL_AskLbl",OBJPROP_CORNER,CORNER_LEFT_UPPER);
      ObjectSetInteger(0,"LBL_AskLbl",OBJPROP_XDISTANCE,x+(int)(152*Runtime_GuiScale));
      ObjectSetInteger(0,"LBL_AskLbl",OBJPROP_YDISTANCE,y_price);
      ObjectSetInteger(0,"LBL_AskLbl",OBJPROP_COLOR,clrSilver);
      ObjectSetInteger(0,"LBL_AskLbl",OBJPROP_FONTSIZE,mkt_fsz);
      ObjectSetString (0,"LBL_AskLbl",OBJPROP_FONT,"Segoe UI");
      ObjectSetString (0,"LBL_AskLbl",OBJPROP_TEXT,"Ask:"); }
   if(ObjectFind(0,"LBL_ASKVAL") < 0) {
      ObjectCreate(0,"LBL_ASKVAL",OBJ_LABEL,0,0,0);
      ObjectSetInteger(0,"LBL_ASKVAL",OBJPROP_CORNER,CORNER_LEFT_UPPER);
      ObjectSetInteger(0,"LBL_ASKVAL",OBJPROP_XDISTANCE,x+(int)(180*Runtime_GuiScale));
      ObjectSetInteger(0,"LBL_ASKVAL",OBJPROP_YDISTANCE,y_price);
      ObjectSetInteger(0,"LBL_ASKVAL",OBJPROP_COLOR,clrWhite);
      ObjectSetInteger(0,"LBL_ASKVAL",OBJPROP_FONTSIZE,mkt_fsz);
      ObjectSetString (0,"LBL_ASKVAL",OBJPROP_FONT,"Segoe UI"); }
   ObjectSetString(0,"LBL_ASKVAL",OBJPROP_TEXT,DoubleToString(SymbolInfoDouble(_Symbol,SYMBOL_ASK),_Digits));

   // Row 2: Spread | Last
   {
      double _sp = (pip_size > 0) ? (SymbolInfoDouble(_Symbol,SYMBOL_ASK)-SymbolInfoDouble(_Symbol,SYMBOL_BID))/pip_size : 0;
      if(ObjectFind(0,"LBL_SprdLbl") < 0) {
         ObjectCreate(0,"LBL_SprdLbl",OBJ_LABEL,0,0,0);
         ObjectSetInteger(0,"LBL_SprdLbl",OBJPROP_CORNER,CORNER_LEFT_UPPER);
         ObjectSetInteger(0,"LBL_SprdLbl",OBJPROP_XDISTANCE,x+(int)(82*Runtime_GuiScale));
         ObjectSetInteger(0,"LBL_SprdLbl",OBJPROP_YDISTANCE,y_price);
         ObjectSetInteger(0,"LBL_SprdLbl",OBJPROP_COLOR,clrSilver);
         ObjectSetInteger(0,"LBL_SprdLbl",OBJPROP_FONTSIZE,mkt_fsz7);
         ObjectSetString (0,"LBL_SprdLbl",OBJPROP_FONT,"Segoe UI");
         ObjectSetString (0,"LBL_SprdLbl",OBJPROP_TEXT,"Sprd:"); }
      if(ObjectFind(0,"LBL_SPRVAL") < 0) {
         ObjectCreate(0,"LBL_SPRVAL",OBJ_LABEL,0,0,0);
         ObjectSetInteger(0,"LBL_SPRVAL",OBJPROP_CORNER,CORNER_LEFT_UPPER);
         ObjectSetInteger(0,"LBL_SPRVAL",OBJPROP_XDISTANCE,x+(int)(108*Runtime_GuiScale));
         ObjectSetInteger(0,"LBL_SPRVAL",OBJPROP_YDISTANCE,y_price);
         ObjectSetInteger(0,"LBL_SPRVAL",OBJPROP_FONTSIZE,mkt_fsz7);
         ObjectSetString (0,"LBL_SPRVAL",OBJPROP_FONT,"Segoe UI"); }
      ObjectSetInteger(0,"LBL_SPRVAL",OBJPROP_COLOR,(_sp<=MaxSpreadPips)?clrLimeGreen:clrOrangeRed);
      ObjectSetString (0,"LBL_SPRVAL",OBJPROP_TEXT,DoubleToString(_sp,1)+(_sp>MaxSpreadPips?" [W]":""));
   }
   if(ObjectFind(0,"LBL_LastLbl") < 0) {
      ObjectCreate(0,"LBL_LastLbl",OBJ_LABEL,0,0,0);
      ObjectSetInteger(0,"LBL_LastLbl",OBJPROP_CORNER,CORNER_LEFT_UPPER);
      ObjectSetInteger(0,"LBL_LastLbl",OBJPROP_XDISTANCE,x+(int)(86*Runtime_GuiScale));
      ObjectSetInteger(0,"LBL_LastLbl",OBJPROP_YDISTANCE,y_price+(int)(12*Runtime_GuiScale));
      ObjectSetInteger(0,"LBL_LastLbl",OBJPROP_COLOR,clrSilver);
      ObjectSetInteger(0,"LBL_LastLbl",OBJPROP_FONTSIZE,mkt_fsz7);
      ObjectSetString (0,"LBL_LastLbl",OBJPROP_FONT,"Segoe UI");
      ObjectSetString (0,"LBL_LastLbl",OBJPROP_TEXT,"Last:"); }
   if(ObjectFind(0,"LBL_LSTVAL") < 0) {
      ObjectCreate(0,"LBL_LSTVAL",OBJ_LABEL,0,0,0);
      ObjectSetInteger(0,"LBL_LSTVAL",OBJPROP_CORNER,CORNER_LEFT_UPPER);
      ObjectSetInteger(0,"LBL_LSTVAL",OBJPROP_XDISTANCE,x+(int)(112*Runtime_GuiScale));
      ObjectSetInteger(0,"LBL_LSTVAL",OBJPROP_YDISTANCE,y_price+(int)(12*Runtime_GuiScale));
      ObjectSetInteger(0,"LBL_LSTVAL",OBJPROP_COLOR,clrWhite);
      ObjectSetInteger(0,"LBL_LSTVAL",OBJPROP_FONTSIZE,mkt_fsz7);
      ObjectSetString (0,"LBL_LSTVAL",OBJPROP_FONT,"Segoe UI"); }
   ObjectSetString(0,"LBL_LSTVAL",OBJPROP_TEXT,DoubleToString(SymbolInfoDouble(_Symbol,SYMBOL_LAST),_Digits));

   // Smart Entry Section
   int y_smart = y_price + (int)(24 * Runtime_GuiScale);

   string buy_name = "BTN_SmartBuy";
   if(ObjectFind(0, buy_name) < 0)
   {
      ObjectCreate(0, buy_name, OBJ_BUTTON, 0, 0, 0);
      ObjectSetInteger(0, buy_name, OBJPROP_CORNER,    CORNER_LEFT_UPPER);
      ObjectSetInteger(0, buy_name, OBJPROP_XDISTANCE, x + (int)(10 * Runtime_GuiScale));
      ObjectSetInteger(0, buy_name, OBJPROP_YDISTANCE, y_smart);
      ObjectSetInteger(0, buy_name, OBJPROP_XSIZE,     (int)(50 * Runtime_GuiScale));
      ObjectSetInteger(0, buy_name, OBJPROP_YSIZE,     (int)(22 * Runtime_GuiScale));
      ObjectSetString (0, buy_name, OBJPROP_TEXT,      "BUY");
      ObjectSetInteger(0, buy_name, OBJPROP_BGCOLOR,   clrGreen);
      ObjectSetInteger(0, buy_name, OBJPROP_COLOR,     clrWhite);
      ObjectSetInteger(0, buy_name, OBJPROP_FONTSIZE,  (int)(7 * Runtime_GuiScale));
      ObjectSetString (0, buy_name, OBJPROP_FONT,      "Segoe UI Bold");
      ObjectSetInteger(0, buy_name, OBJPROP_ZORDER,    10);
      ObjectSetInteger(0, buy_name, OBJPROP_STATE,     false);
   }

   string sell_name = "BTN_SmartSell";
   if(ObjectFind(0, sell_name) < 0)
   {
      ObjectCreate(0, sell_name, OBJ_BUTTON, 0, 0, 0);
      ObjectSetInteger(0, sell_name, OBJPROP_CORNER,    CORNER_LEFT_UPPER);
      ObjectSetInteger(0, sell_name, OBJPROP_XDISTANCE, x + (int)(65 * Runtime_GuiScale));
      ObjectSetInteger(0, sell_name, OBJPROP_YDISTANCE, y_smart);
      ObjectSetInteger(0, sell_name, OBJPROP_XSIZE,     (int)(50 * Runtime_GuiScale));
      ObjectSetInteger(0, sell_name, OBJPROP_YSIZE,     (int)(22 * Runtime_GuiScale));
      ObjectSetString (0, sell_name, OBJPROP_TEXT,      "SELL");
      ObjectSetInteger(0, sell_name, OBJPROP_BGCOLOR,   clrRed);
      ObjectSetInteger(0, sell_name, OBJPROP_COLOR,     clrWhite);
      ObjectSetInteger(0, sell_name, OBJPROP_FONTSIZE,  (int)(7 * Runtime_GuiScale));
      ObjectSetString (0, sell_name, OBJPROP_FONT,      "Segoe UI Bold");
      ObjectSetInteger(0, sell_name, OBJPROP_ZORDER,    10);
      ObjectSetInteger(0, sell_name, OBJPROP_STATE,     false);
   }

   // Order-entry container layout (container-relative positioning)
   int row_gap      = (int)(30 * Runtime_GuiScale);
   int row_label_y  = (int)(4  * Runtime_GuiScale);
   int order_left   = x + (int)(10 * Runtime_GuiScale);
   int mode_btn_w   = (int)(60 * Runtime_GuiScale);
   int small_gap    = (int)(6  * Runtime_GuiScale);
   int medium_gap   = (int)(10 * Runtime_GuiScale);
   int size_edit_w  = (int)(60 * Runtime_GuiScale);
   int input_edit_w = (int)(40 * Runtime_GuiScale);

   // Order mode row
   int y_mode       = y_smart + row_gap;
   int mode_btn_x   = order_left;
   int limit_lbl_x  = mode_btn_x + mode_btn_w + medium_gap;
   int price_edit_x = limit_lbl_x + (int)(35 * Runtime_GuiScale);

   string mode_btn = "BTN_OrderMode";
   if(ObjectFind(0, mode_btn) < 0)
   {
      ObjectCreate(0, mode_btn, OBJ_BUTTON, 0, 0, 0);
      ObjectSetInteger(0, mode_btn, OBJPROP_CORNER,    CORNER_LEFT_UPPER);
      ObjectSetInteger(0, mode_btn, OBJPROP_XDISTANCE, mode_btn_x);
      ObjectSetInteger(0, mode_btn, OBJPROP_YDISTANCE, y_mode);
      ObjectSetInteger(0, mode_btn, OBJPROP_XSIZE,     mode_btn_w);
      ObjectSetInteger(0, mode_btn, OBJPROP_YSIZE,     (int)(18 * Runtime_GuiScale));
      ObjectSetInteger(0, mode_btn, OBJPROP_FONTSIZE,  (int)(8 * Runtime_GuiScale));
      ObjectSetString (0, mode_btn, OBJPROP_FONT,      "Segoe UI");
      ObjectSetInteger(0, mode_btn, OBJPROP_COLOR,     clrWhite);
   }
   ObjectSetString (0, mode_btn, OBJPROP_TEXT,   Runtime_IsPendingMode ? "PENDING" : "MARKET");
   ObjectSetInteger(0, mode_btn, OBJPROP_BGCOLOR, Runtime_IsPendingMode ? clrOrange : clrSteelBlue);

   string lim_lbl = "LBL_Limit";
   if(ObjectFind(0, lim_lbl) < 0)
   {
      ObjectCreate(0, lim_lbl, OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(0, lim_lbl, OBJPROP_CORNER,    CORNER_LEFT_UPPER);
      ObjectSetInteger(0, lim_lbl, OBJPROP_XDISTANCE, limit_lbl_x);
      ObjectSetInteger(0, lim_lbl, OBJPROP_YDISTANCE, y_mode + row_label_y);
      ObjectSetInteger(0, lim_lbl, OBJPROP_COLOR,     clrWhite);
      ObjectSetInteger(0, lim_lbl, OBJPROP_FONTSIZE,  (int)(8 * Runtime_GuiScale));
      ObjectSetString (0, lim_lbl, OBJPROP_FONT,      "Segoe UI");
      ObjectSetString (0, lim_lbl, OBJPROP_TEXT,      "Limit:");
   }
   ObjectSetInteger(0, lim_lbl, OBJPROP_HIDDEN, !Runtime_IsPendingMode);

   string pr_edit = "GUI_EDIT_Price";
   if(ObjectFind(0, pr_edit) < 0)
   {
      ObjectCreate(0, pr_edit, OBJ_EDIT, 0, 0, 0);
      ObjectSetInteger(0, pr_edit, OBJPROP_CORNER,    CORNER_LEFT_UPPER);
      ObjectSetInteger(0, pr_edit, OBJPROP_XDISTANCE, price_edit_x);
      ObjectSetInteger(0, pr_edit, OBJPROP_YDISTANCE, y_mode);
      ObjectSetInteger(0, pr_edit, OBJPROP_XSIZE,     (int)(60 * Runtime_GuiScale));
      ObjectSetInteger(0, pr_edit, OBJPROP_YSIZE,     (int)(18 * Runtime_GuiScale));
      ObjectSetInteger(0, pr_edit, OBJPROP_FONTSIZE,  (int)(8 * Runtime_GuiScale));
      ObjectSetString (0, pr_edit, OBJPROP_FONT,      "Segoe UI");
      ObjectSetInteger(0, pr_edit, OBJPROP_COLOR,     clrBlack);
      ObjectSetInteger(0, pr_edit, OBJPROP_BGCOLOR,   clrWhite);
      ObjectSetInteger(0, pr_edit, OBJPROP_ALIGN,     ALIGN_CENTER);
   }
   ObjectSetInteger(0, pr_edit, OBJPROP_HIDDEN, !Runtime_IsPendingMode);
   if(Runtime_IsPendingMode)
   {
      if(Runtime_PendingPrice == 0)
         ObjectSetString(0, pr_edit, OBJPROP_TEXT, DoubleToString(SymbolInfoDouble(_Symbol, SYMBOL_BID), _Digits));
      else
         ObjectSetString(0, pr_edit, OBJPROP_TEXT, DoubleToString(Runtime_PendingPrice, _Digits));
   }

   // Size row
   int y_size      = y_mode + row_gap;
   int size_lbl_x  = order_left;
   int size_edit_x = order_left + (int)(28 * Runtime_GuiScale);

   string sz_lbl = "LBL_Size";
   if(ObjectFind(0, sz_lbl) < 0)
   {
      ObjectCreate(0, sz_lbl, OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(0, sz_lbl, OBJPROP_CORNER,    CORNER_LEFT_UPPER);
      ObjectSetInteger(0, sz_lbl, OBJPROP_XDISTANCE, size_lbl_x);
      ObjectSetInteger(0, sz_lbl, OBJPROP_YDISTANCE, y_size + row_label_y);
      ObjectSetString (0, sz_lbl, OBJPROP_TEXT,      "Size:");
      ObjectSetInteger(0, sz_lbl, OBJPROP_COLOR,     clrWhite);
      ObjectSetInteger(0, sz_lbl, OBJPROP_FONTSIZE,  (int)(8 * Runtime_GuiScale));
      ObjectSetString (0, sz_lbl, OBJPROP_FONT,      "Segoe UI");
   }

   string sz_edit = "GUI_EDIT_Size";
   if(ObjectFind(0, sz_edit) < 0)
   {
      ObjectCreate(0, sz_edit, OBJ_EDIT, 0, 0, 0);
      ObjectSetInteger(0, sz_edit, OBJPROP_CORNER,    CORNER_LEFT_UPPER);
      ObjectSetInteger(0, sz_edit, OBJPROP_XDISTANCE, size_edit_x);
      ObjectSetInteger(0, sz_edit, OBJPROP_YDISTANCE, y_size);
      ObjectSetInteger(0, sz_edit, OBJPROP_XSIZE,     size_edit_w);
      ObjectSetInteger(0, sz_edit, OBJPROP_YSIZE,     (int)(20 * Runtime_GuiScale));
      ObjectSetInteger(0, sz_edit, OBJPROP_FONTSIZE,  (int)(8 * Runtime_GuiScale));
      ObjectSetString (0, sz_edit, OBJPROP_FONT,      "Segoe UI");
      ObjectSetInteger(0, sz_edit, OBJPROP_COLOR,     clrBlack);
      ObjectSetInteger(0, sz_edit, OBJPROP_BGCOLOR,   clrWhite);
      ObjectSetInteger(0, sz_edit, OBJPROP_ALIGN,     ALIGN_CENTER);
      ObjectSetString (0, sz_edit, OBJPROP_TEXT,      DoubleToString(Runtime_FixedLotSize, 2));
   }

   // SL/TP container row
   int y_inputs    = y_size + row_gap;
   int sl_lbl_x    = order_left;
   int sl_edit_x   = sl_lbl_x + (int)(28 * Runtime_GuiScale);
   int rr_x        = sl_edit_x + input_edit_w + medium_gap;
   int tp_lbl_x    = rr_x + (int)(32 * Runtime_GuiScale);
   int tp_edit_x   = tp_lbl_x + (int)(26 * Runtime_GuiScale);
   int usd_y       = y_inputs + (int)(22 * Runtime_GuiScale);
   int rr_y        = y_inputs + row_label_y;

   string sl_lbl = "LBL_SL_Pips";
   if(ObjectFind(0, sl_lbl) < 0)
   {
      ObjectCreate(0, sl_lbl, OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(0, sl_lbl, OBJPROP_CORNER,    CORNER_LEFT_UPPER);
      ObjectSetInteger(0, sl_lbl, OBJPROP_XDISTANCE, sl_lbl_x);
      ObjectSetInteger(0, sl_lbl, OBJPROP_YDISTANCE, y_inputs + row_label_y);
      ObjectSetString (0, sl_lbl, OBJPROP_TEXT,      "SL:");
      ObjectSetInteger(0, sl_lbl, OBJPROP_COLOR,     clrWhite);
      ObjectSetInteger(0, sl_lbl, OBJPROP_FONTSIZE,  (int)(8 * Runtime_GuiScale));
      ObjectSetString (0, sl_lbl, OBJPROP_FONT,      "Segoe UI");
   }

   string sl_edit = "GUI_EDIT_SL";
   if(ObjectFind(0, sl_edit) < 0)
   {
      ObjectCreate(0, sl_edit, OBJ_EDIT, 0, 0, 0);
      ObjectSetInteger(0, sl_edit, OBJPROP_CORNER,    CORNER_LEFT_UPPER);
      ObjectSetInteger(0, sl_edit, OBJPROP_XDISTANCE, sl_edit_x);
      ObjectSetInteger(0, sl_edit, OBJPROP_YDISTANCE, y_inputs);
      ObjectSetInteger(0, sl_edit, OBJPROP_XSIZE,     input_edit_w);
      ObjectSetInteger(0, sl_edit, OBJPROP_YSIZE,     (int)(20 * Runtime_GuiScale));
      ObjectSetInteger(0, sl_edit, OBJPROP_FONTSIZE,  (int)(8 * Runtime_GuiScale));
      ObjectSetString (0, sl_edit, OBJPROP_FONT,      "Segoe UI");
      ObjectSetInteger(0, sl_edit, OBJPROP_COLOR,     clrBlack);
      ObjectSetInteger(0, sl_edit, OBJPROP_BGCOLOR,   clrWhite);
      ObjectSetInteger(0, sl_edit, OBJPROP_ALIGN,     ALIGN_CENTER);
      ObjectSetString (0, sl_edit, OBJPROP_TEXT,      IntegerToString(Runtime_SL_Pips));
   }

   string tp_lbl = "LBL_TP_Pips";
   if(ObjectFind(0, tp_lbl) < 0)
   {
      ObjectCreate(0, tp_lbl, OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(0, tp_lbl, OBJPROP_CORNER,    CORNER_LEFT_UPPER);
      ObjectSetInteger(0, tp_lbl, OBJPROP_XDISTANCE, tp_lbl_x);
      ObjectSetInteger(0, tp_lbl, OBJPROP_YDISTANCE, y_inputs + row_label_y);
      ObjectSetString (0, tp_lbl, OBJPROP_TEXT,      "TP:");
      ObjectSetInteger(0, tp_lbl, OBJPROP_COLOR,     clrWhite);
      ObjectSetInteger(0, tp_lbl, OBJPROP_FONTSIZE,  (int)(8 * Runtime_GuiScale));
      ObjectSetString (0, tp_lbl, OBJPROP_FONT,      "Segoe UI");
   }

   string tp_edit = "GUI_EDIT_TP";
   if(ObjectFind(0, tp_edit) < 0)
   {
      ObjectCreate(0, tp_edit, OBJ_EDIT, 0, 0, 0);
      ObjectSetInteger(0, tp_edit, OBJPROP_CORNER,    CORNER_LEFT_UPPER);
      ObjectSetInteger(0, tp_edit, OBJPROP_XDISTANCE, tp_edit_x);
      ObjectSetInteger(0, tp_edit, OBJPROP_YDISTANCE, y_inputs);
      ObjectSetInteger(0, tp_edit, OBJPROP_XSIZE,     input_edit_w);
      ObjectSetInteger(0, tp_edit, OBJPROP_YSIZE,     (int)(20 * Runtime_GuiScale));
      ObjectSetInteger(0, tp_edit, OBJPROP_FONTSIZE,  (int)(8 * Runtime_GuiScale));
      ObjectSetString (0, tp_edit, OBJPROP_FONT,      "Segoe UI");
      ObjectSetInteger(0, tp_edit, OBJPROP_COLOR,     clrBlack);
      ObjectSetInteger(0, tp_edit, OBJPROP_BGCOLOR,   clrWhite);
      ObjectSetInteger(0, tp_edit, OBJPROP_ALIGN,     ALIGN_CENTER);
      ObjectSetString (0, tp_edit, OBJPROP_TEXT,      IntegerToString(Runtime_TP_Pips));
   }

   // Live R:R ratio + separate whole-dollar SL/TP labels within the same container
   {
      string rr_name    = "LBL_RR";
      string slusd_name = "LBL_RR_SLUSD";
      string tpusd_name = "LBL_RR_TPUSD";
      int rr_sl = Runtime_SL_Pips;
      int rr_tp = Runtime_TP_Pips;
      double rr_lots = Runtime_FixedLotSize;
      if(ObjectFind(0, "GUI_EDIT_SL") >= 0)
         rr_sl = (int)StringToInteger(ObjectGetString(0, "GUI_EDIT_SL", OBJPROP_TEXT));
      if(ObjectFind(0, "GUI_EDIT_TP") >= 0)
         rr_tp = (int)StringToInteger(ObjectGetString(0, "GUI_EDIT_TP", OBJPROP_TEXT));
      if(ObjectFind(0, "GUI_EDIT_Size") >= 0)
      {
         double lots_txt = StringToDouble(ObjectGetString(0, "GUI_EDIT_Size", OBJPROP_TEXT));
         if(lots_txt > 0.0)
            rr_lots = lots_txt;
      }
      double _rr = (rr_sl > 0) ? (double)rr_tp / (double)rr_sl : 0.0;
      double sl_cash = 0.0;
      double tp_cash = 0.0;
      double sl_dist = rr_sl * pip_size;
      double tp_dist = rr_tp * pip_size;
      if(rr_lots > 0.0)
      {
         if(is_index && pip_size > 0)
         {
            sl_cash = sl_dist * rr_lots;
            tp_cash = tp_dist * rr_lots;
         }
         else
         {
            double tv = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
            double ts = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
            if(ts > 0)
            {
               sl_cash = sl_dist * rr_lots * tv / ts;
               tp_cash = tp_dist * rr_lots * tv / ts;
            }
         }
      }
      if(ObjectFind(0, rr_name) < 0)
      {
         ObjectCreate(0, rr_name, OBJ_LABEL, 0, 0, 0);
         ObjectSetInteger(0, rr_name, OBJPROP_CORNER,    CORNER_LEFT_UPPER);
         ObjectSetInteger(0, rr_name, OBJPROP_XDISTANCE, rr_x);
         ObjectSetInteger(0, rr_name, OBJPROP_YDISTANCE, rr_y);
         ObjectSetInteger(0, rr_name, OBJPROP_FONTSIZE,  (int)(7 * Runtime_GuiScale));
         ObjectSetString (0, rr_name, OBJPROP_FONT,      "Segoe UI");
         ObjectSetInteger(0, rr_name, OBJPROP_COLOR,     clrSilver);
      }
      if(ObjectFind(0, slusd_name) < 0)
      {
         ObjectCreate(0, slusd_name, OBJ_LABEL, 0, 0, 0);
         ObjectSetInteger(0, slusd_name, OBJPROP_CORNER,    CORNER_LEFT_UPPER);
         ObjectSetInteger(0, slusd_name, OBJPROP_XDISTANCE, sl_edit_x + (int)(4 * Runtime_GuiScale));
         ObjectSetInteger(0, slusd_name, OBJPROP_YDISTANCE, usd_y);
         ObjectSetInteger(0, slusd_name, OBJPROP_FONTSIZE,  (int)(7 * Runtime_GuiScale));
         ObjectSetString (0, slusd_name, OBJPROP_FONT,      "Segoe UI");
         ObjectSetInteger(0, slusd_name, OBJPROP_COLOR,     clrSilver);
      }
      if(ObjectFind(0, tpusd_name) < 0)
      {
         ObjectCreate(0, tpusd_name, OBJ_LABEL, 0, 0, 0);
         ObjectSetInteger(0, tpusd_name, OBJPROP_CORNER,    CORNER_LEFT_UPPER);
         ObjectSetInteger(0, tpusd_name, OBJPROP_XDISTANCE, tp_edit_x + (int)(4 * Runtime_GuiScale));
         ObjectSetInteger(0, tpusd_name, OBJPROP_YDISTANCE, usd_y);
         ObjectSetInteger(0, tpusd_name, OBJPROP_FONTSIZE,  (int)(7 * Runtime_GuiScale));
         ObjectSetString (0, tpusd_name, OBJPROP_FONT,      "Segoe UI");
         ObjectSetInteger(0, tpusd_name, OBJPROP_COLOR,     clrSilver);
      }
      ObjectSetString(0, rr_name, OBJPROP_TEXT, "1:" + DoubleToString(_rr, 1));
      ObjectSetString(0, slusd_name, OBJPROP_TEXT, "$" + IntegerToString((int)MathRound(MathAbs(sl_cash))));
      ObjectSetString(0, tpusd_name, OBJPROP_TEXT, "$" + IntegerToString((int)MathRound(MathAbs(tp_cash))));
   }
   */
   // ─── METRICS SECTION ─────────────────────────────────────────────────
   // Static label objects (M_ prefix) created here with ObjectFind guard.
   // Value objects use v15.0 names (ACC_/LIM_/RISK_) so UpdateRiskPanel()
   // can update them every tick without touching the static labels.
   // v15.2 Fix B: metrics built unconditionally — removed if(!SettingsPanelExpanded).
   // That guard caused DeleteAllMetrics() to fire when SaveSettingsFromPanel() ran
   // while the panel was still open (SettingsPanelExpanded=true).
   {
      int y_start = y + (int)(240 * Runtime_GuiScale);
      int lh      = (int)(22 * Runtime_GuiScale);
      int lx      = x + 10;
      int vx      = x + (int)(135 * Runtime_GuiScale);
      int cur_y   = y_start;

      // ── ACCOUNT ────────────────────────────────────────────────────────
      CreateMetricLabel("M_AccTitle",    "── ACCOUNT ──", lx, cur_y, clrYellow, true);
      cur_y += lh;

      CreateMetricLabel("M_OrigSizeLbl", "Orig Size:", lx, cur_y, clrSilver);
      CreateMetricLabel("ACC_ORIGSIZE_VAL", "$" + DoubleToString(WorkingAccountSize, 2), vx, cur_y, clrWhite);
      cur_y += lh;

      CreateMetricLabel("M_EquityLbl",   "Equity:",      lx, cur_y, clrSilver);
      CreateMetricLabel("ACC_EQUITY_VAL","$" + DoubleToString(CurrentEquity, 2), vx, cur_y, clrWhite);
      cur_y += lh;

      color dgain_c = (TodaysTotalGain >= 0) ? clrLimeGreen : clrRed;
      CreateMetricLabel("M_DGainLbl",    "Daily Gain:",  lx, cur_y, clrSilver);
      CreateMetricLabel("ACC_DGAIN_VAL", (TodaysTotalGain>=0?"+$":"-$")+DoubleToString(MathAbs(TodaysTotalGain),2), vx, cur_y, dgain_c);
      cur_y += lh;

      double total_gain = CurrentEquity - WorkingAccountSize;
      color tgain_c = (total_gain >= 0) ? clrLimeGreen : clrRed;
      CreateMetricLabel("M_TGainLbl",    "Total Gain:",  lx, cur_y, clrSilver);
      CreateMetricLabel("ACC_TGAIN_VAL", (total_gain>=0?"+$":"-$")+DoubleToString(MathAbs(total_gain),2), vx, cur_y, tgain_c);
      cur_y += lh;

      double dgt_level = PriorDayClose + Runtime_DailyGainTarget;
      CreateMetricLabel("M_DGTLbl",      "DGT Target:",  lx, cur_y, clrSilver);
      CreateMetricLabel("ACC_DGT_VAL",   "$" + DoubleToString(dgt_level, 2), vx, cur_y, clrWhite);
      cur_y += lh;

      DistToDGT = dgt_level - CurrentEquity;
      color ddgt_c = (DistToDGT <= 0) ? clrLimeGreen : clrOrange;
      CreateMetricLabel("M_DistDGTLbl",  "Dist to DGT:", lx, cur_y, clrSilver);
      CreateMetricLabel("ACC_DISTDGT_VAL",(DistToDGT<=0?"✓ $":"$")+DoubleToString(MathAbs(DistToDGT),2), vx, cur_y, ddgt_c);
      cur_y += lh;

      double ttg_level = WorkingAccountSize * (1.0 + Runtime_TotalTargetGainPct / 100.0);
      CreateMetricLabel("M_TTGLbl",      "TTG Target:",  lx, cur_y, clrSilver);
      CreateMetricLabel("ACC_TTG_VAL",   "$" + DoubleToString(ttg_level, 2), vx, cur_y, clrAqua);
      cur_y += lh;

      DistToTTG = ttg_level - CurrentEquity;
      color dttg_c = (DistToTTG <= 0) ? clrLimeGreen : clrOrange;
      CreateMetricLabel("M_DistTTGLbl",  "Dist to TTG:", lx, cur_y, clrSilver);
      CreateMetricLabel("ACC_DISTTTG_VAL",(DistToTTG<=0?"✓ $":"$")+DoubleToString(MathAbs(DistToTTG),2), vx, cur_y, dttg_c);
      cur_y += lh;

      // ── LIMITATIONS ────────────────────────────────────────────────────
      cur_y += (int)(12 * Runtime_GuiScale);
      CreateMetricLabel("M_LimTitle",    "── LIMITATIONS ──", lx, cur_y, clrYellow, true);
      cur_y += lh;

      CreateMetricLabel("M_DLLLimLbl",   "DLL Limit:",   lx, cur_y, clrSilver);
      CreateMetricLabel("LIM_DLL_VAL",   "$" + DoubleToString(DailyLossLimit, 2), vx, cur_y, clrWhite);
      cur_y += lh;

      CreateMetricLabel("M_TLLLimLbl",   "TLL Limit:",   lx, cur_y, clrSilver);
      CreateMetricLabel("LIM_TLL_VAL",   "$" + DoubleToString(TLLLimit, 2), vx, cur_y, clrWhite);
      cur_y += lh;

      CreateMetricLabel("M_TFSLimLbl",   "TF Shield:",   lx, cur_y, clrSilver);
      CreateMetricLabel("LIM_TFS_VAL",   "$" + DoubleToString(TFShieldLimit, 2), vx, cur_y, clrWhite);
      cur_y += lh;

      // ── RISKS ──────────────────────────────────────────────────────────
      cur_y += (int)(12 * Runtime_GuiScale);
      CreateMetricLabel("M_RiskTitle",   "── RISKS ──",  lx, cur_y, clrYellow, true);
      cur_y += lh;

      color dllbuf_c = (Buffer_DLL_Pct > 30) ? clrLimeGreen : (Buffer_DLL_Pct > 10) ? clrYellow : clrRed;
      CreateMetricLabel("M_DLLBufLbl",   "DLL Buffer:",  lx, cur_y, clrSilver);
      CreateMetricLabel("RISK_DLLBUF_VAL","$"+DoubleToString(Buffer_DLL,2)+" ("+DoubleToString(Buffer_DLL_Pct,0)+"%)", vx, cur_y, dllbuf_c);
      cur_y += lh;

      color tllbuf_c = (Buffer_TLL_Pct > 30) ? clrLimeGreen : (Buffer_TLL_Pct > 10) ? clrYellow : clrRed;
      CreateMetricLabel("M_TLLBufLbl",   "TLL Buffer:",  lx, cur_y, clrSilver);
      CreateMetricLabel("RISK_TLLBUF_VAL","$"+DoubleToString(Buffer_TLL,2)+" ("+DoubleToString(Buffer_TLL_Pct,0)+"%)", vx, cur_y, tllbuf_c);
      cur_y += lh;

      color tfsbuf_c = (Buffer_TF_Pct > 30) ? clrLimeGreen : (Buffer_TF_Pct > 10) ? clrYellow : clrRed;
      CreateMetricLabel("M_TFSBufLbl",   "TFS Buffer:",  lx, cur_y, clrSilver);
      CreateMetricLabel("RISK_TFSBUF_VAL","$"+DoubleToString(Buffer_TF,2)+" ("+DoubleToString(Buffer_TF_Pct,0)+"%)", vx, cur_y, tfsbuf_c);
      cur_y += lh;

      string eff_tag = TLL_IsBinding ? " [TLL]" : " [DLL]";
      color  eff_c   = (Buffer_Effective_Pct > 30) ? clrLimeGreen : (Buffer_Effective_Pct > 10) ? clrYellow : clrRed;
      CreateMetricLabel("M_EffBufLbl",   "Eff Risk Buf:", lx, cur_y, clrSilver);
      CreateMetricLabel("RISK_EFF_VAL",  "$"+DoubleToString(Buffer_Effective,2)+" ("+DoubleToString(Buffer_Effective_Pct,0)+"%)"+eff_tag, vx, cur_y, eff_c);
      cur_y += lh;

      CreateMetricLabel("M_RiskExpLbl",  "Risk Exp:",    lx, cur_y, clrSilver);
      CreateMetricLabel("RISK_EXP_VAL",  "$" + DoubleToString(RiskExposure, 2), vx, cur_y, clrWhite);
      cur_y += lh;

      double dll_vs_sl = DLL_FixedAmount - RiskExposure;
      color  dvssl_c   = (dll_vs_sl >= 0) ? clrLimeGreen : clrRed;
      CreateMetricLabel("M_DvsSLLbl",    "DLL vs SL:",   lx, cur_y, clrSilver);
      CreateMetricLabel("RISK_DVSSL_VAL","$" + DoubleToString(dll_vs_sl, 2), vx, cur_y, dvssl_c);
      cur_y += lh;

      Runtime_PanelBottomY = cur_y;
   }
   // (else { DeleteAllMetrics(); } removed — v15.2 Fix B)

   ChartRedraw();
}

//+------------------------------------------------------------------+
//| Panel Helper — Label                                             |
//| Font size and position always fully updated (enables rescaling)  |
//+------------------------------------------------------------------+
void CreatePanelLabel(string name, string txt, int x, int y, color clr, int fsize=9, bool bold=false)
{
   if(ObjectFind(0,name) < 0)
   {
      ObjectCreate(0,name, OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(0,name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   }
   // v14.37: Always update ZORDER to maintain layering
   ObjectSetInteger(0,name, OBJPROP_ZORDER, 5); 
   // Update ALL properties every call — GuiScale changes take effect immediately
   ObjectSetInteger(0,name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0,name, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0,name, OBJPROP_COLOR,     clr);
   ObjectSetInteger(0,name, OBJPROP_FONTSIZE,  fsize);
   ObjectSetString (0,name, OBJPROP_FONT,      bold ? "Segoe UI Bold" : "Segoe UI");
   ObjectSetString (0,name, OBJPROP_TEXT,      txt);
}

//+------------------------------------------------------------------+
//| Panel Helper — Button                                            |
//+------------------------------------------------------------------+
void CreatePanelButton(string name, string txt, int x, int y, int w, int h, color bg, color txtclr, int fsize=9)
{
   if(ObjectFind(0,name) < 0)
   {
      ObjectCreate(0,name, OBJ_BUTTON, 0, 0, 0);
      ObjectSetInteger(0,name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   }
   ObjectSetInteger(0,name, OBJPROP_ZORDER, 5); // v14.37
   ObjectSetInteger(0,name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0,name, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0,name, OBJPROP_XSIZE,     w);
   ObjectSetInteger(0,name, OBJPROP_YSIZE,     h);
   ObjectSetInteger(0,name, OBJPROP_BGCOLOR,   bg);
   ObjectSetInteger(0,name, OBJPROP_COLOR,     txtclr);
   ObjectSetInteger(0,name, OBJPROP_FONTSIZE,  fsize);
   ObjectSetString (0,name, OBJPROP_FONT,      "Segoe UI Bold");
   ObjectSetString (0,name, OBJPROP_TEXT,      txt);
}

//+------------------------------------------------------------------+
//| Panel Helper — Edit Box                                          |
//+------------------------------------------------------------------+
void CreatePanelEdit(string name, string txt, int x, int y, int w, int fsize)
{
   if(ObjectFind(0,name) < 0)
   {
      ObjectCreate(0,name, OBJ_EDIT, 0, 0, 0);
      ObjectSetInteger(0,name, OBJPROP_CORNER,  CORNER_LEFT_UPPER);
      ObjectSetInteger(0,name, OBJPROP_BGCOLOR, C'240,240,240');
      ObjectSetInteger(0,name, OBJPROP_COLOR,   clrBlack);
      ObjectSetString (0,name, OBJPROP_FONT,    "Segoe UI");
      ObjectSetInteger(0,name, OBJPROP_FONTSIZE, (int)MathRound(fsize * Runtime_GuiScale));
   }
   ObjectSetInteger(0,name, OBJPROP_ZORDER, 5); // v14.37
   ObjectSetInteger(0,name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0,name, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0,name, OBJPROP_XSIZE,     w);
   ObjectSetInteger(0,name, OBJPROP_YSIZE,     (int)(22 * Runtime_GuiScale));  // v14.36: taller
   ObjectSetString (0,name, OBJPROP_TEXT,      txt);
}

//+------------------------------------------------------------------+
//| Panel Helper — Section Header                                    |
//+------------------------------------------------------------------+
void CreatePanelHeader(string name, string txt, int x, int y, color clr, int fsize=10)
{
   CreatePanelLabel(name, txt, x, y, clr, fsize, true);
}

//+------------------------------------------------------------------+
//| Panel Helper — Info Row (label left-column, value right-column)  |
//| lbl_w passed in so val column is always the same X across rows   |
//+------------------------------------------------------------------+
void CreatePanelInfo(string name, string label, string value, int x, int y, color valclr, int lbl_w=135, int fsize=9)
{
   CreatePanelLabel(name+"_LBL", label+":", x,          y, clrSilver, fsize, false);
   CreatePanelLabel(name+"_VAL", value,     x+lbl_w+8,  y, valclr,    fsize, false);
}

//+------------------------------------------------------------------+
//| Panel Helper — Open Position Row                                 |
//+------------------------------------------------------------------+
void CreatePanelPosLine(string name, string ticket, string lots, string sl, string tp, int x, int y, color pl_clr)
{
   double s = Runtime_GuiScale; 
   int fsz = (int)MathRound(8 * s);
   CreatePanelLabel(name+"_T", ticket, x,                   y, clrRed,    fsz, false);
   CreatePanelLabel(name+"_L", lots,   x + (int)(145 * s),  y, clrWhite,  fsz, false); 
   CreatePanelLabel(name+"_S", sl,     x + (int)(215 * s),  y, clrOrange, fsz, false); 
   CreatePanelLabel(name+"_P", tp,     x + (int)(295 * s),  y, pl_clr,    fsz, false); 
}

//+------------------------------------------------------------------+
//| Dynamic Panel Update — every tick, only refreshes values/colors  |
//+------------------------------------------------------------------+
void UpdateRiskPanel()
{
   // v15.2 robustness: avoid GUI object churn while editing Settings fields.
   if(StringFind(g_active_edit_object, "SET_EDIT_") == 0)
      return;

   if(!ShowRiskPanel) return;

   // v14.37: Market Data Live Updates
   double bid_price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double ask_price = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double spread_pips = (ask_price - bid_price) / pip_size; // Use pip_size for accuracy
   double last_price = SymbolInfoDouble(_Symbol, SYMBOL_LAST);

   // Market data — names match split label+value objects in CreateTransparentPanel
   ObjectSetString (0,"LBL_BIDVAL",OBJPROP_TEXT,  DoubleToString(bid_price, _Digits));
   ObjectSetString (0,"LBL_ASKVAL",OBJPROP_TEXT,  DoubleToString(ask_price, _Digits));
   ObjectSetInteger(0,"LBL_SPRVAL",OBJPROP_COLOR, (spread_pips <= MaxSpreadPips) ? clrLimeGreen : clrOrangeRed);
   ObjectSetString (0,"LBL_SPRVAL",OBJPROP_TEXT,  DoubleToString(spread_pips, 1) + (spread_pips > MaxSpreadPips ? " [W]" : ""));
   ObjectSetString (0,"LBL_LSTVAL",OBJPROP_TEXT,  DoubleToString(last_price, _Digits));

   // Update order box bid/ask with spread
   double spread = ask_price - bid_price;
   string bid_ask_text = "Bid " + DoubleToString(bid_price, 2) + " Ask " + DoubleToString(ask_price, 2);
   ObjectSetString(0, "LBL_BID_ASK", OBJPROP_TEXT, bid_ask_text);
   ObjectSetString(0, "LBL_SPREAD", OBJPROP_TEXT, DoubleToString(spread, 2));

   // Update SL/TP from edits
   string sl_str = ObjectGetString(0, "EDIT_SL", OBJPROP_TEXT);
   string tp_str = ObjectGetString(0, "EDIT_TP", OBJPROP_TEXT);
   Runtime_SL_Pips = (int)StringToInteger(sl_str);
   Runtime_TP_Pips = (int)StringToInteger(tp_str);

   // Update R:R
   double rr_value = (Runtime_SL_Pips > 0) ? (double)Runtime_TP_Pips / Runtime_SL_Pips : 0.0;
   string rr_text = DoubleToString(rr_value, 1);
   ObjectSetString(0, "LBL_RR", OBJPROP_TEXT, rr_text);

   // Update $ amounts
   double sl_value = RiskPerTradePct * 10;
   string sl_dollar = "$" + IntegerToString((int)sl_value);
   string tp_dollar = "$" + IntegerToString((int)(rr_value * sl_value));
   ObjectSetString(0, "LBL_SL_DOLLAR", OBJPROP_TEXT, sl_dollar);
   ObjectSetString(0, "LBL_TP_DOLLAR", OBJPROP_TEXT, tp_dollar);

   // ── ACCOUNT ───────────────────────────────────────────────────────
   ObjectSetString (0, "ACC_EQUITY_VAL",  OBJPROP_TEXT, "$" + DoubleToString(CurrentEquity, 2));

   color gainColor = (TodaysTotalGain >= 0) ? clrLime : clrRed;
   ObjectSetString (0, "ACC_DGAIN_VAL",   OBJPROP_TEXT, (TodaysTotalGain >= 0 ? "+$" : "-$") + DoubleToString(MathAbs(TodaysTotalGain), 2));
   ObjectSetInteger(0, "ACC_DGAIN_VAL",   OBJPROP_COLOR, gainColor);

   double totalGain = CurrentEquity - WorkingAccountSize;
   color  tgColor   = (totalGain >= 0) ? clrLime : clrRed;
   ObjectSetString (0, "ACC_TGAIN_VAL",   OBJPROP_TEXT, (totalGain >= 0 ? "+$" : "-$") + DoubleToString(MathAbs(totalGain), 2));
   ObjectSetInteger(0, "ACC_TGAIN_VAL",   OBJPROP_COLOR, tgColor);

   double dgt_base = (Manual_PriorDayClose > 0.0) ? Manual_PriorDayClose : PriorDayClose;
   if(dgt_base <= 0.0)
      dgt_base = CurrentEquity;
   double dgt_level = dgt_base * (1.0 + Runtime_DailyGainTargetPct / 100.0);
   double ttg_level = WorkingAccountSize * (1.0 + Runtime_TotalTargetGainPct / 100.0);
   DistToDGT = dgt_level - CurrentEquity;
   DistToTTG = ttg_level - CurrentEquity;

   ObjectSetString (0, "ACC_DGT_VAL",     OBJPROP_TEXT, "$" + DoubleToString(dgt_level, 2));
   color dgtColor = (DistToDGT <= 0) ? clrLime : clrOrange;
   ObjectSetString (0, "ACC_DISTDGT_VAL", OBJPROP_TEXT, (DistToDGT <= 0 ? "✓ $" : "$") + DoubleToString(MathAbs(DistToDGT), 2));
   ObjectSetInteger(0, "ACC_DISTDGT_VAL", OBJPROP_COLOR, dgtColor);

   ObjectSetString (0, "ACC_TTG_VAL",     OBJPROP_TEXT, "$" + DoubleToString(ttg_level, 2));
   color ttgColor = (DistToTTG <= 0) ? clrLime : clrOrange;
   ObjectSetString (0, "ACC_DISTTTG_VAL", OBJPROP_TEXT, (DistToTTG <= 0 ? "✓ $" : "$") + DoubleToString(MathAbs(DistToTTG), 2));
   ObjectSetInteger(0, "ACC_DISTTTG_VAL", OBJPROP_COLOR, ttgColor);

   // ── LIMITATIONS ───────────────────────────────────────────────────
   ObjectSetString(0, "LIM_DLL_VAL", OBJPROP_TEXT, "$" + DoubleToString(DLL_FixedAmount, 2));
   ObjectSetString(0, "LIM_TLL_VAL", OBJPROP_TEXT, "$" + DoubleToString(TLL_FixedAmount, 2));
   ObjectSetString(0, "LIM_TFS_VAL", OBJPROP_TEXT, "$" + DoubleToString(TFShieldLimit,   2));

   // ── RISKS ─────────────────────────────────────────────────────────
   color dllC = (Buffer_DLL_Pct > 30) ? clrLime : (Buffer_DLL_Pct > 10) ? clrYellow : clrRed;  // v14.35: Grok thresholds
   ObjectSetString (0, "RISK_DLLBUF_VAL", OBJPROP_TEXT, "$" + DoubleToString(Buffer_DLL, 2) + " (" + DoubleToString(Buffer_DLL_Pct, 0) + "%)");
   ObjectSetInteger(0, "RISK_DLLBUF_VAL", OBJPROP_COLOR, dllC);

   color tllC = (Buffer_TLL_Pct > 30) ? clrLime : (Buffer_TLL_Pct > 10) ? clrYellow : clrRed;  // v14.35: Grok thresholds
   ObjectSetString (0, "RISK_TLLBUF_VAL", OBJPROP_TEXT, "$" + DoubleToString(Buffer_TLL, 2) + " (" + DoubleToString(Buffer_TLL_Pct, 0) + "%)");
   ObjectSetInteger(0, "RISK_TLLBUF_VAL", OBJPROP_COLOR, tllC);

   color tfsC = (Buffer_TF_Pct  > 30) ? clrLime : (Buffer_TF_Pct  > 10) ? clrYellow : clrRed;  // v14.35: Grok thresholds
   ObjectSetString (0, "RISK_TFSBUF_VAL", OBJPROP_TEXT, "$" + DoubleToString(Buffer_TF, 2) + " (" + DoubleToString(Buffer_TF_Pct, 0) + "%)");
   ObjectSetInteger(0, "RISK_TFSBUF_VAL", OBJPROP_COLOR, tfsC);

   string effTag = TLL_IsBinding ? " [TLL]" : " [DLL]";
   color  effC   = (Buffer_Effective_Pct > 30) ? clrLime : (Buffer_Effective_Pct > 10) ? clrYellow : clrRed;  // v14.35: Grok thresholds
   ObjectSetString (0, "RISK_EFF_VAL", OBJPROP_TEXT, "$" + DoubleToString(Buffer_Effective, 2) + " (" + DoubleToString(Buffer_Effective_Pct, 0) + "%)" + effTag);
   ObjectSetInteger(0, "RISK_EFF_VAL", OBJPROP_COLOR, effC);

   ObjectSetString (0, "RISK_EXP_VAL",   OBJPROP_TEXT, "$" + DoubleToString(RiskExposure, 2));
   double dll_vs_sl = DLL_FixedAmount - RiskExposure;
   color  dvC       = (dll_vs_sl >= 0) ? clrLime : clrRed;
   ObjectSetString (0, "RISK_DVSSL_VAL", OBJPROP_TEXT, "$" + DoubleToString(dll_vs_sl, 2));
   ObjectSetInteger(0, "RISK_DVSSL_VAL", OBJPROP_COLOR, dvC);

   // ── OPEN POSITIONS — dynamic rows ─────────────────────────────────
   double s    = Runtime_GuiScale;
   int    s_row = (int)(24 * s); // v14.37: Increased from 20
   int    pos_fsz = (int)MathRound(8 * s);
   int    pos_x   = PanelOffsetX + (int)(8 * s);
   int    pos_y   = Runtime_PanelBottomY + s_row;

   ObjectsDeleteAll(0, "MON_PL_");

   int shown = 0;
   for(int i = PositionsTotal()-1; i >= 0 && shown < 6; i--) // v14.37: Limit to 6 for space
   {
      ulong tk = PositionGetTicket(i);
      if(tk <= 0 || PositionGetString(POSITION_SYMBOL) != _Symbol) continue;
      if(!PositionSelectByTicket(tk)) continue;

      string sym  = PositionGetString(POSITION_SYMBOL);
      string dir  = (PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY) ? "B" : "S";
      string ticket_str = sym + " " + dir; // v14.37: Show symbol instead of ticket number
      string lots_str = DoubleToString(PositionGetDouble(POSITION_VOLUME), 2) + " L";
      double pl   = PositionGetDouble(POSITION_PROFIT);
      double sl_p = PositionGetDouble(POSITION_SL);
      string sl_s = (sl_p > 0) ? "SL:" + DoubleToString(sl_p, 1) : "no SL";
      string pl_s = (pl >= 0 ? "+$" : "-$") + DoubleToString(MathAbs(pl), 2);
      string nm   = "MON_PL_" + IntegerToString(shown);
      color  pl_c = (pl >= 0) ? clrLime : clrRed; // v14.37: Color-coded P&L

      CreatePanelPosLine(nm, ticket_str, lots_str, sl_s, pl_s, pos_x, pos_y, pl_c);
      pos_y += s_row;
      shown++;
   }
   if(shown == 0)
      CreatePanelLabel("MON_PL_NONE", "No open positions", pos_x, pos_y, clrDimGray, pos_fsz, false);

   ChartRedraw();
}

//+------------------------------------------------------------------+
//| Create Metric Label Helper                                       |
//+------------------------------------------------------------------+
void CreateMetricLabel(string name, string text, int x, int y, color clr, bool bold = false)
{
   if(ObjectFind(0, name) < 0)
   {
      ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
      ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
      ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
      ObjectSetInteger(0, name, OBJPROP_FONTSIZE, (int)(8 * Runtime_GuiScale));
      if(bold)
         ObjectSetString(0, name, OBJPROP_FONT, "Segoe UI Bold");
      else
         ObjectSetString(0, name, OBJPROP_FONT, "Segoe UI");
   }
   ObjectSetString(0, name, OBJPROP_TEXT, text);
}

//+------------------------------------------------------------------+
//| Delete All Metrics                                               |
//+------------------------------------------------------------------+
void DeleteAllMetrics()
{
   ObjectsDeleteAll(0, "M_");          // static label objects
   ObjectsDeleteAll(0, "ACC_");        // account value objects
   ObjectsDeleteAll(0, "LIM_");        // limitation value objects
   ObjectsDeleteAll(0, "RISK_");       // risk value objects
   ObjectsDeleteAll(0, "LBL_BIDVAL");  // market data value objects
   ObjectsDeleteAll(0, "LBL_ASKVAL");
   ObjectsDeleteAll(0, "LBL_SPRVAL");
   ObjectsDeleteAll(0, "LBL_LSTVAL");
}

//+------------------------------------------------------------------+
//| Draw or Update SL/TP Lines                                       |
//+------------------------------------------------------------------+
void DrawOrUpdateSLTPLines(int idx)
{
   if(!ShowChartLines) return;
   if(idx < 0 || idx >= monitor_count) return;

   ulong ticket = monitored_positions[idx].ticket;
   string sl_name = SL_LinePrefix + IntegerToString(ticket);
   string tp_name = TP_LinePrefix + IntegerToString(ticket);
   
   bool sl_selected = false;
   bool tp_selected = false;
   
   if(ObjectFind(0, sl_name) >= 0)
      sl_selected = (bool)ObjectGetInteger(0, sl_name, OBJPROP_SELECTED);
   
   if(ObjectFind(0, tp_name) >= 0)
      tp_selected = (bool)ObjectGetInteger(0, tp_name, OBJPROP_SELECTED);

   double sl_price = monitored_positions[idx].trailing_sl_price;
   if(sl_price == 0 && monitored_positions[idx].sl_pips > 0)
   {
      double dir = (monitored_positions[idx].type == POSITION_TYPE_BUY) ? -1 : 1;
      sl_price = monitored_positions[idx].entry_price + dir * monitored_positions[idx].sl_pips * pip_size;
   }

   double tp_price = 0;
   if(monitored_positions[idx].tp_pips > 0)
   {
      double dir = (monitored_positions[idx].type == POSITION_TYPE_BUY) ? 1 : -1;
      tp_price = monitored_positions[idx].entry_price + dir * monitored_positions[idx].tp_pips * pip_size;
   }
   
   if(sl_selected)
   {
      // User is dragging - trust chart object position
   }
   else if(sl_price > 0)
   {
       if(ObjectFind(0, sl_name) >= 0)
       {
           double curr_obj_price = ObjectGetDouble(0, sl_name, OBJPROP_PRICE);
           if(MathAbs(curr_obj_price - sl_price) > point_value)
           {
               ObjectSetDouble(0, sl_name, OBJPROP_PRICE, sl_price);
               ChartRedraw();
           }
           if(!ObjectGetInteger(0, sl_name, OBJPROP_SELECTABLE))
               ObjectSetInteger(0, sl_name, OBJPROP_SELECTABLE, true);
       }
   }
   else
   {
       if(ObjectFind(0, sl_name) >= 0) 
       {
           Print("Draw: Deleting SL ", sl_name, " (Price=", sl_price, ", Pips=", monitored_positions[idx].sl_pips, ")");
           ObjectDelete(0, sl_name);
           ChartRedraw();
       }
   }

   if(tp_selected)
   {
      // User is dragging
   }
   else if(tp_price > 0)
   {
       if(ObjectFind(0, tp_name) >= 0)
       {
           double curr_obj_price = ObjectGetDouble(0, tp_name, OBJPROP_PRICE);
           if(MathAbs(curr_obj_price - tp_price) > point_value)
           {
               ObjectSetDouble(0, tp_name, OBJPROP_PRICE, tp_price);
               ChartRedraw();
           }
           if(!ObjectGetInteger(0, tp_name, OBJPROP_SELECTABLE))
               ObjectSetInteger(0, tp_name, OBJPROP_SELECTABLE, true);
       }
   }
   else
   {
       if(ObjectFind(0, tp_name) >= 0) 
       {
           Print("Draw: Deleting TP ", tp_name, " (Price=", tp_price, ", Pips=", monitored_positions[idx].tp_pips, ")");
           ObjectDelete(0, tp_name);
           ChartRedraw();
       }
   }

   if(sl_price > 0 && ObjectFind(0, sl_name) < 0)
   {
      ObjectCreate(0, sl_name, OBJ_HLINE, 0, 0, sl_price);
      ObjectSetInteger(0, sl_name, OBJPROP_COLOR, SL_LineColor);
      ObjectSetInteger(0, sl_name, OBJPROP_STYLE, STYLE_SOLID);
      ObjectSetInteger(0, sl_name, OBJPROP_WIDTH, 1);
      ObjectSetInteger(0, sl_name, OBJPROP_SELECTED, false);
      ObjectSetInteger(0, sl_name, OBJPROP_SELECTABLE, true);
      ObjectSetInteger(0, sl_name, OBJPROP_ZORDER, 10);
      ObjectSetInteger(0, sl_name, OBJPROP_HIDDEN, false);
      ChartRedraw();
   }

   if(tp_price > 0 && ObjectFind(0, tp_name) < 0)
   {
      ObjectCreate(0, tp_name, OBJ_HLINE, 0, 0, tp_price);
      ObjectSetInteger(0, tp_name, OBJPROP_COLOR, TP_LineColor);
      ObjectSetInteger(0, tp_name, OBJPROP_STYLE, STYLE_SOLID);
      ObjectSetInteger(0, tp_name, OBJPROP_WIDTH, 1);
      ObjectSetInteger(0, tp_name, OBJPROP_SELECTED, false);
      ObjectSetInteger(0, tp_name, OBJPROP_SELECTABLE, true);
      ObjectSetInteger(0, tp_name, OBJPROP_ZORDER, 10);
      ObjectSetInteger(0, tp_name, OBJPROP_HIDDEN, false);
      ChartRedraw();
   }
}

//+------------------------------------------------------------------+
//| Update Monitor GUI                                               |
//+------------------------------------------------------------------+
void UpdateMonitorGUI()
{
   // v15.2 robustness: avoid monitor redraw while editing Settings fields.
   if(StringFind(g_active_edit_object, "SET_EDIT_") == 0)
      return;

   if(!ShowMonitorGUI) return;
   
   int x = PanelOffsetX;
   int y_start;
   
   if(SettingsPanelExpanded)
   {
      y_start = (int)(490 * Runtime_GuiScale);
   }
   else if(Runtime_PanelBottomY > 0)
   {
      y_start = Runtime_PanelBottomY + (int)(20 * Runtime_GuiScale);
   }
   else
   {
      y_start = (int)(550 * Runtime_GuiScale);
   }
   
   ObjectDelete(0, "MON_Header");

   int y_offset = 0;
   
   for(int i = 0; i < monitor_count; i++)
   {
      ulong ticket = monitored_positions[i].ticket;
      if(!PositionSelectByTicket(ticket)) continue;
      
      string sym = PositionGetString(POSITION_SYMBOL);
      double profit = PositionGetDouble(POSITION_PROFIT);
      ENUM_POSITION_TYPE type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
      string type_str = (type == POSITION_TYPE_BUY) ? "BUY" : "SELL";
      color p_color = (profit >= 0) ? clrLimeGreen : clrRed;
      
      double _gui_open = PositionGetDouble(POSITION_PRICE_OPEN);
      double _gui_sl   = PositionGetDouble(POSITION_SL);
      double _gui_tp   = PositionGetDouble(POSITION_TP);
      string _sl_str, _tp_str;
      if(_gui_sl > 0)
      {
         int _sl_p = (int)MathRound(MathAbs(_gui_sl - _gui_open) / pip_size);
         _sl_str = DoubleToString(_gui_sl,_Digits)+"("+IntegerToString(_sl_p)+"p)";
      }
      else _sl_str = "no SL";
      if(_gui_tp > 0)
      {
         int _tp_p = (int)MathRound(MathAbs(_gui_tp - _gui_open) / pip_size);
         _tp_str = DoubleToString(_gui_tp,_Digits)+"("+IntegerToString(_tp_p)+"p)";
      }
      else _tp_str = "no TP";
      string display_text = StringFormat("#%-8d %-5s %-4s %7.2f  SL:%-18s TP:%s",
                                         ticket, sym, type_str, profit, _sl_str, _tp_str);

      string lbl_name = "MON_Pos_" + IntegerToString(ticket);
      if(ObjectFind(0, lbl_name) < 0)
      {
         ObjectCreate(0, lbl_name, OBJ_LABEL, 0, 0, 0);
         ObjectSetInteger(0, lbl_name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
         ObjectSetString(0, lbl_name, OBJPROP_FONT, "Consolas");
      }
      ObjectSetInteger(0, lbl_name, OBJPROP_XDISTANCE, x + (int)(10 * Runtime_GuiScale));
      ObjectSetInteger(0, lbl_name, OBJPROP_FONTSIZE, (int)(9 * Runtime_GuiScale));
      ObjectSetInteger(0, lbl_name, OBJPROP_YDISTANCE, y_start + y_offset);
      ObjectSetString(0, lbl_name, OBJPROP_TEXT, display_text);
      ObjectSetInteger(0, lbl_name, OBJPROP_COLOR, p_color);
      
      string btn_close = "BTN_Close_" + IntegerToString(ticket);
      if(ObjectFind(0, btn_close) < 0)
      {
         ObjectCreate(0, btn_close, OBJ_BUTTON, 0, 0, 0);
         ObjectSetInteger(0, btn_close, OBJPROP_CORNER, CORNER_LEFT_UPPER);
         ObjectSetString(0, btn_close, OBJPROP_TEXT, "X");
         ObjectSetInteger(0, btn_close, OBJPROP_BGCOLOR, clrRed);
         ObjectSetInteger(0, btn_close, OBJPROP_COLOR, clrWhite);
         ObjectSetString(0, btn_close, OBJPROP_FONT, "Segoe UI");
      }
      ObjectSetInteger(0, btn_close, OBJPROP_XDISTANCE, x + (int)(220 * Runtime_GuiScale));
      ObjectSetInteger(0, btn_close, OBJPROP_XSIZE, (int)(25 * Runtime_GuiScale));
      ObjectSetInteger(0, btn_close, OBJPROP_YSIZE, (int)(20 * Runtime_GuiScale));
      ObjectSetInteger(0, btn_close, OBJPROP_FONTSIZE, (int)(8 * Runtime_GuiScale));
      ObjectSetInteger(0, btn_close, OBJPROP_YDISTANCE, y_start + y_offset);
      
      y_offset += (int)(32 * Runtime_GuiScale);   // v14.36: more space between positions
   }
}

//+------------------------------------------------------------------+
//| Scan and Add Positions                                           |
//+------------------------------------------------------------------+
void ScanAndAddPositions()
{
   for(int i = monitor_count - 1; i >= 0; i--)
   {
      if(IsStopped()) return;
      if(!PositionSelectByTicket(monitored_positions[i].ticket))
      {
         ObjectDelete(0, SL_LinePrefix + IntegerToString(monitored_positions[i].ticket));
         ObjectDelete(0, TP_LinePrefix + IntegerToString(monitored_positions[i].ticket));
         ObjectDelete(0, "MON_Pos_" + IntegerToString(monitored_positions[i].ticket));
         ObjectDelete(0, "BTN_Close_" + IntegerToString(monitored_positions[i].ticket));
         
         for(int j = i; j < monitor_count - 1; j++)
         {
            monitored_positions[j] = monitored_positions[j + 1];
         }
         monitor_count--;
         ArrayResize(monitored_positions, monitor_count);
      }
   }
   
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(IsStopped()) return;
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0) continue;
      
      bool already_monitored = false;
      for(int j = 0; j < monitor_count; j++)
      {
         if(monitored_positions[j].ticket == ticket)
         {
            already_monitored = true;
            break;
         }
      }
      
      if(!already_monitored)
      {
         if(PositionSelectByTicket(ticket) &&
            PositionGetString(POSITION_SYMBOL)==_Symbol &&
            PositionGetInteger(POSITION_MAGIC)==MagicNumber)
         {
            int idx = monitor_count;
            ArrayResize(monitored_positions, idx + 1);
            monitor_count++;
            
            monitored_positions[idx].ticket = ticket;
            monitored_positions[idx].type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
            monitored_positions[idx].volume = PositionGetDouble(POSITION_VOLUME);
            monitored_positions[idx].entry_price = PositionGetDouble(POSITION_PRICE_OPEN);
            monitored_positions[idx].open_time = (datetime)PositionGetInteger(POSITION_TIME);
            monitored_positions[idx].monitoring_enabled = true;
            monitored_positions[idx].trailing_enabled = Runtime_TrailingEnabled;
            monitored_positions[idx].breakeven_locked = false;
            monitored_positions[idx].partial_levels_hit = 0;
            
            monitored_positions[idx].highest_price = monitored_positions[idx].entry_price;
            monitored_positions[idx].lowest_price = monitored_positions[idx].entry_price;
            
            double existing_sl = PositionGetDouble(POSITION_SL);
            double existing_tp = PositionGetDouble(POSITION_TP);
            
            if(existing_sl > 0)
               {
                  double _rsd = MathAbs(existing_sl - monitored_positions[idx].entry_price);
                  monitored_positions[idx].sl_pips = (int)MathRound(_rsd / pip_size);
                  if(is_index && Runtime_SL_Pips > 0 && monitored_positions[idx].sl_pips > Runtime_SL_Pips * 3)
                     monitored_positions[idx].sl_pips = (int)MathRound(_rsd / point_value);
               }
            else if(Runtime_UseATR && current_atr > 0)
               monitored_positions[idx].sl_pips = (int)MathRound(current_atr * ATR_Multi_SL / pip_size);
            else
               monitored_positions[idx].sl_pips = Runtime_SL_Pips;
               
            if(existing_tp > 0)
               {
                  double _rtd = MathAbs(existing_tp - monitored_positions[idx].entry_price);
                  monitored_positions[idx].tp_pips = (int)MathRound(_rtd / pip_size);
                  if(is_index && Runtime_TP_Pips > 0 && monitored_positions[idx].tp_pips > Runtime_TP_Pips * 3)
                     monitored_positions[idx].tp_pips = (int)MathRound(_rtd / point_value);
               }
            else if(Runtime_UseATR && current_atr > 0)
               monitored_positions[idx].tp_pips = (int)MathRound(current_atr * ATR_Multi_TP / pip_size);
            else
               monitored_positions[idx].tp_pips = Runtime_TP_Pips;
            
            if(ShowChartLines)
               DrawOrUpdateSLTPLines(idx);
            
            string _d2dir  = (monitored_positions[idx].type==POSITION_TYPE_BUY) ? "BUY" : "SELL";
            double _d2sl   = PositionGetDouble(POSITION_SL);
            double _d2tp   = PositionGetDouble(POSITION_TP);
            double _d2dist = (_d2sl > 0) ? MathAbs(monitored_positions[idx].entry_price - _d2sl) : 0;
            Print("[Monitor] ",_d2dir," #",ticket,
                  " Entry=",DoubleToString(monitored_positions[idx].entry_price,_Digits),
                  " | Broker SL=",DoubleToString(_d2sl,_Digits),
                  " (",monitored_positions[idx].sl_pips," EA-pips / ",
                  (int)MathRound(_d2dist/point_value)," MT5-pts)",
                  " | Broker TP=",DoubleToString(_d2tp,_Digits));
            PlaySound("ok.wav");
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Sync Monitored Positions with Server                             |
//+------------------------------------------------------------------+
void SyncMonitoredPositions()
{
   for(int i = 0; i < monitor_count; i++)
   {
      ulong ticket = monitored_positions[i].ticket;
      if(PositionSelectByTicket(ticket))
      {
         double server_sl = PositionGetDouble(POSITION_SL);
         double server_tp = PositionGetDouble(POSITION_TP);
         double entry     = PositionGetDouble(POSITION_PRICE_OPEN);
         
         if(server_sl > 0)
         {
            double _sld = MathAbs(server_sl - entry);
            int pips = (int)MathRound(_sld / pip_size);
            if(is_index && monitored_positions[i].sl_pips > 0 && pips > monitored_positions[i].sl_pips * 3)
               pips = (int)MathRound(_sld / point_value);
            if(pips != monitored_positions[i].sl_pips)
               monitored_positions[i].sl_pips = pips;
               
            if(monitored_positions[i].trailing_enabled)
            {
               if(MathAbs(server_sl - monitored_positions[i].trailing_sl_price) > point_value)
                  monitored_positions[i].trailing_sl_price = server_sl;
            }
         }
         
         if(server_tp > 0)
         {
            double _tpd = MathAbs(server_tp - entry);
            int pips = (int)MathRound(_tpd / pip_size);
            if(is_index && monitored_positions[i].tp_pips > 0 && pips > monitored_positions[i].tp_pips * 3)
               pips = (int)MathRound(_tpd / point_value);
            if(pips != monitored_positions[i].tp_pips)
               monitored_positions[i].tp_pips = pips;
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Monitor Positions                                                |
//+------------------------------------------------------------------+
void MonitorPositions()
{
   for(int i = monitor_count - 1; i >= 0; i--)
   {
      if(IsStopped()) return;
      if(!monitored_positions[i].monitoring_enabled) continue;
      
      ulong ticket = monitored_positions[i].ticket;
      if(!PositionSelectByTicket(ticket))
      {
         Print("Monitor: Position ", ticket, " closed or not found. Removing lines.");
         ObjectDelete(0, SL_LinePrefix + IntegerToString(ticket));
         ObjectDelete(0, TP_LinePrefix + IntegerToString(ticket));
         ObjectDelete(0, "MON_Pos_" + IntegerToString(ticket));
         ObjectDelete(0, "BTN_Close_" + IntegerToString(ticket));
         
         for(int j = i; j < monitor_count - 1; j++)
         {
            monitored_positions[j] = monitored_positions[j + 1];
         }
         monitor_count--;
         ArrayResize(monitored_positions, monitor_count);
         continue;
      }
      
      if(TimeCurrent() - monitored_positions[i].open_time < 10)
      {
         if(ShowChartLines) DrawOrUpdateSLTPLines(i);
         continue; 
      }
      
      double current_price;
      if(monitored_positions[i].type == POSITION_TYPE_BUY)
         current_price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      else
         current_price = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      
      double pip_distance = MathAbs(current_price - monitored_positions[i].entry_price) / pip_size;
      if(monitored_positions[i].type == POSITION_TYPE_BUY)
         pip_distance = (current_price > monitored_positions[i].entry_price) ? pip_distance : -pip_distance;
      else
         pip_distance = (current_price < monitored_positions[i].entry_price) ? pip_distance : -pip_distance;
      
      monitored_positions[i].current_profit_pips = pip_distance;
      
      if(monitored_positions[i].type == POSITION_TYPE_BUY && current_price > monitored_positions[i].highest_price)
         monitored_positions[i].highest_price = current_price;
      if(monitored_positions[i].type == POSITION_TYPE_SELL && current_price < monitored_positions[i].lowest_price)
         monitored_positions[i].lowest_price = current_price;
      
      double server_sl = PositionGetDouble(POSITION_SL);
      if(server_sl > 0 && MathAbs(server_sl - monitored_positions[i].trailing_sl_price) > point_value)
      {
          monitored_positions[i].trailing_sl_price = server_sl;
      }
      else if(server_sl == 0 && monitored_positions[i].trailing_sl_price > 0)
      {
          monitored_positions[i].trailing_sl_price = 0;
          monitored_positions[i].breakeven_locked = false; 
      }
      
      if (server_sl > 0)
      {
           double dist = MathAbs(server_sl - monitored_positions[i].entry_price);
           int pips = (int)MathRound(dist / pip_size);
           if(is_index && monitored_positions[i].sl_pips > 0 && pips > monitored_positions[i].sl_pips * 3)
              pips = (int)MathRound(dist / point_value);
           if (pips != monitored_positions[i].sl_pips)
               monitored_positions[i].sl_pips = pips;
      }
      else
      {
           if(monitored_positions[i].sl_pips > 0)
               monitored_positions[i].sl_pips = 0;
      }
      
      double server_tp = PositionGetDouble(POSITION_TP);
      if (server_tp > 0)
      {
           double dist = MathAbs(server_tp - monitored_positions[i].entry_price);
           int pips = (int)MathRound(dist / pip_size);
           if(is_index && monitored_positions[i].tp_pips > 0 && pips > monitored_positions[i].tp_pips * 3)
              pips = (int)MathRound(dist / point_value);
           if (pips != monitored_positions[i].tp_pips)
               monitored_positions[i].tp_pips = pips;
      }
      else
      {
           if(monitored_positions[i].tp_pips > 0)
               monitored_positions[i].tp_pips = 0;
      }

      if(!monitored_positions[i].trailing_enabled)
      {
         if(monitored_positions[i].sl_pips > 0 && pip_distance <= -monitored_positions[i].sl_pips)
         {
            if(Runtime_EnableAutoClose)
            {
               Print("CLOSE: Fixed SL hit. Dist=", pip_distance, " SL=", monitored_positions[i].sl_pips, " Price=", current_price);
               ClosePositionAtMarket(ticket, "Fixed SL hit");
            }
            continue;
         }
         
         if(monitored_positions[i].tp_pips > 0 && pip_distance >= monitored_positions[i].tp_pips)
         {
            if(Runtime_EnableAutoClose)
            {
               Print("CLOSE: Fixed TP hit. Dist=", pip_distance, " TP=", monitored_positions[i].tp_pips, " Price=", current_price);
               ClosePositionAtMarket(ticket, "Fixed TP hit");
            }
            continue;
         }
      }
      else
      {
         ProcessTrailingStop(i, current_price, pip_distance);
      }
      
      if(ShowChartLines)
         DrawOrUpdateSLTPLines(i);
   }
}

//+------------------------------------------------------------------+
//| Process Trailing Stop                                            |
//+------------------------------------------------------------------+
void ProcessTrailingStop(int idx, double current_price, double pip_distance)
{
   ulong ticket = monitored_positions[idx].ticket;
   
   double activation_distance = Runtime_TrailingActivation * pip_size;
   double trail_distance = Runtime_TrailingDistance * pip_size;
   
   if(Runtime_UseATR && current_atr > 0)
   {
      activation_distance = current_atr * ATR_Multi_Activation;
      trail_distance = current_atr * ATR_Multi_TrailingDist;
   }
   
   if(!monitored_positions[idx].breakeven_locked && MathAbs(pip_distance * pip_size) >= activation_distance)
   {
      double breakeven_buffer = 0;
      if(UseBreakevenBuffer)
      {
         if(BreakevenType == BUFFER_FIXED)
            breakeven_buffer = BreakevenFixedPips * pip_size;
         else if(Runtime_UseATR && current_atr > 0)
            breakeven_buffer = current_atr * BreakevenATRMulti;
      }
      
      if(monitored_positions[idx].type == POSITION_TYPE_BUY)
      {
         monitored_positions[idx].trailing_sl_price = monitored_positions[idx].entry_price + breakeven_buffer;
      }
      else
      {
         monitored_positions[idx].trailing_sl_price = monitored_positions[idx].entry_price - breakeven_buffer;
      }
      
      monitored_positions[idx].breakeven_locked = true;
      
      if(UseServerTrailing && Runtime_EnableAutoClose)
         ModifyPositionSL(ticket, monitored_positions[idx].trailing_sl_price, "Breakeven lock");
   }
   
   if(monitored_positions[idx].breakeven_locked)
   {
      double new_sl_price = 0;
      
      if(monitored_positions[idx].type == POSITION_TYPE_BUY)
      {
         new_sl_price = monitored_positions[idx].highest_price - trail_distance;
         {
            double _buy_floor = monitored_positions[idx].entry_price
                              - monitored_positions[idx].sl_pips * pip_size * 1.05;
            if(new_sl_price < _buy_floor) new_sl_price = _buy_floor;
         }
         if(new_sl_price > monitored_positions[idx].trailing_sl_price)
         {
            monitored_positions[idx].trailing_sl_price = new_sl_price;
            if(UseServerTrailing && Runtime_EnableAutoClose)
               ModifyPositionSL(ticket, new_sl_price, "Trailing update");
         }
         
         if(current_price <= monitored_positions[idx].trailing_sl_price)
         {
            if(Runtime_EnableAutoClose) ClosePositionAtMarket(ticket, "Trailing SL hit");
         }
      }
      else
      {
         new_sl_price = monitored_positions[idx].lowest_price + trail_distance;
         {
            double _sell_cap = monitored_positions[idx].entry_price
                             + monitored_positions[idx].sl_pips * pip_size * 1.05;
            if(new_sl_price > _sell_cap) new_sl_price = _sell_cap;
         }
         if(new_sl_price < monitored_positions[idx].trailing_sl_price || monitored_positions[idx].trailing_sl_price == 0)
         {
            monitored_positions[idx].trailing_sl_price = new_sl_price;
            if(UseServerTrailing && Runtime_EnableAutoClose)
               ModifyPositionSL(ticket, new_sl_price, "Trailing update");
         }
         
         if(current_price >= monitored_positions[idx].trailing_sl_price)
         {
            if(Runtime_EnableAutoClose) ClosePositionAtMarket(ticket, "Trailing SL hit");
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Close Position At Market                                         |
//+------------------------------------------------------------------+
bool ClosePositionAtMarket(ulong ticket, string reason)
{
   if(!PositionSelectByTicket(ticket)) return false;
   
   MqlTradeRequest request;
   MqlTradeResult result;
   ZeroMemory(request);
   ZeroMemory(result);
   
   string symbol = PositionGetString(POSITION_SYMBOL);
   double volume = PositionGetDouble(POSITION_VOLUME);
   ENUM_POSITION_TYPE pos_type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
   
   request.action = TRADE_ACTION_DEAL;
   request.position = ticket;
   request.symbol = symbol;
   request.volume = volume;
   request.deviation = MaxSlippagePips * (int)MathRound(pip_size / point_value);
   request.type = (pos_type == POSITION_TYPE_BUY) ? ORDER_TYPE_SELL : ORDER_TYPE_BUY;
   request.price = (pos_type == POSITION_TYPE_BUY) ? 
                   SymbolInfoDouble(symbol, SYMBOL_BID) : 
                   SymbolInfoDouble(symbol, SYMBOL_ASK);
   request.magic = MagicNumber;
   request.comment = reason;
   
   bool success = OrderSend(request, result);
   if(success && (result.retcode == TRADE_RETCODE_DONE || result.retcode == TRADE_RETCODE_POSITION_CLOSED))
   {
      Print("Position closed #", ticket, " - ", reason);
      return true;
   }
   else
   {
      Print("Failed to close position #", ticket, " - Error: ", result.retcode);
      return false;
   }
}

//+------------------------------------------------------------------+
//| Modify Position SL                                               |
//+------------------------------------------------------------------+
bool ModifyPositionSL(ulong ticket, double new_sl, string reason)
{
   if(!PositionSelectByTicket(ticket)) return false;
   
   double current_tp = PositionGetDouble(POSITION_TP);
   new_sl = NormalizeDouble(new_sl, _Digits);
   
   MqlTradeRequest request;
   MqlTradeResult result;
   ZeroMemory(request);
   ZeroMemory(result);
   
   request.action = TRADE_ACTION_SLTP;
   request.position = ticket;
   request.symbol = PositionGetString(POSITION_SYMBOL);
   request.sl = new_sl;
   request.tp = current_tp;
   request.magic = MagicNumber;
   request.comment = reason;
   
   bool success = OrderSend(request, result);
   if(success && (result.retcode == TRADE_RETCODE_DONE || result.retcode == TRADE_RETCODE_NO_CHANGES))
   {
      Print("SL modified #", ticket, " to ", new_sl, " - ", reason);
      return true;
   }
   else
   {
      Print("Failed to modify SL #", ticket, " - Error: ", result.retcode);
      return false;
   }
}

//+------------------------------------------------------------------+
//| OnTradeTransaction for Tilt Protection                           |
//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction& trans,
                        const MqlTradeRequest& request,
                        const MqlTradeResult& result)
{
   if(trans.type != TRADE_TRANSACTION_DEAL_ADD) return;
   ulong deal_ticket = trans.deal;
   if(!HistoryDealSelect(deal_ticket)) return;
   long   entry_type = HistoryDealGetInteger(deal_ticket, DEAL_ENTRY);
   double profit     = HistoryDealGetDouble(deal_ticket, DEAL_PROFIT);
   if(entry_type == DEAL_ENTRY_OUT)
      TodaysRealizedProfit += profit
                           +  HistoryDealGetDouble(deal_ticket, DEAL_SWAP)
                           +  HistoryDealGetDouble(deal_ticket, DEAL_COMMISSION);
   ScanAndAddPositions();
   if(EnableTiltProtection && entry_type == DEAL_ENTRY_OUT)
   {
      if(profit < 0)
      {
         ConsecutiveLossCount++;
         if(ConsecutiveLossCount >= MaxConsecutiveLosses)
         {
            TiltBlockEndTime = (datetime)(TimeCurrent() + (long)MathMin(TiltPauseMinutes, 30) * 60L);  // v14.18: 30min cap
            Print("Tilt Protection: ",ConsecutiveLossCount," losses. Paused ",TiltPauseMinutes," min.");
         }
      }
      else if(profit >= 0) ConsecutiveLossCount = 0;
   }
}

//+------------------------------------------------------------------+
//| Toggle Setting State (Helper for Data-Driven UI)                 |
//+------------------------------------------------------------------+
void ToggleSettingState(ENUM_TOGGLE_VARS var_id)
{
    switch(var_id)
    {
        case TOGGLE_MONITOR:       Runtime_EnableAutoClose = !Runtime_EnableAutoClose; break;
        case TOGGLE_TRAILING:      Runtime_TrailingEnabled = !Runtime_TrailingEnabled; break;
        case TOGGLE_TIME_FILTER:   Runtime_UseTimeFilter = !Runtime_UseTimeFilter; break;
        case TOGGLE_NEWS_FILTER:   Runtime_UseNewsFilter = !Runtime_UseNewsFilter; break;
        case TOGGLE_ATR_MODE:      Runtime_UseATR = !Runtime_UseATR; break;
    }
}


//+------------------------------------------------------------------+
//| Close All Positions                                              |
//+------------------------------------------------------------------+
int CloseAllPositions(string reason = "")
{
   int closed_count = 0;
   int total = PositionsTotal();
   
   for(int i = total - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket==0) continue;
      if(!PositionSelectByTicket(ticket)) continue;
      if(PositionGetInteger(POSITION_MAGIC)!=MagicNumber) continue;
      if(PositionGetString(POSITION_SYMBOL)!=_Symbol)    continue;
      if(ClosePositionAtMarket(ticket, reason)) closed_count++;
   }
   
   return closed_count;
}

//+------------------------------------------------------------------+
//| v14.13 D1: Execution diagnostic print                            |
//+------------------------------------------------------------------+
void PrintExecutionDiagnostic(int order_type, double entry_px, double sl_px,
                              double tp_px, double lots, int sl_pips_entered)
{
   string dir = (order_type == ORDER_TYPE_BUY) ? "BUY" : "SELL";
   double sl_dist_px = (sl_px > 0) ? MathAbs(entry_px - sl_px) : 0;
   double tp_dist_px = (tp_px > 0) ? MathAbs(entry_px - tp_px) : 0;
   int    sl_mt5pts  = (int)MathRound(sl_dist_px / point_value);
   int    tp_mt5pts  = (int)MathRound(tp_dist_px / point_value);
   Print(dir," executed: Entry=",DoubleToString(entry_px,_Digits),
         " SL=",DoubleToString(sl_px,_Digits),
         " (",sl_pips_entered," EA-pips / ",sl_mt5pts," MT5-pts)",
         " TP=",DoubleToString(tp_px,_Digits),
         " (",tp_mt5pts," MT5-pts)",
         " Lots=",DoubleToString(lots,2));
   if(is_index && pip_size > point_value)
      Print("  [",dir,": 1 EA-pip=",DoubleToString(pip_size/point_value,1),
            " MT5-pts. Crosshair shows ",sl_mt5pts," pts for your ",sl_pips_entered," pip SL]");
}

//+------------------------------------------------------------------+
//| Execute Smart Entry                                              |
//+------------------------------------------------------------------+
void ExecuteSmartEntry(int type)
{
   Print("ExecuteSmartEntry called for type: ", type);

   if(!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED))
   {
      Alert("!! ORDER BLOCKED: AutoTrading DISABLED in MT5 toolbar. Enable the Algo Trading button.");
      if(LogToTerminal) Print("OrderSend blocked: TERMINAL_TRADE_ALLOWED=false (Retcode 10027)");
      return;
   }
   if(!AccountInfoInteger(ACCOUNT_TRADE_EXPERT))
   {
      Alert("!! ORDER BLOCKED: EA Algo Trading DISABLED. EA Properties > Common > Allow Algo Trading.");
      if(LogToTerminal) Print("OrderSend blocked: ACCOUNT_TRADE_EXPERT=false (Retcode 10027)");
      return;
   }

   // v14.18 Mod3B: Tilt Protection popup in ExecuteSmartEntry
   if(EnableTiltProtection && TiltBlockEndTime > TimeCurrent())
   {
      int _secs2 = (int)(TiltBlockEndTime - TimeCurrent());
      PlaySound("alert.wav");
      Alert("⛔ TILT PROTECTION: Trading paused. Resumes in ", _secs2/60, " min ", _secs2%60, " sec (", TimeToString(TiltBlockEndTime, TIME_MINUTES), ")");
      return;
   }
   
   if(MaxOpenPositions>0){
   int _ep=0;
   for(int _pi=0;_pi<PositionsTotal();_pi++){ulong _t=PositionGetTicket(_pi);
      if(_t>0&&PositionSelectByTicket(_t)&&PositionGetString(POSITION_SYMBOL)==_Symbol&&PositionGetInteger(POSITION_MAGIC)==MagicNumber)_ep++;}
   if(_ep>=MaxOpenPositions){Alert("Max Open Positions (",_ep,"/",MaxOpenPositions,")");return;}}
   
   if(MaxTotalLots>0){
   double _tv=0;
   for(int i=0;i<PositionsTotal();i++){ulong t=PositionGetTicket(i);
      if(t>0&&PositionSelectByTicket(t)&&PositionGetString(POSITION_SYMBOL)==_Symbol&&PositionGetInteger(POSITION_MAGIC)==MagicNumber)_tv+=PositionGetDouble(POSITION_VOLUME);}
   if(_tv>=MaxTotalLots){Alert("Max Total Lots reached!");return;}}
   
   if(Runtime_EnableEmergencyStop)
   {
      Alert("EMERGENCY STOP ACTIVE: Trading Disabled.");
      return;
   }
   
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double spread = (ask - bid) / pip_size;
   
   // v14.18 MOD 7: Updated spread rejection message
   if(spread > MaxSpreadPips)
   {
      PlaySound("alert.wav");
      Alert("⚠️ ENTRY REJECTED: Spread too wide (", DoubleToString(spread,1), " pips > ", MaxSpreadPips, " pip limit). Wait for spread to tighten.");
      return;
   }
   
   if(DailyLossBreached)
   {
      Alert("⛔ ENTRY BLOCKED: Daily Loss Limit (DLL) has been breached. No new trades today.");
      return;
   }
   if(TLLBreached)
   {
      Alert("⛔ ENTRY BLOCKED: Max Trailing Drawdown (TLL) has been breached. No new trades today.");
      return;
   }
   if(EnableDailyTargetAutoClose && DailyTargetReached)
   {
      Alert("🏆 ENTRY BLOCKED: Daily Gain Target reached. Trading stopped for today.");
      return;
   }
   
   // --- SL/TP CALCULATION & VALIDATION ---
   double sl_dist;
   if(Runtime_UseATR && current_atr > 0)
      sl_dist = MathRound(current_atr * ATR_Multi_SL / pip_size) * pip_size;
   else
      sl_dist = Runtime_SL_Pips * pip_size;
   
   if(sl_dist == 0) sl_dist = 0.0001;
   
   if(sl_dist > 0 && sl_dist <= (ask - bid) * 1.1)
   {
      Alert("ENTRY REJECTED: SL Distance ($", DoubleToString(sl_dist, 2), ") is too close to Spread ($", DoubleToString(ask-bid, 2), ")!");
      return;
   }
   
   Print("Executing Smart Entry. SL Pips: ", Runtime_SL_Pips, " ($", DoubleToString(sl_dist, 2), ")");
   
   double lots = 0.01;
   
   if(Runtime_FixedLotSize > 0.0)
   {
      lots = Runtime_FixedLotSize;
   }
   else if(Runtime_RiskPerTradePct > 0.001)
   {
      double risk_amt = WorkingAccountSize * (Runtime_RiskPerTradePct / 100.0);
      double contract_size = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_CONTRACT_SIZE);
      
      if(sl_dist > 0)
      {
         if(is_index)            lots = risk_amt / sl_dist;
         else if(contract_size>0) lots = risk_amt / (contract_size * sl_dist);
      }
   }
   
   double min_lot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double max_lot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   double step_lot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   
   lots = MathFloor(lots / step_lot) * step_lot;
   if(lots < min_lot) lots = min_lot;
   if(lots > max_lot) lots = max_lot;
   
   if(Runtime_RiskPerTradePct > 0.001 && sl_dist > 0)
   {
      double _f3_max_usd  = WorkingAccountSize * (Runtime_RiskPerTradePct * 2.0 / 100.0);
      double _f3_max_lots = _f3_max_usd / sl_dist;
      _f3_max_lots = MathFloor(_f3_max_lots / step_lot) * step_lot;
      if(_f3_max_lots < min_lot) _f3_max_lots = min_lot;
      if(lots > _f3_max_lots)
      {
         Print("v14.13 F3: Lot cap applied. Calc=",DoubleToString(lots,2),
               " -> capped to ",DoubleToString(_f3_max_lots,2),
               " (MaxRisk=$",DoubleToString(_f3_max_usd,2),
               " / SLdist=",DoubleToString(sl_dist,5),")");
         Alert("v14.13 F3: Lot size capped to ",DoubleToString(_f3_max_lots,2),
               " — SL may be too large for risk settings.");
         lots = _f3_max_lots;
      }
   }
   
   bool success = false;
   if(Runtime_IsPendingMode)
   {
      ENUM_ORDER_TYPE order_type;
      double current_bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      double current_ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      
      if(type == ORDER_TYPE_BUY)
         order_type = (Runtime_PendingPrice > current_ask) ? ORDER_TYPE_BUY_STOP : ORDER_TYPE_BUY_LIMIT;
      else
         order_type = (Runtime_PendingPrice < current_bid) ? ORDER_TYPE_SELL_STOP : ORDER_TYPE_SELL_LIMIT;
      
      double sl_price = 0;
      double tp_price = 0;
      
      if (Runtime_SL_Pips > 0) {
          if (type == ORDER_TYPE_BUY) sl_price = Runtime_PendingPrice - Runtime_SL_Pips * pip_size;
          else sl_price = Runtime_PendingPrice + Runtime_SL_Pips * pip_size;
          sl_price = NormalizeDouble(sl_price, _Digits);
      }
      
      if (Runtime_TP_Pips > 0) {
          if (type == ORDER_TYPE_BUY) tp_price = Runtime_PendingPrice + Runtime_TP_Pips * pip_size;
          else tp_price = Runtime_PendingPrice - Runtime_TP_Pips * pip_size;
          tp_price = NormalizeDouble(tp_price, _Digits);
      }
         
      success = trade.OrderOpen(_Symbol, order_type, lots, 0, Runtime_PendingPrice, sl_price, tp_price, ORDER_TIME_GTC, 0, "Manual Smart Entry");
      if(success) { PlaySound("alert.wav"); }  // v14.18: pending fill audio
   }
   else
   {
      if(type == ORDER_TYPE_BUY)
      {
         Print("Sending BUY request... Lot:", lots, " SL_Dist:", sl_dist);
         MqlTradeRequest request;
         MqlTradeResult result;
         ZeroMemory(request); ZeroMemory(result);
         ENUM_ORDER_TYPE_FILLING filling_mode = (ENUM_ORDER_TYPE_FILLING)GetFillingMode(_Symbol, false);
         long sym_filling = (long)SymbolInfoInteger(_Symbol, SYMBOL_FILLING_MODE);
         Print("Filling Mode: Flags=",sym_filling," Sel=",EnumToString(filling_mode)," Manual=",EnumToString(ManualFillingMode));
         request.action=TRADE_ACTION_DEAL; request.symbol=_Symbol; request.volume=lots;
         request.type=ORDER_TYPE_BUY;
         request.price=SymbolInfoDouble(_Symbol, SYMBOL_ASK);
         double _tick_sz=SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_SIZE);
         if(_tick_sz<=0) _tick_sz=point_value;
         double _tp_dist=Runtime_TP_Pips*pip_size;
         if(Runtime_SL_Pips>0) request.sl=NormalizeDouble(request.price-MathRound(sl_dist/_tick_sz)*_tick_sz,_Digits);
         if(Runtime_TP_Pips>0) request.tp=NormalizeDouble(request.price+MathRound(_tp_dist/_tick_sz)*_tick_sz,_Digits);
         request.deviation=MaxSlippagePips; request.magic=MagicNumber;
         request.comment="Manual Smart Entry"; request.type_filling=filling_mode;
   
         bool success_buy = OrderSend(request, result);
         if(success_buy) { PlaySound("alert.wav"); }  // v14.18: order fill audio

         if(!success_buy)
         {
             Print("OrderSend Failed with ", EnumToString(filling_mode), " Retcode: ", result.retcode);
             if(result.retcode == TRADE_RETCODE_CLIENT_DISABLES_AT)
             {
                Alert("!! Retcode 10027: AutoTrading is OFF. Enable Algo Trading toolbar OR EA Properties > Allow Algo Trading.");
                if(LogToTerminal) Print("Retcode 10027 - no filling mode retry.");
                return;
             }
             if(result.retcode == TRADE_RETCODE_REQUOTE || result.retcode == 10030)
             {
                Print("Retcode 10030 requote — refreshing price and retrying...");
                Sleep(200);
                request.price = (request.type == ORDER_TYPE_BUY)
                              ? SymbolInfoDouble(_Symbol, SYMBOL_ASK)
                              : SymbolInfoDouble(_Symbol, SYMBOL_BID);
                if(OrderSend(request, result))
                   success = (result.retcode==TRADE_RETCODE_DONE||result.retcode==TRADE_RETCODE_PLACED);
                if(success) Print("Requote retry succeeded.");
                else        Print("Requote retry failed. Retcode: ",result.retcode);
             }
             if(result.retcode == TRADE_RETCODE_INVALID_FILL)
             {
                 if(filling_mode != ORDER_FILLING_FOK && (sym_filling & SYMBOL_FILLING_FOK) != 0)
                 {
                     Print("Retrying with FOK...");
                     request.type_filling = ORDER_FILLING_FOK;
                     if(OrderSend(request, result)) return;
                 }
                 if(filling_mode != ORDER_FILLING_IOC && (sym_filling & SYMBOL_FILLING_IOC) != 0)
                 {
                     Print("Retrying with IOC...");
                     request.type_filling = ORDER_FILLING_IOC;
                     if(OrderSend(request, result)) return;
                 }
                 if(filling_mode != ORDER_FILLING_RETURN)
                 {
                     Print("Retrying with RETURN...");
                     request.type_filling = ORDER_FILLING_RETURN;
                     if(OrderSend(request, result)) return;
                 }
             }
             if(result.retcode == TRADE_RETCODE_TRADE_DISABLED)
             {
                 Alert("CRITICAL: Broker rejected trade - TRADE DISABLED (10017). Check Account/Symbol permissions.");
             }
             else if(result.retcode == TRADE_RETCODE_MARKET_CLOSED)
             {
                 Alert("CRITICAL: Market is CLOSED.");
             }
         }

         success = (result.retcode == TRADE_RETCODE_DONE || result.retcode == TRADE_RETCODE_PLACED);
         
         if(success)
         {
             Print("Trade Successful with Filling Mode: ", EnumToString(request.type_filling));
             trade.Result(result);
         }

      }
      else
      {
         Print("Sending SELL request... Lot:", lots);
         
         MqlTradeRequest request;
         MqlTradeResult result;
         ZeroMemory(request); ZeroMemory(result);
         ENUM_ORDER_TYPE_FILLING filling_mode = (ENUM_ORDER_TYPE_FILLING)GetFillingMode(_Symbol, false);
         long sym_filling = (long)SymbolInfoInteger(_Symbol, SYMBOL_FILLING_MODE);
         Print("Filling Mode: Flags=",sym_filling," Sel=",EnumToString(filling_mode)," Manual=",EnumToString(ManualFillingMode));
         request.action=TRADE_ACTION_DEAL; request.symbol=_Symbol; request.volume=lots;
         request.type=ORDER_TYPE_SELL;
         request.price=SymbolInfoDouble(_Symbol, SYMBOL_BID);
         double _tick_sz=SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_SIZE);
         if(_tick_sz<=0) _tick_sz=point_value;
         double _tp_dist=Runtime_TP_Pips*pip_size;
         if(Runtime_SL_Pips>0) request.sl=NormalizeDouble(request.price+MathRound(sl_dist/_tick_sz)*_tick_sz,_Digits);
         if(Runtime_TP_Pips>0) request.tp=NormalizeDouble(request.price-MathRound(_tp_dist/_tick_sz)*_tick_sz,_Digits);
         request.deviation=MaxSlippagePips; request.magic=MagicNumber;
         request.comment="Manual Smart Entry"; request.type_filling=filling_mode;
   
         bool success_sell = OrderSend(request, result);
         if(success_sell) { PlaySound("alert.wav"); }  // v14.18: order fill audio

         if(!success_sell)
         {
             Print("OrderSend Failed with ", EnumToString(filling_mode), " Retcode: ", result.retcode);
             if(result.retcode == TRADE_RETCODE_CLIENT_DISABLES_AT)
             {
                Alert("!! Retcode 10027: AutoTrading is OFF. Enable Algo Trading toolbar OR EA Properties > Allow Algo Trading.");
                if(LogToTerminal) Print("Retcode 10027 - no filling mode retry.");
                return;
             }
             if(result.retcode == TRADE_RETCODE_REQUOTE || result.retcode == 10030)
             {
                Print("Retcode 10030 requote — refreshing price and retrying...");
                Sleep(200);
                request.price = (request.type == ORDER_TYPE_BUY)
                              ? SymbolInfoDouble(_Symbol, SYMBOL_ASK)
                              : SymbolInfoDouble(_Symbol, SYMBOL_BID);
                if(OrderSend(request, result))
                   success = (result.retcode==TRADE_RETCODE_DONE||result.retcode==TRADE_RETCODE_PLACED);
                if(success) Print("Requote retry succeeded.");
                else        Print("Requote retry failed. Retcode: ",result.retcode);
             }
             if(result.retcode == TRADE_RETCODE_INVALID_FILL)
             {
                 if(filling_mode != ORDER_FILLING_FOK && (sym_filling & SYMBOL_FILLING_FOK) != 0)
                 {
                     Print("Retrying with FOK...");
                     request.type_filling = ORDER_FILLING_FOK;
                     if(OrderSend(request, result)) return;
                 }
                 if(filling_mode != ORDER_FILLING_IOC && (sym_filling & SYMBOL_FILLING_IOC) != 0)
                 {
                     Print("Retrying with IOC...");
                     request.type_filling = ORDER_FILLING_IOC;
                     if(OrderSend(request, result)) return;
                 }
                 if(filling_mode != ORDER_FILLING_RETURN)
                 {
                     Print("Retrying with RETURN...");
                     request.type_filling = ORDER_FILLING_RETURN;
                     if(OrderSend(request, result)) return;
                 }
             }
             if(result.retcode == TRADE_RETCODE_TRADE_DISABLED)
             {
                 Alert("CRITICAL: Broker rejected trade - TRADE DISABLED (10017). Check Account/Symbol permissions.");
             }
             else if(result.retcode == TRADE_RETCODE_MARKET_CLOSED)
             {
                 Alert("CRITICAL: Market is CLOSED.");
             }
         }
 
         success = (result.retcode == TRADE_RETCODE_DONE || result.retcode == TRADE_RETCODE_PLACED);
         
         if(success) trade.Result(result);
      }
   }
   
   if(success)
   {
      double _epx = (type == ORDER_TYPE_BUY)
                  ? SymbolInfoDouble(_Symbol, SYMBOL_ASK)
                  : SymbolInfoDouble(_Symbol, SYMBOL_BID);
      double _slpx = _epx + ((type==ORDER_TYPE_BUY) ? -sl_dist : sl_dist);
      double _tppx = (Runtime_TP_Pips > 0)
                   ? _epx + ((type==ORDER_TYPE_BUY) ? Runtime_TP_Pips*pip_size : -Runtime_TP_Pips*pip_size)
                   : 0;
      PrintExecutionDiagnostic(type, _epx, _slpx, _tppx, lots, Runtime_SL_Pips);
      PlaySound("ok.wav");
      if(!Runtime_IsPendingMode) ScanAndAddPositions();
   }
   else
   {
       Print("Smart Entry Failed. Last Error: ", GetLastError());
       Alert("Order Send Failed! Check Journal/Experts tab.");
   }
}

void AddToggle(string id, string txt, bool state, int &btn_x, int row_y, int btn_w)
{
   string btn_name = "SET_BTN_" + id;
   ObjectDelete(0, btn_name);
   ObjectCreate(0, btn_name, OBJ_BUTTON, 0, 0, 0);
   ObjectSetInteger(0, btn_name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, btn_name, OBJPROP_XDISTANCE, btn_x);
   ObjectSetInteger(0, btn_name, OBJPROP_YDISTANCE, row_y);
   ObjectSetInteger(0, btn_name, OBJPROP_XSIZE, btn_w);
   ObjectSetInteger(0, btn_name, OBJPROP_YSIZE, Scaled(24));
   ObjectSetInteger(0, btn_name, OBJPROP_FONTSIZE, ScaledFont()-1);
   ObjectSetString(0, btn_name, OBJPROP_TEXT, txt);
   ObjectSetInteger(0, btn_name, OBJPROP_BGCOLOR, state ? clrGreen : clrFireBrick);
   ObjectSetInteger(0, btn_name, OBJPROP_COLOR, clrWhite);
   ObjectSetInteger(0, btn_name, OBJPROP_ZORDER, 1005);
   btn_x += btn_w + Scaled(5);
}

//+------------------------------------------------------------------+
//| IMPROVED SETTINGS / INPUTS PANEL - v2 (non-overlapping, clean layout) |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| CREATE FULL SETTINGS PANEL                                       |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| Get Toggle State (Helper for Data-Driven UI)                     |
//+------------------------------------------------------------------+
bool GetToggleState(ENUM_TOGGLE_VARS var_id)
{
    switch(var_id)
    {
        case TOGGLE_MONITOR:       return Runtime_EnableAutoClose;
        case TOGGLE_TRAILING:      return Runtime_TrailingEnabled;
        case TOGGLE_TIME_FILTER:   return Runtime_UseTimeFilter;
        case TOGGLE_NEWS_FILTER:   return Runtime_UseNewsFilter;
        case TOGGLE_ATR_MODE:      return Runtime_UseATR;
    }
    return false;
}

//+------------------------------------------------------------------+
//| Get Input Value as String (Helper for Data-Driven UI)            |
//+------------------------------------------------------------------+
string GetInputValueAsString(ENUM_INPUT_VARS var_id, int precision)
{
    switch(var_id)
    {
        case INPUT_RISK_PCT:   return DoubleToString(Runtime_RiskPerTradePct, precision);
        case INPUT_DLL_PCT:    return DoubleToString(Runtime_DailyLossLimitPct, precision);
        case INPUT_DGT_PCT:    return DoubleToString(Runtime_DailyGainTargetPct, precision);
        case INPUT_TLL_PCT:    return DoubleToString(Runtime_MaxTrailingDDPct, precision);
        case INPUT_TFS_PCT:    return DoubleToString(Runtime_TFShieldPercentage, precision);
        case INPUT_SL_PIPS:    return IntegerToString(Runtime_SL_Pips);
        case INPUT_TP_PIPS:    return IntegerToString(Runtime_TP_Pips);
        case INPUT_TRAIL_DIST: return IntegerToString(Runtime_TrailingDistance);
        case INPUT_TRAIL_ACT:  return IntegerToString(Runtime_TrailingActivation);
        case INPUT_NEWS_PRE:   return IntegerToString(Runtime_NewsPreMinutes);
        case INPUT_NEWS_POST:  return IntegerToString(Runtime_NewsPostMinutes);
        case INPUT_LOCK_RELEASE:return IntegerToString(Runtime_LockReleaseMinutes);
        case INPUT_PDC:        return DoubleToString(Manual_PriorDayClose, precision);
        case INPUT_HWM:        return DoubleToString(Manual_HighWaterMark, precision);
        case INPUT_START_BAL:  return DoubleToString(Manual_StartingBalance, precision);
        case INPUT_GUI_SCALE:  return DoubleToString(Runtime_GuiScale, precision);
    }
    return "";
}

//+------------------------------------------------------------------+
//| Set Input Value from String (Helper for Data-Driven UI)          |
//+------------------------------------------------------------------+
void SetInputVarFromString(ENUM_INPUT_VARS var_id, string value)
{
   double dv = StringToDouble(value);
   int    iv = (int)StringToInteger(value);

   switch(var_id)
   {
      // ── Percentage fields — require > 0, then recalculate limits/buffers ──
      case INPUT_RISK_PCT:
         if(dv > 0) Runtime_RiskPerTradePct = dv;
         break;
      case INPUT_DLL_PCT:
         if(dv > 0) { Runtime_DailyLossLimitPct = dv; RecalculateLimits(); RecalculateBuffers(); }
         break;
      case INPUT_DGT_PCT:
         if(dv > 0) {
            Runtime_DailyGainTargetPct = dv;
            Runtime_DailyGainTarget    = WorkingAccountSize * (dv / 100.0);
         }
         break;
      case INPUT_TLL_PCT:
         if(dv > 0) { Runtime_MaxTrailingDDPct = dv; RecalculateLimits(); RecalculateBuffers(); }
         break;
      case INPUT_TFS_PCT:
         if(dv > 0) { Runtime_TFShieldPercentage = dv; RecalculateLimits(); RecalculateBuffers(); }
         break;

      // ── Pip / integer fields — require >= 0 ──
      case INPUT_SL_PIPS:
         if(iv >= 0) Runtime_SL_Pips = iv;
         break;
      case INPUT_TP_PIPS:
         if(iv >= 0) Runtime_TP_Pips = iv;
         break;
      case INPUT_TRAIL_DIST:
         if(iv >= 0) Runtime_TrailingDistance = iv;
         break;
      case INPUT_TRAIL_ACT:
         if(iv >= 0) Runtime_TrailingActivation = iv;
         break;
      case INPUT_NEWS_PRE:
         if(iv >= 0) Runtime_NewsPreMinutes = iv;
         break;
      case INPUT_NEWS_POST:
         if(iv >= 0) Runtime_NewsPostMinutes = iv;
         break;
      case INPUT_LOCK_RELEASE:
         Runtime_LockReleaseMinutes = MathMax(0, iv);
         if(Runtime_EnableEmergencyStop)
            Runtime_LockReleaseEndTime = (Runtime_LockReleaseMinutes > 0) ? (GetLockClock() + Runtime_LockReleaseMinutes * 60) : 0;
         break;

      // ── Manual account fields — require >= 0, then recalculate ──
      case INPUT_PDC:
         if(dv >= 0) { Manual_PriorDayClose = dv; RecalculateLimits(); RecalculateBuffers(); }
         break;
      case INPUT_HWM:
         if(dv >= 0) { Manual_HighWaterMark = dv; RecalculateLimits(); RecalculateBuffers(); }
         break;
      case INPUT_START_BAL:
         if(dv > 0) {
            Manual_StartingBalance = dv;
            WorkingAccountSize     = dv;   // sync Original Size display
            RecalculateLimits();
            RecalculateBuffers();
         }
         break;

      // ── GUI scale — must rebuild entire panel, but ONLY if the value changed ──
      // v15.2 Fix: Previously, SetInputVarFromString(INPUT_GUI_SCALE) triggered
      // ObjectsDeleteAll(0) + ToggleSettingsPanel() unconditionally (whenever dv>0.1).
      // SaveSettingsFromPanel() calls this for every field on panel close, so even if
      // the scale was unchanged (e.g. still 1.30), a full rebuild was triggered every
      // single time the CLOSE button was clicked — causing two spurious full rebuilds
      // and visual glitches. Now we only rebuild when the value actually changes.
      case INPUT_GUI_SCALE:
         if(dv > 0.1) {
            if(MathAbs(dv - Runtime_GuiScale) > 0.001)
            {
               // Scale genuinely changed — full panel rebuild required
               Runtime_GuiScale       = dv;
               Runtime_UseAutoScaling = false;
               ObjectsDeleteAll(0);
               CreateTransparentPanel();
               UpdateMonitorGUI();
               SettingsPanelExpanded = false;
               ToggleSettingsPanel();
            }
            else
            {
               // Scale unchanged — just keep the runtime var in sync (no rebuild)
               Runtime_GuiScale       = dv;
               Runtime_UseAutoScaling = false;
            }
         }
         break;
   }
}

//+------------------------------------------------------------------+
//| CREATE SETTINGS PANEL (main function)                            |
//+------------------------------------------------------------------+
string GetAccountTypeDisplayText()
{
   switch(Runtime_AccountType)
   {
      case TF_STEP1:   return "1-Step";
      case TF_STEP2:   return "2-Step";
      case TF_INSTANT: return "Instant";
      case TF_FLEX:    return Runtime_FlexFundedAccount ? "Flex Funded" : "Flex Eval";
   }
   return "1-Step";
}

void CycleAccountTypeSetting()
{
   switch(Runtime_AccountType)
   {
      case TF_STEP1:
         Runtime_AccountType = TF_STEP2;
         Runtime_FlexFundedAccount = false;
         break;
      case TF_STEP2:
         Runtime_AccountType = TF_INSTANT;
         Runtime_FlexFundedAccount = false;
         break;
      case TF_INSTANT:
         Runtime_AccountType = TF_FLEX;
         Runtime_FlexFundedAccount = false;
         break;
      case TF_FLEX:
         if(!Runtime_FlexFundedAccount)
            Runtime_FlexFundedAccount = true;
         else
         {
            Runtime_AccountType = TF_STEP1;
            Runtime_FlexFundedAccount = false;
         }
         break;
      default:
         Runtime_AccountType = TF_STEP1;
         Runtime_FlexFundedAccount = false;
         break;
   }
   RecalculateLimits();
   RecalculateBuffers();
}

void CreateSettingsPanelObjects()
{
   int x = PanelOffsetX;
   int y = PanelOffsetY;   // open settings panel near the top, over the output panel
   int row_h = Scaled(30);

   int panel_w = Scaled(350);
   int num_toggles = ArraySize(g_toggle_settings);
   int num_inputs = ArraySize(g_input_settings);
   int content_h = Scaled(40) + (num_toggles * row_h) + Scaled(12) + row_h + (num_inputs * row_h);
   int panel_h = content_h + Scaled(20);

   ObjectDelete(0, "SET_BG");
   ObjectCreate(0, "SET_BG", OBJ_RECTANGLE_LABEL, 0, 0, 0);
   ObjectSetInteger(0, "SET_BG", OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, "SET_BG", OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, "SET_BG", OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, "SET_BG", OBJPROP_XSIZE, panel_w);
   ObjectSetInteger(0, "SET_BG", OBJPROP_YSIZE, panel_h);
   ObjectSetInteger(0, "SET_BG", OBJPROP_BGCOLOR, C'20,30,40');
   ObjectSetInteger(0, "SET_BG", OBJPROP_COLOR, C'20,30,40');
   ObjectSetInteger(0, "SET_BG", OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSetInteger(0, "SET_BG", OBJPROP_BACK, false);
   ObjectSetInteger(0, "SET_BG", OBJPROP_ZORDER, 990);

   int current_y = y + Scaled(10);
   int content_x = x + Scaled(10);

   string header_name = "SET_HEADER";
   ObjectDelete(0, header_name);
   ObjectCreate(0, header_name, OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, header_name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, header_name, OBJPROP_XDISTANCE, content_x);
   ObjectSetInteger(0, header_name, OBJPROP_YDISTANCE, current_y);
   ObjectSetString(0, header_name, OBJPROP_TEXT, "INPUT SETTINGS");
   ObjectSetInteger(0, header_name, OBJPROP_FONTSIZE, ScaledFont() + 2);
   ObjectSetInteger(0, header_name, OBJPROP_COLOR, clrWhite);
   ObjectSetInteger(0, header_name, OBJPROP_ZORDER, 995);
   current_y += Scaled(30);

   for(int i = 0; i < num_toggles; i++)
   {
      bool is_on = GetToggleState(g_toggle_settings[i].var_id);
      AddSettingsToggle(g_toggle_settings[i].name, g_toggle_settings[i].label, is_on, "", content_x, current_y, panel_w - Scaled(90), row_h);
   }
   current_y += Scaled(12);

   string acct_lbl = "SET_LBL_AccountType";
   ObjectDelete(0, acct_lbl);
   ObjectCreate(0, acct_lbl, OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, acct_lbl, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, acct_lbl, OBJPROP_XDISTANCE, content_x);
   ObjectSetInteger(0, acct_lbl, OBJPROP_YDISTANCE, current_y + Scaled(5));
   ObjectSetInteger(0, acct_lbl, OBJPROP_COLOR, clrWhite);
   ObjectSetInteger(0, acct_lbl, OBJPROP_FONTSIZE, ScaledFont());
   ObjectSetString(0, acct_lbl, OBJPROP_TEXT, "TF Account:");
   ObjectSetInteger(0, acct_lbl, OBJPROP_ZORDER, 1005);

   string acct_btn = "SET_BTN_AccountType";
   ObjectDelete(0, acct_btn);
   ObjectCreate(0, acct_btn, OBJ_BUTTON, 0, 0, 0);
   ObjectSetInteger(0, acct_btn, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, acct_btn, OBJPROP_XDISTANCE, x + panel_w - Scaled(150));
   ObjectSetInteger(0, acct_btn, OBJPROP_YDISTANCE, current_y);
   ObjectSetInteger(0, acct_btn, OBJPROP_XSIZE, Scaled(130));
   ObjectSetInteger(0, acct_btn, OBJPROP_YSIZE, Scaled(26));
   ObjectSetInteger(0, acct_btn, OBJPROP_FONTSIZE, ScaledFont() - 1);
   ObjectSetString(0, acct_btn, OBJPROP_TEXT, GetAccountTypeDisplayText());
   ObjectSetInteger(0, acct_btn, OBJPROP_BGCOLOR, clrDarkSlateBlue);
   ObjectSetInteger(0, acct_btn, OBJPROP_COLOR, clrWhite);
   ObjectSetInteger(0, acct_btn, OBJPROP_ZORDER, 1005);
   current_y += row_h;

   for(int i = 0; i < num_inputs; i++)
   {
      string value_str = GetInputValueAsString(g_input_settings[i].var_id, g_input_settings[i].precision);
      AddSettingsRow(g_input_settings[i].name, g_input_settings[i].label, value_str, content_x, current_y, panel_w - Scaled(120), Scaled(100), row_h);
   }

   ChartRedraw();
}
//+------------------------------------------------------------------+
//| Save Settings From Panel (DATA-DRIVEN)                           |
//+------------------------------------------------------------------+
void SaveSettingsFromPanel()
{
   if(!SettingsPanelExpanded) return;

   // Loop through all defined input settings
   for(int i = 0; i < ArraySize(g_input_settings); i++)
   {
      string edit_name = "SET_EDIT_" + g_input_settings[i].name;
      if(ObjectFind(0, edit_name) >= 0)
      {
         // Read the value from the GUI
         string value = ObjectGetString(0, edit_name, OBJPROP_TEXT);
         
         // Use the helper function to update the correct runtime variable
         SetInputVarFromString(g_input_settings[i].var_id, value);
      }
   }

   // After updating variables, recalculate any dependent values.
   // Note: SetInputVarFromString already recalculates per-field on live edits,
   // but we call again here as a safety net for any fields we may have missed.
   RecalculateLimits();
   RecalculateBuffers();
}

//+------------------------------------------------------------------+
//| DELETE SETTINGS PANEL (clean close)                              |
//+------------------------------------------------------------------+
void DeleteSettingsPanelObjects()
{
   ObjectsDeleteAll(0, "SET_");   // Deletes BG, title, labels, edits

   // Explicitly delete the data-driven toggle buttons and their labels
   for(int i = 0; i < ArraySize(g_toggle_settings); i++)
   {
      ObjectDelete(0, "BTN_" + g_toggle_settings[i].name);
      ObjectDelete(0, "SET_LBL_" + g_toggle_settings[i].name);
   }
   ObjectDelete(0, "SET_BTN_AccountType");
   ObjectDelete(0, "SET_LBL_AccountType");
}

void OnChartEvent(const int id, const long& lparam, const double& dparam, const string& sparam)
{
   // Draggable SL/TP lines
   if(id == CHARTEVENT_OBJECT_DRAG)
   {
      if(StringFind(sparam, SL_LinePrefix) == 0 || StringFind(sparam, TP_LinePrefix) == 0)
      {
         static uint last_drag_time = 0;
         if(GetTickCount() - last_drag_time < 200) return;
         last_drag_time = GetTickCount();

         double new_price = ObjectGetDouble(0, sparam, OBJPROP_PRICE);
         bool   is_sl     = StringFind(sparam, SL_LinePrefix) == 0;
         int    pfx_len   = is_sl ? StringLen(SL_LinePrefix) : StringLen(TP_LinePrefix);
         ulong  ticket    = (ulong)StringToInteger(StringSubstr(sparam, pfx_len));

         int idx = -1;
         for(int i = 0; i < monitor_count; i++)
            if(monitored_positions[i].ticket == ticket) { idx = i; break; }
         if(idx < 0) return;

         if(!PositionSelectByTicket(ticket)) return;
         double new_sl = is_sl ? new_price : PositionGetDouble(POSITION_SL);
         double new_tp = is_sl ? PositionGetDouble(POSITION_TP) : new_price;
         double cur_sl = PositionGetDouble(POSITION_SL);
         double cur_tp = PositionGetDouble(POSITION_TP);

         if((is_sl && MathAbs(new_sl - cur_sl) > point_value) || (!is_sl && MathAbs(new_tp - cur_tp) > point_value))
         {
            if(ModifyPositionSLTP(ticket, new_sl, new_tp, "Manual drag " + (is_sl ? "SL" : "TP")))
            {
               if(is_sl) monitored_positions[idx].trailing_sl_price = new_price;
               Print("Manual drag updated ", (is_sl ? "SL" : "TP"), " #", ticket, " to ", DoubleToString(new_price, _Digits));
            }
            else Print("Manual drag failed - reverting line");
         }
         ChartRedraw();
         return;
      }
   }

   // Button click handlers
   if(id == CHARTEVENT_OBJECT_CLICK)
   {
      // ── "Do Not Disturb" — pause OnTick updates while user types in ANY edit field ──
      // Catches GUI_EDIT_SL/TP/Size/Price AND all SET_EDIT_* fields in one place.
      if(ObjectGetInteger(0, sparam, OBJPROP_TYPE) == OBJ_EDIT)
      {
         g_active_edit_object = sparam;         // Track active edit box for GUI-pause logic.
      }

      if(sparam == "BTN_FlattenAll")
      {
         ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
         CloseAllPositions("MANUAL FLATTEN");
         CancelAllPendingOrders("MANUAL FLATTEN");
         ChartRedraw();
         return;
      }

      if(sparam == "BTN_BE_ALL")
      {
         ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
         MoveAllToBreakeven();
         return;
      }

      if(sparam == "BTN_Settings")
      {
         ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
         if(SettingsPanelExpanded) SaveSettingsFromPanel();
         ToggleSettingsPanel();
         ChartRedraw();
         return;
      }

      if(sparam == "BTN_SmartBuy")
      {
         ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
         string sl_str   = ObjectGetString(0, "EDIT_SL",   OBJPROP_TEXT);
         string tp_str   = ObjectGetString(0, "EDIT_TP",   OBJPROP_TEXT);
         string size_str = ObjectGetString(0, "EDIT_SIZE", OBJPROP_TEXT);
         Runtime_SL_Pips = (int)StringToInteger(sl_str);
         Runtime_TP_Pips = (int)StringToInteger(tp_str);
         if(StringLen(size_str) > 0)
         {
            double _p  = StringToDouble(size_str);
            double _mn = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
            double _mx = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
            double _st = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
            if(_p >= _mn && _p <= _mx) Runtime_FixedLotSize = MathFloor(_p / _st) * _st;
            else { Runtime_FixedLotSize = MathMax(_mn, MathMin(_mx, _p > 0 ? _p : _mn));
                   ObjectSetString(0, "EDIT_SIZE", OBJPROP_TEXT, DoubleToString(Runtime_FixedLotSize, 2)); }
         }
         ExecuteSmartEntry(ORDER_TYPE_BUY);
         return;
      }

      if(sparam == "BTN_SmartSell")
      {
         ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
         string sl_str   = ObjectGetString(0, "EDIT_SL",   OBJPROP_TEXT);
         string tp_str   = ObjectGetString(0, "EDIT_TP",   OBJPROP_TEXT);
         string size_str = ObjectGetString(0, "EDIT_SIZE", OBJPROP_TEXT);
         Runtime_SL_Pips = (int)StringToInteger(sl_str);
         Runtime_TP_Pips = (int)StringToInteger(tp_str);
         if(StringLen(size_str) > 0)
         {
            double _p  = StringToDouble(size_str);
            double _mn = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
            double _mx = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
            double _st = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
            if(_p >= _mn && _p <= _mx) Runtime_FixedLotSize = MathFloor(_p / _st) * _st;
            else { Runtime_FixedLotSize = MathMax(_mn, MathMin(_mx, _p > 0 ? _p : _mn));
                   ObjectSetString(0, "EDIT_SIZE", OBJPROP_TEXT, DoubleToString(Runtime_FixedLotSize, 2)); }
         }
         ExecuteSmartEntry(ORDER_TYPE_SELL);
         return;
      }

      if(sparam == "BTN_BUY")
      {
         ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
         string sl_str = ObjectGetString(0, "EDIT_SL", OBJPROP_TEXT);
         string tp_str = ObjectGetString(0, "EDIT_TP", OBJPROP_TEXT);
         Runtime_SL_Pips = (int)StringToInteger(sl_str);
         Runtime_TP_Pips = (int)StringToInteger(tp_str);
         ExecuteSmartEntry(ORDER_TYPE_BUY);
         return;
      }

      if(sparam == "BTN_SELL")
      {
         ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
         string sl_str = ObjectGetString(0, "EDIT_SL", OBJPROP_TEXT);
         string tp_str = ObjectGetString(0, "EDIT_TP", OBJPROP_TEXT);
         Runtime_SL_Pips = (int)StringToInteger(sl_str);
         Runtime_TP_Pips = (int)StringToInteger(tp_str);
         ExecuteSmartEntry(ORDER_TYPE_SELL);
         return;
      }

      if(StringFind(sparam, "BTN_Close_") == 0)
      {
         ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
         ulong ticket = (ulong)StringToInteger(StringSubstr(sparam, 10));
         ClosePositionAtMarket(ticket, "Manual Monitor Close");
         ChartRedraw();
         return;
      }
      if(sparam == "BTN_MARKET")
      {
         ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
         Runtime_IsPendingMode = false;
         CreateTransparentPanel();
         return;
      }

      if(sparam == "BTN_LIMIT")
      {
         ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
         Runtime_IsPendingMode = true;
         if(Runtime_PendingPrice == 0)
            Runtime_PendingPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);
         CreateTransparentPanel();
         return;
      }


      if(sparam == "BTN_KillSwitch")
      {
         ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
         Runtime_EnableEmergencyStop = !Runtime_EnableEmergencyStop;
         if(Runtime_EnableEmergencyStop)
         {
            Runtime_LockReleaseEndTime = (Runtime_LockReleaseMinutes > 0) ? (GetLockClock() + Runtime_LockReleaseMinutes * 60) : 0;
            CancelAllPendingOrders("MANUAL LOCK");
            Print("TRADING LOCK ACTIVATED", (Runtime_LockReleaseEndTime > 0 ? StringFormat(": %d min, release at %s", Runtime_LockReleaseMinutes, TimeToString(Runtime_LockReleaseEndTime, TIME_MINUTES|TIME_SECONDS)) : ": manual release only"));
         }
         else
         {
            Runtime_LockReleaseEndTime = 0;
            Print("TRADING LOCK RELEASED manually");
         }
         CreateTransparentPanel();
         return;
      }

      // Settings panel toggle buttons (v14.12 style: UpdateSettingsPanel ONLY)
      // CRITICAL: must NOT call CreateSettingsPanelObjects() here — that function
      // deletes and rebuilds all SET_EDIT_* boxes, silently discarding any value
      // the user has typed but not yet committed with Enter.
      if(StringFind(sparam, "BTN_") == 0)
      {
         string name = StringSubstr(sparam, 4);
         for(int i = 0; i < ArraySize(g_toggle_settings); i++)
         {
            if(name == g_toggle_settings[i].name)
            {
               ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
               ToggleSettingState(g_toggle_settings[i].var_id);
               UpdateSettingsPanel();   // buttons-only refresh — never touches edit boxes
               ChartRedraw();
               return;
            }
         }
      }

      if(sparam == "SET_BTN_AccountType")
      {
         ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
         CycleAccountTypeSetting();
         UpdateSettingsPanel();
         CreateTransparentPanel();
         ChartRedraw();
         return;
      }

      if(sparam == "SET_BTN_Scale")
      {
         ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
         Runtime_UseAutoScaling = !Runtime_UseAutoScaling;
         if(Runtime_UseAutoScaling)
         {
            int dpi = TerminalInfoInteger(TERMINAL_SCREEN_DPI);
            Runtime_GuiScale = (dpi > 0) ? dpi / 96.0 : 1.0;
         }
         ObjectsDeleteAll(0);
         CreateTransparentPanel();
         UpdateMonitorGUI();
         if(SettingsPanelExpanded) { SettingsPanelExpanded = false; ToggleSettingsPanel(); }
         ChartRedraw();
         return;
      }
   }

   // Edit box end-edit handlers
   if(id == CHARTEVENT_OBJECT_ENDEDIT)
   {
      // Settings panel fields (v15.0 architecture)
      if(StringFind(sparam, "SET_EDIT_") == 0)
      {
         string name = StringSubstr(sparam, 9);
         for(int i = 0; i < ArraySize(g_input_settings); i++)
         {
            if(name == g_input_settings[i].name)
            {
               string value_str = ObjectGetString(0, sparam, OBJPROP_TEXT);
               // SetInputVarFromString handles validation + per-field side effects
               // (RecalculateLimits/Buffers, DailyGainTarget sync, etc.)
               SetInputVarFromString(g_input_settings[i].var_id, value_str);
               UpdateSettingsPanel();  // refresh display with validated values
               break;
            }
         }
         g_active_edit_object = "";
         return;
      }

      // GUI input fields
      if(sparam == "GUI_EDIT_SL")
      {
         int val = (int)StringToInteger(ObjectGetString(0, sparam, OBJPROP_TEXT));
         if(val >= 0) Runtime_SL_Pips = val;
         g_active_edit_object = "";
         ChartRedraw();
      }
      if(sparam == "GUI_EDIT_TP")
      {
         int val = (int)StringToInteger(ObjectGetString(0, sparam, OBJPROP_TEXT));
         if(val >= 0) Runtime_TP_Pips = val;
         g_active_edit_object = "";
         ChartRedraw();
      }
      if(sparam == "GUI_EDIT_Size")
      {
         double val = StringToDouble(ObjectGetString(0, sparam, OBJPROP_TEXT));
         if(val > 0) Runtime_FixedLotSize = val;
         g_active_edit_object = "";
         ChartRedraw();
      }
      if(sparam == "GUI_EDIT_Price")
      {
         double val = StringToDouble(ObjectGetString(0, sparam, OBJPROP_TEXT));
         if(val > 0) Runtime_PendingPrice = val;
         g_active_edit_object = "";
         ChartRedraw();
      }
      // Safety net: clear flag for any other edit field not handled above
      if(g_active_edit_object == sparam)
         g_active_edit_object = "";
   }  // end CHARTEVENT_OBJECT_ENDEDIT
}  // end OnChartEvent

//+------------------------------------------------------------------+
//| TOGGLE (fixes button not de-activating)                          |
//+------------------------------------------------------------------+
void ToggleSettingsPanel()
{
   SettingsPanelExpanded = !SettingsPanelExpanded;

   if(SettingsPanelExpanded)
   {
      CreateSettingsPanelObjects();
      ObjectSetString(0,  "BTN_Settings", OBJPROP_TEXT,    "CLOSE");
      ObjectSetInteger(0, "BTN_Settings", OBJPROP_BGCOLOR, clrDarkRed);
   }
   else
   {
      // Commit any active Settings edit before closing the panel.
      if(StringFind(g_active_edit_object, "SET_EDIT_") == 0 && ObjectFind(0, g_active_edit_object) >= 0)
      {
         string active_value = ObjectGetString(0, g_active_edit_object, OBJPROP_TEXT);
         for(int i = 0; i < ArraySize(g_input_settings); i++)
         {
            if(("SET_EDIT_" + g_input_settings[i].name) == g_active_edit_object)
            {
               SetInputVarFromString(g_input_settings[i].var_id, active_value);
               break;
            }
         }
      }
      // --- IMPORTANT: Clear active edit object when closing the panel ---
      g_active_edit_object = ""; 
      DeleteSettingsPanelObjects();
      ObjectSetString(0,  "BTN_Settings", OBJPROP_TEXT,    "SET");
      ObjectSetInteger(0, "BTN_Settings", OBJPROP_BGCOLOR, clrGray);
      CreateTransparentPanel(); // v15.2 Fix C: always rebuild metrics on panel close
   }
   ChartRedraw();
}
//+------------------------------------------------------------------+
//| UPDATE (called every tick + after edit)                          |
//+------------------------------------------------------------------+
void UpdateSettingsPanel()
{
   if(!SettingsPanelExpanded) return;

   // v15.2 Fix E: Update button states ONLY.
   // Edit boxes are intentionally excluded here.
   //
   // The bug: the previous data-driven loop deleted+recreated every SET_EDIT_*
   // box on each call (via the g_active_edit_object guard path), resetting
   // unsaved typed values to the stale runtime value.
   //
   // With this buttons-only implementation, edit boxes are written ONCE when the
   // panel opens (CreateSettingsPanelObjects), then kept alive until the user
   // explicitly commits a value (CHARTEVENT_OBJECT_ENDEDIT) or closes the panel
   // (SaveSettingsFromPanel reads them all).  No live tick re-writes, no race.

   for(int i = 0; i < ArraySize(g_toggle_settings); i++)
   {
      string btn_name = "BTN_" + g_toggle_settings[i].name;
      if(ObjectFind(0, btn_name) >= 0)
      {
         bool is_on = GetToggleState(g_toggle_settings[i].var_id);
         ObjectSetString (0, btn_name, OBJPROP_TEXT,   is_on ? "ON" : "OFF");
         ObjectSetInteger(0, btn_name, OBJPROP_BGCOLOR, is_on ? clrGreen : clrMaroon);
         ObjectSetInteger(0, btn_name, OBJPROP_STATE,   false);
      }
   }

   if(ObjectFind(0, "SET_BTN_AccountType") >= 0)
   {
      ObjectSetString (0, "SET_BTN_AccountType", OBJPROP_TEXT, GetAccountTypeDisplayText());
      ObjectSetInteger(0, "SET_BTN_AccountType", OBJPROP_BGCOLOR, clrDarkSlateBlue);
      ObjectSetInteger(0, "SET_BTN_AccountType", OBJPROP_STATE, false);
   }

   ChartRedraw();
}

//+------------------------------------------------------------------+
//| Add Settings Toggle (Helper Function)                            |
//+------------------------------------------------------------------+
void AddSettingsToggle(string key, string label_text, bool is_on, string group, int x, int &y, int label_w, int row_h)
{
   string lbl = "SET_LBL_" + key;
   ObjectDelete(0, lbl);
   ObjectCreate(0, lbl, OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, lbl, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, lbl, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, lbl, OBJPROP_YDISTANCE, y + Scaled(5));
   ObjectSetInteger(0, lbl, OBJPROP_COLOR, clrWhite);
   ObjectSetInteger(0, lbl, OBJPROP_FONTSIZE, ScaledFont());
   ObjectSetString(0, lbl, OBJPROP_TEXT, label_text);
   ObjectSetInteger(0, lbl, OBJPROP_ZORDER, 1005);

   string btn = "BTN_" + key;
   ObjectDelete(0, btn);
   ObjectCreate(0, btn, OBJ_BUTTON, 0, 0, 0);
   ObjectSetInteger(0, btn, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, btn, OBJPROP_XDISTANCE, x + label_w);
   ObjectSetInteger(0, btn, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, btn, OBJPROP_XSIZE, Scaled(60));
   ObjectSetInteger(0, btn, OBJPROP_YSIZE, Scaled(26));
   ObjectSetInteger(0, btn, OBJPROP_FONTSIZE, ScaledFont());
   ObjectSetString(0, btn, OBJPROP_TEXT, is_on ? "ON" : "OFF");
   ObjectSetInteger(0, btn, OBJPROP_BGCOLOR, is_on ? clrGreen : clrMaroon);
   ObjectSetInteger(0, btn, OBJPROP_COLOR, clrWhite);
   ObjectSetInteger(0, btn, OBJPROP_ZORDER, 1005);
   y += row_h;
}

//+------------------------------------------------------------------+
//| Add Settings Row (Helper Function)                               |
//+------------------------------------------------------------------+
void AddSettingsRow(string key, string label_text, string value,
                    int x, int &y, int label_w, int edit_w, int row_h)
{
   // v15.2 robustness: revert to the original working CreateField-style OBJ_EDIT setup.
   string lbl = "SET_LBL_" + key;
   ObjectDelete(0, lbl);
   ObjectCreate(0, lbl, OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, lbl, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, lbl, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, lbl, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, lbl, OBJPROP_COLOR, clrWhite);
   ObjectSetInteger(0, lbl, OBJPROP_FONTSIZE, ScaledFont());
   ObjectSetString(0, lbl, OBJPROP_TEXT, label_text);
   ObjectSetInteger(0, lbl, OBJPROP_ZORDER, 1005);

   string edt = "SET_EDIT_" + key;
   ObjectDelete(0, edt);
   ObjectCreate(0, edt, OBJ_EDIT, 0, 0, 0);
   ObjectSetInteger(0, edt, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, edt, OBJPROP_XDISTANCE, x + label_w);
   ObjectSetInteger(0, edt, OBJPROP_YDISTANCE, y - Scaled(2));
   ObjectSetInteger(0, edt, OBJPROP_XSIZE, edit_w);
   ObjectSetInteger(0, edt, OBJPROP_YSIZE, Scaled(24));
   ObjectSetInteger(0, edt, OBJPROP_FONTSIZE, ScaledFont());
   ObjectSetInteger(0, edt, OBJPROP_COLOR, clrWhite);
   ObjectSetInteger(0, edt, OBJPROP_BGCOLOR, C'15,35,70');
   ObjectSetString(0, edt, OBJPROP_TEXT, value);
   ObjectSetInteger(0, edt, OBJPROP_ZORDER, 1005);

   y += row_h;
}

//+------------------------------------------------------------------+
//| Get Filling Mode                                                 |
//+------------------------------------------------------------------+
int GetFillingMode(string sym, bool is_pending)
{
   if(ManualFillingMode == FILLING_FOK) return (int)ORDER_FILLING_FOK;
   if(ManualFillingMode == FILLING_IOC) return (int)ORDER_FILLING_IOC;
   if(ManualFillingMode == FILLING_RETURN) return (int)ORDER_FILLING_RETURN;

   if(is_pending) return (int)ORDER_FILLING_RETURN;

   int filling = (int)SymbolInfoInteger(sym, SYMBOL_FILLING_MODE);
   if((filling & (int)SYMBOL_FILLING_IOC) != 0) return (int)ORDER_FILLING_IOC;
   if((filling & (int)SYMBOL_FILLING_FOK) != 0) return (int)ORDER_FILLING_FOK;
   
   int exec = (int)SymbolInfoInteger(sym, SYMBOL_TRADE_EXEMODE);
   
   if(exec == (int)SYMBOL_TRADE_EXECUTION_MARKET || 
      exec == (int)SYMBOL_TRADE_EXECUTION_INSTANT || 
      exec == (int)SYMBOL_TRADE_EXECUTION_REQUEST)
   {
      return (int)ORDER_FILLING_IOC;
   }
   
   return (int)ORDER_FILLING_RETURN;
}

//+------------------------------------------------------------------+
//| Close Partial Position                                           |
//+------------------------------------------------------------------+
bool ClosePartialPosition(ulong ticket, double vol_to_close, string reason)
{
   if(!PositionSelectByTicket(ticket)) return false;

   MqlTradeRequest request;
   MqlTradeResult  result;
   ZeroMemory(request);
   ZeroMemory(result);

   string symbol  = PositionGetString(POSITION_SYMBOL);
   ENUM_POSITION_TYPE pos_type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);

   request.action       = TRADE_ACTION_DEAL;
   request.position     = ticket;
   request.symbol       = symbol;
   request.volume       = vol_to_close;
   ulong points_per_pip = (ulong) MathRound(pip_size / point_value);
   request.deviation    = MaxSlippagePips * points_per_pip;
   request.type         = (pos_type == POSITION_TYPE_BUY ? ORDER_TYPE_SELL : ORDER_TYPE_BUY);
   request.price        = (pos_type == POSITION_TYPE_BUY ? 
                          SymbolInfoDouble(symbol, SYMBOL_BID) : 
                          SymbolInfoDouble(symbol, SYMBOL_ASK));
   request.magic        = MagicNumber;
   request.comment      = reason;
   request.type_filling = (ENUM_ORDER_TYPE_FILLING)GetFillingMode(symbol, false);

   bool sent = OrderSend(request, result);
   if(!sent)
   {
      Print("Partial close attempt FAILED #", ticket, " err=", _LastError);
      return false;
   }
   else if(result.retcode == TRADE_RETCODE_DONE || result.retcode == TRADE_RETCODE_POSITION_CLOSED)
   {
      Print("Partial closed #", ticket, " vol=", DoubleToString(vol_to_close, 2), " - ", reason);
      return true;
   }
   else
   {
      Print("Partial close attempt retcode FAILED #", ticket,
            " retcode=", result.retcode, " comment='", result.comment, "'");
      return false;
   }
}

//+------------------------------------------------------------------+
//| Process Fixed Stops                                              |
//+------------------------------------------------------------------+
void ProcessFixedStops(int idx, double pip_distance)
{
   ulong ticket = monitored_positions[idx].ticket;

   if(monitored_positions[idx].sl_pips > 0 && pip_distance <= -monitored_positions[idx].sl_pips)
   {
      Print("Fixed SL triggered #", ticket);
      ClosePositionAtMarket(ticket, "Fixed SL");
      return;
   }

   if(pip_distance >= monitored_positions[idx].tp_pips && monitored_positions[idx].tp_pips > 0)
   {
      if(UseMultiPartialTP && PartialLevelCount > 0)
      {
         struct PartialLevel
         {
            double pct;
            double threshold_pips;
         };
         PartialLevel levels[3];
         int num_levels = MathMin(PartialLevelCount, 3);

         levels[0].pct = PartialPct1;
         levels[0].threshold_pips = UseATRForPartialLevels ? (current_atr * PartialATRMulti1 / pip_size) : PartialPips1;

         if(num_levels >= 2)
         {
            levels[1].pct = PartialPct2;
            levels[1].threshold_pips = UseATRForPartialLevels ? (current_atr * PartialATRMulti2 / pip_size) : PartialPips2;
         }
         if(num_levels >= 3)
         {
            levels[2].pct = PartialPct3;
            levels[2].threshold_pips = UseATRForPartialLevels ? (current_atr * PartialATRMulti3 / pip_size) : PartialPips3;
         }

         bool any_partial = false;
         for(int lv = 0; lv < num_levels; lv++)
         {
            int bit = (1 << lv);
            if((monitored_positions[idx].partial_levels_hit & bit) == 0 && pip_distance >= levels[lv].threshold_pips)
            {
               double vol = monitored_positions[idx].volume;
               double close_vol = NormalizeDouble(vol * levels[lv].pct / 100.0, 2);

               if(close_vol >= SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN))
               {
                  if(ClosePartialPosition(ticket, close_vol, "Multi Partial TP Level " + IntegerToString(lv+1)))
                  {
                     monitored_positions[idx].volume -= close_vol;
                     monitored_positions[idx].partial_levels_hit |= bit;
                     any_partial = true;
                  }
               }
            }
         }

         if(any_partial && ShowChartLines)
            DrawOrUpdateSLTPLines(idx);
      }
      else
      {
         Print("Fixed TP #", ticket);
         ClosePositionAtMarket(ticket, "Fixed TP");
      }
      return;
   }
}

//+------------------------------------------------------------------+
//| Get Current ATR Value                                            |
//+------------------------------------------------------------------+
double GetCurrentATR()
{
   if(atr_handle == INVALID_HANDLE) return 0.0;

   double atr_buffer[1];
   if(CopyBuffer(atr_handle, 0, 1, 1, atr_buffer) != 1)
   {
      return 0.0;
   }

   return atr_buffer[0];
}

//+------------------------------------------------------------------+
//| Save High Water Mark                                             |
//+------------------------------------------------------------------+
void SaveHighWaterMark()
{
   int fh = FileOpen(PeakFileName, FILE_WRITE|FILE_BIN|FILE_COMMON);
   if(fh != INVALID_HANDLE)
   {
      FileWriteDouble(fh, HighWaterMark);
      FileClose(fh);
   }
}
//+------------------------------------------------------------------+
//| v14.28: SaveDailyState — persist PDC, HWM, WorkingAccountSize    |
//|  File: TF_State_{login}.dat  (FILE_COMMON so it survives EA      |
//|  restarts and MetaTrader restarts on the same machine)            |
//+------------------------------------------------------------------+
void SaveDailyState()
{
   int fh = FileOpen(StateFileName, FILE_WRITE|FILE_BIN|FILE_COMMON);
   if(fh != INVALID_HANDLE)
   {
      FileWriteDouble(fh, PriorDayClose);
      FileWriteDouble(fh, HighWaterMark);
      FileWriteDouble(fh, WorkingAccountSize);
      FileWriteInteger(fh, (int)TimeCurrent());   // save timestamp for staleness check
      FileClose(fh);
   }
}

//+------------------------------------------------------------------+
//| v14.28: LoadDailyState — restore PDC, HWM, WorkingAccountSize    |
//|  Returns true only if the saved values pass a sanity check:       |
//|   • All values within 10% – 500% of AccountSize input            |
//|   • Timestamp is within 72 hours (handles weekends)              |
//+------------------------------------------------------------------+
bool LoadDailyState(double &out_pdc, double &out_hwm, double &out_bal)
{
   int fh = FileOpen(StateFileName, FILE_READ|FILE_BIN|FILE_COMMON);
   if(fh == INVALID_HANDLE) return false;
   out_pdc = FileReadDouble(fh);
   out_hwm = FileReadDouble(fh);
   out_bal = FileReadDouble(fh);
   int   ts  = FileReadInteger(fh);
   FileClose(fh);
   double ref = (AccountSize > 0) ? AccountSize : 10000.0;
   if(out_pdc < ref*0.10 || out_pdc > ref*5.0) return false;
   if(out_hwm < ref*0.10 || out_hwm > ref*5.0) return false;
   if(out_bal < ref*0.10 || out_bal > ref*5.0) return false;
   if((int)TimeCurrent() - ts > 72*3600)        return false;   // too stale
   return true;
}


//+------------------------------------------------------------------+
//| Save Daily Snapshot                                              |
//+------------------------------------------------------------------+
void SaveDailySnapshot(double balance)
{
   Print("Daily snapshot: $", DoubleToString(balance, 2));
}

//+------------------------------------------------------------------+
//| Get Retcode Description                                          |
//+------------------------------------------------------------------+
string GetRetcodeDescription(int retcode)
{
   switch(retcode)
   {
       case 10008: return "TRADE_RETCODE_REJECT";
       case 10010: return "TRADE_RETCODE_REJECT_CANCEL";
       case 10013: return "TRADE_RETCODE_ERROR";
       default: return "Unknown error: " + IntegerToString(retcode);
   }
}

//+------------------------------------------------------------------+
//| Cancel All Pending Orders                                        |
//+------------------------------------------------------------------+
void CancelAllPendingOrders(string reason = "Manual Cancel")
{
   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      ulong ticket = OrderGetTicket(i);
      if(ticket > 0)
      {
         MqlTradeRequest request;
         MqlTradeResult  result;
         ZeroMemory(request);
         ZeroMemory(result);
         
         request.action = TRADE_ACTION_REMOVE;
         request.order = ticket;
         
         bool success = OrderSend(request, result);
         
         if(!success)
         {
            Print("Failed to cancel order #", ticket, 
                  ". Error: ", result.retcode, 
                  " (", GetRetcodeDescription(result.retcode), ")",
                  ", Reason: ", reason);
         }
         else
         {
            Print("Successfully cancelled order #", ticket,
                  ". Reason: ", reason);
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Draw News Lines                                                  |
//+------------------------------------------------------------------+
void DrawNewsLines()
{
   if(!Runtime_UseNewsFilter) return;
   
   MqlCalendarValue values[];
   datetime now = TimeCurrent();
   datetime from = now;
   datetime to   = now + 86400;
   
   if(CalendarValueHistory(values, from, to))
   {
      for(int i = 0; i < ArraySize(values); i++)
      {
         MqlCalendarEvent event;
         if(!CalendarEventById(values[i].event_id, event)) continue;
         
         if(StringLen(Runtime_NewsCurrencyFilter) > 0)
         {
            string event_currency = "";
            MqlCalendarCountry country;
            if(CalendarCountryById(event.country_id, country))
               event_currency = country.currency;
            
            if(StringFind(Runtime_NewsCurrencyFilter, event_currency) < 0) continue;
         }

         bool is_high = (event.importance == CALENDAR_IMPORTANCE_HIGH);
         bool is_med  = (event.importance == CALENDAR_IMPORTANCE_MODERATE);
         bool is_low  = (event.importance == CALENDAR_IMPORTANCE_LOW);

         if(!is_high && !(Runtime_IncludeMediumImpact && is_med) && !(Runtime_IncludeLowImpact && is_low)) continue;
         
         string name = "NewsLine_" + IntegerToString(values[i].time);
         if(ObjectFind(0, name) < 0)
         {
            ObjectCreate(0, name, OBJ_VLINE, 0, values[i].time, 0);
            
            color line_color = is_high ? Runtime_NewsColorHigh : (is_med ? Runtime_NewsColorMedium : Runtime_NewsColorLow);
            string line_text = is_high ? "NEWS (High)" : (is_med ? "NEWS (Med)" : "NEWS (Low)");
            
            ObjectSetInteger(0, name, OBJPROP_COLOR, line_color);
            ObjectSetInteger(0, name, OBJPROP_STYLE, STYLE_DOT);
            ObjectSetString(0, name, OBJPROP_TEXT, line_text);
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Draw Time Filter Lines                                           |
//+------------------------------------------------------------------+
void DrawTimeFilterLines()
{
   if(!Runtime_UseTimeFilter) return;

   datetime now = TimeCurrent();
   MqlDateTime dt;
   TimeToStruct(now, dt);

   string start_parts[];
   string end_parts[];
   StringSplit(AllowedStartTime, ':', start_parts);
   StringSplit(AllowedEndTime, ':', end_parts);

   if(ArraySize(start_parts) < 2 || ArraySize(end_parts) < 2) return;

   dt.hour = (int)StringToInteger(start_parts[0]);
   dt.min  = (int)StringToInteger(start_parts[1]);
   dt.sec  = 0;
   datetime start_time = StructToTime(dt);

   dt.hour = (int)StringToInteger(end_parts[0]);
   dt.min  = (int)StringToInteger(end_parts[1]);
   datetime end_time = StructToTime(dt);

   string start_name = "TimeStart_" + IntegerToString(start_time);
   if(ObjectFind(0, start_name) < 0)
   {
      ObjectCreate(0, start_name, OBJ_VLINE, 0, start_time, 0);
      ObjectSetInteger(0, start_name, OBJPROP_COLOR, clrGreen);
      ObjectSetInteger(0, start_name, OBJPROP_STYLE, STYLE_DOT);
      ObjectSetString(0, start_name, OBJPROP_TEXT, "START");
   }

   string end_name = "TimeEnd_" + IntegerToString(end_time);
   if(ObjectFind(0, end_name) < 0)
   {
      ObjectCreate(0, end_name, OBJ_VLINE, 0, end_time, 0);
      ObjectSetInteger(0, end_name, OBJPROP_COLOR, clrRed);
      ObjectSetInteger(0, end_name, OBJPROP_STYLE, STYLE_DOT);
      ObjectSetString(0, end_name, OBJPROP_TEXT, "END");
   }
}

//+------------------------------------------------------------------+
//| Log Trade Event to CSV                                           |
//+------------------------------------------------------------------+
void LogTradeEvent(string type, ulong ticket, string symbol, double volume, double price, string reason)
{
   int file_handle = FileOpen(LogFileName, FILE_READ|FILE_WRITE|FILE_CSV|FILE_ANSI|FILE_COMMON, ',');
   if(file_handle != INVALID_HANDLE)
   {
      FileSeek(file_handle, 0, SEEK_END);
      if(FileSize(file_handle) == 0)
      {
         FileWrite(file_handle, "Time", "Type", "Ticket", "Symbol", "Volume", "Price", "Reason");
      }
      FileWrite(file_handle, TimeToString(TimeCurrent(), TIME_DATE|TIME_SECONDS), type, IntegerToString(ticket), symbol, DoubleToString(volume, 2), DoubleToString(price, _Digits), reason);
      FileClose(file_handle);
   }
}

//+------------------------------------------------------------------+
//| Update Price Display                                             |
//+------------------------------------------------------------------+
void UpdatePriceDisplay()
{
   // v15.2 RETIRED: LBL_MarketBid/Ask replaced by LBL_BIDVAL/ASKVAL in v15.0.
   // Market data refresh handled entirely by UpdateRiskPanel().
}

//+------------------------------------------------------------------+
//| Is New Bar                                                       |
//+------------------------------------------------------------------+
bool IsNewBar()
{
   static datetime last_bar_time = 0;
   datetime current_bar_time = iTime(_Symbol, _Period, 0);
   
   if(last_bar_time != current_bar_time)
   {
      last_bar_time = current_bar_time;
      return true;
   }
   return false;
}

//+------------------------------------------------------------------+
//| Remove SL/TP Lines                                               |
//+------------------------------------------------------------------+
void RemoveSLTPLines(ulong ticket)
{
   if(!ShowChartLines) return;
   ObjectDelete(0, SL_LinePrefix + IntegerToString(ticket));
   ObjectDelete(0, TP_LinePrefix + IntegerToString(ticket));
   ChartRedraw();
}

//+------------------------------------------------------------------+
//| Is Position Monitored                                            |
//+------------------------------------------------------------------+
bool IsPositionMonitored(ulong ticket)
{
   for(int i = 0; i < monitor_count; i++)
      if(monitored_positions[i].ticket == ticket)
         return true;
   return false;
}

//+------------------------------------------------------------------+
//| Get Monitor Index By Ticket                                      |
//+------------------------------------------------------------------+
int GetMonitorIndexByTicket(ulong ticket)
{
   for(int i = 0; i < monitor_count; i++)
      if(monitored_positions[i].ticket == ticket)
         return i;
   return -1;
}

//+------------------------------------------------------------------+
//| Remove From Monitor                                              |
//+------------------------------------------------------------------+
void RemoveFromMonitor(int index)
{
   if(index < 0 || index >= monitor_count) return;

   RemoveSLTPLines(monitored_positions[index].ticket);

   for(int i = index; i < monitor_count - 1; i++)
      monitored_positions[i] = monitored_positions[i + 1];

   monitor_count--;
   ArrayResize(monitored_positions, monitor_count);
}

//+------------------------------------------------------------------+
//| Save Monitoring State                                            |
//+------------------------------------------------------------------+
void SaveMonitoringState()
{
   int file_handle = FileOpen(StateFileName, FILE_WRITE|FILE_BIN|FILE_COMMON);
   if(file_handle != INVALID_HANDLE)
   {
      FileWriteInteger(file_handle, monitor_count);
      for(int i = 0; i < monitor_count; i++)
      {
         FileWriteStruct(file_handle, monitored_positions[i]);
      }
      FileClose(file_handle);
   }
}

//+------------------------------------------------------------------+
//| Recover Monitored Positions                                      |
//+------------------------------------------------------------------+
int RecoverMonitoredPositions()
{
   int recovered = 0;
   
   int file_handle = FileOpen(StateFileName, FILE_READ|FILE_BIN|FILE_COMMON);
   if(file_handle != INVALID_HANDLE)
   {
      int count = FileReadInteger(file_handle);
      for(int i = 0; i < count; i++)
      {
         PositionMonitor pos;
         FileReadStruct(file_handle, pos);
         
         if(PositionSelectByTicket(pos.ticket))
         {
            if(monitor_count < MAX_POSITIONS && !IsPositionMonitored(pos.ticket))
            {
               ArrayResize(monitored_positions, monitor_count + 1);
               monitored_positions[monitor_count++] = pos;
               recovered++;
            }
         }
      }
      FileClose(file_handle);
   }

   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket <= 0 || PositionGetString(POSITION_SYMBOL) != _Symbol) continue;
      if(IsPositionMonitored(ticket)) continue;

      if(PositionSelectByTicket(ticket))
      {
         int idx = monitor_count;
         ArrayResize(monitored_positions, idx + 1);
         monitor_count++;
         
         monitored_positions[idx].ticket = ticket;
         monitored_positions[idx].type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
         monitored_positions[idx].volume = PositionGetDouble(POSITION_VOLUME);
         monitored_positions[idx].entry_price = PositionGetDouble(POSITION_PRICE_OPEN);
         monitored_positions[idx].open_time = (datetime)PositionGetInteger(POSITION_TIME);
         monitored_positions[idx].monitoring_enabled = true;
         monitored_positions[idx].trailing_enabled = Runtime_TrailingEnabled;
         monitored_positions[idx].breakeven_locked = false;
         monitored_positions[idx].partial_levels_hit = 0;
         
         double pos_sl = PositionGetDouble(POSITION_SL);
         double pos_tp = PositionGetDouble(POSITION_TP);
         
         if (pos_sl > 0)
         {
            double sl_dist = MathAbs(pos_sl - monitored_positions[idx].entry_price);
            monitored_positions[idx].sl_pips = (int)MathRound(sl_dist / pip_size);
            Print("Scan: Added #", ticket, " with existing Server SL. Pips=", monitored_positions[idx].sl_pips);
         }
         else
         {
             if(Runtime_SL_Pips == 0)
             {
                 monitored_positions[idx].sl_pips = 0;
                 Print("Scan: Added #", ticket, " SL Box Empty (0). Forced SL=0.");
             }
             else if(Runtime_UseATR && current_atr > 0)
             {
                monitored_positions[idx].sl_pips = (int)MathRound(current_atr * ATR_Multi_SL / pip_size);
                Print("Scan: Added #", ticket, " Used ATR for SL. Pips=", monitored_positions[idx].sl_pips);
             }
             else
             {
                monitored_positions[idx].sl_pips = Runtime_SL_Pips;
                Print("Scan: Added #", ticket, " Used Fixed SL. Pips=", monitored_positions[idx].sl_pips);
             }
         }

         if (pos_tp > 0)
         {
            double tp_dist = MathAbs(pos_tp - monitored_positions[idx].entry_price);
            monitored_positions[idx].tp_pips = (int)MathRound(tp_dist / pip_size);
            Print("Scan: Used existing Server TP. Pips=", monitored_positions[idx].tp_pips);
         }
         else
         {
             if(Runtime_TP_Pips == 0)
             {
                 monitored_positions[idx].tp_pips = 0;
                 Print("Scan: TP Box Empty (0). Forced TP=0.");
             }
             else if(Runtime_UseATR && current_atr > 0)
             {
                monitored_positions[idx].tp_pips = (int)MathRound(current_atr * ATR_Multi_TP / pip_size);
                Print("Scan: Used ATR for TP. Pips=", monitored_positions[idx].tp_pips);
             }
             else
             {
                monitored_positions[idx].tp_pips = Runtime_TP_Pips;
                Print("Scan: Used Fixed TP. Pips=", monitored_positions[idx].tp_pips);
             }
         }
         
         monitored_positions[idx].highest_price = monitored_positions[idx].entry_price;
         monitored_positions[idx].lowest_price = monitored_positions[idx].entry_price;
         
         recovered++;
      }
   }
   
   trade.SetExpertMagicNumber(MagicNumber);
   trade.SetMarginMode();
   trade.SetTypeFilling(ORDER_FILLING_IOC);
   trade.SetDeviationInPoints(MaxSlippagePips * (int)MathRound(pip_size / point_value));

   if(recovered > 0) SaveMonitoringState();
   
   if(!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED))
      Print("WARNING: Algo Trading is disabled in the terminal toolbar.");
   
   if(!MQLInfoInteger(MQL_TRADE_ALLOWED))
      Print("WARNING: Algo Trading is disabled in the EA properties (Common tab).");

   if(!AccountInfoInteger(ACCOUNT_TRADE_ALLOWED))
      Print("WARNING: Trading is disabled for this account.");

   return recovered;
}

//+------------------------------------------------------------------+
//| Timer event                                                      |
//+------------------------------------------------------------------+
void OnTimer()
{
   if(Runtime_EnableEmergencyStop && Runtime_LockReleaseEndTime > 0 && GetLockClock() >= Runtime_LockReleaseEndTime)
   {
      Runtime_EnableEmergencyStop = false;
      Runtime_LockReleaseEndTime = 0;
      if(LogToTerminal)
         Print("Trading lock auto-released");
      CreateTransparentPanel();
      ChartRedraw();
   }
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   EventKillTimer();
   DeleteSettingsPanelObjects();
   // v14.20 ZZ-10: ZigZag cleanup on EA removal
   if(ZZ_Enabled) DeleteZigZagObjects();

   ObjectsDeleteAll(0,"TF_");   ObjectsDeleteAll(0,"BTN_");  ObjectsDeleteAll(0,"LBL_");
   ObjectsDeleteAll(0,"GUI_");  ObjectsDeleteAll(0,"M_");    ObjectsDeleteAll(0,"SET_");
   ObjectsDeleteAll(0,"MON_");  ObjectsDeleteAll(0,"ACC_");  ObjectsDeleteAll(0,"LIM_");
   ObjectsDeleteAll(0,"RISK_"); ObjectsDeleteAll(0,SL_LinePrefix); ObjectsDeleteAll(0,TP_LinePrefix);
   ObjectsDeleteAll(0,"MON_Pos_");
   if(atr_handle!=INVALID_HANDLE){ IndicatorRelease(atr_handle); atr_handle=INVALID_HANDLE; }
   ChartRedraw();
   Print("TF Manager v15.2 Deinitialized. Reason=",reason);
}

//+------------------------------------------------------------------+
//| End of File                                                      |
//+------------------------------------------------------------------+
