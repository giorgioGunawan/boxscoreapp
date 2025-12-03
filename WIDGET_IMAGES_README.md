# Widget Preview Images Setup

This guide explains how to easily add widget preview images to your F1 app.

## 🚀 Quick Start

1. **Add your images** to the `widget-preview-images/` folder
2. **Run the script**: `./add_widget_preview_assets.sh`
3. **Done!** Your images are now available in the app

## 📁 Required Image Names

Your images must be named exactly as follows (case-sensitive):

### Widget Previews
- `next_race_small_preview.png`
- `next_race_medium_preview.png`
- `next_race_complete_preview.png`
- `next_race_compact_preview.png`
- `next_race_countdown_preview.png`
- `race_result_small_preview.png`
- `race_result_medium_preview.png`
- `race_result_lockscreen_preview.png`
- `driver_small_preview.png`
- `driver_medium_preview.png`
- `driver_lockscreen_preview.png`
- `constructor_small_preview.png`
- `constructor_medium_preview.png`
- `constructor_lockscreen_preview.png`
- `top3_drivers_preview.png`
- `top3_constructors_preview.png`

### Tutorial Step Images
- `home_step1_longpress.png`
- `home_step2_plus_button.png`
- `home_step3_search.png`
- `home_step4_choose_size.png`
- `home_step5_add_widget.png`
- `home_step6_customize.png`
- `lock_step1_lock_screen.png`
- `lock_step2_longpress.png`
- `lock_step3_customize.png`
- `lock_step4_choose_lockscreen.png`
- `lock_step5_add_widgets.png`
- `lock_step6_select_widget.png`
- `lock_step7_done.png`

## 📝 Step-by-Step Instructions

### 1. Prepare Your Images
- Create screenshots or mockups of your widgets
- Save them as PNG, JPG, or JPEG files
- Name them exactly as listed above
- Recommended size: 300-600px wide for good quality

### 2. Add Images to Folder
```bash
# The folder structure should look like this:
widget-preview-images/
├── next_race_small_preview.png
├── next_race_medium_preview.png
├── driver_small_preview.png
└── ... (other images)
```

### 3. Run the Script
```bash
./add_widget_preview_assets.sh
```

The script will:
- ✅ Check for all expected images
- ✅ Create proper Xcode imagesets
- ✅ Copy images to `Assets.xcassets`
- ✅ Show you what's missing

### 4. Verify in Xcode
1. Open your Xcode project
2. Navigate to `Assets.xcassets`
3. You should see your new imagesets
4. The images will now display in your app!

## 🔧 Troubleshooting

### "No images found" error
- Make sure you've added images to the `widget-preview-images/` folder
- Check that the folder exists in your project root

### Images not showing in app
- Verify image names match exactly (case-sensitive)
- Make sure images are valid PNG/JPG files
- Clean and rebuild your Xcode project

### "Unexpected image" warning
- Check the spelling of your image names
- Refer to the required names list above

## 💡 Tips

- **Batch processing**: Add multiple images at once and run the script
- **Updates**: When you update an image, just replace it in the folder and run the script again
- **Quality**: Use high-resolution images for better display on all devices
- **Consistency**: Keep similar styling across all widget previews

## 🎨 Image Recommendations

### Widget Previews
- Show actual widget content (race info, driver stats, etc.)
- Use your app's color scheme and branding
- Include realistic data for better user understanding

### Tutorial Steps
- Use iPhone screenshots showing the actual steps
- Highlight important UI elements (buttons, menus)
- Keep consistent iPhone model/iOS version across steps

## 🔄 Updating Images

To update existing images:
1. Replace the image file in `widget-preview-images/`
2. Run `./add_widget_preview_assets.sh` again
3. The script will overwrite the old imageset

---

**Need help?** Check that your image names match exactly and that you're running the script from the project root directory. 