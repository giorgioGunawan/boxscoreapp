#!/bin/bash

# Script to add home screen and lock screen tutorial images to Assets.xcassets
# Place your tutorial images in the 'home-tutorial-images' and 'lock-tutorial-images' folders
# Home screen images: home_step_1.png, home_step_2.png, ..., home_step_7.png
# Lock screen images: lock_step_1.png, lock_step_2.png, ..., lock_step_9.png

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Directories
HOME_SOURCE_DIR="home-tutorial-images"
LOCK_SOURCE_DIR="lock-tutorial-images"
ASSETS_DIR="gridnextapp/Assets.xcassets"

echo -e "${BLUE}📱 Tutorial Images Installer${NC}"
echo "============================"

# Check if assets directory exists
if [ ! -d "$ASSETS_DIR" ]; then
    echo -e "${RED}❌ Error: $ASSETS_DIR directory not found!${NC}"
    echo "Make sure you're running this script from the project root."
    exit 1
fi

# List of expected tutorial images
declare -a HOME_TUTORIAL_IMAGES=(
    "home_step_1"
    "home_step_2"
    "home_step_3"
    "home_step_4"
    "home_step_5"
    "home_step_6"
    "home_step_7"
)

declare -a LOCK_TUTORIAL_IMAGES=(
    "lock_step_1"
    "lock_step_2"
    "lock_step_3"
    "lock_step_4"
    "lock_step_5"
    "lock_step_6"
    "lock_step_7"
    "lock_step_8"
    "lock_step_9"
)

echo -e "${YELLOW}📋 Expected home screen tutorial images:${NC}"
for image in "${HOME_TUTORIAL_IMAGES[@]}"; do
    echo "  • $image.png"
done
echo ""

echo -e "${YELLOW}📋 Expected lock screen tutorial images:${NC}"
for image in "${LOCK_TUTORIAL_IMAGES[@]}"; do
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

# Process home screen images
home_processed_count=0

echo -e "${YELLOW}🏠 Processing Home Screen Tutorial Images...${NC}"

if [ -d "$HOME_SOURCE_DIR" ] && [ -n "$(ls -A $HOME_SOURCE_DIR 2>/dev/null)" ]; then
    for image_name in "${HOME_TUTORIAL_IMAGES[@]}"; do
        # Look for the image file (png, jpg, jpeg)
        found_file=""
        for ext in png PNG jpg JPG jpeg JPEG; do
            if [ -f "$HOME_SOURCE_DIR/${image_name}.${ext}" ]; then
                found_file="$HOME_SOURCE_DIR/${image_name}.${ext}"
                break
            fi
        done
        
        if [ -n "$found_file" ]; then
            create_imageset "$image_name" "$found_file"
            ((home_processed_count++))
        else
            echo -e "${YELLOW}⚠️  Missing: ${image_name}.png${NC}"
        fi
    done
else
    echo -e "${YELLOW}⚠️  No home screen tutorial images found in $HOME_SOURCE_DIR${NC}"
fi

echo ""

# Process lock screen images
lock_processed_count=0

echo -e "${YELLOW}🔒 Processing Lock Screen Tutorial Images...${NC}"

if [ -d "$LOCK_SOURCE_DIR" ] && [ -n "$(ls -A $LOCK_SOURCE_DIR 2>/dev/null)" ]; then
    for image_name in "${LOCK_TUTORIAL_IMAGES[@]}"; do
        # Look for the image file (png, jpg, jpeg)
        found_file=""
        for ext in png PNG jpg JPG jpeg JPEG; do
            if [ -f "$LOCK_SOURCE_DIR/${image_name}.${ext}" ]; then
                found_file="$LOCK_SOURCE_DIR/${image_name}.${ext}"
                break
            fi
        done
        
        if [ -n "$found_file" ]; then
            create_imageset "$image_name" "$found_file"
            ((lock_processed_count++))
        else
            echo -e "${YELLOW}⚠️  Missing: ${image_name}.png${NC}"
        fi
    done
else
    echo -e "${YELLOW}⚠️  No lock screen tutorial images found in $LOCK_SOURCE_DIR${NC}"
fi

echo ""
echo -e "${GREEN}🎉 Processing complete!${NC}"
echo "  • Home Screen: $home_processed_count/7 tutorial images"
echo "  • Lock Screen: $lock_processed_count/9 tutorial images"

total_processed=$((home_processed_count + lock_processed_count))

if [ $total_processed -gt 0 ]; then
    echo ""
    echo -e "${BLUE}📱 Next steps:${NC}"
    echo "1. Open your Xcode project"
    echo "2. The tutorial images are now available in your app"
    echo "3. Your tutorial should now display the images!"
    echo ""
    echo -e "${GREEN}✨ Tutorial images successfully added!${NC}"
else
    echo ""
    echo -e "${BLUE}📝 To add tutorial images:${NC}"
    echo "1. Create folders: mkdir $HOME_SOURCE_DIR $LOCK_SOURCE_DIR"
    echo "2. Add your home screen tutorial images to $HOME_SOURCE_DIR/"
    echo "3. Add your lock screen tutorial images to $LOCK_SOURCE_DIR/"
    echo "4. Run this script again: ./add_tutorial_images.sh"
    echo ""
fi 