# Backend Implementation Prompt for LLM

Copy and paste this entire prompt to an LLM (Claude, ChatGPT, etc.) to implement the backend endpoint.

---

## INSTRUCTION FOR LLM

I need you to implement a new API endpoint for my NBA stats backend. This endpoint will provide current player roster data with team relationships for iOS widgets.

### CONTEXT

**Backend URL:** `https://boxscore-backend.onrender.com`
**Tech Stack:** [Provide your tech stack: Node.js/Express, Python/Flask, etc.]
**Database:** [Provide your database: PostgreSQL, MongoDB, etc.]

**Existing Database Tables:**
- `players` table - Contains NBA player information
- `teams` table - Contains NBA team information

### REQUIREMENTS

Create a new API endpoint:

**Endpoint:** `GET /api/players/roster`

**Purpose:** Return all active NBA players with their current team relationships and NBA player IDs.

### EXPECTED RESPONSE FORMAT

The endpoint MUST return JSON in this exact format:

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
    // ... all active players
  ]
}
```

### FIELD SPECIFICATIONS

**Root Level Fields:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `season` | string | Yes | Current NBA season in format "YYYY-YY" (e.g., "2025-26") |
| `updated_at` | string | Yes | ISO 8601 UTC timestamp when this data was generated |
| `total_players` | integer | Yes | Total count of players in the array |
| `players` | array | Yes | Array of all active player objects |

**Player Object Fields:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `nba_player_id` | integer | Yes | Official NBA player ID - this is the permanent identifier |
| `name` | string | Yes | Player's full name (first and last) |
| `team_abbreviation` | string | Yes | 3-letter team abbreviation (e.g., "GSW", "LAL", "MIA") |
| `team_name` | string | Yes | Full official team name (e.g., "Golden State Warriors") |
| `jersey_number` | string | No | Player's jersey number as string (can be null) |
| `position` | string | No | Player's position: "G", "F", "C", "G-F", or "F-C" (can be null) |

### DATABASE QUERY GUIDANCE

The query should:
1. Select all **active** players from your players table
2. JOIN with the teams table to get team names and abbreviations
3. Include the official `nba_player_id` field (this is critical - it's the permanent NBA identifier)
4. Order by player name alphabetically
5. Only include players who are currently on an NBA roster (active = true)

**Example SQL (adjust to your schema):**

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
ORDER BY p.full_name ASC;
```

### IMPLEMENTATION REQUIREMENTS

1. **Performance:**
   - Response time should be < 500ms
   - Consider adding database indexes on `is_active` and `team_id`
   - Consider caching this response (Redis, in-memory) with 1-2 hour TTL

2. **Error Handling:**
   - Return proper HTTP status codes
   - Handle database connection errors gracefully
   - If no players found, return empty array (not an error)

