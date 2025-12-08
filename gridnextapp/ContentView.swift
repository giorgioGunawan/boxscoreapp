//
//  ContentView.swift
//  gridnextapp
//
//  Created by Giorgio Gunawan on 22/5/2025.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @State private var selectedTab = 0
    @State private var howToCategory: HowToView.HowToCategory = .homeScreen
    @State private var showingUpgradeSheet = false
    @State private var showingFullPagePaywall = false
    @State private var showingConfetti = false
    
    var body: some View {
        TabView(selection: Binding(
            get: { selectedTab },
            set: { newValue in
                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                impactFeedback.impactOccurred()
                selectedTab = newValue
            }
        )) {
            NavigationView {
                WidgetGalleryView(showingUpgradeSheet: $showingUpgradeSheet, showingFullPagePaywall: $showingFullPagePaywall)
                    .navigationBarHidden(true)
            }
            .tabItem {
                Image(systemName: "rectangle.3.group")
                Text("Widgets")
            }
            .tag(0)
            
            HowToView(initialCategory: howToCategory)
                .tabItem {
                    Image(systemName: "questionmark.circle")
                    Text("How To")
                }
                .tag(1)
            
            SettingsView()
                .tabItem {
                    Image(systemName: "gear")
                    Text("Settings")
                }
                .tag(2)
        }
        .accentColor(.white)
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
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("SwitchToHowToTab"))) { notification in
            if let category = notification.object as? HowToView.HowToCategory {
                howToCategory = category
                selectedTab = 1
            }
        }
        // Disabled paywall - all features are free
        // .onAppear {
        //     if selectedTab == 0 && !subscriptionManager.effectiveProStatus {
        //         showingFullPagePaywall = true
        //     }
        // }
        // .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
        //     if selectedTab == 0 && !subscriptionManager.effectiveProStatus {
        //         showingFullPagePaywall = true
        //     }
        // }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ShowUpgradeScreen"))) { _ in
            // Show upgrade screen when deep link is triggered (from widget tap)
            showingFullPagePaywall = true
        }
        .sheet(isPresented: $showingUpgradeSheet) {
            SimpleUpgradeSheet(isPresented: $showingUpgradeSheet, showingConfetti: $showingConfetti)
        }
        .fullScreenCover(isPresented: $showingFullPagePaywall) {
            FullPagePaywall(isPresented: $showingFullPagePaywall, showingConfetti: $showingConfetti)
        }
        .environmentObject(subscriptionManager)
        .overlay(
            // Confetti overlay for home page
            ConfettiView(isActive: $showingConfetti)
                .allowsHitTesting(false)
        )
    }
}

struct WidgetGalleryView: View {
    let widgetCategories = [
        WidgetCategory(
            title: "Team Games Widgets",
            description: "Track your team's upcoming games and results",
            widgets: [
                WidgetInfo(
                    name: "Next 3 Games",
                    description: "Shows your team's next 3 upcoming games",
                    size: "Home Screen",
                    imageName: "next_games_preview",
                    isPremium: false
                ),
                WidgetInfo(
                    name: "Last 3 Results",
                    description: "Shows your team's last 3 game results",
                    size: "Home Screen",
                    imageName: "last_games_preview",
                    isPremium: false
                ),
                WidgetInfo(
                    name: "Countdown to Next Game",
                    description: "Countdown timer until your team's next game",
                    size: "Home Screen",
                    imageName: "countdown_preview",
                    isPremium: false
                ),
                WidgetInfo(
                    name: "Team Standing",
                    description: "Shows your team's current record and conference rank",
                    size: "Home Screen",
                    imageName: "team_standing_preview",
                    isPremium: false
                )
            ]
        ),
        WidgetCategory(
            title: "Player Widgets",
            description: "Follow your favorite player's performance",
            widgets: [
                WidgetInfo(
                    name: "Season Average",
                    description: "Shows a player's season averages and stats",
                    size: "Home Screen",
                    imageName: "season_average_preview",
                    isPremium: false
                ),
                WidgetInfo(
                    name: "Player Last Game",
                    description: "Shows a player's last game performance",
                    size: "Home Screen",
                    imageName: "player_last_game_preview",
                    isPremium: false
                )
            ]
        )
    ]
    
