# Backend API Endpoint Specification

## Player Roster Endpoint

### Endpoint
```
GET /api/players/roster
```

### Description
Returns the current NBA player roster with team relationships and NBA player IDs. This endpoint should be called by widgets to maintain up-to-date player-team mappings.

### Response Format

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
    },
    {
      "nba_player_id": 2544,
      "name": "LeBron James",
      "team_abbreviation": "LAL",
      "team_name": "Los Angeles Lakers",
      "jersey_number": "23",
      "position": "F"
    }
  ]
}
```

### Response Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `season` | string | Yes | Current NBA season (e.g., "2025-26") |
| `updated_at` | string | Yes | ISO 8601 timestamp of when data was last updated |
| `total_players` | integer | Yes | Total number of active players |
| `players` | array | Yes | Array of player objects |

### Player Object Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `nba_player_id` | integer | Yes | Official NBA player ID (permanent identifier) |
| `name` | string | Yes | Player's full name |
| `team_abbreviation` | string | Yes | 3-letter team abbreviation (e.g., "GSW", "LAL") |
| `team_name` | string | Yes | Full team name (e.g., "Golden State Warriors") |
| `jersey_number` | string | No | Player's jersey number |
| `position` | string | No | Player's position (G, F, C, G-F, F-C) |

### Status Codes

- `200 OK` - Successfully retrieved roster
- `500 Internal Server Error` - Server error

### Notes

1. **Caching**: This endpoint data should be cached for 24 hours on the client side
2. **Updates**: The roster should be updated when:
   - Players are traded
   - Players are signed/released
   - Jersey numbers change
   - Position changes occur
3. **Data Source**: This should pull from your existing database that tracks active NBA rosters
4. **Performance**: Response should be fast (<500ms) as widgets call this on refresh

### Implementation Notes for Backend

The backend should:
1. Query the active players from your database
2. Join with team data to get abbreviations and full names
3. Return JSON in the specified format
4. Consider adding caching on the backend (Redis) with a TTL of 1-2 hours
5. Update the `updated_at` timestamp whenever the roster data changes

### Example Usage (Swift/iOS)

```swift
// In widget timeline provider
let roster = try await NBAAPIService.shared.getPlayerRoster()

// The service automatically handles:
// - Caching for 24 hours in App Group UserDefaults
// - Returning cached data if < 24 hours old
// - Fetching fresh data if cache expired
```

### Database Query Example (Pseudo-SQL)

```sql
SELECT 
    p.nba_player_id,
    p.full_name as name,
    t.abbreviation as team_abbreviation,
    t.name as team_name,
    p.jersey_number,
    p.position
FROM players p
INNER JOIN teams t ON p.team_id = t.id
WHERE p.is_active = true
ORDER BY p.full_name;
```

