# TF_RiskManager

TF_RiskManager is a MetaTrader 5 Expert Advisor designed to enforce risk
management rules across all open positions. It provides configurable limits,
automatic position handling, and real‑time monitoring.

## Features
- Global risk limits (daily, weekly, per‑trade)
- Automatic position closing based on rules
- Configurable alerts and notifications
- Broker‑agnostic logic
- Lightweight and efficient

## Folder Structure
- `src/` — Source code (.mq5)
- `build/` — Compiled EA (.ex5)
- `docs/` — Notes, parameters, design docs
- `tests/` — Strategy tester presets and results
- `releases/` — Versioned release packages

## Installation
1. Copy the `.ex5` file from `build/` into:
   `MQL5/Experts/TF_RiskManager/`
2. Restart MetaTrader 5.
3. Attach the EA to a chart.

## Development
Source code lives in `src/`.  
Compiled output goes into `build/`.

## License
Proprietary — All rights reserved.