    @Binding var showingUpgradeSheet: Bool
    @Binding var showingFullPagePaywall: Bool
    @State private var glowOpacity: Double = 0.5
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 24) {
                // BoxScore Title
                Text("BoxScore")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.horizontal)
                    .padding(.top, 20)
                    .shadow(color: .black.opacity(0.5), radius: 3, x: 0, y: 2)
                
                // Quick How-To Access
                VStack(spacing: 12) {
                    Text("Learn how to:")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                        .shadow(color: .black.opacity(0.5), radius: 3, x: 0, y: 2)
                    
                    VStack(spacing: 8) {
                        QuickHowToButton(
                            title: "Add Widgets to Home Screen",
                            description: "Step-by-step guide to add widgets to home screen",
                            targetCategory: .homeScreen
                        )
                        
                        QuickHowToButton(
                            title: "Add Widgets to Lock Screen", 
                            description: "Step-by-step guide to add widgets to lock screen",
                            targetCategory: .lockScreen
                        )
                    }
                    .padding(.horizontal)
                }
                .padding(.top, -10)

                // Get Pro Button (only shown for non-pro users)
                if !subscriptionManager.effectiveProStatus {
                    Button(action: {
                        showingFullPagePaywall = true
                    }) {
                        HStack(spacing: 8) {
                            Text("Get Pro")
                                .font(.custom("Formula1-Display-Bold", size: 20))
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color(hex: "FF1E00"))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(color: Color(hex: "FF1E00").opacity(0.3), radius: 4, x: 0, y: 2)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color(hex: "FFD700").opacity(0.7 * glowOpacity),
                                            Color(hex: "FFA500").opacity(0.7 * glowOpacity),
                                            Color(hex: "FFD700").opacity(0.7 * glowOpacity)
                                        ]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    ),
                                    lineWidth: 2
                                )
                                .blur(radius: 2)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color(hex: "FFD700").opacity(0.3 * glowOpacity),
                                            Color(hex: "FFA500").opacity(0.3 * glowOpacity),
                                            Color(hex: "FFD700").opacity(0.3 * glowOpacity)
                                        ]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    ),
                                    lineWidth: 4
                                )
                                .blur(radius: 4)
                        )
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .onAppear {
                        withAnimation(
                            .easeInOut(duration: 1.5)
                            .repeatForever(autoreverses: true)
                        ) {
                            glowOpacity = 1.0
                        }
                    }
                }

                // Widget Categories
                ForEach(Array(widgetCategories.enumerated()), id: \.element.title) { index, category in
                    WidgetCategoryView(category: category, showingUpgradeSheet: $showingUpgradeSheet)
                    
                    // Add divider after each category except the last one
                    if index < widgetCategories.count - 1 {
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
                    }
                }
            }
        }
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

struct WidgetCategoryView: View {
    let category: WidgetCategory
    @Binding var showingUpgradeSheet: Bool
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(category.title)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .shadow(color: .black.opacity(0.5), radius: 3, x: 0, y: 2)
                
