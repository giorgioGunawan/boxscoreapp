# Player Roster Cache Usage Guide

## Overview

The player roster caching system automatically fetches and caches player-team relationships for 24 hours. This ensures widgets always have access to current roster data without making excessive API calls.

## How It Works

1. **First Call**: When a widget requests roster data, it checks the cache
2. **Cache Hit**: If data is < 24 hours old, return cached data immediately
3. **Cache Miss/Expired**: If cache is empty or > 24 hours old, fetch from API and cache the result
4. **Shared Storage**: Cache is stored in App Group UserDefaults, accessible by all widgets and the main app

## Usage in Widgets

### Example: Player Widget

```swift
// In your widget's timeline provider
func timeline(for configuration: ConfigurePlayerIntent, in context: Context) async -> Timeline<PlayerEntry> {
    guard let playerID = configuration.player?.id else {
        return Timeline(entries: [/* error entry */], policy: .after(Date().addingTimeInterval(3600)))
    }
    
    do {
        // ✅ This automatically handles caching
        // - Returns cached data if < 24 hours old
        // - Fetches fresh data if cache expired
        let roster = try await NBAAPIService.shared.getPlayerRoster()
        
        // Find the player's current team
        if let player = roster.players.first(where: { $0.nba_player_id == playerID }) {
            print("Player \(player.name) is on \(player.team_abbreviation)")
            
            // Now fetch their stats using the correct team
            let stats = try await NBAAPIService.shared.getSeasonAverages(nbaPlayerID: playerID)
            
            // Create entry...
        }
        
        // Refresh widget every 6 hours (roster cache handles 24hr TTL internally)
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 6, to: Date()) ?? Date()
        return Timeline(entries: [entry], policy: .after(nextUpdate))
    } catch {
        // Handle error...
    }
}
```

### Example: Get Specific Player's Team

```swift
// Quick lookup for a player's current team
do {
    let (team, teamName) = try await NBAAPIService.shared.getPlayerTeam(nbaPlayerID: 201939)
    print("Stephen Curry plays for \(team)") // "GSW"
} catch {
    print("Player not found or API error")
}
```

## Usage in Main App

### Pre-warming the Cache

Add this to your main app to ensure the cache is fresh when users open the app:

```swift
// In ContentView.swift or gridnextappApp.swift

struct ContentView: View {
    @State private var isLoadingRoster = false
    
    var body: some View {
        // ... your existing view code
    }
    .onAppear {
        Task {
            await preloadRosterIfNeeded()
        }
    }
    
    private func preloadRosterIfNeeded() async {
        guard !isLoadingRoster else { return }
        
        isLoadingRoster = true
        defer { isLoadingRoster = false }
        
        do {
            // This will use cache if fresh, or fetch if needed
            let roster = try await NBAAPIService.shared.getPlayerRoster()
            print("✅ Roster loaded: \(roster.total_players) players")
        } catch {
            print("⚠️ Failed to preload roster: \(error.localizedDescription)")
            // Not critical - widgets will fetch on their own
        }
    }
}
```

### Manual Refresh (Optional)

Add a settings option to force refresh the roster:

```swift
// In SettingsView.swift

Button {
    Task {
        do {
            try await NBAAPIService.shared.refreshPlayerRoster()
            // Show success message
        } catch {
            // Show error message
        }
    }
} label: {
    HStack {
        Spacer()
        Text("Refresh Player Roster")
        Spacer()
    }
}
```

## Widget Timeline Recommendations

Since the roster cache handles 24-hour TTL internally, you can set your widget refresh policies based on the data type:

| Widget Type | Recommended Refresh | Reason |
|-------------|-------------------|--------|
| Next Games | 1 hour | Game times rarely change |
| Last Games | 1 hour | Results are final |
| Season Averages | 6 hours | Stats update daily |
| Player Last Game | 2 hours | Recent game stats |
| Team Standings | 6 hours | Standings update daily |
| Countdown | 1 minute | Time-sensitive |

## Cache Behavior

### Cache Storage
- **Location**: App Group UserDefaults (`group.com.giorgiogunawan.boxscore`)
- **Key**: `cachedPlayerRoster`
- **Size**: ~50-100KB for ~500 players
- **TTL**: 24 hours

### Cache Invalidation
Cache is automatically invalidated when:
- 24 hours have passed since last fetch
- No cached data exists

Cache is NOT invalidated when:
- App is backgrounded/terminated (persists)
- Widget is removed and re-added (persists)
- Device restarts (persists in UserDefaults)

## Error Handling

The system gracefully handles errors:

1. **API Unavailable**: Widget shows last cached data (even if > 24hrs old)
2. **Network Error**: Falls back to bundled `players_db.json`
3. **Player Not Found**: Throws `APIError.playerNotFound`

## Best Practices

### DO ✅
- Let the cache handle TTL automatically
- Pre-warm cache in main app when user opens it
- Use roster data to validate player selections
- Check roster before fetching player-specific stats

### DON'T ❌
- Don't fetch roster on every widget refresh (cache handles this)
- Don't implement your own TTL logic (already built-in)
- Don't fetch roster if you only need static player list (use bundled JSON)
- Don't block widget display waiting for roster (show cached/loading state)

## Monitoring

Add console logs to track cache performance:

```swift
// Already included in NBAAPIService:
// ✅ Using cached player roster (age: 5hrs)
// 🔄 Fetching fresh player roster from API...
// 💾 Saved player roster to cache (526 players)
```

## Testing

### Test Cache Hit
1. Call `getPlayerRoster()` twice quickly
2. First call should fetch from API
3. Second call should use cache (instant)

### Test Cache Expiry
1. Fetch roster
2. Manually modify cached date to 25 hours ago
3. Next call should fetch fresh data

### Test App Group Sharing
1. Fetch roster in main app
2. Immediately check widget
3. Widget should use cached data (no API call)

## Migration Notes

### Before (Bundled JSON)
```swift
// Static data, requires app update for roster changes
let playerDB = loadPlayerDatabase()
```

### After (Live API with Cache)
```swift
// Fresh data, automatic 24hr updates
let roster = try await NBAAPIService.shared.getPlayerRoster()
```

The bundled `players_db.json` is kept as a fallback but no longer the primary data source.

