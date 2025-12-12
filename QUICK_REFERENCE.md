# Quick Reference - Player Roster Cache

## 🎯 One-Sentence Answer
**Yes, call the API from widgets when they refresh data** - the 24hr cache prevents unnecessary API calls and works without app opens.

## 📞 Backend Endpoint Needed

```
GET https://boxscore-backend.onrender.com/api/players/roster
```

Returns:
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

## 💻 iOS Usage (Already Implemented)

### In Any Widget

```swift
// Just call this - caching is automatic!
let roster = try await NBAAPIService.shared.getPlayerRoster()

// Find a player's team
let player = roster.players.first(where: { $0.nba_player_id == playerID })
print("Team: \(player?.team_abbreviation)")
```

### Quick Team Lookup

```swift
let (team, teamName) = try await NBAAPIService.shared.getPlayerTeam(nbaPlayerID: 201939)
// Returns: ("GSW", "Golden State Warriors")
```

### Force Refresh (Optional)

```swift
try await NBAAPIService.shared.refreshPlayerRoster()
```

## ⚙️ How It Works

1. **First call**: Fetches from API (~500ms), saves to cache
2. **Subsequent calls**: Returns cached data instantly (<1ms)
3. **After 24 hours**: Automatically fetches fresh data
4. **Shared cache**: All widgets use the same cached data

## 📊 Key Metrics

| Metric | Value |
|--------|-------|
| Cache TTL | 24 hours |
| Cache Size | ~50-100KB |
| Storage | App Group UserDefaults |
| API Calls | ~1-2 per day (for all widgets) |
| Response Time (cached) | <1ms |
| Response Time (API) | ~500ms |

## 🏗️ Files Modified

- ✅ `BoxScoreWidgetExtension/NBAModels.swift` - Added models
- ✅ `BoxScoreWidgetExtension/NBAAPIService.swift` - Added cache logic
- ✅ `BoxScoreWidgetExtension/SeasonAverageWidget.swift` - Example usage

## 📚 Documentation

| File | Purpose |
|------|---------|
| `BACKEND_API_SPEC.md` | Complete backend endpoint spec |
| `ROSTER_CACHE_USAGE.md` | Detailed usage guide with examples |
| `IMPLEMENTATION_SUMMARY.md` | Full implementation overview |
| `ARCHITECTURE_DIAGRAM.md` | Visual diagrams and flows |
| `QUICK_REFERENCE.md` | This file - quick lookup |

## ✅ Implementation Checklist

### Backend (TODO)
- [ ] Create `GET /api/players/roster` endpoint
- [ ] Test endpoint with Postman/curl
- [ ] Deploy to production

### iOS (DONE)
- [x] Models added
- [x] Cache logic implemented
- [x] Example widget updated
- [x] Documentation written

### Testing (TODO)
- [ ] Test first API call
- [ ] Test cache hit on second call
- [ ] Test cache expiry after 24hrs
- [ ] Test with multiple widgets

## 🐛 Troubleshooting

| Issue | Solution |
|-------|----------|
| Cache not working | Check App Group ID in entitlements |
| Always hitting API | Check console logs for cache age |
| Stale data | Call `refreshPlayerRoster()` |
| Player not found | Ensure backend returns all active players |

## 💡 Why This Approach?

✅ **Works without app opens** - Users rarely open widget apps
✅ **Efficient** - Shared cache across all widgets
✅ **Fresh data** - Updates within 24 hours
✅ **Low backend load** - Only 1-2 API calls per day
✅ **Fast** - Cached responses are instant
✅ **iOS-managed** - OS controls widget refresh timing

## 🚀 Next Steps

1. Implement backend endpoint (see `BACKEND_API_SPEC.md`)
2. Deploy iOS app (code already done)
3. Test end-to-end
4. Monitor cache hit rate in logs

## 📞 Console Logs to Watch

```
✅ Using cached player roster (age: 5hrs)  // Cache hit
🔄 Fetching fresh player roster from API...  // Cache miss
💾 Saved player roster to cache (526 players)  // Cache saved
```

## 🎓 Example: Complete Widget Implementation

```swift
func timeline(for configuration: ConfigurePlayerIntent, in context: Context) async -> Timeline<PlayerEntry> {
    guard let playerID = configuration.player?.id else {
        return errorTimeline()
    }
    
    do {
        // This line handles all caching automatically!
        let roster = try await NBAAPIService.shared.getPlayerRoster()
        
        // Your widget logic here
        let stats = try await NBAAPIService.shared.getSeasonAverages(nbaPlayerID: playerID)
        
        let entry = PlayerEntry(date: Date(), stats: stats)
        let nextUpdate = Date().addingTimeInterval(6 * 3600) // 6 hours
        
        return Timeline(entries: [entry], policy: .after(nextUpdate))
    } catch {
        return errorTimeline()
    }
}
```

## 📖 Remember

- **Don't** implement your own caching - it's already done
- **Don't** fetch on every widget refresh - cache handles it
- **Don't** worry about app opens - widgets work independently
- **Do** call `getPlayerRoster()` before fetching player stats
- **Do** use the console logs to verify cache behavior
- **Do** let iOS manage widget refresh timing

---

**Questions?** See full documentation in the files listed above. ✨

