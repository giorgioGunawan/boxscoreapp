//
//  WidgetDetailView.swift
//  gridnextapp
//
//  Created by Giorgio Gunawan on 22/5/2025.
//

import SwiftUI

struct WidgetDetailView: View {
    let widget: WidgetInfo
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Large Widget Preview
                VStack(spacing: 16) {
                    Text("Widget Preview")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.bottom, 4)
                        .overlay(
                            Rectangle()
                                .frame(height: 1)
                                .foregroundColor(Color.white.opacity(0.2)),
                            alignment: .bottom
                        )
                    
                    // Large preview with actual image
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(.systemGray4),
                                    Color(.systemGray5),
                                    Color(.systemGray6)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(height: widgetPreviewHeight)
                        .overlay(
                            Group {
                                // Try to load the actual image first
                                if UIImage(named: widget.imageName) != nil {
                                    Image(widget.imageName)
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(maxHeight: widgetPreviewHeight - 20)
                                        .padding(10)
                                        .scaleEffect(widget.size == "Lock Screen" ? 1.5 : 1.0)
                                } else {
                                    // Fallback to placeholder
                                    VStack(spacing: 12) {
                                        Image(systemName: "rectangle.3.group")
                                            .font(.largeTitle)
                                            .foregroundColor(.secondary)
                                        
                                        Text(widget.imageName)
                                            .font(.headline)
                                            .foregroundColor(.secondary)
                                            .multilineTextAlignment(.center)
                                        
                                        Text("Large Preview")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                }

                
                // Widget Information
                VStack(alignment: .leading, spacing: 16) {
                    Text("About This Widget")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.bottom, 4)
                        .overlay(
                            Rectangle()
                                .frame(height: 1)
                                .foregroundColor(Color.white.opacity(0.2)),
                            alignment: .bottom
                        )
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text(widget.description)
                            .font(.body)
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 8) {
                            Image(systemName: widget.size == "Lock Screen" ? "iphone.gen3" : "square.grid.2x2")
                                .foregroundColor(Color(hex: "FF1E00"))
                            Text(widget.size == "Lock Screen" ? "For Lock Screen" : "For Home Screen")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(16)
                .background(Color.white.opacity(0.05))
                .cornerRadius(12)
                
                // Configuration Instructions
                VStack(alignment: .leading, spacing: 16) {
                    Text("How to Add & Configure")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.bottom, 4)
                        .overlay(
                            Rectangle()
                                .frame(height: 1)
                                .foregroundColor(Color.white.opacity(0.2)),
                            alignment: .bottom
                        )
                    
                    VStack(alignment: .leading, spacing: 16) {
                        // Add to Home/Lock Screen section
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 8) {
                                Image(systemName: widget.size == "Lock Screen" ? "lock.fill" : "house.fill")
                                    .foregroundColor(Color(hex: "FF1E00"))
                                Text(widget.size == "Lock Screen" ? "Add to Lock Screen" : "Add to Home Screen")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                            }
                            
                            Text(widget.size == "Lock Screen" 
                                ? "Long press lock screen → Customize → tap widget area → search 'GridBox'"
                                : "Long press home screen → Edit Home Screen → tap + → search 'GridBox'")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        // Customization section (if needed)
                        if customizationText != "No customization needed" {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack(spacing: 8) {
                                    Image(systemName: "slider.horizontal.3")
                                        .foregroundColor(Color(hex: "FF1E00"))
                                    Text("Customization")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                }
                                
                                Text(customizationInstructions)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        // Step by step guide link
                        Button(action: {
                            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                            impactFeedback.impactOccurred()
                            
                            NotificationCenter.default.post(
                                name: NSNotification.Name("SwitchToHowToTab"),
                                object: widget.size == "Lock Screen" ? HowToView.HowToCategory.lockScreen : HowToView.HowToCategory.homeScreen
                            )
                        }) {
                            HStack(spacing: 4) {
                                Text("See step-by-step guide")
                                    .font(.subheadline)
                                    .foregroundColor(Color(hex: "FF1E00"))
                                
                                Image(systemName: "arrow.right")
                                    .font(.subheadline)
                                    .foregroundColor(Color(hex: "FF1E00"))
                            }
                        }
                        .padding(.top, 8)
                        .overlay(
                            Rectangle()
                                .frame(height: 1)
                                .foregroundColor(Color(hex: "FF1E00"))
                                .offset(y: 2),
                            alignment: .bottom
                        )
                    }
                }
                .padding(16)
                .background(Color.white.opacity(0.05))
                .cornerRadius(12)
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(widget.name)
        .navigationBarTitleDisplayMode(.large)
    }
    
    // MARK: - Computed Properties
    
    private var widgetPreviewHeight: CGFloat {
        switch widget.size {
        case "Home Screen":
            if widget.name.contains("Small") {
                return 200
            } else {
                return 250 // Medium widgets
            }
        case "Lock Screen":
            return 200 // Same height as small home screen widgets
        default:
            return 220
        }
    }
    
    private var customizationText: String {
        if widget.name.contains("Driver") {
            return "Choose any F1 driver!"
        } else if widget.name.contains("Constructor") || widget.name.contains("Team") {
            return "Select your favorite F1 team!"
        } else if widget.name.contains("Next Race") || widget.name.contains("Race Complete") || widget.name.contains("Race Compact") || widget.name.contains("Race Countdown") {
            return "No customization needed"
        } else if widget.name.contains("Result") {
            return "No customization needed"
        } else if widget.name.contains("Top 3") {
            return "No customization needed"
        } else {
            return "No customization needed"
        }
    }
    
    private var customizationInstructions: String {
        // First check if it's a lock screen widget
        if widget.size == "Lock Screen" {
            if widget.name.contains("Driver") {
                return "Long press lock screen → Customize → tap widget area → select your favorite driver"
            } else if widget.name.contains("Team") || widget.name.contains("Constructor") {
                return "Long press lock screen → Customize → tap widget area → choose your team"
            } else if widget.name.contains("Race Complete") {
                return "No customization needed - shows detailed race information"
            } else if widget.name.contains("Race Compact") {
                return "No customization needed - shows essential race information"
            } else if widget.name.contains("Race Countdown") {
                return "No customization needed - shows pure countdown timer"
            } else if widget.name.contains("Top 3 Drivers") {
                return "No customization needed - shows current championship top 3 drivers"
            } else if widget.name.contains("Top 3 Teams") {
                return "No customization needed - shows current championship top 3 teams"
            }
        }
        
        // Home screen widgets
        if widget.name.contains("Driver") {
            return "Long press widget → Edit Widget → select your favorite driver"
        } else if widget.name.contains("Team") || widget.name.contains("Constructor") {
            return "Long press widget → Edit Widget → choose your team"
        } else if widget.name.contains("Next Race Small") {
            return "No customization needed - shows next race countdown"
        } else if widget.name.contains("Next Race Medium") {
            return "No customization needed - shows full race weekend schedule"
        } else if widget.name.contains("Result Small") {
            return "No customization needed - shows latest race winner and podium"
        } else if widget.name.contains("Result Medium") {
            return "No customization needed - shows detailed podium results"
        }
        
        return "No customization needed"
    }
    
    private var tips: [String] {
        var tipsList: [String] = []
        
        if widget.name.contains("Driver") {
            tipsList.append("Switch drivers anytime by editing the widget")
            tipsList.append("Driver helmet images update automatically")
        }
        
        if widget.name.contains("Constructor") {
            tipsList.append("Team colors and F1 car images change with your selection")
            tipsList.append("Shows both drivers' points for the team")
        }
        
        if widget.name.contains("Next Race") {
            tipsList.append("Countdown updates in real-time as race approaches")
            tipsList.append("Shows practice, qualifying, and race times")
            tipsList.append("Perfect for planning your race weekend viewing")
        }
        
        if widget.name.contains("Race Result") {
            tipsList.append("Updates immediately after each race finishes")
            tipsList.append("Shows podium finishers and race winner")
            tipsList.append("Great for catching up on races you missed")
        }
        
        if widget.size == "Lock Screen" {
            tipsList.append("Perfect for quick glances without unlocking your phone")
        }
        
        if widget.size == "Medium" {
            tipsList.append("Best balance of information and screen space")
        }
        
        tipsList.append("Data updates automatically after each race")
        
        return tipsList
    }
}

struct InfoRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.trailing)
        }
    }
}

struct ConfigStep: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

#Preview {
    NavigationView {
        WidgetDetailView(
            widget: WidgetInfo(
                name: "Driver Medium",
                description: "Detailed driver info with helmet",
                size: "Medium",
                imageName: "driver_medium_preview"
            )
        )
    }
} 