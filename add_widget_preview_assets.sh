#!/bin/bash

# Script to add widget preview images to Assets.xcassets
# Place your widget preview images in the 'widget-preview-images' folder
# Images should be named exactly as they appear in your ContentView.swift imageName properties

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Directories
SOURCE_DIR="widget-preview-images"
ASSETS_DIR="gridnextapp/Assets.xcassets"

echo -e "${BLUE}🏎️  F1 Widget Preview Assets Installer${NC}"
echo "=================================="

# Check if source directory exists
if [ ! -d "$SOURCE_DIR" ]; then
    echo -e "${RED}❌ Error: $SOURCE_DIR directory not found!${NC}"
    echo "Please create the directory and add your widget preview images there."
    exit 1
fi

# Check if assets directory exists
if [ ! -d "$ASSETS_DIR" ]; then
    echo -e "${RED}❌ Error: $ASSETS_DIR directory not found!${NC}"
    echo "Make sure you're running this script from the project root."
    exit 1
fi

# List of expected widget preview images based on ContentView.swift
declare -a EXPECTED_IMAGES=(
    "next_race_small_preview"
    "next_race_medium_preview"
    "next_race_complete_preview"
    "next_race_compact_preview"
    "next_race_countdown_preview"
    "race_result_small_preview"
    "race_result_medium_preview"
    "race_result_lockscreen_preview"
    "driver_small_preview"
    "driver_medium_preview"
    "driver_lockscreen_preview"
    "constructor_small_preview"
    "constructor_medium_preview"
    "constructor_lockscreen_preview"
    "top3_drivers_preview"
    "top3_constructors_preview"
    "home_step1_longpress"
    "home_step2_plus_button"
    "home_step3_search"
    "home_step4_choose_size"
    "home_step5_add_widget"
    "home_step6_customize"
    "lock_step1_lock_screen"
    "lock_step2_longpress"
    "lock_step3_customize"
    "lock_step4_choose_lockscreen"
    "lock_step5_add_widgets"
    "lock_step6_select_widget"
    "lock_step7_done"
)

echo -e "${YELLOW}📋 Expected widget preview images:${NC}"
for image in "${EXPECTED_IMAGES[@]}"; do
    echo "  • $image"
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

# Process images
processed_count=0
skipped_count=0

echo -e "${YELLOW}🔍 Scanning for images in $SOURCE_DIR...${NC}"

# Check for images in source directory
if [ -z "$(ls -A $SOURCE_DIR 2>/dev/null)" ]; then
    echo -e "${YELLOW}⚠️  No images found in $SOURCE_DIR${NC}"
    echo ""
    echo -e "${BLUE}📝 To add widget preview images:${NC}"
    echo "1. Add your images to the '$SOURCE_DIR' folder"
    echo "2. Name them exactly as shown in the list above"
    echo "3. Supported formats: PNG, JPG, JPEG"
    echo "4. Run this script again"
    echo ""
    exit 0
fi

# Process each image file in source directory
for file in "$SOURCE_DIR"/*; do
    if [ -f "$file" ]; then
        filename=$(basename "$file")
        name_without_ext="${filename%.*}"
        extension="${filename##*.}"
        
        # Check if it's a supported image format
        if [[ "$extension" =~ ^(png|jpg|jpeg|PNG|JPG|JPEG)$ ]]; then
            # Check if this image is expected
            if [[ " ${EXPECTED_IMAGES[@]} " =~ " ${name_without_ext} " ]]; then
                create_imageset "$name_without_ext" "$file"
                ((processed_count++))
            else
                echo -e "${YELLOW}⚠️  Skipping unexpected image: $filename${NC}"
                echo "   (Not in expected list - check spelling)"
                ((skipped_count++))
            fi
        else
            echo -e "${YELLOW}⚠️  Skipping unsupported file: $filename${NC}"
            echo "   (Supported formats: PNG, JPG, JPEG)"
            ((skipped_count++))
        fi
    fi
done

echo ""
echo -e "${GREEN}🎉 Processing complete!${NC}"
echo "  • Processed: $processed_count images"
echo "  • Skipped: $skipped_count files"

if [ $processed_count -gt 0 ]; then
    echo ""
    echo -e "${BLUE}📱 Next steps:${NC}"
    echo "1. Open your Xcode project"
    echo "2. The images are now available in your app"
    echo "3. You can reference them by name in your SwiftUI code"
    echo ""
    echo -e "${GREEN}✨ Your widget previews should now display properly!${NC}"
fi

# Show missing images
missing_images=()
for expected in "${EXPECTED_IMAGES[@]}"; do
    found=false
    for file in "$SOURCE_DIR"/*; do
        if [ -f "$file" ]; then
            filename=$(basename "$file")
            name_without_ext="${filename%.*}"
            if [ "$name_without_ext" = "$expected" ]; then
                found=true
                break
            fi
        fi
    done
    if [ "$found" = false ]; then
        missing_images+=("$expected")
    fi
done

if [ ${#missing_images[@]} -gt 0 ]; then
    echo ""
    echo -e "${YELLOW}📋 Still missing these images:${NC}"
    for missing in "${missing_images[@]}"; do
        echo "  • $missing"
    done
    echo ""
    echo -e "${BLUE}💡 Tip: Add these images to '$SOURCE_DIR' and run the script again${NC}"
fi 