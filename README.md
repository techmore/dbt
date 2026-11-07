# TM-DBT

A low-friction DBT (Dialectical Behavior Therapy) practice kit in two parts:

- **Website** (repo root): a static GitHub Pages site with a 0-to-1 progression for the first 14 days, a daily schedule, printable worksheets, a tool guide, and a progress tracker saved in the browser. Live at https://techmore.github.io/dbt/
- **App** (`TM-DBT/`): a SwiftUI app for iPhone, iPad and Mac with the same daily scaffold.

This is educational and does not replace therapy. For urgent crises in the US, call or text `988`, or contact local emergency services.

## App

| Tab | What it does |
| --- | --- |
| Today | The block for the current time of day, the next block, four daily checkpoints, the whole-day schedule, and a chain analysis ("hard moment review") form. |
| Diary | A quick diary card (emotion, trigger, response, notes), the last 30 days of check-ins, and saved hard-moment reviews. |
| Worksheets | The order to use the worksheets in, plus links to the printable versions on the website. |
| Resources | Crisis line, DBT references and videos. |

Data stays on the device as JSON files in Application Support (`TM-DBT/`). There is no account and no sync.

**Requirements:** Xcode 16 or later; runs on iOS 17+ and macOS 14+.

```bash
open TM-DBT/TM-DBT.xcodeproj          # then Run the TM-DBT scheme
```

**Tests**

```bash
cd TM-DBT
# Unit tests (storage, schedule)
xcodebuild test -project TM-DBT.xcodeproj -scheme TM-DBT -destination 'platform=macOS' -only-testing:TM-DBTTests
# UI smoke test (needs an iPhone simulator)
xcodebuild test -project TM-DBT.xcodeproj -scheme TM-DBT -destination 'platform=iOS Simulator,name=iPhone 18 Pro'  # any installed iPhone simulator -only-testing:TM-DBTUITests/TM_DBTUITests/testMainScreensAreReachable
```

## Website

Open `index.html` directly in a browser, or run:

```bash
python3 -m http.server 4173
```

Then visit `http://localhost:4173`. GitHub Pages serves the repo root from `main`.