                Text(category.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .shadow(color: .black.opacity(0.4), radius: 2, x: 0, y: 1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(category.widgets, id: \.name) { widget in
                        if widget.isPremium && !subscriptionManager.effectiveProStatus {
                            Button(action: {
                                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                                impactFeedback.impactOccurred()
                                showingUpgradeSheet = true
                            }) {
                                WidgetPreviewCard(widget: widget, showingUpgradeSheet: $showingUpgradeSheet, isProUser: subscriptionManager.effectiveProStatus)
                            }
                            .buttonStyle(PlainButtonStyle())
                        } else {
                            NavigationLink(destination: WidgetDetailView(widget: widget)) {
                                WidgetPreviewCard(widget: widget, showingUpgradeSheet: $showingUpgradeSheet, isProUser: subscriptionManager.effectiveProStatus)
                            }
                            .simultaneousGesture(TapGesture().onEnded {
                                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                                impactFeedback.impactOccurred()
                            })
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

struct WidgetPreviewCard: View {
    let widget: WidgetInfo
    @Binding var showingUpgradeSheet: Bool
    let isProUser: Bool
    
    var shouldShowPremiumOverlay: Bool {
        widget.isPremium && !isProUser
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // Widget Preview Image
            RoundedRectangle(cornerRadius: 16)
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
                .frame(width: 200, height: 150)
                .overlay(
                    Group {
                        // Try to load the actual image first
                        if UIImage(named: widget.imageName) != nil {
                            Image(widget.imageName)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxWidth: 200, maxHeight: 150)
                                .scaleEffect(widget.size == "Lock Screen" ? 1.5 : 1.0)
                                .opacity(shouldShowPremiumOverlay ? 0.45 : 1.0)
                        } else {
                            // Fallback to placeholder
                            VStack(spacing: 8) {
                                Image(systemName: "rectangle.3.group")
                                    .font(.title2)
                                    .foregroundColor(.secondary)
                                
                                Text(widget.imageName)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 4)
                            }
                            .opacity(shouldShowPremiumOverlay ? 0.45 : 1.0)
                        }
                        
                        // Premium overlay (only show if not pro user)
                        if shouldShowPremiumOverlay {
                            ZStack {
                                // Centered lock icon
                                VStack(spacing: 8) {
                                    Image(systemName: "lock.fill")
                                        .font(.system(size: 32))
                                        .foregroundColor(.white)
                                        .shadow(color: .black.opacity(0.7), radius: 4, x: 0, y: 2)
                                    
                                    Text("PRO")
                                        .font(.headline)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                        .shadow(color: .black.opacity(0.7), radius: 4, x: 0, y: 2)
                                }
                                
                                // Ribbon badge on right side
                                VStack {
                                    HStack {
                                        Spacer()
                                        PremiumBadge()
                                    }
                                    .padding(.top, 12)
                                    Spacer()
                                }
                            }
                        }
                    }
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
            
            VStack(spacing: 4) {
                HStack(spacing: 4) {
                    Text(widget.name)
                        .font(.headline)
                        .fontWeight(.medium)
                    
                    if widget.isPremium && !isProUser {
                        Image(systemName: "crown.fill")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
                
                Text(widget.size)
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: widget.size == "Home Screen" ? 
                                [Color.red, Color.orange] : 
                                [Color.blue, Color.purple]
                            ),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(Capsule())
            }
        }
        .frame(width: 200)
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Data Models

struct WidgetCategory {
    let title: String
    let description: String
    let widgets: [WidgetInfo]
}

struct WidgetInfo {
    let name: String
    let description: String
    let size: String
    let imageName: String
    let isPremium: Bool
    
    init(name: String, description: String, size: String, imageName: String, isPremium: Bool = false) {
        self.name = name
        self.description = description
        self.size = size
        self.imageName = imageName
        self.isPremium = isPremium
    }
}

// MARK: - Quick How To Button

struct QuickHowToButton: View {
    let title: String
    let description: String
    let targetCategory: HowToView.HowToCategory
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            // This will be handled by the parent to switch to How To tab
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            
            NotificationCenter.default.post(
                name: NSNotification.Name("SwitchToHowToTab"),
                object: targetCategory
            )
        }) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(red: 0.05, green: 0.05, blue: 0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(.systemGray5), lineWidth: 1)
                    )
                    .shadow(color: .white.opacity(0.1), radius: 8, x: 0, y: 4)
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}

// MARK: - How To View

struct HowToView: View {
    @State private var selectedCategory: HowToCategory
    @State private var currentStep: Int = 0
    
    enum HowToCategory: String, CaseIterable {
        case homeScreen = "Home Screen"
        case lockScreen = "Lock Screen"
    }
    
    init(initialCategory: HowToCategory = .homeScreen) {
        _selectedCategory = State(initialValue: initialCategory)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Category Selector
                HStack(spacing: 0) {
                    ForEach(HowToCategory.allCases, id: \.self) { category in
                        Button(action: {
                            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                            impactFeedback.impactOccurred()
                            selectedCategory = category
                            currentStep = 0
                        }) {
                            Text(category.rawValue)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(selectedCategory == category ? .white : .gray)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(
                                    selectedCategory == category ? 
                                    Color(hex: "FF1E00") : Color.clear
                                )
                        }
                    }
                }
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .padding(.horizontal, 24)
                .padding(.vertical, 8)
                
                // Slideshow
                TabView(selection: Binding(
                    get: { currentStep },
                    set: { newValue in
                        let impactFeedback = UIImpactFeedbackGenerator(style: .soft)
                        impactFeedback.impactOccurred()
                        currentStep = newValue
                    }
                )) {
                    ForEach(0..<currentSteps.count, id: \.self) { index in
                        HowToSlideView(
                            step: currentSteps[index],
                            stepNumber: index + 1,
                            totalSteps: currentSteps.count
                        )
                        .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
                .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
                
                Spacer()
            }
            .navigationTitle("How to Add Widgets")
            .navigationBarTitleDisplayMode(.inline)
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
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("SwitchToHowToTab"))) { notification in
                if let category = notification.object as? HowToCategory {
                    selectedCategory = category
                    currentStep = 0
                }
            }
        }
    }
    
    private var currentSteps: [TutorialStep] {
        switch selectedCategory {
        case .homeScreen:
            return homeScreenSteps
        case .lockScreen:
            return lockScreenSteps
        }
    }
    
    private let homeScreenSteps = [
        TutorialStep(
            title: "Long Press Home Screen",
            description: "Press and hold on an empty area of your home screen until the apps start wiggling.",
            imageName: "home_step_1"
        ),
        TutorialStep(
            title: "Tap the Edit button",
            description: "Look for the edit button on the top left corner",
            imageName: "home_step_2"
        ),
        TutorialStep(
            title: "Tap on Add Widget",
            description: "Tap on Add Widget",
            imageName: "home_step_3"
        ),
        TutorialStep(
            title: "Search for BoxScore",
            description: "Type 'BoxScore' in the search bar or scroll to find our widgets.",
            imageName: "home_step_4"
        ),
        TutorialStep(
            title: "Choose & Add Widget",
            description: "Select your preferred BoxScore widget and tap 'Add Widget' to place it on your home screen.",
            imageName: "home_step_5"
        ),
        TutorialStep(
            title: "Customize Your Widget (Optional)",
            description: "For customizable widgets, long press the widget and select 'Edit Widget' to choose your favorite player or team.",
            imageName: "home_step_6"
        ),
        TutorialStep(
            title: "Select Your Preferences (Optional)",
            description: "Choose your favorite player or team from the customization options that appear.",
            imageName: "home_step_7"
        )
    ]
    
    private let lockScreenSteps = [
        TutorialStep(
            title: "Long Press Lock Screen",
            description: "Make sure your iPhone is locked, then press and hold on an empty area of your lock screen.",
            imageName: "lock_step_1"
        ),
        TutorialStep(
            title: "Tap Customize",
            description: "Tap 'Customize' when the menu appears at the bottom.",
            imageName: "lock_step_2"
        ),
        TutorialStep(
            title: "Choose Lock Screen",
            description: "Select 'Lock Screen' from the customization options.",
            imageName: "lock_step_3"
        ),
        TutorialStep(
            title: "Add Widgets",
            description: "Tap the widget area below the time to add widgets.",
            imageName: "lock_step_4"
        ),
        TutorialStep(
            title: "Find BoxScore Widgets",
            description: "Search for 'BoxScore' and select your preferred widget.",
            imageName: "lock_step_5"
        ),
        TutorialStep(
            title: "Choose Preferred Widgets",
            description: "Select the BoxScore widgets you want to add to your lock screen.",
            imageName: "lock_step_6"
        ),
        TutorialStep(
            title: "Customize Widget (Optional)",
            description: "If you want to customize, tap on the customizable widget while in edit mode.",
            imageName: "lock_step_7"
        ),
        TutorialStep(
            title: "Pick Your Favorite",
            description: "Choose your favorite player or team from the customization options.",
            imageName: "lock_step_8"
        ),
        TutorialStep(
            title: "Done!",
            description: "Tap 'Done' to save your lock screen with the new BoxScore widgets.",
            imageName: "lock_step_9"
        )
    ]
}

struct HowToSlideView: View {
    let step: TutorialStep
    let stepNumber: Int
    let totalSteps: Int
    
