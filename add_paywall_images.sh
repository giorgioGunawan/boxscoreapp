#!/bin/bash

# Script to add paywall background images to Assets.xcassets
# Place your paywall images in the 'paywall-images' folder
# Expected images: paywall_background.png

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Directories
SOURCE_DIR="paywall-images"
ASSETS_DIR="gridnextapp/Assets.xcassets"

echo -e "${BLUE}💳 Paywall Images Installer${NC}"
echo "=========================="

# Check if assets directory exists
if [ ! -d "$ASSETS_DIR" ]; then
    echo -e "${RED}❌ Error: $ASSETS_DIR directory not found!${NC}"
    echo "Make sure you're running this script from the project root."
    exit 1
fi

# List of expected paywall images
declare -a PAYWALL_IMAGES=(
    "paywall_background"
)

echo -e "${YELLOW}📋 Expected paywall images:${NC}"
for image in "${PAYWALL_IMAGES[@]}"; do
    echo "  • $image.png"
done
echo ""

# Function to create imageset
create_imageset() {
    local image_name="$1"
    local source_file="$2"
    local imageset_dir="$ASSETS_DIR/${image_name}.imageset"
    
    echo -e "${BLUE}📁 Creating imageset for: $image_name${NC}"
    
    # Create imageset directory
    mkdir -p "$imageset_dir"
    
    # Get file extension
    extension="${source_file##*.}"
    
    # Copy image file
    cp "$source_file" "$imageset_dir/${image_name}.${extension}"
    
    # Create Contents.json
    cat > "$imageset_dir/Contents.json" << EOF
{
  "images" : [
    {
      "filename" : "${image_name}.${extension}",
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
    
    echo -e "${GREEN}✅ Created: $imageset_dir${NC}"
}

# Process paywall images
processed_count=0

echo -e "${YELLOW}💳 Processing Paywall Images...${NC}"

if [ -d "$SOURCE_DIR" ] && [ -n "$(ls -A $SOURCE_DIR 2>/dev/null)" ]; then
    for image_name in "${PAYWALL_IMAGES[@]}"; do
        # Look for the image file (png, jpg, jpeg)
        found_file=""
        for ext in png PNG jpg JPG jpeg JPEG; do
            if [ -f "$SOURCE_DIR/${image_name}.${ext}" ]; then
                found_file="$SOURCE_DIR/${image_name}.${ext}"
                break
            fi
        done
        
        if [ -n "$found_file" ]; then
            create_imageset "$image_name" "$found_file"
            ((processed_count++))
        else
            echo -e "${YELLOW}⚠️  Missing: ${image_name}.png${NC}"
        fi
    done
else
    echo -e "${YELLOW}⚠️  No paywall images found in $SOURCE_DIR${NC}"
fi

echo ""
echo -e "${GREEN}🎉 Processing complete!${NC}"
echo "  • Processed: $processed_count/1 paywall images"

if [ $processed_count -gt 0 ]; then
    echo ""
    echo -e "${BLUE}📱 Next steps:${NC}"
    echo "1. Open your Xcode project"
    echo "2. The paywall background image is now available in your app"
    echo "3. Your paywalls should now display the background image!"
    echo ""
    echo -e "${GREEN}✨ Paywall images successfully added!${NC}"
else
    echo ""
    echo -e "${BLUE}📝 To add paywall images:${NC}"
    echo "1. Create folder: mkdir $SOURCE_DIR"
    echo "2. Add your paywall background image: paywall_background.png"
    echo "3. Run this script again: ./add_paywall_images.sh"
    echo ""
fi 