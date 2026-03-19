import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var selectedTab = 0
    @State private var showingAddEntry = false

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationView {
                DayView(date: Date(), showingAddEntry: $showingAddEntry)
                    .navigationTitle("Today")
                    .toolbar {
                        ToolbarItem(placement: .primaryAction) {
                            Button(action: { showingAddEntry = true }) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title3)
                            }
                        }
                    }
            }
            .tabItem { Label("Today", systemImage: "clock.fill") }
            .tag(0)

            NavigationView {
                HistoryView()
                    .navigationTitle("History")
            }
            .tabItem { Label("History", systemImage: "calendar") }
            .tag(1)

            NavigationView {
                StatsView()
                    .navigationTitle("Stats")
            }
            .tabItem { Label("Stats", systemImage: "chart.bar.fill") }
            .tag(2)

            NavigationView {
                ExportView()
                    .navigationTitle("Export")
            }
            .tabItem { Label("Export", systemImage: "square.and.arrow.up") }
            .tag(3)
        }
        .sheet(isPresented: $showingAddEntry) {
            AddEntryView(defaultDate: Date())
                .frame(minWidth: 460, minHeight: 560)
        }
    }
}
