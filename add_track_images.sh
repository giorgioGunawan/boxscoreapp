#!/bin/bash

# Script to add F1 track outline images to all asset catalogs
# Usage: ./add_track_images.sh

# Array of track image names (without .png extension)
tracks=(
    "f1-track-bhr"      # Bahrain
    "f1-track-sau"      # Saudi Arabia
    "f1-track-aus"      # Australia
    "f1-track-jpn"      # Japan
    "f1-track-chn"      # China
    "f1-track-mia"      # Miami
    "f1-track-ita"      # Emilia Romagna (Imola)
    "f1-track-mon"      # Monaco
    "f1-track-can"      # Canada
    "f1-track-esp"      # Spain
    "f1-track-aut"      # Austria
    "f1-track-gbr"      # Great Britain
    "f1-track-hun"      # Hungary
    "f1-track-bel"      # Belgium
    "f1-track-ned"      # Netherlands
    "f1-track-ita-monza" # Italy (Monza)
    "f1-track-aze"      # Azerbaijan
    "f1-track-sgp"      # Singapore
    "f1-track-usa"      # United States
    "f1-track-mex"      # Mexico
    "f1-track-bra"      # Brazil
    "f1-track-lv"       # Las Vegas
    "f1-track-qat"      # Qatar
    "f1-track-are"      # Abu Dhabi
)

# Asset catalog paths
asset_paths=(
    "gridnextapp/Assets.xcassets"
    "F1RaceWidget/Assets.xcassets"
    "F1RaceResult/Assets.xcassets"
)

echo "🏁 Adding F1 track outline images to asset catalogs..."

for track in "${tracks[@]}"; do
    echo "Processing: $track"
    
    # Check if source image exists
    if [ ! -f "${track}.png" ]; then
        echo "⚠️  Warning: ${track}.png not found in current directory"
        continue
    fi
    
    # Add to each asset catalog
    for asset_path in "${asset_paths[@]}"; do
        imageset_path="${asset_path}/${track}.imageset"
        
        # Create imageset directory
        mkdir -p "$imageset_path"
        
        # Copy image
        cp "${track}.png" "$imageset_path/"
        
        # Create Contents.json
        cat > "${imageset_path}/Contents.json" << EOF
{
  "images" : [
    {
      "filename" : "${track}.png",
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
        
        echo "  ✅ Added to $asset_path"
    done
done

echo ""
echo "🎉 Done! All track images have been added to the asset catalogs."
echo ""
echo "📝 Next steps:"
echo "1. Make sure all your track PNG files are named correctly:"
echo "   - f1-track-can.png (Canada)"
echo "   - f1-track-esp.png (Spain)"
echo "   - f1-track-mon.png (Monaco)"
echo "   - etc..."
echo ""
echo "2. Run this script from the directory containing your track images"
echo "3. The track backgrounds will automatically appear based on race shortname" 