    var body: some View {
        VStack(spacing: 16) {
            // Step indicator
            Text("Step \(stepNumber) of \(totalSteps)")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top, 3)
                .padding(.bottom, 6)
            
            // iPhone mockup with screenshot placeholder
            VStack(spacing: 12) {
                // iPhone frame
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.black)
                    .frame(width: 200, height: 400)
                    .overlay(
                        // Display the actual tutorial image
                        Image(step.imageName)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 204, height: 424)
                            .clipped()
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    )
            }
            .padding(.bottom, 12)
            
            // Step description
            VStack(spacing: 8) {
                Text(step.title)
                    .font(.headline)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text(step.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
            }
            
            Spacer(minLength: 10)
        }
        .padding(.horizontal)
    }
}

struct TutorialStep {
    let title: String
    let description: String
    let imageName: String
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Premium Components

struct PremiumBadge: View {
    var body: some View {
        // Badge that wraps around the card edge
        HStack(spacing: 4) {
            Image(systemName: "crown.fill")
                .font(.system(size: 8))
                .foregroundColor(.white)
            
            Text("PRO")
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.red)
        .clipShape(
            UnevenRoundedRectangle(
                topLeadingRadius: 4,
                bottomLeadingRadius: 4,
                bottomTrailingRadius: 0,
                topTrailingRadius: 0
            )
        )
        .shadow(color: .black.opacity(0.3), radius: 2, x: 1, y: 1)
        .scaleEffect(1.25)
    }
}

struct FullPagePaywall: View {
    @Binding var isPresented: Bool
    @Binding var showingConfetti: Bool
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @State private var showingAlert = false
    @State private var pulseScale: CGFloat = 1.0
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background Image
                if UIImage(named: "paywall_background") != nil {
                    Image("paywall_background")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .ignoresSafeArea()
                        .overlay(
                            // Enhanced gradient overlay - darker at bottom
                            LinearGradient(
                                gradient: Gradient(stops: [
                                    .init(color: Color.black.opacity(0.3), location: 0.0),
                                    .init(color: Color.black.opacity(0.6), location: 0.5),
                                    .init(color: Color.black.opacity(0.9), location: 1.0)
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            .ignoresSafeArea()
                        )
                } else {
                    // Fallback gradient background - enhanced with darker bottom
                    LinearGradient(
                        gradient: Gradient(stops: [
                            .init(color: Color.black, location: 0.0),
                            .init(color: Color.black, location: 0.5),
                            .init(color: Color(hex: "2A0000"), location: 0.8),
                            .init(color: Color(hex: "0A0000"), location: 1.0)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .ignoresSafeArea()
                }
                
                if subscriptionManager.isLoading {
                    // Loading overlay
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    
                    VStack(spacing: 16) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .red))
                            .scaleEffect(1.5)
                        
                        VStack(spacing: 12) {
                            Text("Processing Purchase")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                            
                            Text("Please don't close the app")
                                .font(.headline)
                                .foregroundColor(.white.opacity(0.8))
                                .multilineTextAlignment(.center)
                        }
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 40) {
                            // Header
                            VStack(spacing: 20) {
                                Image(systemName: "crown.fill")
                                    .font(.system(size: 60))
                                    .foregroundColor(.red)
                                    .shadow(color: .red.opacity(0.5), radius: 15, x: 0, y: 8)
                                
                                Text("BoxScore Pro")
                                    .font(.largeTitle)
                                    .fontWeight(.bold)
                                    .foregroundStyle(
                                        LinearGradient(
                                            gradient: Gradient(colors: [Color.orange, Color.red]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .multilineTextAlignment(.center)
                                
                                Text("Lifetime Access")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                    .opacity(0.9)
                            }
                            .padding(.top, 30)
                            
                            // Price Display
                            VStack(spacing: 8) {
                                Text("One-time payment")
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.8))
                                
                                Text(subscriptionManager.lifetimePrice)
                                    .font(.system(size: 48, weight: .bold, design: .rounded))
                                    .foregroundColor(.red)
                                    .shadow(color: .red.opacity(0.3), radius: 8, x: 0, y: 4)
                            }
                            
                            // Features List
                            VStack(alignment: .leading, spacing: 20) {
                                Text("What's Included")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .foregroundColor(.white)
                                
                                VStack(spacing: 16) {
                                    FeatureRow(icon: "checkmark.circle.fill", text: "All premium widgets unlocked")
                                    FeatureRow(icon: "checkmark.circle.fill", text: "Choose your favorite player or team")
                                    FeatureRow(icon: "checkmark.circle.fill", text: "Advanced lock screen widgets")
                                    FeatureRow(icon: "checkmark.circle.fill", text: "Remove annoying ads")
                                    FeatureRow(icon: "checkmark.circle.fill", text: "Future updates included")
                                }
                            }
                            
                            // CTA Button with Pulse Animation
                            VStack(spacing: 16) {
                                Button(action: {
                                    Task {
                                        let success = await subscriptionManager.purchaseLifetime()
                                        
                                        if success {
                                            // Close paywall immediately
                                            isPresented = false
                                            
                                            // Show confetti on home page after a brief delay
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                                showingConfetti = true
                                            }
                                        } else if subscriptionManager.errorMessage != nil {
                                            showingAlert = true
                                        }
                                    }
                                }) {
                                    HStack(spacing: 12) {
                                        Image(systemName: "crown.fill")
                                            .font(.title2)
                                        
                                        Text("Get Pro")
                                            .font(.title2)
                                            .fontWeight(.bold)
                                    }
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 18)
                                    .background(Color.red)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                    .scaleEffect(pulseScale)
                                    .shadow(color: .red.opacity(0.6), radius: 10, x: 0, y: 5)
                                }
                                .disabled(subscriptionManager.isLoading)
                                .onAppear {
                                    withAnimation(
                                        Animation.easeInOut(duration: 1.0)
                                            .repeatForever(autoreverses: true)
                                    ) {
                                        pulseScale = 1.05
                                    }
                                }
                                
                                // Restore Purchases Button
                                Button("Restore Purchases") {
                                    Task {
                                        let success = await subscriptionManager.restorePurchases()
                                        if success && subscriptionManager.effectiveProStatus {
                                            // Close paywall immediately
                                            isPresented = false
                                            
                                            // Show confetti on home page after brief delay
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                                showingConfetti = true
                                            }
                                        } else if subscriptionManager.errorMessage != nil {
                                            showingAlert = true
                                        }
                                    }
                                }
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.7))
                            }
                            .padding(.bottom, 30)
                        }
                        .padding(.horizontal, 24)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Not Now") {
                isPresented = false
            }
            .foregroundColor(.gray))
            .onAppear {
                Task {
                    await subscriptionManager.fetchOfferings()
                }
            }
            .alert("Error", isPresented: $showingAlert) {
                Button("OK") {
                    subscriptionManager.errorMessage = nil
                }
            } message: {
                Text(subscriptionManager.errorMessage ?? "An unknown error occurred")
            }
        }
    }
}

