//
//  SettingsView.swift
//  gridnextapp
//
//  Created by Giorgio Gunawan on 22/5/2025.
//

import SwiftUI
import WidgetKit

struct SettingsView: View {
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // App Info Section
                    VStack(spacing: 16) {
                        HStack(spacing: 16) {
                            // App Icon
                            Group {
                                if let appIcon = UIImage(named: "AppIcon") {
                                    Image(uiImage: appIcon)
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                } else {
                                    // Fallback placeholder
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.blue.gradient)
                                        .overlay(
                                            Image(systemName: "basketball.fill")
                                                .font(.title2)
                                                .foregroundColor(.white)
                                        )
                                }
                            }
                            .frame(width: 60, height: 60)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("BoxScore")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                
                                Text("Version 1.0")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                Text("NBA widgets for your phone")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)

                    // About Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("About")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        VStack(spacing: 12) {
                            InfoCard(
                                icon: "info.circle",
                                title: "Privacy",
                                subtitle: "No personal data collected",
                                iconColor: .blue
                            )
                            
                            InfoCard(
                                icon: "heart",
                                title: "Made for NBA Fans",
                                subtitle: "by NBA Fans",
                                iconColor: .red
                            )
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                    
                    // Divider
                    Rectangle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.clear,
                                    Color.white.opacity(0.6),
                                    Color.gray.opacity(0.8),
                                    Color.white.opacity(0.6),
                                    Color.clear
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(height: 0.5)
                        .frame(maxWidth: .infinity)
                        .scaleEffect(x: 0.8, y: 1.0)
                        .shadow(color: .white.opacity(0.3), radius: 2, x: 0, y: 0)
                        .shadow(color: .white.opacity(0.1), radius: 4, x: 0, y: 0)
                        .padding(.bottom, -5)
                    
                    // Contact Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Contact")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        InfoCard(
                            icon: "envelope",
                            title: "Email",
                            subtitle: "boxscorewidget@gmail.com",
                            iconColor: .blue
                        )
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                    
                    // Divider
                    Rectangle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.clear,
                                    Color.white.opacity(0.6),
                                    Color.gray.opacity(0.8),
                                    Color.white.opacity(0.6),
                                    Color.clear
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(height: 0.5)
                        .frame(maxWidth: .infinity)
                        .scaleEffect(x: 0.8, y: 1.0)
                        .shadow(color: .white.opacity(0.3), radius: 2, x: 0, y: 0)
                        .shadow(color: .white.opacity(0.1), radius: 4, x: 0, y: 0)
                        .padding(.bottom, -5)
                    
                    // Social Media Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Social Media")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        InfoCard(
                            icon: "at",
                            title: "Follow Us on Instagram, X, and TikTok",
                            subtitle: "@boxscorewidget",
                            iconColor: .purple
                        )
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                }
                .padding()
            }
            .navigationTitle("Settings")
            .background(
                LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: Color.black, location: 0.0),
                        .init(color: Color.black, location: 0.7),
                        .init(color: Color(hex: "1A0000"), location: 1.0)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
        }
    }
}

struct InfoCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let iconColor: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(iconColor)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

struct ProToggleCard: View {
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: subscriptionManager.effectiveProStatus ? "crown.fill" : "crown")
                    .font(.title3)
                    .foregroundColor(subscriptionManager.effectiveProStatus ? .orange : .gray)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Pro Status")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text(subscriptionManager.effectiveProStatus ? "Pro User" : "Free User")
                        .font(.caption)
                        .foregroundColor(subscriptionManager.effectiveProStatus ? .orange : .secondary)
                }
                
                Spacer()
            }
            
            if subscriptionManager.isProUser {
                HStack {
                    Image(systemName: "info.circle")
                        .font(.caption)
                        .foregroundColor(.orange)
                    
                    Text("Active subscription")
                        .font(.caption2)
                        .foregroundColor(.orange)
                    
                    Spacer()
                }
            }
        }
    }
}

#Preview {
    SettingsView()
} 