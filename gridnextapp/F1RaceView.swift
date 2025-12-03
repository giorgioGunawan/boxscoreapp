import SwiftUI

struct F1RaceView: View {
    @State private var currentRace: F1Race?
    @State private var isLoading = false
    
    var body: some View {
        VStack {
            if isLoading {
                ProgressView()
                    .tint(F1RaceStyle.accentColor)
            } else if let race = currentRace {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("ROUND \(race.round)")
                            .modifier(F1RaceStyle.SessionStyle(isWidget: false))
                        Spacer()
                        Image(systemName: "flag.checkered")
                            .foregroundColor(F1RaceStyle.accentColor)
                    }
                    
                    Text(race.name)
                        .modifier(F1RaceStyle.TitleStyle(isWidget: false))
                    
                    Text(race.location)
                        .modifier(F1RaceStyle.SubtitleStyle(isWidget: false))
                    
                    if let nextSession = race.nextUpcomingSession() {
                        Spacer()
                            .frame(height: 20)
                        
                        HStack {
                            Text(nextSession.name)
                                .modifier(F1RaceStyle.SessionStyle(isWidget: false))
                            
                            Spacer()
                            
                            Text(Date(timeIntervalSince1970: TimeInterval(nextSession.timestamp)), style: .relative)
                                .modifier(F1RaceStyle.TimeStyle(isWidget: false))
                        }
                    }
                }
                .modifier(F1RaceStyle.CardStyle(isWidget: false))
            } else {
                Text("No upcoming races")
                    .modifier(F1RaceStyle.SubtitleStyle(isWidget: false))
            }
            
            Spacer()
            
            Text("Add this view as a widget to your home screen")
                .modifier(F1RaceStyle.SubtitleStyle(isWidget: false))
                .multilineTextAlignment(.center)
                .padding()
        }
        .padding()
        .background(F1RaceStyle.backgroundColor)
        .onAppear(perform: loadData)
        .refreshable {
            await refreshData()
        }
    }
    
    private func loadData() {
        if let races = F1SharedData.loadRaces() {
            updateCurrentRace(from: races)
        }
        Task {
            await refreshData()
        }
    }
    
    private func refreshData() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let url = URL(string: "https://f1apibackend-1.onrender.com/api/races")!
            let (data, _) = try await URLSession.shared.data(from: url)
            let races = try JSONDecoder().decode([F1Race].self, from: data)
            
            F1SharedData.saveRaces(races)
            updateCurrentRace(from: races)
        } catch {
            print("Error loading data: \(error)")
        }
    }
    
    private func updateCurrentRace(from races: [F1Race]) {
        let sortedRaces = races.sorted { $0.round < $1.round }
        let now = Date()
        currentRace = sortedRaces.first { race in
            if let nextSession = race.nextUpcomingSession() {
                let sessionDate = Date(timeIntervalSince1970: TimeInterval(nextSession.timestamp))
                return sessionDate > now
            }
            return false
        }
    }
} 