struct FeatureCard: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.orange)
                .frame(height: 30)
            
            VStack(spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct SimpleUpgradeSheet: View {
    @Binding var isPresented: Bool
    @Binding var showingConfetti: Bool
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @State private var showingAlert = false
    @State private var pulseScale: CGFloat = 1.0
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background Image
                if UIImage(named: "paywall_background") != nil {
                    Image("paywall_background")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .ignoresSafeArea()
                        .overlay(
                            // Enhanced gradient overlay - darker at bottom
                            LinearGradient(
                                gradient: Gradient(stops: [
                                    .init(color: Color.black.opacity(0.3), location: 0.0),
                                    .init(color: Color.black.opacity(0.6), location: 0.5),
                                    .init(color: Color.black.opacity(0.9), location: 1.0)
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            .ignoresSafeArea()
                        )
                } else {
                    // Fallback gradient background - enhanced with darker bottom
                    LinearGradient(
                        gradient: Gradient(stops: [
                            .init(color: Color.black, location: 0.0),
                            .init(color: Color.black, location: 0.5),
                            .init(color: Color(hex: "2A0000"), location: 0.8),
                            .init(color: Color(hex: "0A0000"), location: 1.0)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .ignoresSafeArea()
                }
                
                if subscriptionManager.isLoading {
                    // Loading overlay
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    
                    VStack(spacing: 16) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .red))
                            .scaleEffect(1.5)
                        
                        VStack(spacing: 12) {
                            Text("Processing Purchase")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                            
                            Text("Please don't close the app")
                                .font(.headline)
                                .foregroundColor(.white.opacity(0.8))
                                .multilineTextAlignment(.center)
                        }
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 32) {
                            // Header
                            VStack(spacing: 16) {
                                Image(systemName: "crown.fill")
                                    .font(.system(size: 50))
                                    .foregroundColor(.red)
                                    .shadow(color: .red.opacity(0.4), radius: 12, x: 0, y: 6)
                                
                                Text("BoxScore Pro")
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundStyle(
                                        LinearGradient(
                                            gradient: Gradient(colors: [Color.orange, Color.red]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                
                                Text("Lifetime Access")
                                    .font(.title3)
                                    .fontWeight(.medium)
                                    .foregroundColor(.white)
                                    .opacity(0.9)
                            }
                            .padding(.top, 20)
                            
                            // Price Display
                            VStack(spacing: 6) {
                                Text("One-time payment")
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.8))
                                
                                Text(subscriptionManager.lifetimePrice)
                                    .font(.system(size: 36, weight: .bold, design: .rounded))
                                    .foregroundColor(.red)
                                    .shadow(color: .red.opacity(0.3), radius: 6, x: 0, y: 3)
                            }
                            
                            // Features
                            VStack(alignment: .leading, spacing: 16) {
                                FeatureRow(icon: "checkmark.circle.fill", text: "All premium widgets unlocked")
                                FeatureRow(icon: "checkmark.circle.fill", text: "Choose your favorite driver or team")
                                FeatureRow(icon: "checkmark.circle.fill", text: "Advanced lock screen widgets")
                                FeatureRow(icon: "checkmark.circle.fill", text: "Remove annoying ads")
                            }
                            
                            // CTA Button with Pulse Animation
                            VStack(spacing: 16) {
                                Button(action: {
                                    Task {
                                        let success = await subscriptionManager.purchaseLifetime()
                                        
                                        if success {
                                            // Close paywall immediately
                                            isPresented = false
                                            
                                            // Show confetti on home page after a brief delay
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                                showingConfetti = true
                                            }
                                        } else if subscriptionManager.errorMessage != nil {
                                            showingAlert = true
                                        }
                                    }
                                }) {
                                    HStack(spacing: 12) {
                                        Image(systemName: "crown.fill")
                                            .font(.title2)
                                        
                                        Text("Get Pro")
                                            .font(.title2)
                                            .fontWeight(.bold)
                                    }
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 18)
                                    .background(Color.red)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                    .scaleEffect(pulseScale)
                                    .shadow(color: .red.opacity(0.6), radius: 10, x: 0, y: 5)
                                }
                                .disabled(subscriptionManager.isLoading)
                                .onAppear {
                                    withAnimation(
                                        Animation.easeInOut(duration: 1.0)
                                            .repeatForever(autoreverses: true)
                                    ) {
                                        pulseScale = 1.05
                                    }
                                }
                                
                                // Restore Purchases Button
                                Button("Restore Purchases") {
                                    Task {
                                        let success = await subscriptionManager.restorePurchases()
                                        if success && subscriptionManager.effectiveProStatus {
                                            // Close paywall immediately
                                            isPresented = false
                                            
                                            // Show confetti on home page after brief delay
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                                showingConfetti = true
                                            }
                                        } else if subscriptionManager.errorMessage != nil {
                                            showingAlert = true
                                        }
                                    }
                                }
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.7))
                            }
                            
                            Spacer(minLength: 20)
                        }
                        .padding(.horizontal, 20)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Not Now") {
                isPresented = false
            }
            .foregroundColor(.gray))
            .onAppear {
                Task {
                    await subscriptionManager.fetchOfferings()
                }
            }
            .alert("Error", isPresented: $showingAlert) {
                Button("OK") {
                    subscriptionManager.errorMessage = nil
                }
            } message: {
                Text(subscriptionManager.errorMessage ?? "An unknown error occurred")
            }
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundColor(.white)
                .shadow(color: .white.opacity(0.3), radius: 2, x: 0, y: 1)
            
            Text(text)
                .font(.body)
                .fontWeight(.semibold)
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Confetti Animation

