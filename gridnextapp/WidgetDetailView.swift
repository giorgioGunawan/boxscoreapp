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
                                ? "Long press lock screen → Customize → tap widget area → search 'BoxScore'"
                                : "Long press home screen → Edit Home Screen → tap + → search 'BoxScore'")
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
        if widget.name.contains("Player") {
            return "Choose any NBA player!"
        } else if widget.name.contains("Team") {
            return "Select your favorite NBA team!"
        } else {
            return "No customization needed"
        }
    }
    
    private var customizationInstructions: String {
        if widget.name.contains("Player") {
            return "Long press widget → Edit Widget → select your favorite player"
        } else if widget.name.contains("Team") {
            return "Long press widget → Edit Widget → choose your team"
        } else {
            return "No customization needed"
        }
    }
    
    private var tips: [String] {
        var tipsList: [String] = []
        
        if widget.name.contains("Player") {
            tipsList.append("Switch players anytime by editing the widget")
            tipsList.append("Player stats update automatically")
        }
        
        if widget.name.contains("Team") {
            tipsList.append("Team information updates automatically")
            tipsList.append("Shows current record and standings")
        }
        
        if widget.name.contains("Next") || widget.name.contains("Countdown") {
            tipsList.append("Countdown updates in real-time as game approaches")
            tipsList.append("Shows game times in your local timezone")
        }
        
        if widget.name.contains("Last") || widget.name.contains("Result") {
            tipsList.append("Updates immediately after each game finishes")
            tipsList.append("Shows scores and win/loss indicators")
        }
        
        if widget.size == "Lock Screen" {
            tipsList.append("Perfect for quick glances without unlocking your phone")
        }
        
        if widget.size == "Medium" {
            tipsList.append("Best balance of information and screen space")
        }
        
        tipsList.append("Data updates automatically after each game")
        
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