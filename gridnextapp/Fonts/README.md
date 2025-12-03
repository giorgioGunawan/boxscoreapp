# Font Setup - Formula1 & Orbitron

## Font Files Required
Place the following font files in this directory:

### Formula1 Fonts (Primary)
- `F1-Regular.ttf` → Internal name: `Formula1-Display-Regular`
- `F1-Bold.ttf` → Internal name: `Formula1-Display-Bold`  
- `F1-Wide.ttf` → Internal name: `Formula1-Display-Wide`

### Orbitron Fonts (Secondary)
- `Orbitron-Regular.ttf`
- `Orbitron-Bold.ttf` 
- `Orbitron-Black.ttf`
- `Orbitron-Medium.ttf`
- `Orbitron-SemiBold.ttf`
- `Orbitron-ExtraBold.ttf`

## Current Usage

### Formula1 Fonts (Used throughout all widgets)
- **Formula1-Display-Regular**: Used for regular text, smaller sizes, and secondary information
- **Formula1-Display-Bold**: Used for prominent text, larger sizes (20+), and emphasis
- **Formula1-Display-Wide**: Available for special use cases

### Orbitron Fonts
- **Orbitron-Bold**: Currently used for team names in driver lock screen widget

## Font Registration
The fonts are registered in the following Info.plist files:
- `gridnextapp/Info.plist`
- `F1RaceWidget/Info.plist`
- `F1RaceResult/Info.plist`

## Adding Font Files to Xcode
1. Drag the TTF files from this folder into your Xcode project
2. Make sure to check "Add to target" for all three targets:
   - gridnextapp (main app)
   - F1RaceWidget (widget extension)
   - F1RaceResult (result extension)

## Font Name Mapping
| File Name | Internal PostScript Name | Usage in Code |
|-----------|-------------------------|---------------|
| `F1-Regular.ttf` | `Formula1-Display-Regular` | `.font(.custom("Formula1-Display-Regular", size: X))` |
| `F1-Bold.ttf` | `Formula1-Display-Bold` | `.font(.custom("Formula1-Display-Bold", size: X))` |
| `F1-Wide.ttf` | `Formula1-Display-Wide` | `.font(.custom("Formula1-Display-Wide", size: X))` |

## Testing
After adding the font files and building the project:
- All widget text should display using Formula1 fonts
- Team names in driver lock screen widget should use Orbitron Bold
- Check that fonts render correctly across all widget sizes and types 