






TF COMPLETE RISK MANAGER
User Guide â€” Version 15.5
Author: Andre Denis  |  March 2026

 
╔══════════════════════════════════════════════════════════════════════════════════╗
║        TF COMPLETE RISK MANAGER — USER GUIDE                                   ║
║        Version 15.5  |  Author: Andre Denis  |  March 2026                 ║
╚══════════════════════════════════════════════════════════════════════════════════╝
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
TABLE OF CONTENTS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
1.  Overview & Purpose
2.  Installation
3.  Input Parameters — Complete Reference
4.  GUI Panel — Controls & Metrics
5.  Risk Protection System
5.1  Daily Loss Limit (DLL)
5.2  Max Trailing Drawdown (TLL)
5.3  TF Shield
5.4  Daily Gain Target (DGT)
5.5  Profit Ratchet
5.6  Tilt Protection
6.  Alert System (v15.5)
6.1  Entry-Block Alerts — Individualised
6.2  Buffer Warning Alerts — Individualised
6.3  Full Alert Reference
7.  Smart Entry System
8.  Position Monitor & Auto-Close
9.  Trailing Stop & Breakeven
10.  Partial Take-Profit
11.  ATR Dynamic Distances
12.  News & Time Filters
13.  Settings Panel (Runtime Edits)
14.  Daily Reset Logic
15.  Symbol & Pip Size Detection
16.  Execution & Filling Modes
17.  Files Written to Disk
18.  Version Changelog (v14.6 → v15.5)

v15.0 - v15.5  (2026-03-16)
- Major UI overhaul: Added unified, compact Risk Panel with integrated order box.
- Fixed Size input box rejecting arbitrary inputs (now accepts typed input correctly).
- Limit Price text field integrated seamlessly and fixed to push values prior to BUY/SELL.
- Corrected real-time SL/TP risk dollar amount calculations to scale dynamically to lot size.
- Hardcoded TF Shield engine updated to mathematically replicate official TradingFunds definition 
  (Maximum Floating Loss tied specifically to exactly 2% of original account balance).
- Addressed memory-leak cleanup issues causing artifacts during EA removal.
- Removed deprecated POSITION_COMMISSION tags ensuring MT5 builds > 4100 compatibility.

