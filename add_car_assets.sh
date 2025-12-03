#!/bin/bash

# F1 Car Assets Installer
# This script adds F1 car images to the iOS project

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Asset directories
ASSETS_DIR="gridnextapp/Assets.xcassets"
CARS_DIR="f1-cars"

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

# Function to process F1 car images
add_f1_cars() {
    echo -e "${BLUE}🏎️ Adding F1 Car Images...${NC}"
    
    # F1 Teams with their car identifiers
    local teams=(
        "redbull:Red Bull Racing"
        "ferrari:Ferrari"
        "mercedes:Mercedes"
        "mclaren:McLaren"
        "astonmartin:Aston Martin"
        "alpine:Alpine"
        "williams:Williams"
        "rb:RB"
        "haas:Haas F1 Team"
        "kicksauber:Kick Sauber"
    )
    
    for team_info in "${teams[@]}"; do
        IFS=':' read -r team_key team_name <<< "$team_info"
        
        # Look for common image formats
        for ext in png jpg jpeg PNG JPG JPEG; do
            image_file="$CARS_DIR/${team_key}.$ext"
            if [ -f "$image_file" ]; then
                imageset_dir="$ASSETS_DIR/f1-car-${team_key}.imageset"
                create_imageset "$imageset_dir" "$image_file" "F1 Car: $team_name"
                break
            fi
        done
        
        # Also check for alternative naming patterns
        for ext in png jpg jpeg PNG JPG JPEG; do
            # Try with 2025 suffix
            image_file="$CARS_DIR/${team_key}-2025.$ext"
            if [ -f "$image_file" ]; then
                imageset_dir="$ASSETS_DIR/f1-car-${team_key}.imageset"
                create_imageset "$imageset_dir" "$image_file" "F1 Car: $team_name (2025)"
                break
            fi
        done
        
        # Check if no image was found
        found=false
        for ext in png jpg jpeg PNG JPG JPEG; do
            [ -f "$CARS_DIR/${team_key}.$ext" ] && found=true && break
            [ -f "$CARS_DIR/${team_key}-2025.$ext" ] && found=true && break
        done
        
        if [ "$found" = false ]; then
            echo -e "${YELLOW}⚠${NC} No car image found for $team_name (expected: ${team_key}.png/jpg or ${team_key}-2025.png/jpg)"
        fi
    done
}

# Main execution
echo -e "${BLUE}🏁 F1 Car Assets Installer${NC}"
echo -e "${BLUE}================================${NC}"

# Check if assets directory exists
if [ ! -d "$ASSETS_DIR" ]; then
    echo -e "${RED}✗${NC} Assets directory not found: $ASSETS_DIR"
    echo -e "${YELLOW}Make sure you're running this script from the project root directory.${NC}"
    exit 1
fi

# Check if cars directory exists
if [ ! -d "$CARS_DIR" ]; then
    echo -e "${YELLOW}⚠${NC} Cars directory not found: $CARS_DIR"
    echo -e "${YELLOW}Creating directory structure...${NC}"
    mkdir -p "$CARS_DIR"
    echo -e "${GREEN}✓${NC} Created $CARS_DIR directory"
    echo ""
    echo -e "${BLUE}📁 Please add your F1 car images to the '$CARS_DIR' directory with these naming conventions:${NC}"
    echo -e "${YELLOW}   • redbull.png (or .jpg)${NC}"
    echo -e "${YELLOW}   • ferrari.png (or .jpg)${NC}"
    echo -e "${YELLOW}   • mercedes.png (or .jpg)${NC}"
    echo -e "${YELLOW}   • mclaren.png (or .jpg)${NC}"
    echo -e "${YELLOW}   • astonmartin.png (or .jpg)${NC}"
    echo -e "${YELLOW}   • alpine.png (or .jpg)${NC}"
    echo -e "${YELLOW}   • williams.png (or .jpg)${NC}"
    echo -e "${YELLOW}   • rb.png (or .jpg)${NC}"
    echo -e "${YELLOW}   • haas.png (or .jpg)${NC}"
    echo -e "${YELLOW}   • kicksauber.png (or .jpg)${NC}"
    echo ""
    echo -e "${BLUE}Alternative naming with year suffix is also supported:${NC}"
    echo -e "${YELLOW}   • redbull-2025.png, ferrari-2025.png, etc.${NC}"
    echo ""
    echo -e "${GREEN}After adding the images, run this script again to install them.${NC}"
    exit 0
fi

echo -e "${GREEN}✓${NC} Found assets directory: $ASSETS_DIR"
echo -e "${GREEN}✓${NC} Found cars directory: $CARS_DIR"
echo ""

# Add car images
add_f1_cars

echo ""
echo -e "${GREEN}🏁 F1 Car Assets Installation Complete!${NC}"
echo ""
echo -e "${BLUE}📱 Usage in Swift code:${NC}"
echo -e "${YELLOW}   Image(\"f1-car-redbull\")${NC}"
echo -e "${YELLOW}   Image(\"f1-car-ferrari\")${NC}"
echo -e "${YELLOW}   Image(\"f1-car-mercedes\")${NC}"
echo -e "${YELLOW}   etc...${NC}"
echo ""
echo -e "${BLUE}💡 You can now use these car images in your F1RaceResult widgets!${NC}" 