struct ConfettiView: View {
    @Binding var isActive: Bool
    @State private var particles: [ConfettiParticle] = []
    
    var body: some View {
        ZStack {
            ForEach(particles, id: \.id) { particle in
                Circle()
                    .fill(particle.color)
                    .frame(width: particle.size, height: particle.size)
                    .position(x: particle.x, y: particle.y)
                    .opacity(particle.opacity)
            }
        }
        .ignoresSafeArea()
        .onChange(of: isActive) { active in
            if active {
                startConfetti()
            } else {
                particles.removeAll()
            }
        }
    }
    
    private func startConfetti() {
        particles.removeAll()
        
        // Create multiple bursts
        for burst in 0..<3 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(burst) * 0.3) {
                createParticles()
            }
        }
        
        // Auto-stop after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            isActive = false
        }
    }
    
    private func createParticles() {
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height
        
        for _ in 0..<50 {
            let particle = ConfettiParticle(
                x: Double.random(in: 0...screenWidth),
                y: -50,
                size: Double.random(in: 4...12),
                color: [.red, .orange, .yellow, .green, .blue, .purple, .pink].randomElement() ?? .red,
                opacity: 1.0
            )
            particles.append(particle)
            
            // Animate particle falling
            withAnimation(.easeIn(duration: Double.random(in: 2...4))) {
                if let index = particles.firstIndex(where: { $0.id == particle.id }) {
                    particles[index].y = screenHeight + 100
                    particles[index].x += Double.random(in: -100...100)
                    particles[index].opacity = 0.0
                }
            }
        }
    }
}

struct ConfettiParticle {
    let id = UUID()
    var x: Double
    var y: Double
    let size: Double
    let color: Color
    var opacity: Double
}

#Preview {
    ContentView()
}