19.  Recommended Default Settings
20.  Troubleshooting
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
1. OVERVIEW & PURPOSE

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
TF Complete Risk Manager is a MetaTrader 5 Expert Advisor designed for proprietary
trading firm (prop firm) accounts. It does NOT generate trade signals. Its sole
purpose is to:
• Enforce account-level risk limits (DLL, TLL, TF Shield)
• Manage position-level risk (SL, TP, trailing, breakeven, partial TP)
• Provide a clean GUI for manual smart entry and live metrics
• Alert the trader with precise, individual, actionable popup messages
• Protect the account from tilt, overtrading, and limit violations
Designed for: Funded accounts (FTMO, MyForexFunds, TopStep-style rules)
Instruments:  Forex pairs, CFD indices (US500/SPX, US30, NAS100, GER40)
Platform:     MetaTrader 5 only
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
2. INSTALLATION

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
1.  Copy TF_RiskManager_v15.5.mq5 to: MT5_Data_Folder/MQL5/Experts/
2.  In MetaEditor: Open → Compile (F7). Verify 0 errors.
3.  In MT5 chart: Drag EA from Navigator onto desired symbol chart.
4.  Enable "Allow Algo Trading" in EA Properties > Common tab.
5.  Ensure the MT5 toolbar "Algo Trading" button is active (green).
6.  Configure inputs (see Section 3) and click OK.
IMPORTANT: Attach one instance per symbol. Do not attach multiple instances
of the EA to the same symbol simultaneously.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
3.  INPUT PARAMETERS — COMPLETE REFERENCE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
┌─ RISK MANAGER ──────────────────────────────────────────────────────────────┐
│ AccountSize             $25,000   Original funded account size               │
│ UseAutoDetection        false     If true, reads live equity on init         │
│ DailyLossLimitPct       5.0       Max daily loss as % of prior day close     │
│ TFShieldPercentage      2.0       Max intraday floating loss % of balance    │
│ MaxTrailingDrawdownPct  6.0       Max drawdown from account peak (TLL)       │
│ WarningThreshold        80.0      Alert when any buffer is X% consumed       │
│ DailyGainTargetPct      1.0       Daily profit target (auto-stop if hit)     │
│ TotalTargetGainPct      4.0       Overall account profit target (display)    │
│ EnableTFShield          true      Activates TF Shield protection             │
│ EnableDailyTargetAutoClose true   Stops trading when DGT is reached         │
│ ShowRiskPanel           true      Renders the GUI overlay                   │
│ PanelOffsetX/Y          10/70     Panel position on chart                   │
│ RiskPerTradePct         1.0       Risk % per trade (0 = use fixed lot)      │
│ FixedLotSize            0.01      Lot size when RiskPerTradePct = 0         │
│ UnblockCountdownMinutes 60        Minutes before auto-unblock after breach  │
└─────────────────────────────────────────────────────────────────────────────┘
┌─ PROFIT RATCHET ────────────────────────────────────────────────────────────┐
│ EnableProfitRatchet     true      Activates trailing profit floor           │
│ RatchetActivationPct    1.0       Daily gain % to activate ratchet          │
│ RatchetLockPct          0.5       Minimum daily gain % locked after ratchet │
└─────────────────────────────────────────────────────────────────────────────┘
┌─ TILT PROTECTION ───────────────────────────────────────────────────────────┐
│ EnableTiltProtection    true      Activates anti-revenge trading logic      │
│ MaxConsecutiveLosses    3         Loss streak count before trading pauses   │
│ TiltPauseMinutes        15        Minutes trading is blocked after tilt     │
└─────────────────────────────────────────────────────────────────────────────┘
┌─ EXPOSURE LIMITS ───────────────────────────────────────────────────────────┐
│ MaxTotalLots            10.0      Max total open volume (0 = unlimited)     │
│ MaxOpenPositions        5         Max simultaneous open trades (0 = unlim.) │
└─────────────────────────────────────────────────────────────────────────────┘
┌─ MARKET MONITOR ────────────────────────────────────────────────────────────┐
│ EnableAutoClose         true      EA monitors & closes SL/TP/trailing       │
│ DefaultSLPips           50        Default stop loss in pips                 │
│ DefaultTPPips           150       Default take profit in pips               │
│ DefaultTrailingEnabled  false     Enable trailing stop by default           │
│ TrailingDistancePips    50        Trailing distance in pips                 │
│ TrailingActivationPips  75        Activate trailing after this many pips    │
│ ShowMonitorGUI          true      Show live position list on chart          │
└─────────────────────────────────────────────────────────────────────────────┘
┌─ GENERAL ───────────────────────────────────────────────────────────────────┐
│ ShowAlert               true      Enables MT5 popup alert windows           │
│ LogToTerminal           true      Logs events to Experts/Journal tab        │
│ MagicNumber             99999     EA identifier (must be unique per symbol) │
│ MaxSlippagePips         5         Max slippage on market orders             │
│ MaxSpreadPips           100       Max spread to allow entry (US500: ~2 pip) │
│ EnableEmergencyStop     false     Manual kill switch (closes all positions) │
│ GuiScale                1.3       GUI size multiplier (1.0=normal)          │
│ DailyResetHour          0         Hour for daily metric reset (0=midnight)  │
│ ManualFillingMode       AUTO      Order filling: AUTO/FOK/IOC/RETURN        │
└─────────────────────────────────────────────────────────────────────────────┘
┌─ TRAILING EXECUTION RELIABILITY ───────────────────────────────────────────┐
│ UseRealTrailing         false     Server-side trailing (recommended off)    │
│ MaxCloseRetries         3         Retry attempts on failed close/modify     │
│ RetryDelayMs            300       Delay between retries in milliseconds     │
└─────────────────────────────────────────────────────────────────────────────┘
┌─ ATR DYNAMIC DISTANCES ─────────────────────────────────────────────────────┐
│ InputUseATR             false     Use ATR-based SL/TP/trailing distances    │
│ ATRPeriod               14        ATR calculation period (bars)             │
│ ATRMultiSL              2.0       SL = ATR × this multiplier                │
│ ATRMultiTP              3.0       TP = ATR × this multiplier                │
│ ATRMultiActivation      2.0       Trailing activation = ATR × this          │
│ ATRMultiTrailingDist    2.5       Trailing distance = ATR × this            │
└─────────────────────────────────────────────────────────────────────────────┘
┌─ BREAKEVEN BUFFER ──────────────────────────────────────────────────────────┐
│ UseBreakevenBuffer      true      Moves SL to entry + buffer when in profit │
│ BreakevenType           FIXED     FIXED (pips) or ATR-based                 │
│ BreakevenFixedPips      5         Fixed breakeven buffer in pips            │
│ BreakevenATRMulti       0.3       ATR multiplier for breakeven buffer       │
└─────────────────────────────────────────────────────────────────────────────┘
┌─ MULTI-PARTIAL TP ──────────────────────────────────────────────────────────┐
│ UseMultiPartialTP       false     Enable multi-level partial take profits   │
│ PartialLevelCount       2         Number of partial TP levels (1–3)        │
│ PartialPct1/2/3         50/30/20  % of position to close at each level     │
│ PartialPips1/2/3        75/150/250 Pip targets for each level              │
│ UseATRForPartialLevels  false     Use ATR multiples instead of fixed pips  │
│ PartialATRMulti1/2/3   1.5/3.0/5.0 ATR multiples for each partial level   │
└─────────────────────────────────────────────────────────────────────────────┘
┌─ CHART LINES ───────────────────────────────────────────────────────────────┐
│ ShowChartLines          true      Show draggable SL/TP lines on chart       │
│ SLLineColor             Red       SL horizontal line color                 │
│ TPLineColor             Lime      TP horizontal line color                 │
└─────────────────────────────────────────────────────────────────────────────┘
┌─ NEWS / TIME FILTER ────────────────────────────────────────────────────────┐
│ UseNewsFilter           true      Block new entries near high-impact news   │
│ NewsPreMinutes          30        Minutes before event to block entries     │
│ NewsPostMinutes         30        Minutes after event to block entries      │
│ NewsCurrencyFilter      USD       Currencies to monitor (e.g. "USD,EUR")   │
│ IncludeMediumImpact     false     Also block medium-impact news             │
│ CloseOnHighNews         true      Auto-close open positions before news     │
│ UseTimeFilter           false     Block trading outside set hours           │
│ AllowedStartTime        0000      Trading start time (HHMM, server time)   │
│ AllowedEndTime          2359      Trading end time (HHMM, server time)     │
└─────────────────────────────────────────────────────────────────────────────┘
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
4.  GUI PANEL — CONTROLS & METRICS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
TOP ROW — CONTROLS
┌──────────────┬───────────┬────────────────────────────────────────────────┐
│ FLATTEN ALL  │ SETTINGS  │ Emergency stop icon (🔴/⬛)                    │
└──────────────┴───────────┴────────────────────────────────────────────────┘
• FLATTEN ALL  — Immediately closes all open positions for this EA/symbol
• SETTINGS     — Opens the runtime Settings Panel (see Section 13)
• Kill Switch  — Toggles emergency stop. RED = active (blocks all trading)
MARKET PRICE ROW
Bid:  XXXXX.XX    Ask:  XXXXX.XX
Sprd: X.X pips  [GREEN = within MaxSpreadPips | ORANGE = WIDE]
SMART ENTRY ROW
[  BUY  ]  [  SELL  ]  — Market or pending orders, using current SL/TP/size
ORDER MODE ROW
[MARKET / PENDING]  Limit: [price field — visible in pending mode only]
INPUTS ROW
Size: [lots]    SL: [pips]    TP: [pips]
RR: 1:X.X  — Live risk/reward ratio display
KILL SWITCH
[🔴] Emergency Stop — closes all positions, blocks all new entries
─────────────────────────────────────────────────────────────────────────────
METRICS PANEL  (below kill switch — layout v14.12+)
─────────────────────────────────────────────────────────────────────────────
ACCOUNT
Original Size    $XX,XXX.XX
Equity           $XX,XXX.XX
Daily Gain       $XXX.XX        [GREEN = profit | RED = loss]
DGT Target       $XXX.XX
Dist to DGT      $XXX.XX        [GREEN = profit cushion | RED = below target]
TTG Target       $X,XXX.XX
Dist to TTG      $X,XXX.XX      [GREEN = reached | RED = not yet]
LIMITATIONS
DLL Limit        $X,XXX.XX      Max daily loss dollar amount
TLL Limit        $X,XXX.XX      Max trailing drawdown dollar amount
TF Shield Limit  $X,XXX.XX      Max floating loss dollar amount
RISKS
DLL Buffer       $XXX.XX (XX.X%)  [RED if ≤20% | GREEN if >20%]
TLL Buffer       $XXX.XX (XX.X%)  [RED if ≤20% | GREEN if >20%]
TF Shield Buffer $XXX.XX (XX.X%)  [RED if ≤20% | GREEN if >20%]
Risk Exposure    $XXX.XX (XX.X% of TLL)
Risk Under/Over  $XXX.XX         [GREEN = under limit | RED = over]
Total Gain       $X,XXX.XX       [GREEN = profit | RED = loss]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
5. RISK PROTECTION SYSTEM

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
5.1 DAILY LOSS LIMIT (DLL)
Trigger:  Equity drops below  PriorDayClose − (AccountSize × DailyLossLimitPct%)
Effect:   All new entries blocked. Existing positions are NOT automatically closed
unless CloseOnDLL is also active.
Reset:    Automatically at DailyResetHour, or after UnblockCountdownMinutes.
Alert:    "DAILY LOSS LIMIT HIT! Trading stopped."  (individual popup)
Buffer:   Shown in RISKS panel as DLL Buffer ($remaining, %remaining)
WARNING alert fires when buffer ≤ 20% consumed threshold.
5.2 MAX TRAILING DRAWDOWN (TLL)
Trigger:  Equity drops below  HighWaterMark − (AccountSize × MaxTrailingDrawdownPct%)
Effect:   All new entries blocked immediately.
Reset:    Automatically at DailyResetHour, or after UnblockCountdownMinutes.
HighWaterMark updates in real time as equity grows.
Alert:    "MAX TRAILING DRAWDOWN HIT! Trading stopped."  (individual popup)
Buffer:   Shown in RISKS panel as TLL Buffer.
WARNING alert fires when buffer ≤ 20%.
5.3 TF SHIELD
Purpose:  Prevents catastrophic intraday floating loss (open positions going
deep into drawdown simultaneously).
Trigger:  Sum of all open position losses > AccountSize × TFShieldPercentage%
1st Breach: All positions closed immediately.
Alert: "⚠️ TF SHIELD 1ST VIOLATION: Closing Positions"
2nd Breach: (ManualTFSBreach = true) Escalated alert — account termination warning.
Alert: "🚨 TF SHIELD 2ND VIOLATION: IMMEDIATE ACCOUNT TERMINATION 🚨"
Enable:   Set EnableTFShield = true (disabled by default guard added v14.6 A4)
5.4 DAILY GAIN TARGET (DGT)
Trigger:  Equity ≥ PriorDayClose + RuntimeDailyGainTarget
Effect:   All new entries blocked (if EnableDailyTargetAutoClose = true)
Reset:    Automatically at DailyResetHour, or after UnblockCountdownMinutes.
Alert:    "🏆 DAILY GAIN TARGET HIT! Trading stopped."  (individual popup)
5.5 PROFIT RATCHET
Purpose:  Once the daily gain target is hit, automatically raises the DLL
floor to lock in a minimum profit, preventing a full reversal.
Activation: Daily gain ≥ AccountSize × RatchetActivationPct%
Lock Level: DLL floor raised to PriorDayClose + (AccountSize × RatchetLockPct%)
Rule:     Floor only moves UP, never DOWN.
Alert:    "🔒 PROFIT RATCHET ACTIVATED! Gains Locked."
5.6 TILT PROTECTION
Purpose:  Prevents revenge trading after a losing streak.
Trigger:  ConsecutiveLossCount ≥ MaxConsecutiveLosses
Effect:   All new entries blocked for TiltPauseMinutes.
Reset:    Automatic after pause expires. Counter resets on any winning trade.
Alert:    "Trading Paused due to Tilt Protection!"
Note:     Tilt logic is unchanged from v14.6 through v15.5 (frozen by design).
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
6.  ALERT SYSTEM (v15.5)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
DESIGN PRINCIPLE (introduced v15.5):
Every alert fires for ONE specific condition only. No alert message ever
combines two or more conditions into a single popup. This allows immediate,
unambiguous identification of which limit was breached without reading
compound sentences under time pressure.
6.1 ENTRY-BLOCK ALERTS — INDIVIDUALISED (v15.5 A1)
These fire when the BUY or SELL button is pressed and a limit blocks the order.
┌─────────────────────────────────────────────────────────────────────────────┐
│ Condition         │ Alert Message                                           │
├─────────────────────────────────────────────────────────────────────────────┤
│ DLL breached      │ ⛔ ENTRY BLOCKED: Daily Loss Limit (DLL) has been       │
│                   │    breached. No new trades today.                       │
├─────────────────────────────────────────────────────────────────────────────┤
│ TLL breached      │ ⛔ ENTRY BLOCKED: Max Trailing Drawdown (TLL) has been  │
│                   │    breached. No new trades today.                       │
├─────────────────────────────────────────────────────────────────────────────┤
│ Daily target hit  │ 🏆 ENTRY BLOCKED: Daily Gain Target reached.            │
│                   │    Trading stopped for today.                           │
└─────────────────────────────────────────────────────────────────────────────┘
BEFORE v15.5, all three conditions produced the same vague message:
"Trading Blocked: Risk Limit or Target Reached!"
This has been permanently replaced.
6.2 BUFFER WARNING ALERTS — INDIVIDUALISED (v15.5 A2)
These fire on every tick cycle when any buffer is ≤ 20% remaining,
throttled to maximum once per 60 seconds per condition.
Each alert includes the exact dollar amount and percentage remaining.
┌─────────────────────────────────────────────────────────────────────────────┐
│ Condition           │ Alert Message                                         │
├─────────────────────────────────────────────────────────────────────────────┤
│ DLL buffer ≤ 20%   │ ⚠️ DLL CRITICAL: Daily Loss Limit buffer is >80%      │
│                    │   consumed ($XXX.XX remaining — XX.X% left).          │
├─────────────────────────────────────────────────────────────────────────────┤
│ TLL buffer ≤ 20%   │ ⚠️ TLL CRITICAL: Trailing Drawdown buffer is >80%     │
│                    │   consumed ($XXX.XX remaining — XX.X% left).          │
├─────────────────────────────────────────────────────────────────────────────┤
│ TF Shield ≤ 20%    │ ⚠️ TF SHIELD CRITICAL: TF Shield buffer is >80%       │
│                    │   consumed ($XXX.XX remaining — XX.X% left).          │
└─────────────────────────────────────────────────────────────────────────────┘
BEFORE v15.5, all active buffer warnings were concatenated into one string:
"⚠️ WARNING: DLL Critical (>80% Used)! TLL Critical (>80% Used)!"
This has been permanently replaced.
6.3 FULL ALERT REFERENCE TABLE
┌─────────────────────────────────────────────────────────────────────────────────┐
│ Alert                                             │ When                        │
├─────────────────────────────────────────────────────────────────────────────────┤
│ US500 Mode: 1 Pip = $0.01 Price Change            │ On init, US500/SPX detected │
│ CRITICAL WARNING: Automated Trading is DISABLED   │ On init, toolbar off        │
│ CRITICAL WARNING: Trading is DISABLED for Account │ On init, account permission │
│ CRITICAL WARNING: EAs are DISABLED for Account    │ On init, EA permission      │
│ CRITICAL WARNING: Trading is DISABLED for Symbol  │ On init, symbol permission  │
│ CRITICAL WARNING: Symbol is CLOSE ONLY            │ On init, symbol mode        │
│ ✅ Daily Loss Limit Block EXPIRED                  │ Unblock countdown elapsed   │
│ ✅ Max Trailing Drawdown Block EXPIRED             │ Unblock countdown elapsed   │
│ ✅ Daily Gain Target Block EXPIRED                 │ Unblock countdown elapsed   │
│ DAILY LOSS LIMIT HIT! Trading stopped.            │ DLL breach detected         │
│ MAX TRAILING DRAWDOWN HIT! Trading stopped.       │ TLL breach detected         │
│ 🏆 DAILY GAIN TARGET HIT! Trading stopped.        │ DGT reached                 │
│ 🔒 PROFIT RATCHET ACTIVATED! Gains Locked.        │ Ratchet activated           │
│ ⚠️ DLL CRITICAL: ... ($X remaining — X% left)     │ DLL buffer ≤ 20% (60s throt)│
│ ⚠️ TLL CRITICAL: ... ($X remaining — X% left)     │ TLL buffer ≤ 20% (60s throt)│
│ ⚠️ TF SHIELD CRITICAL: ... ($X remaining — X%)    │ TF buffer ≤ 20% (60s throt) │
│ 🚨 TF SHIELD 2ND VIOLATION: ACCOUNT TERMINATION  │ 2nd TF Shield breach        │
│ ⚠️ TF SHIELD 1ST VIOLATION: Closing Positions     │ 1st TF Shield breach        │
│ !! ORDER BLOCKED: AutoTrading DISABLED (toolbar)  │ Entry attempt, toolbar off  │
│ !! ORDER BLOCKED: EA Algo Trading DISABLED        │ Entry attempt, EA prop off  │
│ Trading Paused due to Tilt Protection!            │ Tilt block active           │
│ Max Open Positions reached!                       │ Position count at max       │
│ Max Total Lots reached!                           │ Volume at max              │
│ EMERGENCY STOP ACTIVE: Trading Disabled.          │ Kill switch enabled         │
│ ENTRY REJECTED: Spread too high (X > MaxSpread)   │ Spread exceeds limit        │
│ ⛔ ENTRY BLOCKED: Daily Loss Limit (DLL)...        │ DLL active, entry attempt   │
│ ⛔ ENTRY BLOCKED: Max Trailing Drawdown (TLL)...   │ TLL active, entry attempt   │
│ 🏆 ENTRY BLOCKED: Daily Gain Target reached...    │ DGT active, entry attempt   │
│ ENTRY REJECTED: SL Distance too close to Spread   │ SL inside spread            │
│ v15.5 F3: Lot size capped to X.XX               │ Lot cap applied             │
│ !! Retcode 10027: AutoTrading is OFF              │ Order blocked by broker     │
│ CRITICAL: Broker rejected - TRADE DISABLED (10017)│ Broker rejection            │
│ CRITICAL: Market is CLOSED.                       │ Market closed               │
│ Order Send Failed! Check Journal/Experts tab.     │ Unresolved order failure    │
└─────────────────────────────────────────────────────────────────────────────────┘
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
7. SMART ENTRY SYSTEM

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
MARKET MODE
1.  Set SL pips, TP pips, and lot size in the GUI input fields.
2.  Click BUY or SELL.
3.  EA reads the current fields, validates lot size against broker limits, calculates tick-aligned SL/TP prices, and submits the order.
PENDING MODE
1.  Click [MARKET] to toggle to [PENDING].
2.  Enter the limit/stop price in the price field.
3.  Set SL, TP, size. Click BUY or SELL.
4.  EA places a pending order (Buy Limit/Stop or Sell Limit/Stop depending on whether price is above or below current market).
LOT SIZE CALCULATION
• If RiskPerTradePct > 0: Lots = (AccountSize × Risk%) ÷ (SL pips × pip value)
• If RiskPerTradePct = 0: Fixed lot from FixedLotSize input
• For indices: Lots = RiskAmount ÷ (SL distance in price)
• Lot is capped by broker SYMBOL_VOLUME_MAX and F3 safety cap
• Lot is snapped to SYMBOL_VOLUME_STEP precision
ENTRY GUARDS (checked in order before any order is sent):
1.  Terminal AutoTrading enabled
2.  EA Algo Trading allowed (EA Properties)
3.  Tilt Protection not active
4.  Not in news filter window
5.  Not in time filter block
6.  DLL not breached
7.  TLL not breached
8.  Daily Gain Target not reached
9.  Max Open Positions not exceeded
10.  Max Total Lots not exceeded
11.  Emergency Stop not active
12.  Spread within MaxSpreadPips
13.  SL distance > spread (SL not inside spread)
FILLING MODE
Order filling is attempted in this sequence:
1.  Broker's detected filling mode (AUTO negotiation)
2.  On INVALID_FILL rejection: retry with FOK if supported
3.  On FOK failure: retry with IOC if supported
4.  Manual override available via ManualFillingMode input
REQUOTE HANDLING
On REQUOTE retcode: automatically retries once with refreshed price (200ms delay).
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
8. POSITION MONITOR & AUTO-CLOSE

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
The EA monitors all positions that match its MagicNumber AND symbol.
Positions opened manually or by other EAs are ignored.
SCAN LOGIC
• ScanAndAddPositions() runs once per second (1Hz throttle)
• New positions are added to the monitor array automatically
• Closed positions are removed and their chart lines deleted
AUTO-CLOSE CONDITIONS (EnableAutoClose = true)
• SL hit:       EA closes position when price crosses SL distance
• TP hit:       EA closes position when price crosses TP distance
• Trailing SL:  EA manages trailing stop per ProcessTrailingStop()
• Partial TP:   EA closes partial lots at each configured level
SAFETY: 10-second hold after open — no auto-close within first 10 seconds
to prevent spread-spike false triggers on entry.
MAGIC NUMBER FILTER (v14.6 A7)
CloseAllPositions() and all monitors only operate on positions where
POSITION_MAGIC == MagicNumber. Third-party positions are never touched.
FLATTEN ALL
Closes all EA positions on this symbol immediately. Useful for emergency
manual exit. Does not affect pending orders (use CancelAllPendingOrders).
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
9. TRAILING STOP & BREAKEVEN

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
TRAILING STOP
Activation: Position must be in profit by TrailingActivationPips
Trailing:   Once active, SL trails price by TrailingDistancePips
Direction:  BUY — SL only moves up. SELL — SL only moves down.
Method:     EA-side trailing (UseRealTrailing = false, recommended)
or server-side (UseRealTrailing = true, broker-dependent)
BREAKEVEN
When UseBreakevenBuffer = true:
Once position reaches TrailingActivationPips in profit, SL is moved to
entry price + BreakevenFixedPips (or ATR-based buffer).
This locks a minimum profit before the trailing stop takes over.
ATR MODE
When InputUseATR = true, all distances (SL, TP, activation, trailing)
are calculated as ATR × multiplier, updated dynamically each tick.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
10. PARTIAL TAKE-PROFIT

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Requires UseMultiPartialTP = true.
Up to 3 levels. For each level:
• PartialPctN  — % of original position to close
• PartialPipsN — pip target (or ATR multiple if UseATRForPartialLevels = true)
Example (default):
Level 1: Close 50% at 75 pips
Level 2: Close 30% at 150 pips
Level 3: Close 20% at 250 pips (if PartialLevelCount = 3)
Once a level is hit it is bitmasked and not triggered again (partiallevelshit).
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
11. ATR DYNAMIC DISTANCES

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
When InputUseATR = true:
SL distance        = current_atr × ATRMultiSL
TP distance        = current_atr × ATRMultiTP
Trailing activation = current_atr × ATRMultiActivation
Trailing distance   = current_atr × ATRMultiTrailingDist
ATR is calculated using iATR(Symbol, PERIOD_CURRENT, ATRPeriod).
Handle is created at OnInit and released at OnDeinit.
NOTE: If ATR handle creation fails, RuntimeUseATR is set to false and the
EA falls back to fixed pip distances.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
12. NEWS & TIME FILTERS

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
NEWS FILTER
Uses MT5's built-in CalendarValueHistory() API.
Checks for upcoming high-impact events on the currencies in NewsCurrencyFilter.
Blocks new entries from (event_time − NewsPreMinutes) to (event_time + NewsPostMinutes).
If CloseOnHighNews = true, also closes all open positions before the block window.
Calendar is queried once per 60 seconds (not every tick).
TIME FILTER
When UseTimeFilter = true:
AllowedStartTime and AllowedEndTime define the permitted trading window (HHMM).
Supports overnight windows (e.g. 2200 to 0200).
Outside the window, all new entries are blocked. Active positions continue.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
13. SETTINGS PANEL (RUNTIME EDITS)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Click the [SETTINGS] button to open the runtime settings panel.
Changes take effect immediately without reloading the EA.
EDITABLE FIELDS (SETTINGS panel):
Risk %      — RiskPerTradePct
Daily Loss  — DailyLossLimitPct (recalculates DLL immediately)
TLL %       — MaxTrailingDrawdownPct (recalculates TLL immediately)
TF Shield % — TFShieldPercentage (recalculates TF Shield immediately)
DGT %       — DailyGainTargetPct
TTG %       — TotalTargetGainPct
PDC $       — ManualPriorDayClose (override for prior day close price)
HWM $       — ManualHighWaterMark (override for high water mark)
Bal $       — ManualStartingBalance (override for account balance base)
Scale       — GuiScale (resizes entire GUI without EA reload)
News Pre    — NewsPreMinutes
News Post   — NewsPostMinutes
TOGGLES (SETTINGS panel):
Monitor ON/OFF    — EnableAutoClose
Trailing ON/OFF   — RuntimeTrailingEnabled
Time Filter ON/OFF — RuntimeUseTimeFilter
News Filter ON/OFF — RuntimeUseNewsFilter
ATR ON/OFF        — RuntimeUseATR
Auto Scale        — Enables DPI-based auto scaling
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
14. DAILY RESET LOGIC

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
The daily reset fires when:
(a) Calendar day changes AND
(b) Server hour == DailyResetHour (default: 0 = midnight)
On reset:
• PriorDayClose updated to current equity
• DLL, TLL, DGT breach flags cleared
• DailyLossAlertSent, GainTargetAlertSent reset to false
• Realized P&L counter reset to 0
• All limits recalculated from new PriorDayClose
The reset key uses day × 100 + DailyResetHour to prevent double-firing.
Setting DailyResetHour = 17 for a 5 PM EST close is fully supported.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
15. SYMBOL & PIP SIZE DETECTION

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
The EA auto-detects pip size at init using symbol name keywords:
┌────────────────────────────────────┬──────────────┬────────────────────────┐
│ Symbol Pattern                     │ Pip Size     │ Notes                  │
├────────────────────────────────────┼──────────────┼────────────────────────┤
│ US500, SPX (2 decimal digits)      │ 0.01         │ 1:1 with MT5 points    │
│ US30, WALL (Dow Jones variants)    │ 1.00         │                        │
│ NAS, USTECH (Nasdaq variants)      │ 0.10         │                        │
│ GER, DE40 (DAX variants)           │ 1.00         │                        │
│ 5-digit Forex (EURUSD, etc.)       │ 0.0001       │                        │
│ 3-digit JPY pairs                  │ 0.01         │                        │
│ All others                         │ 10^(-Digits) │ Dynamic                │
└────────────────────────────────────┴──────────────┴────────────────────────┘
NOTE (v14.11 fix): US500/SPX pip size corrected from 0.02 to 0.01 to match
native MT5 point display (1:1 relationship). 300 pips = $3.00 price move.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
16. EXECUTION & FILLING MODES

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
The EA negotiates the optimal filling mode automatically:
AUTO → tries broker-reported flag → falls back to FOK → falls back to IOC
ManualFillingMode options:
FILLING_AUTO    — Automatic negotiation (recommended)
FILLING_FOK     — Fill or Kill (common for most brokers)
FILLING_IOC     — Immediate or Cancel
FILLING_RETURN  — Partial fill allowed (rare, ECN)
Retcode 10027 (TRADE_RETCODE_CLIENT_DISABLES_AT):
Fires a specific alert and does not retry. The trader must manually
enable the MT5 Algo Trading toolbar button or EA Properties permission.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
17. FILES WRITTEN TO DISK

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
All files are stored in MT5's Common Files folder.
File names are account-number-specific to prevent cross-account contamination.
┌─────────────────────────┬────────────────────────────────────────────────┐
│ File                    │ Contents                                       │
├─────────────────────────┼────────────────────────────────────────────────┤
│ TFHWM[AccountNo].dat    │ High Water Mark (binary double)               │
│ TFLog[AccountNo].csv    │ Trade journal / event log                     │
│ TFState[AccountNo].dat  │ EA state (breach flags, balances)             │
└─────────────────────────┴────────────────────────────────────────────────┘
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
18.  VERSION CHANGELOG (v14.6 → v15.5)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
v14.6  (2026-02-19)
A1  Removed dead first-build code in ExecuteSmartEntry BUY/SELL paths
A2  DailyResetHour now correctly honoured (was dead code; always reset at midnight)
A3  TLL breach flag was never set to true — silent protection failure — FIXED
A4  TF Shield auto-close now guarded by EnableTFShield (was always active)
A5  Dead code cleanup in order submission
A6  Index lot sizing corrected: Lots = RiskAmt ÷ SL_distance_in_price
A7  CloseAllPositions and ScanAndAdd now filter by MagicNumber AND Symbol
B2  Duplicate Tilt check removed from CheckTradingConditions
B3  OnTick throttled to 1Hz (was firing every sub-second tick)
C1  Live spread display added to GUI (green/orange colour coded)
C2  Event-driven position scan on trade transaction (instant fill detection)
C4  Live RR ratio display added to GUI
C5  TodaysRealizedProfit accumulation was never incrementing — FIXED
C7  News filter query window tightened
C8  Lot size input field now validates against broker min/max/step
v14.7  (intermediate — merged into v14.8)
v14.8  (2026-02-19)
B3  1Hz throttle confirmed stable
F1  SL distance tick-aligned: MathRound(sl_dist/_tick_sz)*_tick_sz
F1  Server SL sync: EA reads broker-confirmed SL after fill
D1  PrintExecutionDiagnostic() helper function added for Experts tab logging
D2  [Monitor] journal entries with Broker SL= confirmation
D3  GUI now shows live SL/TP prices (_sl_str, _tp_str) for active positions
v14.9  (2026-02-19)
T1  Price floor/cap guards: _buy_floor (entry ≥ ask), _sell_cap (entry ≤ bid)
Prevents limit orders firing at wrong side of spread
v14.10  (2026-02-19)
F3  Lot cap safety: _f3_max_lots prevents oversized entries on wide SL
F4  Requote handler: auto-retry once on TRADE_RETCODE_REQUOTE (200ms delay)
v14.11  (2026-02-20)
Pip size fix: US500/SPX corrected from 0.02 → 0.01 (1:1 with MT5 points)
GUI alert updated: "1 Pip = $0.01 Price Change (1:1 with MT5 points)"
v14.12  (2026-02-20)
G1  Metrics block y_start: 320px → 240px (80px higher, less dead space)
G2  Line height: 20px → 22px (more breathing room per metric line)
G3  Section gap (ACCOUNT→LIMITATIONS, LIMITATIONS→RISKS): 5px → 15px
Result: Clearly separated, readable three-section metrics layout
v14.13  (2026-02-21)
A1  Entry-block alert split: 1 combined alert → 3 individual alerts
(DLL blocked, TLL blocked, Daily Target blocked — each fires alone)
A2  Buffer warning alert split: 1 combined string → 3 individual alerts
(DLL critical, TLL critical, TF Shield critical — each fires alone
with exact dollar amount and percentage remaining displayed)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
19. RECOMMENDED DEFAULT SETTINGS

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
For a $25,000 prop firm account (FTMO-style 5%/10% rules):
AccountSize              = 25000
DailyLossLimitPct        = 5.0        → $1,250 daily loss max
MaxTrailingDrawdownPct   = 10.0       → $2,500 trailing max drawdown
TFShieldPercentage       = 2.0        → $500 floating loss max
DailyGainTargetPct       = 1.0        → $250 daily target
RatchetActivationPct     = 1.0        → activates at $250 gain
RatchetLockPct           = 0.5        → locks $125 minimum profit
MaxConsecutiveLosses     = 3          → pause after 3 consecutive losses
TiltPauseMinutes         = 15
MaxOpenPositions         = 3
MaxSpreadPips            = 3          → (US500: set to 5)
MagicNumber              = 99999      → change if running multiple instances
GuiScale                 = 1.3        → adjust for your monitor resolution
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
20. TROUBLESHOOTING

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
┌──────────────────────────────────────────┬─────────────────────────────────┐
│ Problem                                  │ Solution                        │
├──────────────────────────────────────────┼─────────────────────────────────┤
│ BUY/SELL buttons do nothing              │ Check MT5 Algo Trading toolbar  │
│                                          │ Check EA Properties > Common    │
├──────────────────────────────────────────┼─────────────────────────────────┤
│ "Retcode 10027" alert on every click     │ Enable Algo Trading toolbar or  │
│                                          │ EA Properties Allow Algo Trading│
├──────────────────────────────────────────┼─────────────────────────────────┤
│ Panel not visible                        │ ShowRiskPanel = true; check     │
│                                          │ PanelOffsetX/Y values           │
├──────────────────────────────────────────┼─────────────────────────────────┤
│ Metrics panel too low / off screen       │ Reduce GuiScale or adjust       │
│                                          │ PanelOffsetY                    │
├──────────────────────────────────────────┼─────────────────────────────────┤
│ Wrong pip values / SL too small          │ Check symbol name detection;    │
│                                          │ review Journal for "pipsize="   │
├──────────────────────────────────────────┼─────────────────────────────────┤
│ Positions not being monitored            │ Verify MagicNumber matches the  │
│                                          │ value used when the order fired  │
├──────────────────────────────────────────┼─────────────────────────────────┤
│ TF Shield never triggers                 │ Confirm EnableTFShield = true   │
├──────────────────────────────────────────┼─────────────────────────────────┤
│ DLL / TLL not resetting at correct time  │ Set DailyResetHour to desired   │
│                                          │ server-time hour (0=midnight)   │
├──────────────────────────────────────────┼─────────────────────────────────┤
│ News filter not blocking                 │ Check NewsCurrencyFilter string  │
│                                          │ matches broker currency codes    │
│                                          │ Verify MT5 economic calendar on  │
├──────────────────────────────────────────┼─────────────────────────────────┤
│ "Order Send Failed" with no retcode info │ Check Experts tab — full detail │
│                                          │ printed via PrintExecutionDiag. │
└──────────────────────────────────────────┴─────────────────────────────────┘
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
END OF USER GUIDE — TF Complete Risk Manager v15.5
Author: Andre Denis  |  March 2026  |  Laval, Quebec, Canada
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
