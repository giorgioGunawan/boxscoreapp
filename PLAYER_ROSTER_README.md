# Player Roster Cache System - README

## 📋 Table of Contents

1. [Overview](#overview)
2. [Quick Start](#quick-start)
3. [Documentation Files](#documentation-files)
4. [Implementation Status](#implementation-status)
5. [How to Test](#how-to-test)

---

## Overview

This system provides **automatic caching of player-team relationships** with a **24-hour TTL**, designed specifically for iOS widgets that need up-to-date roster information without requiring the main app to be opened.

### The Problem
- Players get traded/signed throughout the season
- Bundled `players_db.json` becomes outdated
- Widgets may never open the main app to refresh data
- Making API calls on every widget refresh is inefficient

### The Solution ✅
- Backend API endpoint for current roster
- 24-hour client-side cache in App Group UserDefaults
- Widgets automatically fetch when cache expires
- All widgets share the same cache (efficient)
- Works without ever opening the main app

---

## Quick Start

### For Backend Developers

**1. Implement the endpoint:**
```
GET /api/players/roster
```

See: [`BACKEND_API_SPEC.md`](./BACKEND_API_SPEC.md) for complete specification

**2. Test the endpoint:**
```bash
curl https://boxscore-backend.onrender.com/api/players/roster
```

Expected response format:
```json
{
  "season": "2025-26",
  "updated_at": "2025-12-11T12:00:00.000Z",
  "total_players": 526,
  "players": [
    {
      "nba_player_id": 201939,
      "name": "Stephen Curry",
      "team_abbreviation": "GSW",
      "team_name": "Golden State Warriors",
      "jersey_number": "30",
      "position": "G"
    }
  ]
}
```

### For iOS Developers

**The code is already implemented!** ✅

Just use in any widget:
```swift
let roster = try await NBAAPIService.shared.getPlayerRoster()
```

See: [`ROSTER_CACHE_USAGE.md`](./ROSTER_CACHE_USAGE.md) for detailed usage examples

---

## Documentation Files

All documentation is located in the project root:

### 📘 Main Documentation

| File | Purpose | Read This If... |
|------|---------|-----------------|
| **[QUICK_REFERENCE.md](./QUICK_REFERENCE.md)** | One-page cheat sheet | You want a quick lookup |
| **[BACKEND_API_SPEC.md](./BACKEND_API_SPEC.md)** | Backend endpoint specification | You're implementing the backend |
| **[ROSTER_CACHE_USAGE.md](./ROSTER_CACHE_USAGE.md)** | iOS usage guide | You're using it in widgets |
| **[IMPLEMENTATION_SUMMARY.md](./IMPLEMENTATION_SUMMARY.md)** | Complete overview | You want the full picture |
| **[ARCHITECTURE_DIAGRAM.md](./ARCHITECTURE_DIAGRAM.md)** | Visual diagrams | You like visual explanations |
| **[PLAYER_ROSTER_README.md](./PLAYER_ROSTER_README.md)** | This file | You're starting from scratch |

### 🎯 Where to Start?

**If you're a...**
- **Backend dev**: Read `BACKEND_API_SPEC.md` → Implement endpoint → Done!
- **iOS dev**: Read `ROSTER_CACHE_USAGE.md` → Use `getPlayerRoster()` → Done!
- **Project manager**: Read `IMPLEMENTATION_SUMMARY.md` → Understand scope
- **New to project**: Read `QUICK_REFERENCE.md` → Get oriented → Deep dive as needed

---

## Implementation Status

### ✅ iOS Frontend - COMPLETE

| Component | Status | File |
|-----------|--------|------|
| Data models | ✅ Done | `BoxScoreWidgetExtension/NBAModels.swift` |
| Cache logic | ✅ Done | `BoxScoreWidgetExtension/NBAAPIService.swift` |
| Example usage | ✅ Done | `BoxScoreWidgetExtension/SeasonAverageWidget.swift` |
| Documentation | ✅ Done | All `.md` files |
| Testing | ⏳ Pending backend | - |

### ⏳ Backend API - PENDING

| Component | Status | Next Steps |
|-----------|--------|------------|
| Endpoint | ❌ Not started | Implement `GET /api/players/roster` |
| Database query | ❌ Not started | Join players + teams tables |
| Response format | ✅ Specified | See `BACKEND_API_SPEC.md` |
| Testing | ❌ Not started | Test with curl/Postman |
| Deployment | ❌ Not started | Deploy to production |

---

## How to Test

### Phase 1: Backend Testing (Before iOS Testing)

```bash
# 1. Deploy backend endpoint
# 2. Test with curl
curl https://boxscore-backend.onrender.com/api/players/roster

# 3. Verify response format matches spec
# 4. Check all required fields are present
# 5. Verify data is accurate
```

### Phase 2: iOS Integration Testing

```swift
// 1. Build and run app in simulator
// 2. Add a widget to home screen
// 3. Check console logs:

// Expected on first launch:
// "🔄 Fetching fresh player roster from API..."
// "💾 Saved player roster to cache (526 players)"

// Expected on subsequent refreshes:
// "✅ Using cached player roster (age: 5hrs)"

// 4. Wait 24 hours or manually modify cache date
// 5. Widget should fetch fresh data automatically
```

### Phase 3: Production Testing

1. **Deploy to TestFlight**
2. **Add widgets to test device**
3. **Monitor for 48 hours:**
   - Check API call frequency
   - Verify cache is working
   - Confirm data freshness
4. **Simulate trade scenario:**
   - Update player's team in backend
   - Wait for cache to expire (24hrs)
   - Verify widget shows updated team

---

## Architecture At A Glance

```
┌─────────────────────────────────────────────────────────┐
│                    YOUR iOS DEVICE                       │
│                                                          │
│  Widget refreshes every 1-6 hours                       │
│         ↓                                               │
│  NBAAPIService.getPlayerRoster()                        │
│         ↓                                               │
│  Check App Group UserDefaults cache                     │
│         ↓                                               │
│  ┌──────────────────┐      ┌──────────────────┐       │
│  │ Cache < 24hrs?   │ YES  │ Return cache     │       │
│  │                  │──→   │ (instant)        │       │
│  └──────────────────┘      └──────────────────┘       │
│         ↓ NO                                           │
│  ┌──────────────────┐      ┌──────────────────┐       │
│  │ Fetch from API   │──→   │ Save to cache    │       │
│  │ (~500ms)         │      │ Return data      │       │
│  └──────────────────┘      └──────────────────┘       │
└─────────────────────────────────────────────────────────┘
                     ↓ (if cache expired)
┌─────────────────────────────────────────────────────────┐
│              BACKEND API (render.com)                    │
│                                                          │
│  GET /api/players/roster                                │
│         ↓                                               │
│  Query database (players + teams)                       │
│         ↓                                               │
│  Return JSON with all active players                    │
└─────────────────────────────────────────────────────────┘
```

---

## Key Decisions Made

### ✅ Decision: Cache at Widget Level (Not App Level)

**Why?**
- Users may never open the main app
- Widgets need data independently
- iOS already manages widget refresh timing
- Efficient with 24hr shared cache

**Alternatives Considered:**
- ❌ Cache only in main app → Requires app opens
- ❌ No caching → Too many API calls
- ❌ Cache forever → Stale data

### ✅ Decision: 24-Hour TTL

**Why?**
- Balances freshness vs API load
- Trades don't happen every day
- Acceptable staleness (max 24hrs)
- Reduces backend costs

**Alternatives Considered:**
- ❌ 1 hour → Too many API calls
- ❌ 7 days → Too stale for trades
- ❌ Real-time → Over-engineered

### ✅ Decision: App Group UserDefaults Storage

**Why?**
- Shared between app and all widgets
- Persists across app kills
- Built-in iOS feature (no dependencies)
- Fast read/write

**Alternatives Considered:**
- ❌ In-memory → Lost on widget kill
- ❌ Core Data → Over-engineered
- ❌ Files → More complex

---

## Monitoring & Maintenance

### What to Monitor

1. **API Call Frequency**
   - Expected: ~1-2 calls per device per day
   - Alert if: >10 calls per day (cache not working)

2. **Cache Hit Rate**
   - Expected: >95% cache hits
   - Alert if: <80% (TTL too short or cache failing)

3. **Response Times**
   - Cached: <1ms
   - API: <500ms
   - Alert if: API >2 seconds

4. **Data Freshness**
   - Trades should reflect within 24 hours
   - Manual refresh option available if urgent

### Console Logs

Monitor these emoji indicators:

```
✅ Using cached player roster (age: 5hrs)    // Good - cache hit
🔄 Fetching fresh player roster from API...  // Normal - cache expired
💾 Saved player roster to cache (526 players) // Good - cache saved
⚠️ Failed to fetch roster: [error]           // Investigate
```

---

## FAQ

### Q: What if a major trade happens mid-day?
**A:** Widget will show old team for up to 24 hours. For urgent updates, add a manual refresh button in the app settings (see `ROSTER_CACHE_USAGE.md`).

### Q: What if the API is down?
**A:** Widget uses last cached data (even if >24hrs old) and shows gracefully. Bundled `players_db.json` is fallback.

### Q: How much data does this use?
**A:** ~100KB per day (one roster fetch). Very efficient.

### Q: Do I need to modify existing widgets?
**A:** Optional. See `SeasonAverageWidget.swift` for example. Adding `getPlayerRoster()` call ensures cache is warm.

### Q: Can I force a refresh?
**A:** Yes: `await NBAAPIService.shared.refreshPlayerRoster()`

### Q: How do I know it's working?
**A:** Check console logs for the emoji indicators (✅🔄💾).

---

## Support & Questions

### Need Help?

1. **Quick question?** → Check `QUICK_REFERENCE.md`
2. **Backend question?** → See `BACKEND_API_SPEC.md`
3. **iOS question?** → See `ROSTER_CACHE_USAGE.md`
4. **Architecture question?** → See `ARCHITECTURE_DIAGRAM.md`
5. **General overview?** → See `IMPLEMENTATION_SUMMARY.md`

### Troubleshooting

| Problem | Solution |
|---------|----------|
| Widget not updating | Check if backend endpoint exists |
| Always hitting API | Verify App Group ID in entitlements |
| Data seems wrong | Check backend data accuracy |
| Cache not shared | Ensure all targets use same App Group |

---

## Next Steps

### Immediate (Critical Path)

1. ✅ ~~iOS implementation~~ (Done!)
2. ⏳ **Backend endpoint implementation** (Next!)
3. ⏳ Integration testing
4. ⏳ Deploy to production

### Future Enhancements (Nice to Have)

- Push notifications for roster changes (instant updates)
- ETag support (bandwidth optimization)
- Analytics dashboard (monitor cache performance)
- A/B test different TTL values

---

## Summary

| What | Status | Owner |
|------|--------|-------|
| iOS implementation | ✅ Complete | Done |
| Backend endpoint | ⏳ Pending | Backend team |
| Documentation | ✅ Complete | Done |
| Testing | ⏳ Blocked on backend | QA team |

**Estimated effort for backend:** 2-4 hours
- 1 hour: Endpoint implementation
- 1 hour: Testing
- 0-2 hours: Deployment/issues

**Total project status:** 70% complete (iOS done, backend pending)

---

**Ready to implement?** Start with `BACKEND_API_SPEC.md` 🚀

