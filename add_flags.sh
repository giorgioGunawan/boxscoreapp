#!/bin/bash

# Script to copy flag images to widget asset catalogs
# Usage: ./add_flags.sh

# Set script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FLAGS_DIR="$SCRIPT_DIR/flags"

# Target asset directories
F1_RACE_WIDGET_ASSETS="$SCRIPT_DIR/F1RaceWidget/Assets.xcassets"
F1_RACE_RESULT_ASSETS="$SCRIPT_DIR/F1RaceResult/Assets.xcassets"

# Function to create imageset for a flag
create_imageset() {
    local asset_dir="$1"
    local flag_file="$2"
    local flag_name="$3"
    
    # Create imageset directory
    local imageset_dir="$asset_dir/${flag_name}.imageset"
    mkdir -p "$imageset_dir"
    
    # Copy the flag image
    cp "$flag_file" "$imageset_dir/"
    
    # Get the filename
    local filename=$(basename "$flag_file")
    
    # Create Contents.json
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
    
    echo "✅ Added $flag_name to $(basename "$asset_dir")"
}

# Check if flags directory exists
if [ ! -d "$FLAGS_DIR" ]; then
    echo "❌ Error: flags/ directory not found in project root"
    echo "Create a flags/ directory and add your flag images (e.g., flag-us.png)"
    exit 1
fi

# Check if flag files exist
flag_count=$(find "$FLAGS_DIR" -name "flag-*.png" -o -name "flag-*.jpg" -o -name "flag-*.jpeg" | wc -l)
if [ $flag_count -eq 0 ]; then
    echo "❌ Error: No flag files found in flags/ directory"
    echo "Add flag files with pattern: flag-us.png, flag-gb.png, etc."
    exit 1
fi

echo "🏁 Adding flags to widget asset catalogs..."

# Process each flag file
for flag_file in "$FLAGS_DIR"/flag-*.{png,jpg,jpeg}; do
    # Skip if file doesn't exist (no glob matches)
    [ ! -f "$flag_file" ] && continue
    
    # Extract flag name (remove flag- prefix and extension)
    filename=$(basename "$flag_file")
    flag_name="flag-${filename#flag-}"
    flag_name="${flag_name%.*}"
    
    # Add to F1RaceWidget assets
    if [ -d "$F1_RACE_WIDGET_ASSETS" ]; then
        create_imageset "$F1_RACE_WIDGET_ASSETS" "$flag_file" "$flag_name"
    else
        echo "⚠️  Warning: F1RaceWidget/Assets.xcassets not found"
    fi
    
    # Add to F1RaceResult assets
    if [ -d "$F1_RACE_RESULT_ASSETS" ]; then
        create_imageset "$F1_RACE_RESULT_ASSETS" "$flag_file" "$flag_name"
    else
        echo "⚠️  Warning: F1RaceResult/Assets.xcassets not found"
    fi
done

echo ""
echo "🎉 Flag import complete!"
echo ""
echo "Flag naming reference:"
echo "flag-us.png  → United States (Austin, Las Vegas, Miami)"
echo "flag-gb.png  → Great Britain"
echo "flag-it.png  → Italy (Monza, Imola)" 
echo "flag-es.png  → Spain"
echo "flag-mc.png  → Monaco"
echo "flag-ca.png  → Canada"
echo "flag-at.png  → Austria"
echo "flag-hu.png  → Hungary"
echo "flag-be.png  → Belgium"
echo "flag-nl.png  → Netherlands"
echo "flag-az.png  → Azerbaijan"
echo "flag-sg.png  → Singapore"
echo "flag-jp.png  → Japan"
echo "flag-au.png  → Australia"
echo "flag-bh.png  → Bahrain"
echo "flag-sa.png  → Saudi Arabia"
echo "flag-cn.png  → China"
echo "flag-mx.png  → Mexico"
echo "flag-br.png  → Brazil"
echo "flag-qa.png  → Qatar"
echo "flag-ae.png  → UAE (Abu Dhabi)"