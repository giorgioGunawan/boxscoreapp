#!/bin/bash

# F1 Team and Driver Assets Installer
# This script adds team logos (full & compact) and driver helmets to the iOS project

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Asset directories
ASSETS_DIR="gridnextapp/Assets.xcassets"
TEAM_LOGOS_FULL_DIR="team-logos-full"
TEAM_LOGOS_COMPACT_DIR="team-logos-compact"
DRIVER_HELMETS_DIR="driver-helmets"

# Function to create imageset
create_imageset() {
    local imageset_dir="$1"
    local image_file="$2"
    local image_name="$3"
    
    mkdir -p "$imageset_dir"
    
    # Copy image file
    if [ -f "$image_file" ]; then
        cp "$image_file" "$imageset_dir/"
        echo -e "${GREEN}✓${NC} Copied $image_name"
    else
        echo -e "${RED}✗${NC} Image not found: $image_file"
        return 1
    fi
    
    # Create Contents.json
    local filename=$(basename "$image_file")
    cat > "$imageset_dir/Contents.json" << EOF
{
  "images" : [
    {
      "filename" : "$filename",
      "idiom" : "universal",
      "scale" : "1x"
    },
    {
      "idiom" : "universal",
      "scale" : "2x"
    },
    {
      "idiom" : "universal",
      "scale" : "3x"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
EOF
}

# Function to process team logos (full)
add_team_logos_full() {
    echo -e "${BLUE}📁 Adding Full Team Logos...${NC}"
    
    # F1 Teams
    local teams=(
        "redbull:red-bull-racing"
        "ferrari:ferrari"
        "mercedes:mercedes"
        "mclaren:mclaren"
        "astonmartin:aston-martin"
        "alpine:alpine"
        "williams:williams"
        "rb:rb"
        "haas:haas-f1-team"
        "kicksauber:kick-sauber"
    )
    
    for team_info in "${teams[@]}"; do
        IFS=':' read -r team_key team_name <<< "$team_info"
        
        # Look for common image formats
        for ext in png jpg jpeg PNG JPG JPEG; do
            image_file="$TEAM_LOGOS_FULL_DIR/${team_key}.$ext"
            if [ -f "$image_file" ]; then
                imageset_dir="$ASSETS_DIR/team-logo-full-${team_key}.imageset"
                create_imageset "$imageset_dir" "$image_file" "Full Logo: $team_name"
                break
            fi
        done
        
        # Check if no image was found
        found=false
        for ext in png jpg jpeg PNG JPG JPEG; do
            [ -f "$TEAM_LOGOS_FULL_DIR/${team_key}.$ext" ] && found=true && break
        done
        
        if [ "$found" = false ]; then
            echo -e "${YELLOW}⚠${NC} No full logo found for $team_name (expected: ${team_key}.png/jpg)"
        fi
    done
}

# Function to process team logos (compact)
add_team_logos_compact() {
    echo -e "${BLUE}📁 Adding Compact Team Logos...${NC}"
    
    # F1 Teams
    local teams=(
        "redbull:red-bull-racing"
        "ferrari:ferrari"
        "mercedes:mercedes"
        "mclaren:mclaren"
        "astonmartin:aston-martin"
        "alpine:alpine"
        "williams:williams"
        "rb:rb"
        "haas:haas-f1-team"
        "kicksauber:kick-sauber"
    )
    
    for team_info in "${teams[@]}"; do
        IFS=':' read -r team_key team_name <<< "$team_info"
        
        # Look for common image formats
        for ext in png jpg jpeg PNG JPG JPEG; do
            image_file="$TEAM_LOGOS_COMPACT_DIR/${team_key}.$ext"
            if [ -f "$image_file" ]; then
                imageset_dir="$ASSETS_DIR/team-logo-compact-${team_key}.imageset"
                create_imageset "$imageset_dir" "$image_file" "Compact Logo: $team_name"
                break
            fi
        done
        
        # Check if no image was found
        found=false
        for ext in png jpg jpeg PNG JPG JPEG; do
            [ -f "$TEAM_LOGOS_COMPACT_DIR/${team_key}.$ext" ] && found=true && break
        done
        
        if [ "$found" = false ]; then
            echo -e "${YELLOW}⚠${NC} No compact logo found for $team_name (expected: ${team_key}.png/jpg)"
        fi
    done
}

# Function to process driver helmets
add_driver_helmets() {
    echo -e "${BLUE}🏎️ Adding Driver Helmets...${NC}"
    
    # F1 Drivers 2025 Season with their numbers and teams
    local drivers=(
        "81:piastri:PIA:Oscar Piastri"
        "4:norris:NOR:Lando Norris"
        "1:verstappen:VER:Max Verstappen"
        "63:russell:RUS:George Russell"
        "16:leclerc:LEC:Charles Leclerc"
        "44:hamilton:HAM:Lewis Hamilton"
        "12:antonelli:ANT:Kimi Antonelli"
        "23:albon:ALB:Alexander Albon"
        "6:hadjar:HAD:Isack Hadjar"
        "31:ocon:OCO:Esteban Ocon"
        "27:hulkenberg:HUL:Nico Hulkenberg"
        "18:stroll:STR:Lance Stroll"
        "55:sainz:SAI:Carlos Sainz"
        "10:gasly:GAS:Pierre Gasly"
        "22:tsunoda:TSU:Yuki Tsunoda"
        "87:bearman:BEA:Oliver Bearman"
        "30:lawson:LAW:Liam Lawson"
        "14:alonso:ALO:Fernando Alonso"
        "43:colapinto:COL:Franco Colapinto"
        "5:bortoleto:BOR:Gabriel Bortoleto"
    )
    
    for driver_info in "${drivers[@]}"; do
        IFS=':' read -r number key display_code full_name <<< "$driver_info"
        
        # Look for common image formats
        for ext in png jpg jpeg PNG JPG JPEG; do
            image_file="$DRIVER_HELMETS_DIR/${key}.$ext"
            if [ -f "$image_file" ]; then
                imageset_dir="$ASSETS_DIR/driver-helmet-${key}.imageset"
                create_imageset "$imageset_dir" "$image_file" "Helmet: $full_name (#$number)"
                break
            fi
        done
        
        # Also check for number-based naming
        for ext in png jpg jpeg PNG JPG JPEG; do
            image_file="$DRIVER_HELMETS_DIR/${number}.$ext"
            if [ -f "$image_file" ]; then
                imageset_dir="$ASSETS_DIR/driver-helmet-${key}.imageset"
                create_imageset "$imageset_dir" "$image_file" "Helmet: $full_name (#$number)"
                break
            fi
        done
        
        # Check if no image was found
        found=false
        for ext in png jpg jpeg PNG JPG JPEG; do
            [ -f "$DRIVER_HELMETS_DIR/${key}.$ext" ] && found=true && break
            [ -f "$DRIVER_HELMETS_DIR/${number}.$ext" ] && found=true && break
        done
        
        if [ "$found" = false ]; then
            echo -e "${YELLOW}⚠${NC} No helmet found for $full_name (expected: ${key}.$ext or ${number}.$ext)"
        fi
    done
}

# Main execution
echo -e "${GREEN}🏁 F1 Team and Driver Assets Installer${NC}"
echo "======================================"

# Check if assets directory exists
if [ ! -d "$ASSETS_DIR" ]; then
    echo -e "${RED}Error: Assets directory not found: $ASSETS_DIR${NC}"
    exit 1
fi

# Create directories if they don't exist
mkdir -p "$TEAM_LOGOS_FULL_DIR" "$TEAM_LOGOS_COMPACT_DIR" "$DRIVER_HELMETS_DIR"

echo -e "${BLUE}📋 Asset Directories:${NC}"
echo "  • Full Team Logos: $TEAM_LOGOS_FULL_DIR/"
echo "  • Compact Team Logos: $TEAM_LOGOS_COMPACT_DIR/"
echo "  • Driver Helmets: $DRIVER_HELMETS_DIR/"
echo ""

# Process assets
add_team_logos_full
echo ""
add_team_logos_compact  
echo ""
add_driver_helmets

echo ""
echo -e "${GREEN}✅ Asset installation complete!${NC}"
echo ""
echo -e "${YELLOW}📝 Next Steps:${NC}"
echo "1. Place your asset files in the appropriate directories:"
echo "   • $TEAM_LOGOS_FULL_DIR/ - Full team logos (redbull.png, ferrari.png, etc.)"
echo "   • $TEAM_LOGOS_COMPACT_DIR/ - Compact team logos (redbull.png, ferrari.png, etc.)"
echo "   • $DRIVER_HELMETS_DIR/ - Driver helmets (verstappen.png, leclerc.png, etc.)"
echo "2. Run this script again to install them"
echo "3. Open Xcode and verify the assets appear in Assets.xcassets"
echo ""
echo -e "${BLUE}💡 Supported formats:${NC} PNG, JPG, JPEG"
echo -e "${BLUE}💡 Naming conventions:${NC}"
echo "   • Teams: redbull, ferrari, mercedes, mclaren, astonmartin, alpine, williams, rb, haas, kicksauber"
echo "   • Drivers (2025): piastri, norris, verstappen, russell, leclerc, hamilton, antonelli, etc."
echo "   • Or by number: 81, 4, 1, 63, 16, 44, 12, etc." 