3. **Data Validation:**
   - Ensure `nba_player_id` is present for all players (it's critical)
   - Ensure team relationships exist (INNER JOIN, not LEFT JOIN)
   - Handle null values for jersey_number and position gracefully

4. **Status Codes:**
   - `200 OK` - Successful response with data
   - `500 Internal Server Error` - Database or server error

5. **Headers:**
   - `Content-Type: application/json`
   - Consider adding `Cache-Control: public, max-age=3600` (1 hour)

### ADDITIONAL CONTEXT

**Why this endpoint is needed:**
- iOS widgets need up-to-date player-team relationships
- Players get traded/signed throughout the season
- The app currently uses a static JSON file that becomes outdated
- Widgets will cache this response for 24 hours on the client side

**Critical Fields:**
- `nba_player_id` - This is the most important field. It's the permanent identifier that never changes even when players switch teams.
- `team_abbreviation` - Used for lookups and display
- `name` - Must match player's full official name

### TESTING

After implementation, test with:

```bash
curl https://boxscore-backend.onrender.com/api/players/roster
```

**Verify:**
1. Response is valid JSON
2. All required fields are present
3. `total_players` matches length of `players` array
4. `nba_player_id` is present for every player
5. Team abbreviations are 3 letters and uppercase
6. Response time is < 500ms
7. Data is accurate (spot-check a few players)

### EXAMPLE DATABASE SCHEMAS

If your schema looks different, adjust accordingly:

**Option 1: Separate Tables**
```sql
-- players table
CREATE TABLE players (
    id SERIAL PRIMARY KEY,
    nba_player_id INTEGER UNIQUE NOT NULL,
    full_name VARCHAR(255) NOT NULL,
    team_id INTEGER REFERENCES teams(id),
    jersey_number VARCHAR(10),
    position VARCHAR(10),
    is_active BOOLEAN DEFAULT true
);

-- teams table
CREATE TABLE teams (
    id SERIAL PRIMARY KEY,
    nba_team_id INTEGER UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL,
    abbreviation VARCHAR(3) NOT NULL,
    conference VARCHAR(50),
    division VARCHAR(50)
);
```

**Option 2: Denormalized**
```sql
-- players table with embedded team info
CREATE TABLE players (
    id SERIAL PRIMARY KEY,
    nba_player_id INTEGER UNIQUE NOT NULL,
    full_name VARCHAR(255) NOT NULL,
    team_abbreviation VARCHAR(3),
    team_name VARCHAR(255),
    jersey_number VARCHAR(10),
    position VARCHAR(10),
    is_active BOOLEAN DEFAULT true
);
```

### OPTIMIZATION SUGGESTIONS

1. **Add Database Index:**
```sql
CREATE INDEX idx_players_active ON players(is_active);
CREATE INDEX idx_players_team ON players(team_id);
```

2. **Add Caching (Redis example):**
```javascript
// Pseudo-code
const cacheKey = 'player_roster_v1';
const cachedData = await redis.get(cacheKey);

if (cachedData) {
    return JSON.parse(cachedData);
}

// Fetch from database
const data = await fetchPlayersFromDB();

// Cache for 1 hour
await redis.setex(cacheKey, 3600, JSON.stringify(data));

return data;
```

3. **Add ETags (optional):**
```javascript
// Generate ETag based on last_updated timestamp
const etag = generateETag(lastUpdatedTimestamp);
res.setHeader('ETag', etag);

if (req.headers['if-none-match'] === etag) {
    return res.status(304).send(); // Not Modified
}
```

### SAMPLE IMPLEMENTATION (Node.js/Express)

```javascript
// Route: GET /api/players/roster
router.get('/api/players/roster', async (req, res) => {
    try {
        // Query database
        const query = `
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
            ORDER BY p.full_name ASC
        `;
        
        const result = await db.query(query);
        
        // Build response
        const response = {
            season: "2025-26", // Update this dynamically based on current season
            updated_at: new Date().toISOString(),
            total_players: result.rows.length,
            players: result.rows.map(row => ({
                nba_player_id: row.nba_player_id,
                name: row.name,
                team_abbreviation: row.team_abbreviation,
                team_name: row.team_name,
                jersey_number: row.jersey_number || null,
                position: row.position || null
            }))
        };
        
        // Set cache headers
        res.setHeader('Cache-Control', 'public, max-age=3600');
        
        // Return response
        res.status(200).json(response);
        
    } catch (error) {
        console.error('Error fetching player roster:', error);
        res.status(500).json({ 
            error: 'Internal server error',
            message: 'Failed to fetch player roster'
        });
    }
});
```

### SAMPLE IMPLEMENTATION (Python/Flask)

```python
from flask import jsonify
from datetime import datetime
import pytz

@app.route('/api/players/roster', methods=['GET'])
def get_player_roster():
    try:
        # Query database
        query = """
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
            ORDER BY p.full_name ASC
        """
        
        cursor = db.cursor()
        cursor.execute(query)
        rows = cursor.fetchall()
        
        # Build player list
        players = []
        for row in rows:
            players.append({
                'nba_player_id': row[0],
                'name': row[1],
                'team_abbreviation': row[2],
                'team_name': row[3],
                'jersey_number': row[4] if row[4] else None,
                'position': row[5] if row[5] else None
            })
        
        # Build response
        response = {
            'season': '2025-26',  # Update dynamically
            'updated_at': datetime.now(pytz.UTC).isoformat(),
            'total_players': len(players),
            'players': players
        }
        
        # Return with cache headers
        resp = jsonify(response)
        resp.headers['Cache-Control'] = 'public, max-age=3600'
        return resp, 200
        
    except Exception as e:
        print(f'Error fetching player roster: {e}')
        return jsonify({
            'error': 'Internal server error',
            'message': 'Failed to fetch player roster'
        }), 500
```

### VALIDATION CHECKLIST

After implementation, verify:

- [ ] Endpoint is accessible at `GET /api/players/roster`
- [ ] Response is valid JSON
- [ ] All required fields are present
- [ ] `nba_player_id` is an integer for all players
- [ ] `team_abbreviation` is 3 letters and uppercase
- [ ] `total_players` matches array length
- [ ] `updated_at` is ISO 8601 format with timezone
- [ ] Response time is < 500ms
- [ ] HTTP status is 200 for success
- [ ] No sensitive data is exposed
- [ ] Works with CORS if needed for web clients

### DEPLOYMENT

1. Deploy the new endpoint to your backend
2. Test with curl/Postman
3. Verify a few players' data is accurate
4. Monitor logs for errors
5. Check performance/response time
6. Notify iOS team that endpoint is live

### MONITORING

Add logging to track:
- Number of requests per day
- Average response time
- Any errors or failed queries
- Cache hit rate (if implemented)

### FUTURE ENHANCEMENTS (Optional)

1. **Pagination** - If roster grows beyond 1000 players
2. **Filtering** - `?team=GSW` to get players by team
3. **Versioning** - `/api/v1/players/roster`
4. **WebSocket updates** - Push notifications when roster changes
5. **Rate limiting** - Prevent abuse

---

## DELIVERABLES

Please provide:

1. **Code** - Complete implementation in your backend framework
2. **Database Migration** - If any schema changes needed
3. **Test Results** - curl output showing the response
4. **Documentation** - Any setup notes or environment variables needed
5. **Performance Stats** - Response time and any optimizations made

---

## QUESTIONS TO ANSWER

Before implementing, please confirm:

1. What backend framework are you using? (Express, Flask, FastAPI, etc.)
2. What database are you using? (PostgreSQL, MySQL, MongoDB, etc.)
3. What are your exact table names and column names?
4. Do you have an `is_active` or similar field to filter active players?
5. Do you have the `nba_player_id` field stored? (This is critical)
6. What is your current season? (For the `season` field in response)

---

## IMPORTANT NOTES

1. **The `nba_player_id` field is CRITICAL** - This is the permanent identifier used by iOS widgets. Do not confuse this with your internal database `id` field.

2. **Team abbreviations must be uppercase** - iOS expects "GSW", not "gsw"

3. **Only active players** - Do not include players who are free agents, retired, or injured-out-for-season unless they're still technically on a roster

4. **Performance matters** - iOS widgets will call this endpoint. Keep response time under 500ms.

5. **JSON format must match exactly** - The iOS code expects these exact field names. Do not rename fields.

---

## SUCCESS CRITERIA

Implementation is successful when:

✅ `curl https://boxscore-backend.onrender.com/api/players/roster` returns valid JSON
✅ Response includes all active NBA players (~500-600 players)
✅ Every player has a valid `nba_player_id`
✅ Team abbreviations are correct and uppercase
✅ Response time is consistently < 500ms
✅ No errors in server logs

---

## EXAMPLE EXPECTED OUTPUT

```json
{
  "season": "2025-26",
  "updated_at": "2025-12-11T18:30:00.000Z",
  "total_players": 526,
  "players": [
    {
      "nba_player_id": 1630639,
      "name": "A.J. Lawson",
      "team_abbreviation": "TOR",
      "team_name": "Toronto Raptors",
      "jersey_number": "0",
      "position": "G"
    },
    {
      "nba_player_id": 1631260,
      "name": "AJ Green",
      "team_abbreviation": "MIL",
      "team_name": "Milwaukee Bucks",
      "jersey_number": "20",
      "position": "G"
    },
    {
      "nba_player_id": 203932,
      "name": "Aaron Gordon",
      "team_abbreviation": "DEN",
      "team_name": "Denver Nuggets",
      "jersey_number": "32",
      "position": "F"
    }
    // ... 523 more players
  ]
}
```

---

## READY TO IMPLEMENT?

Please implement this endpoint following the specifications above. Let me know if you have any questions about the requirements!

