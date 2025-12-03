# F1 Widget Assets Guide

This document explains how to organize and add F1 team logos and driver helmet assets to your iOS project.

## 📁 Asset Organization

The project uses the following directory structure for assets:

```
gridnextapp/
├── team-logos-full/          # Full-size team logos
├── team-logos-compact/       # Compact/small team logos  
├── driver-helmets/           # Driver helmet images
└── gridnextapp/
    └── Assets.xcassets/      # iOS Asset Catalog
```

## 🛠️ Installation Script

Use the provided bash script to automatically add assets to your Xcode project:

```bash
./add_team_and_driver_assets.sh
```

## 🏎️ Asset Types

### 1. Team Logos (Full)
**Directory**: `team-logos-full/`
**Purpose**: Large, detailed team logos for prominent display
**Usage**: Main screens, headers, detailed views

**Naming Convention**:
- `redbull.png` - Red Bull Racing
- `ferrari.png` - Ferrari
- `mercedes.png` - Mercedes
- `mclaren.png` - McLaren
- `astonmartin.png` - Aston Martin
- `alpine.png` - Alpine
- `williams.png` - Williams
- `rb.png` - RB (AlphaTauri)
- `haas.png` - Haas
- `kicksauber.png` - Kick Sauber

### 2. Team Logos (Compact)
**Directory**: `team-logos-compact/`
**Purpose**: Small, simplified team logos for widgets and compact displays
**Usage**: Widget overlays, small indicators, lists

**Naming Convention**: Same as full logos but optimized for small sizes

### 3. Driver Helmets
**Directory**: `driver-helmets/`
**Purpose**: Driver helmet images with numbers
**Usage**: Driver identification, standings, results

**Naming Convention** (either format works):
- **By Name**: `verstappen.png`, `leclerc.png`, `hamilton.png`
- **By Number**: `1.png`, `16.png`, `44.png`

**Current F1 Drivers (2025 Season)**:
| Number | Name | Code | Team | File Name |
|--------|------|------|------|-----------|
| 81 | Oscar Piastri | PIA | McLaren | `piastri.png` or `81.png` |
| 4 | Lando Norris | NOR | McLaren | `norris.png` or `4.png` |
| 1 | Max Verstappen | VER | Red Bull Racing | `verstappen.png` or `1.png` |
| 63 | George Russell | RUS | Mercedes | `russell.png` or `63.png` |
| 16 | Charles Leclerc | LEC | Ferrari | `leclerc.png` or `16.png` |
| 44 | Lewis Hamilton | HAM | Ferrari | `hamilton.png` or `44.png` |
| 12 | Kimi Antonelli | ANT | Mercedes | `antonelli.png` or `12.png` |
| 23 | Alexander Albon | ALB | Williams | `albon.png` or `23.png` |
| 6 | Isack Hadjar | HAD | RB | `hadjar.png` or `6.png` |
| 31 | Esteban Ocon | OCO | Haas | `ocon.png` or `31.png` |
| 27 | Nico Hulkenberg | HUL | Kick Sauber | `hulkenberg.png` or `27.png` |
| 18 | Lance Stroll | STR | Aston Martin | `stroll.png` or `18.png` |
| 55 | Carlos Sainz | SAI | Williams | `sainz.png` or `55.png` |
| 10 | Pierre Gasly | GAS | Alpine | `gasly.png` or `10.png` |
| 22 | Yuki Tsunoda | TSU | Red Bull Racing | `tsunoda.png` or `22.png` |
| 87 | Oliver Bearman | BEA | Haas | `bearman.png` or `87.png` |
| 30 | Liam Lawson | LAW | RB | `lawson.png` or `30.png` |
| 14 | Fernando Alonso | ALO | Aston Martin | `alonso.png` or `14.png` |
| 43 | Franco Colapinto | COL | Alpine | `colapinto.png` or `43.png` |
| 5 | Gabriel Bortoleto | BOR | Kick Sauber | `bortoleto.png` or `5.png` |

## 📋 Usage Instructions

### Step 1: Prepare Your Assets
1. Place your asset files in the appropriate directories:
   - Full team logos → `team-logos-full/`
   - Compact team logos → `team-logos-compact/`
   - Driver helmets → `driver-helmets/`

### Step 2: Run the Installation Script
```bash
./add_team_and_driver_assets.sh
```

### Step 3: Verify in Xcode
1. Open your Xcode project
2. Navigate to `gridnextapp/Assets.xcassets`
3. Verify the new imagesets appear:
   - `team-logo-full-redbull.imageset`
   - `team-logo-compact-ferrari.imageset`
   - `driver-helmet-verstappen.imageset`

## 🎨 Recommended Asset Specifications

### Team Logos (Full)
- **Format**: PNG with transparency
- **Size**: 512x512px or larger
- **Quality**: High resolution for retina displays

### Team Logos (Compact)
- **Format**: PNG with transparency
- **Size**: 128x128px - 256x256px
- **Quality**: Optimized for small display sizes

### Driver Helmets
- **Format**: PNG with transparency
- **Size**: 256x256px - 512x512px
- **Style**: Side or 3/4 view showing helmet design and number
- **Quality**: High resolution with clear number visibility

## 🔧 Accessing Assets in Code

Once installed, access assets in your Swift code:

```swift
// Team logos
Image("team-logo-full-redbull")
Image("team-logo-compact-ferrari")

// Driver helmets
Image("driver-helmet-verstappen")
Image("driver-helmet-leclerc")
```

## 🔄 Updating Assets

To update existing assets:
1. Replace files in the source directories
2. Run the script again: `./add_team_and_driver_assets.sh`
3. The script will overwrite existing imagesets

## ⚠️ Important Notes

- **File Formats**: Support PNG, JPG, JPEG
- **Naming**: Use lowercase names with no spaces
- **Transparency**: PNG recommended for logos with transparent backgrounds
- **Performance**: Compact logos should be optimized for file size
- **Consistency**: Maintain consistent aspect ratios within each category 